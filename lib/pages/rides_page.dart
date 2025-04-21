import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pocketbase/pocketbase.dart';
import '../constants/app_colors.dart';
import '../models/ride_model.dart';
import '../services/pocketbase_service.dart';
import '../widgets/ride_card.dart';
import '../widgets/compact_ride_card.dart';

class RidesPage extends StatefulWidget {
  const RidesPage({super.key});

  @override
  State<RidesPage> createState() => _RidesPageState();
}

class _RidesPageState extends State<RidesPage>
    with SingleTickerProviderStateMixin {
  final PocketBaseService _pbService = PocketBaseService();
  List<RideModel> _userRides = [];
  List<RideModel> _allRides = [];
  bool _isLoading = true;
  String? _error;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadRides();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadRides() async {
    if (!mounted) return; // Проверяем, что виджет все еще в дереве

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Загружаем поездки пользователя и все доступные поездки параллельно
      print('Starting to load rides...');
      final userRidesFuture = _pbService.getUserRides();
      final allRidesFuture = _pbService.getAllPublicRides();

      final results = await Future.wait([userRidesFuture, allRidesFuture]);
      final userRides = results[0];
      final allRides = results[1];

      print(
          'Loaded ${userRides.length} user rides and ${allRides.length} public rides');

      if (allRides.isEmpty && userRides.isEmpty) {
        print('WARNING: No rides found in database!');
      } else {
        print('Rides details:');

        if (userRides.isNotEmpty) {
          print('User rides:');
          for (var i = 0; i < userRides.length; i++) {
            final ride = userRides[i];
            print(
                'User ride $i: ${ride.id} - ${ride.fromAreaName} to ${ride.toAreaName}');
            print('- Status: ${ride.statusText}');
            print('- User: ${ride.userName} (${ride.userId})');
          }
        }

        if (allRides.isNotEmpty) {
          print('Public rides:');
          for (var i = 0; i < allRides.length; i++) {
            final ride = allRides[i];
            print(
                'Public ride $i: ${ride.id} - ${ride.fromAreaName} to ${ride.toAreaName}');
            print('- Status: ${ride.statusText}');
            print('- User: ${ride.userName} (${ride.userId})');
          }
        }
      }

      if (!mounted) return; // Проверяем снова перед setState

      setState(() {
        _userRides = userRides;
        _allRides = allRides;
        _isLoading = false;
      });

      print('Rides state updated. UI should refresh now.');
    } catch (e) {
      print('Error loading rides: $e');
      if (!mounted) return; // Проверяем снова перед setState

      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _cancelRide(String rideId) async {
    try {
      await _pbService.cancelRide(rideId);
      if (!mounted) return; // Проверяем перед обновлением списка

      // Обновляем список поездок после отмены
      await _loadRides();

      if (!mounted) return; // Проверяем перед показом SnackBar

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Поездка отменена'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return; // Проверяем перед показом ошибки

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка при отмене поездки: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _editRide(RideModel ride) {
    context.go('/', extra: {'rideToEdit': ride});
    // Убираем автоматическое обновление, так как оно может вызвать ошибку
    // Вместо этого обновление будет происходить при возвращении на страницу
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Поездки'),
        backgroundColor: AppColors.primary,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Мои поездки'),
            Tab(text: 'Все поездки'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadRides,
            tooltip: 'Обновить',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorState()
              : _buildTabView(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.go('/');
          // Обновляем список поездок после возвращения с экрана создания
          Future.delayed(const Duration(milliseconds: 300), _loadRides);
        },
        backgroundColor: AppColors.primary,
        tooltip: 'Создать новую поездку',
        child: const Icon(Icons.add, color: Colors.black),
      ),
    );
  }

  Widget _buildTabView() {
    print(
        'Building tab view with ${_userRides.length} user rides and ${_allRides.length} all rides');

    return TabBarView(
      controller: _tabController,
      children: [
        // Вкладка "Мои поездки"
        _userRides.isEmpty ? _buildEmptyStateMyRides() : _buildUserRidesList(),

        // Вкладка "Все поездки"
        _allRides.isEmpty ? _buildEmptyStateAllRides() : _buildAllRidesList(),
      ],
    );
  }

  Widget _buildUserRidesList() {
    // Разделяем поездки на активные и исторические
    final activeRides =
        _userRides.where((ride) => ride.status == RideStatus.pending).toList();
    final historicalRides =
        _userRides.where((ride) => ride.status != RideStatus.pending).toList();

    return RefreshIndicator(
      onRefresh: _loadRides,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Активные поездки
            if (activeRides.isNotEmpty) ...[
              const Text(
                'В обработке',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ...activeRides.map((ride) => Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: RideCard(
                      ride: ride,
                      onCancel: () => _cancelRide(ride.id),
                      onEdit: () => _editRide(ride),
                      showActions: true,
                    ),
                  )),
              const SizedBox(height: 24),
            ],

            // История поездок
            if (historicalRides.isNotEmpty) ...[
              const Text(
                'История',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ...historicalRides.map((ride) => Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: RideCard(
                      ride: ride,
                      showActions: false,
                    ),
                  )),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAllRidesList() {
    print('Building all rides list with ${_allRides.length} rides');

    // If there are no rides, show empty state
    if (_allRides.isEmpty) {
      return _buildEmptyStateAllRides();
    }

    return RefreshIndicator(
      onRefresh: _loadRides,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _allRides.length,
        itemBuilder: (context, index) {
          final ride = _allRides[index];
          print(
              'Building ride card for ride $index: ${ride.fromAreaName} to ${ride.toAreaName}');

          // Вывод подробной информации о поездке для отладки
          print('Ride $index details:');
          print('- ID: ${ride.id}');
          print('- From: ${ride.fromAreaName} (${ride.fromArea})');
          print('- To: ${ride.toAreaName} (${ride.toArea})');
          print('- Date: ${ride.formattedDate}');
          print('- Time: ${ride.formattedTime}');
          print('- Status: ${ride.statusText}');
          print('- User: ${ride.userName} (${ride.userId})');

          return CompactRideCard(ride: ride);
        },
      ),
    );
  }

  Widget _buildEmptyStateMyRides() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.directions_car,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'У вас пока нет поездок',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  context.go('/');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.black,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                icon: const Icon(Icons.add),
                label: const Text('Создать поездку'),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: _createDemoRides,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                icon: const Icon(Icons.auto_fix_high),
                label: const Text('Создать демо-поездки'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyStateAllRides() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Нет доступных поездок',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: _loadRides,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.black,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                icon: const Icon(Icons.refresh),
                label: const Text('Обновить'),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: _createDemoRides,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                icon: const Icon(Icons.add),
                label: const Text('Создать демо-поездки'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Ошибка: $_error',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.red),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadRides,
            child: const Text('Повторить'),
          ),
        ],
      ),
    );
  }

  Future<void> _createDemoRides() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _pbService.createDemoRides();

      if (!mounted) return;

      if (result) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Демо-поездки успешно созданы'),
            backgroundColor: Colors.green,
          ),
        );
        // Refresh rides list
        await _loadRides();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Не удалось создать демо-поездки'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка при создании демо-поездок: $e'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }
}
