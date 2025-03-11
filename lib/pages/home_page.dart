import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';
import '../constants/app_colors.dart';
import '../widgets/area_selector.dart';
import '../services/pocketbase_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  RecordModel? fromArea;
  RecordModel? toArea;
  bool isDriver = false;
  final PocketBaseService _pbService = PocketBaseService();
  DateTime? selectedDate;
  TimeOfDay? selectedTime;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Poputka',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User type selector
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => setState(() => isDriver = false),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          !isDriver ? AppColors.primary : Colors.white,
                      foregroundColor: !isDriver ? Colors.white : Colors.black,
                    ),
                    child: const Text('Найти попутчика'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => setState(() => isDriver = true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          isDriver ? AppColors.primary : Colors.white,
                      foregroundColor: isDriver ? Colors.white : Colors.black,
                    ),
                    child: const Text('Я водитель'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // From and To fields with area selectors
            const Text('Выберите маршрут:',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            AreaSelector(
              hintText: 'Откуда',
              excludeArea: toArea,
              onAreaSelected: (area) {
                setState(() => fromArea = area);
                print(
                    'Selected from area: ${area.data['name']} (ID: ${area.id})');
              },
            ),
            if (fromArea != null)
              Padding(
                padding: const EdgeInsets.only(top: 4.0, left: 8.0),
                child: Text(
                  'Выбрано: ${fromArea!.data['name']}',
                  style: TextStyle(
                    color: Colors.green[700],
                    fontSize: 12,
                  ),
                ),
              ),
            const SizedBox(height: 16),
            AreaSelector(
              hintText: 'Куда',
              excludeArea: fromArea,
              onAreaSelected: (area) {
                setState(() => toArea = area);
                print(
                    'Selected to area: ${area.data['name']} (ID: ${area.id})');
              },
            ),
            if (toArea != null)
              Padding(
                padding: const EdgeInsets.only(top: 4.0, left: 8.0),
                child: Text(
                  'Выбрано: ${toArea!.data['name']}',
                  style: TextStyle(
                    color: Colors.green[700],
                    fontSize: 12,
                  ),
                ),
              ),
            const SizedBox(height: 24),

            // Date and Time selectors
            const Text('Выберите время:',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _buildDateSelector()),
                const SizedBox(width: 16),
                Expanded(child: _buildTimeSelector()),
              ],
            ),
            const SizedBox(height: 24),

            // Search button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (fromArea != null && toArea != null) {
                    print(
                        'Searching for a ride from ${fromArea!.data['name']} to ${toArea!.data['name']}');
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Поиск маршрута: ${fromArea!.data['name']} → ${toArea!.data['name']}',
                        ),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Пожалуйста, выберите откуда и куда'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  isDriver ? 'Найти пассажиров' : 'Найти водителя',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
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
        onTap: () async {
          final date = await showDatePicker(
            context: context,
            initialDate: DateTime.now(),
            firstDate: DateTime.now(),
            lastDate: DateTime.now().add(const Duration(days: 365)),
          );

          if (date != null) {
            setState(() {
              selectedDate = date;
            });
          }
        },
        child: Row(
          children: [
            const Icon(Icons.calendar_today),
            const SizedBox(width: 8),
            Text(
              selectedDate != null
                  ? '${selectedDate!.day}.${selectedDate!.month}.${selectedDate!.year}'
                  : 'Выберите дни',
            ),
            const Spacer(),
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
        onTap: () async {
          final time = await showTimePicker(
            context: context,
            initialTime: TimeOfDay.now(),
          );

          if (time != null) {
            setState(() {
              selectedTime = time;
            });
          }
        },
        child: Row(
          children: [
            const Icon(Icons.access_time),
            const SizedBox(width: 8),
            Text(
              selectedTime != null
                  ? '${selectedTime!.hour}:${selectedTime!.minute.toString().padLeft(2, '0')}'
                  : 'Выберите время',
            ),
            const Spacer(),
            const Icon(Icons.arrow_drop_down),
          ],
        ),
      ),
    );
  }
}
