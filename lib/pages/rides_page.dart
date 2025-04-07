import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../constants/app_colors.dart';
import '../models/ride_model.dart';
import '../services/pocketbase_service.dart';
import '../widgets/ride_card.dart';

class RidesPage extends StatefulWidget {
  const RidesPage({super.key});

  @override
  State<RidesPage> createState() => _RidesPageState();
}

class _RidesPageState extends State<RidesPage> {
  final PocketBaseService _pbService = PocketBaseService();
  List<RideModel> _rides = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadRides();
  }

  Future<void> _loadRides() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final rides = await _pbService.getUserRides();
      setState(() {
        _rides = rides;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _cancelRide(String rideId) async {
    try {
      await _pbService.cancelRide(rideId);
      // Обновляем список поездок после отмены
      _loadRides();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Поездка отменена'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка при отмене поездки: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _editRide(RideModel ride) {
    context.go('/', extra: {'rideToEdit': ride});
    // После возвращения с экрана редактирования обновим список
    Future.delayed(const Duration(milliseconds: 300), _loadRides);
  }

  @override
  Widget build(BuildContext context) {
    // Разделяем поездки на активные и исторические
    final activeRides =
        _rides.where((ride) => ride.status == RideStatus.pending).toList();
    final historicalRides =
        _rides.where((ride) => ride.status != RideStatus.pending).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Мои поездки'),
        backgroundColor: AppColors.primary,
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
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Ошибка: $_error'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadRides,
                        child: const Text('Повторить'),
                      ),
                    ],
                  ),
                )
              : _rides.isEmpty
                  ? _buildEmptyState()
                  : RefreshIndicator(
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
                                    padding:
                                        const EdgeInsets.only(bottom: 16.0),
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
                                    padding:
                                        const EdgeInsets.only(bottom: 16.0),
                                    child: RideCard(
                                      ride: ride,
                                      showActions: false,
                                    ),
                                  )),
                            ],
                          ],
                        ),
                      ),
                    ),
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

  Widget _buildEmptyState() {
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
          ElevatedButton.icon(
            onPressed: () {
              context.go('/');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            icon: const Icon(Icons.add),
            label: const Text('Создать поездку'),
          ),
        ],
      ),
    );
  }
}
