import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../models/ride_model.dart';
import 'user_details_modal.dart';

class RideDetailsModal extends StatelessWidget {
  final RideModel ride;
  final VoidCallback? onContactPressed;

  const RideDetailsModal({
    super.key,
    required this.ride,
    this.onContactPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: contentBox(context),
    );
  }

  Widget contentBox(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        shape: BoxShape.rectangle,
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Заголовок с типом поездки и кнопкой закрытия
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Детали поездки',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const Divider(),

            // Информация о маршруте
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.route, color: Colors.blue, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              'Откуда:',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              ride.fromAreaName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Text(
                              'Куда:',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              ride.toAreaName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Информация о дате и времени
            _buildInfoRow(
              Icons.calendar_today,
              'Дата поездки',
              ride.formattedDate,
            ),
            _buildInfoRow(
              Icons.access_time,
              'Время отправления',
              ride.formattedTime,
            ),

            // Статус поездки
            _buildInfoRow(
              _getStatusIcon(),
              'Статус',
              ride.statusText,
              valueColor: ride.statusColor,
            ),

            // Тип поездки и количество мест
            _buildInfoRow(
              ride.isDriver ? Icons.drive_eta : Icons.person,
              'Тип',
              ride.isDriver ? 'Водитель' : 'Пассажир',
            ),

            if (ride.isDriver)
              _buildInfoRow(
                Icons.event_seat,
                'Мест',
                '${ride.availableSeats} ${_getSeatsText(ride.availableSeats)}',
              ),

            // Цена
            if (ride.price != null)
              _buildInfoRow(
                Icons.attach_money,
                'Цена',
                '${ride.price!.toStringAsFixed(0)} ₽',
                valueColor: Colors.green,
              ),

            // Примечания
            if (ride.notes != null && ride.notes!.isNotEmpty)
              _buildInfoRow(
                Icons.notes,
                'Примечания',
                ride.notes!,
              ),

            const SizedBox(height: 16),
            const Divider(),

            // Информация о пользователе
            const SizedBox(height: 8),
            const Text(
              'Контактная информация',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            // Аватар и имя пользователя
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.primary,
                  child: Text(
                    ride.userInitial,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ride.userName ?? 'Пользователь',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      if (ride.userPhone != null)
                        Text(
                          ride.userPhone!,
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 14,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Кнопка связаться
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // Закрываем текущее модальное окно
                  Navigator.of(context).pop();

                  // Открываем модальное окно с подробной информацией о пользователе
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return UserDetailsModal(
                        userId: ride.userId,
                        isDriver: ride.isDriver,
                        onContactPressed: onContactPressed,
                      );
                    },
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Связаться',
                  style: TextStyle(
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

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value, {
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  color: valueColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getSeatsText(int seats) {
    if (seats == 1) return 'место';
    if (seats > 1 && seats < 5) return 'места';
    return 'мест';
  }

  IconData _getStatusIcon() {
    switch (ride.status) {
      case RideStatus.pending:
        return Icons.pending;
      case RideStatus.active:
        return Icons.directions_car;
      case RideStatus.completed:
        return Icons.check_circle;
      case RideStatus.cancelled:
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }
}
