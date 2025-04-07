import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';

enum RideStatus {
  pending, // В обработке
  active, // Активная
  completed, // Завершена
  cancelled, // Отменена
}

class RideModel {
  final String id;
  final String fromArea;
  final String toArea;
  final String fromAreaName;
  final String toAreaName;
  final DateTime date;
  final TimeOfDay time;
  final bool isDriver;
  final int availableSeats;
  final String? notes;
  final double? price;
  final RideStatus status;
  final DateTime createdAt;

  RideModel({
    required this.id,
    required this.fromArea,
    required this.toArea,
    required this.fromAreaName,
    required this.toAreaName,
    required this.date,
    required this.time,
    required this.isDriver,
    required this.availableSeats,
    this.notes,
    this.price,
    required this.status,
    required this.createdAt,
  });

  // Создание модели из записи PocketBase
  factory RideModel.fromRecord(
    RecordModel record, {
    required RecordModel fromArea,
    required RecordModel toArea,
  }) {
    // Парсинг даты и времени из строки
    final DateTime dateTime = DateTime.parse(record.data['date']);

    return RideModel(
      id: record.id,
      fromArea: fromArea.id,
      toArea: toArea.id,
      fromAreaName: fromArea.data['name'].toString(),
      toAreaName: toArea.data['name'].toString(),
      date: DateTime(dateTime.year, dateTime.month, dateTime.day),
      time: TimeOfDay(hour: dateTime.hour, minute: dateTime.minute),
      isDriver: record.data['isDriver'] ?? false,
      availableSeats: record.data['availableSeats'] ?? 1,
      notes: record.data['notes'],
      price: record.data['price']?.toDouble(),
      status: _parseStatus(record.data['status'] ?? 'pending'),
      createdAt: DateTime.parse(record.created),
    );
  }

  // Преобразование строки статуса в enum
  static RideStatus _parseStatus(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return RideStatus.active;
      case 'completed':
        return RideStatus.completed;
      case 'cancelled':
        return RideStatus.cancelled;
      case 'pending':
      default:
        return RideStatus.pending;
    }
  }

  // Получение строкового представления статуса
  String get statusText {
    switch (status) {
      case RideStatus.pending:
        return 'В обработке';
      case RideStatus.active:
        return 'Активна';
      case RideStatus.completed:
        return 'Завершена';
      case RideStatus.cancelled:
        return 'Отменена';
    }
  }

  // Получение цвета для статуса
  Color get statusColor {
    switch (status) {
      case RideStatus.pending:
        return Colors.orange;
      case RideStatus.active:
        return Colors.green;
      case RideStatus.completed:
        return Colors.blue;
      case RideStatus.cancelled:
        return Colors.red;
    }
  }

  // Форматирование даты
  String get formattedDate {
    return '${date.day}.${date.month}.${date.year}';
  }

  // Форматирование времени
  String get formattedTime {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}
