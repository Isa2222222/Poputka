import 'package:flutter/material.dart';
import '../models/ride_model.dart';

class RideCard extends StatelessWidget {
  final RideModel ride;
  final VoidCallback? onCancel;
  final VoidCallback? onEdit;
  final bool showActions;

  const RideCard({
    super.key,
    required this.ride,
    this.onCancel,
    this.onEdit,
    this.showActions = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: ride.statusColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Верхняя часть с датой и статусом
          _buildHeader(),

          // Основная информация о поездке
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Маршрут
                _buildRoute(),
                const SizedBox(height: 16),

                // Время и тип поездки
                _buildDetails(),

                // Примечания
                if (ride.notes != null && ride.notes!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildNotes(),
                ],

                // Кнопки действий
                if (showActions && ride.status == RideStatus.pending) ...[
                  const SizedBox(height: 16),
                  _buildActions(),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: ride.statusColor.withOpacity(0.1),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Дата поездки
          Text(
            ride.formattedDate,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),

          // Статус поездки
          Row(
            children: [
              _getStatusIcon(),
              const SizedBox(width: 8),
              Text(
                ride.statusText,
                style: TextStyle(
                  color: ride.statusColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRoute() {
    return Row(
      children: [
        const Icon(Icons.route, color: Colors.blue),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Откуда: ${ride.fromAreaName}',
                style: const TextStyle(fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                'Куда: ${ride.toAreaName}',
                style: const TextStyle(fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Первая строка: время и тип поездки
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Время
            Expanded(
              child: Row(
                children: [
                  const Icon(Icons.access_time, color: Colors.orange),
                  const SizedBox(width: 8),
                  Text(
                    ride.formattedTime,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),

            // Тип поездки (водитель/пассажир)
            Expanded(
              child: Row(
                children: [
                  Icon(
                    ride.isDriver ? Icons.drive_eta : Icons.person,
                    color: ride.isDriver ? Colors.green : Colors.purple,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    ride.isDriver ? 'Водитель' : 'Пассажир',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ],
        ),

        // Вторая строка: цена и места
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Цена (если указана)
            if (ride.price != null)
              Expanded(
                child: Row(
                  children: [
                    const Icon(Icons.attach_money, color: Colors.green),
                    const SizedBox(width: 8),
                    Text(
                      '${ride.price!.toStringAsFixed(0)} ₽',
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              )
            else
              const Spacer(),

            // Количество мест (только для водителя)
            if (ride.isDriver)
              Expanded(
                child: Row(
                  children: [
                    const Icon(Icons.event_seat, color: Colors.blueGrey),
                    const SizedBox(width: 8),
                    Text(
                      '${ride.availableSeats} ${_getSeatsText(ride.availableSeats)}',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }

  String _getSeatsText(int seats) {
    if (seats == 1) return 'место';
    if (seats > 1 && seats < 5) return 'места';
    return 'мест';
  }

  Widget _buildNotes() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.notes, color: Colors.grey),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Примечания:',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                ride.notes!,
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // Кнопка редактирования
        if (onEdit != null)
          TextButton.icon(
            onPressed: onEdit,
            icon: const Icon(Icons.edit),
            label: const Text('Изменить'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.blue,
            ),
          ),

        // Кнопка отмены
        if (onCancel != null) ...[
          const SizedBox(width: 8),
          TextButton.icon(
            onPressed: onCancel,
            icon: const Icon(Icons.cancel),
            label: const Text('Отменить'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
          ),
        ],
      ],
    );
  }

  Widget _getStatusIcon() {
    switch (ride.status) {
      case RideStatus.pending:
        return const Icon(Icons.pending, color: Colors.orange);
      case RideStatus.active:
        return const Icon(Icons.directions_car, color: Colors.green);
      case RideStatus.completed:
        return const Icon(Icons.check_circle, color: Colors.green);
      case RideStatus.cancelled:
        return const Icon(Icons.cancel, color: Colors.red);
      default:
        return const Icon(Icons.help, color: Colors.grey);
    }
  }
}
