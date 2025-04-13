import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:go_router/go_router.dart';
import '../constants/app_colors.dart';
import '../widgets/area_selector.dart';
import '../services/pocketbase_service.dart';
import '../models/ride_model.dart';

class HomePage extends StatefulWidget {
  final RideModel? rideToEdit;

  const HomePage({super.key, this.rideToEdit});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  RecordModel? fromAreaRecord;
  RecordModel? toAreaRecord;
  String? fromAreaId;
  String? toAreaId;
  bool isDriver = false;
  final PocketBaseService _pbService = PocketBaseService();
  DateTime? selectedDate;
  TimeOfDay? selectedTime;
  bool _isProcessing = false;
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  bool _isEditMode = false;
  String? _rideId;
  int _availableSeats = 4;

  @override
  void initState() {
    super.initState();

    // Если передана поездка для редактирования, заполняем поля
    if (widget.rideToEdit != null) {
      _isEditMode = true;
      _rideId = widget.rideToEdit!.id;
      fromAreaId = widget.rideToEdit!.fromArea;
      toAreaId = widget.rideToEdit!.toArea;
      isDriver = widget.rideToEdit!.isDriver;
      selectedDate = widget.rideToEdit!.date;
      selectedTime = widget.rideToEdit!.time;
      _notesController.text = widget.rideToEdit!.notes ?? '';
      _priceController.text = widget.rideToEdit!.price?.toString() ?? '';
      _availableSeats = widget.rideToEdit!.availableSeats ?? 4;

      // Загрузим записи областей для отображения в селекторах
      _loadAreaRecords();
    }
  }

  Future<void> _loadAreaRecords() async {
    if (fromAreaId != null) {
      try {
        final areas = await _pbService.getAreas();
        setState(() {
          fromAreaRecord = areas.firstWhere((area) => area.id == fromAreaId);
          if (toAreaId != null) {
            toAreaRecord = areas.firstWhere((area) => area.id == toAreaId);
          }
        });
      } catch (e) {
        print('Error loading area records: $e');
      }
    }
  }

  void _toggleUserType(bool value) {
    if (isDriver != value) {
      setState(() => isDriver = value);
    }
  }

  void _handleFromAreaSelected(RecordModel? area) {
    setState(() {
      fromAreaRecord = area;
      fromAreaId = area?.id;
    });
    if (area != null) {
      print('Selected from area: ${area.data['name']} (ID: ${area.id})');
    } else {
      print('From area selection cleared');
    }
  }

  void _handleToAreaSelected(RecordModel? area) {
    setState(() {
      toAreaRecord = area;
      toAreaId = area?.id;
    });
    if (area != null) {
      print('Selected to area: ${area.data['name']} (ID: ${area.id})');
    } else {
      print('To area selection cleared');
    }
  }

  // Swap from and to areas
  void _swapAreas() {
    final tempRecord = fromAreaRecord;
    final tempId = fromAreaId;
    setState(() {
      fromAreaRecord = toAreaRecord;
      fromAreaId = toAreaId;
      toAreaRecord = tempRecord;
      toAreaId = tempId;
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null) {
      setState(() {
        selectedDate = date;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final time = await showTimePicker(
      context: context,
      initialTime: selectedTime ?? TimeOfDay.now(),
    );

    if (time != null) {
      setState(() {
        selectedTime = time;
      });
    }
  }

  void _updateAvailableSeats(int value) {
    setState(() {
      _availableSeats = value;
    });
  }

  Future<void> _submitRide() async {
    if (_isProcessing) return; // Prevent multiple clicks

    // Validate inputs
    if (fromAreaId == null || toAreaId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Пожалуйста, выберите откуда и куда'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    if (selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Пожалуйста, выберите дату'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    if (selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Пожалуйста, выберите время'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    // Проверка цены для водителя
    if (isDriver && _priceController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Пожалуйста, укажите цену поездки'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      // Парсим цену, если она указана
      double? price;
      if (_priceController.text.isNotEmpty) {
        price = double.tryParse(_priceController.text.replaceAll(',', '.'));
      }

      RecordModel? result;

      if (_isEditMode && _rideId != null) {
        // Обновляем существующую поездку
        result = await _pbService.updateRide(
          rideId: _rideId!,
          fromAreaId: fromAreaId!,
          toAreaId: toAreaId!,
          date: selectedDate!,
          time: selectedTime!,
          isDriver: isDriver,
          availableSeats: _availableSeats,
          notes: _notesController.text,
          price: price,
        );

        if (result != null && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Поездка успешно обновлена'),
              backgroundColor: Colors.green,
            ),
          );
          // Возвращаемся на страницу поездок
          context.go('/rides');
        }
      } else {
        // Создаем новую поездку
        result = await _pbService.createRide(
          fromAreaId: fromAreaId!,
          toAreaId: toAreaId!,
          date: selectedDate!,
          time: selectedTime!,
          isDriver: isDriver,
          availableSeats: _availableSeats,
          notes: _notesController.text,
          price: price,
        );

        if (result != null && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Поездка успешно создана'),
              backgroundColor: Colors.green,
            ),
          );
          // Переходим на страницу доступных поездок
          context.go('/available-rides');
        }
      }

      if (result == null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditMode
                ? 'Не удалось обновить поездку'
                : 'Не удалось создать поездку'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditMode ? 'Редактировать поездку' : 'Poputka',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primary,
        actions: [
          // Кнопка для просмотра доступных поездок
          if (!_isEditMode)
            IconButton(
              icon: const Icon(Icons.list),
              onPressed: () => context.go('/available-rides'),
              tooltip: 'Доступные поездки',
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User type selector
              _buildUserTypeSelector(),
              const SizedBox(height: 24),

              // From and To fields with area selectors
              _buildRouteSelectors(),
              const SizedBox(height: 24),

              // Date and Time selectors
              _buildDateTimeSelectors(),
              const SizedBox(height: 24),

              // Дополнительные поля в зависимости от типа пользователя
              if (isDriver) ...[
                _buildDriverOptions(),
                const SizedBox(height: 24),
              ],

              // Notes field
              _buildNotesField(),
              const SizedBox(height: 24),

              // Submit button
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserTypeSelector() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: () => _toggleUserType(false),
            style: ElevatedButton.styleFrom(
              backgroundColor: !isDriver ? AppColors.primary : Colors.white,
              foregroundColor: !isDriver ? Colors.white : Colors.black,
            ),
            child: const Text(
              'Найти попутчика',
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ElevatedButton(
            onPressed: () => _toggleUserType(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: isDriver ? AppColors.primary : Colors.white,
              foregroundColor: isDriver ? Colors.white : Colors.black,
            ),
            child: const Text(
              'Я водитель',
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRouteSelectors() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Expanded(
              child: Text(
                'Выберите маршрут:',
                style: TextStyle(fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Swap button
            if (fromAreaRecord != null && toAreaRecord != null)
              IconButton(
                onPressed: _swapAreas,
                icon: const Icon(Icons.swap_vert),
                tooltip: 'Поменять местами',
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        AreaSelector(
          hintText: 'Откуда',
          excludeArea: toAreaRecord,
          onAreaSelected: _handleFromAreaSelected,
          selectedArea: fromAreaRecord,
        ),
        const SizedBox(height: 16),
        AreaSelector(
          hintText: 'Куда',
          excludeArea: fromAreaRecord,
          onAreaSelected: _handleToAreaSelected,
          selectedArea: toAreaRecord,
        ),
      ],
    );
  }

  Widget _buildDateTimeSelectors() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Выберите время:',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _buildDateSelector()),
            const SizedBox(width: 16),
            Expanded(child: _buildTimeSelector()),
          ],
        ),
      ],
    );
  }

  Widget _buildDateSelector() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: InkWell(
        onTap: () => _selectDate(context),
        child: Row(
          children: [
            const Icon(Icons.calendar_today),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                selectedDate != null
                    ? '${selectedDate!.day}.${selectedDate!.month}.${selectedDate!.year}'
                    : 'Выберите дни',
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(Icons.arrow_drop_down),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeSelector() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: InkWell(
        onTap: () => _selectTime(context),
        child: Row(
          children: [
            const Icon(Icons.access_time),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                selectedTime != null
                    ? '${selectedTime!.hour}:${selectedTime!.minute.toString().padLeft(2, '0')}'
                    : 'Выберите время',
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(Icons.arrow_drop_down),
          ],
        ),
      ),
    );
  }

  Widget _buildDriverOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Параметры поездки:',
            style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),

        // Цена поездки
        TextField(
          controller: _priceController,
          decoration: InputDecoration(
            labelText: 'Цена поездки (₽)',
            hintText: 'Например: 300',
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            prefixIcon: const Icon(Icons.attach_money),
          ),
          keyboardType: TextInputType.number,
        ),

        const SizedBox(height: 16),

        // Количество мест
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Количество свободных мест:'),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(
                4,
                (index) => _buildSeatSelector(index + 1),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSeatSelector(int seats) {
    final isSelected = _availableSeats == seats;

    return InkWell(
      onTap: () => _updateAvailableSeats(seats),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 60,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey.shade300,
          ),
        ),
        child: Column(
          children: [
            Icon(
              Icons.event_seat,
              color: isSelected ? Colors.white : Colors.grey,
            ),
            const SizedBox(height: 4),
            Text(
              '$seats',
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.white : Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Примечания:',
            style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextField(
          controller: _notesController,
          decoration: InputDecoration(
            hintText: 'Дополнительная информация...',
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
          ),
          maxLines: 3,
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isProcessing ? null : _submitRide,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: _isProcessing
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.black54),
                ),
              )
            : Text(
                _isEditMode
                    ? 'Сохранить изменения'
                    : (isDriver ? 'Найти пассажиров' : 'Найти водителя'),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  @override
  void dispose() {
    _notesController.dispose();
    _priceController.dispose();
    super.dispose();
  }
}
