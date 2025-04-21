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
  // User information
  final String userId;
  final String? userName;
  final String? userPhone;
  final String? userEmail;

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
    required this.userId,
    this.userName,
    this.userPhone,
    this.userEmail,
  });

  // Создание модели из записи PocketBase
  factory RideModel.fromRecord(
    RecordModel record, {
    required RecordModel fromArea,
    required RecordModel toArea,
    RecordModel? userData,
  }) {
    try {
      print('Creating RideModel from record: ${record.id}');
      print('- fromArea: ${fromArea.id}, ${fromArea.data['name']}');
      print('- toArea: ${toArea.id}, ${toArea.data['name']}');
      print('- userData: ${userData?.id}');

      // Парсинг даты и времени из строки
      DateTime dateTime;
      try {
        dateTime = DateTime.parse(record.data['date'] ?? '');
      } catch (e) {
        print('Error parsing date: ${record.data['date']} - $e');
        dateTime = DateTime.now(); // Default to current date/time
      }

      // Parse price safely
      double? price;
      if (record.data['price'] != null) {
        try {
          if (record.data['price'] is int) {
            price = (record.data['price'] as int).toDouble();
          } else if (record.data['price'] is double) {
            price = record.data['price'];
          } else if (record.data['price'] is String) {
            price = double.tryParse(record.data['price']);
          }
        } catch (e) {
          print('Error parsing price: ${record.data['price']} - $e');
        }
      }

      return RideModel(
        id: record.id,
        fromArea: fromArea.id,
        toArea: toArea.id,
        fromAreaName: fromArea.data['name']?.toString() ?? 'Unknown',
        toAreaName: toArea.data['name']?.toString() ?? 'Unknown',
        date: DateTime(dateTime.year, dateTime.month, dateTime.day),
        time: TimeOfDay(hour: dateTime.hour, minute: dateTime.minute),
        isDriver: record.data['isDriver'] ?? false,
        availableSeats: record.data['availableSeats'] is int
            ? record.data['availableSeats']
            : (int.tryParse(record.data['availableSeats']?.toString() ?? '') ??
                1),
        notes: record.data['notes']?.toString(),
        price: price,
        status: _parseStatus(record.data['status']?.toString() ?? 'pending'),
        createdAt: DateTime.parse(record.created),
        userId: record.data['driver']?.toString() ?? '',
        userName: userData?.data['username']?.toString() ??
            userData?.data['name']?.toString(),
        userPhone: userData?.data['phone']?.toString(),
        userEmail: userData?.data['email']?.toString(),
      );
    } catch (e) {
      print('ERROR creating RideModel: $e');
      print('Record data: ${record.data}');
      print('Stack trace: ${StackTrace.current}');

      // Still create a minimal model with placeholders to avoid app crashes
      return RideModel(
        id: record.id,
        fromArea: fromArea.id,
        toArea: toArea.id,
        fromAreaName: fromArea.data['name']?.toString() ?? 'Unknown Area',
        toAreaName: toArea.data['name']?.toString() ?? 'Unknown Area',
        date: DateTime.now(),
        time: TimeOfDay.now(),
        isDriver: false,
        availableSeats: 1,
        status: RideStatus.pending,
        createdAt: DateTime.now(),
        userId: record.data['driver']?.toString() ?? '',
      );
    }
  }

  // Преобразование строки статуса в enum
  static RideStatus _parseStatus(String? status) {
    if (status == null) return RideStatus.pending;

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

  // Получение инициала имени пользователя
  String get userInitial {
    if (userName == null || userName!.isEmpty) return 'П';
    return userName![0].toUpperCase();
  }

  // Получение краткого имени пользователя (Ф. Имя)
  String get userShortName {
    if (userName == null || userName!.isEmpty) return 'Ф. Имя';

    final nameParts = userName!.split(' ');
    if (nameParts.length > 1) {
      // Если есть фамилия и имя
      return '${nameParts[0][0]}. ${nameParts[1]}';
    } else {
      // Если только одно слово
      return userName!;
    }
  }

  // Получение строки маршрута
  String get routeString {
    return '$fromAreaName — $toAreaName';
  }
}
