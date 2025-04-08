import 'dart:convert';
import 'package:pocketbase/pocketbase.dart';
import 'package:flutter/material.dart';
import '../models/ride_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PocketBaseService {
  static final PocketBaseService _instance = PocketBaseService._internal();
  final PocketBase pb = PocketBase('https://restaurant-menu.fly.dev');

  // Cache for areas to prevent unnecessary API calls
  List<RecordModel>? _cachedAreas;
  DateTime? _lastFetchTime;
  final _cacheDuration = const Duration(minutes: 5);

  factory PocketBaseService() {
    return _instance;
  }

  PocketBaseService._internal();

  Future<void> initAuth() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    final userData = prefs.getString('auth_user');
    if (token != null && userData != null) {
      final recordObj = RecordModel.fromJson(jsonDecode(userData));
      pb.authStore.save(token, recordObj);
    }
  }

  Future<void> saveAuthState() async {
    final prefs = await SharedPreferences.getInstance();
    if (pb.authStore.isValid) {
      await prefs.setString('auth_token', pb.authStore.token);
      if (pb.authStore.model != null) {
        await prefs.setString(
          'auth_user',
          jsonEncode(pb.authStore.model!.toJson()),
        );
      }
    }
  }

  Future<void> clearAuth() async {
    pb.authStore.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('auth_user');
  }

  bool isAuthenticated() {
    return pb.authStore.isValid;
  }

  Future<Map<String, dynamic>?> getUserData() async {
    try {
      if (pb.authStore.isValid) {
        var userRecord = pb.authStore.model as RecordModel?;
        if (userRecord == null) {
          final record = await pb.collection('poputka_users').authRefresh();
          userRecord = pb.authStore.model as RecordModel?;
          await saveAuthState();
        }
        if (userRecord != null) {
          // Получаем полные данные пользователя
          final fullUserData =
              await pb.collection('poputka_users').getOne(userRecord.id);
          final userData = fullUserData.toJson();
          print('User data: $userData'); // Added logging
          return userData;
        } else {
          throw Exception('User data not found after refresh.');
        }
      } else {
        throw Exception('No authenticated user found');
      }
    } catch (e) {
      print('Error fetching user data: $e');
      return null;
    }
  }

  Future<bool> login(String email, String password) async {
    try {
      print('Attempting to login user with email: $email');

      final authData = await pb.collection('poputka_users').authWithPassword(
            email,
            password,
          );

      print('Login successful, saving auth state');
      await saveAuthState();
      return true;
    } catch (e) {
      print('Login error details: $e');
      return false;
    }
  }

  Future<bool> register(
      String email, String password, String name, String phone) async {
    try {
      print('Attempting to register user with email: $email');
      final body = {
        'email': email,
        'password': password,
        'passwordConfirm': password,
        'name': name,
        'username': name, // Use name as username
        'phone': phone,
      };

      final result = await pb.collection('poputka_users').create(body: body);
      print('Registration successful: ${result.id}');
      return true;
    } catch (e) {
      print('Registration error: $e');
      return false;
    }
  }

  Future<void> logout() async {
    await clearAuth();
  }

  Future<List<RecordModel>> getAreas() async {
    // Check if we have a valid cache
    final now = DateTime.now();
    if (_cachedAreas != null &&
        _lastFetchTime != null &&
        now.difference(_lastFetchTime!) < _cacheDuration) {
      print('Returning ${_cachedAreas!.length} areas from cache');
      return _cachedAreas!;
    }

    try {
      // Try to fetch areas from the PocketBase 'Area' collection
      final records = await pb.collection('poputka_area').getFullList(
            sort: 'name', // Sort alphabetically by name
          );

      print('Successfully fetched ${records.length} areas from PocketBase');

      // Update cache
      _cachedAreas = records;
      _lastFetchTime = now;

      return records;
    } catch (e) {
      print('Error fetching areas from PocketBase: $e');

      // Return fallback data if API fails
      final fallbackData = [
        RecordModel(
            id: '1', data: {'name': 'Ала-Тоо'}, created: '', updated: ''),
        RecordModel(
            id: '2', data: {'name': 'Новотель'}, created: '', updated: ''),
        RecordModel(id: '3', data: {'name': 'Центр'}, created: '', updated: ''),
        RecordModel(
            id: '4', data: {'name': 'Восток-5'}, created: '', updated: ''),
        RecordModel(id: '5', data: {'name': 'Джал'}, created: '', updated: ''),
        RecordModel(
            id: '6', data: {'name': 'Аламедин'}, created: '', updated: ''),
        RecordModel(
            id: '7', data: {'name': 'Ошский рынок'}, created: '', updated: ''),
        RecordModel(
            id: '8', data: {'name': 'Дордой'}, created: '', updated: ''),
      ];

      // Update cache with fallback data
      _cachedAreas = fallbackData;
      _lastFetchTime = now;

      return fallbackData;
    }
  }

  // Method to create a new area (for testing)
  Future<RecordModel?> createArea(String name) async {
    try {
      final record = await pb.collection('poputka_area').create(body: {
        'name': name,
      });
      print('Successfully created area: ${record.data['name']}');

      // Invalidate cache to get fresh data next time
      _cachedAreas = null;

      return record;
    } catch (e) {
      print('Error creating area: $e');
      return null;
    }
  }

  // Method to create a ride
  Future<RecordModel?> createRide({
    required String fromAreaId,
    required String toAreaId,
    required DateTime date,
    required TimeOfDay time,
    required bool isDriver,
    required int availableSeats,
    String? notes,
    double? price,
  }) async {
    try {
      // Format date and time
      final formattedDate =
          "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
      final formattedTime =
          "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:00";

      final record = await pb.collection('poputka_rides').create(body: {
        'fromArea': fromAreaId,
        'toArea': toAreaId,
        'date': '$formattedDate $formattedTime',
        'isDriver': isDriver,
        'availableSeats': availableSeats,
        'notes': notes ?? '',
        'price': price,
        'status': 'pending', // Начальный статус - "В обработке"
        'driver': pb.authStore.model?.id, // Current user as driver
      });

      return record;
    } catch (e) {
      print('Error creating ride: $e');
      return null;
    }
  }

  // Получение поездок пользователя
  Future<List<RideModel>> getUserRides() async {
    try {
      // Получаем записи из коллекции поездок
      final records = await pb.collection('poputka_rides').getFullList(
            sort: '-created',
            expand: 'fromArea,toArea',
          );

      // Преобразуем записи в модели
      final rides = <RideModel>[];
      for (final record in records) {
        // Получаем связанные области
        final fromArea = record.expand['fromArea'] as RecordModel?;
        final toArea = record.expand['toArea'] as RecordModel?;

        // Если области не найдены, пропускаем запись
        if (fromArea == null || toArea == null) continue;

        rides.add(RideModel.fromRecord(
          record,
          fromArea: fromArea,
          toArea: toArea,
        ));
      }

      return rides;
    } catch (e) {
      print('Error fetching user rides: $e');
      return [];
    }
  }

  // Получение активной поездки пользователя (в статусе "В обработке")
  Future<RideModel?> getActiveRide() async {
    try {
      final records = await pb.collection('poputka_rides').getList(
            filter: 'status = "pending"',
            sort: '-created',
            expand: 'fromArea,toArea',
            page: 1,
            perPage: 1,
          );

      if (records.items.isEmpty) return null;

      final record = records.items.first;
      final fromArea = record.expand['fromArea'] as RecordModel?;
      final toArea = record.expand['toArea'] as RecordModel?;

      if (fromArea == null || toArea == null) return null;

      return RideModel.fromRecord(
        record,
        fromArea: fromArea,
        toArea: toArea,
      );
    } catch (e) {
      print('Error fetching active ride: $e');
      return null;
    }
  }

  // Отмена поездки
  Future<bool> cancelRide(String rideId) async {
    try {
      await pb.collection('poputka_rides').update(rideId, body: {
        'status': 'cancelled',
      });
      return true;
    } catch (e) {
      print('Error cancelling ride: $e');
      return false;
    }
  }

  // Обновление поездки
  Future<RecordModel?> updateRide({
    required String rideId,
    required String fromAreaId,
    required String toAreaId,
    required DateTime date,
    required TimeOfDay time,
    required bool isDriver,
    required int availableSeats,
    String? notes,
    double? price,
  }) async {
    try {
      // Format date and time
      final formattedDate =
          "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
      final formattedTime =
          "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:00";

      final record = await pb.collection('poputka_rides').update(rideId, body: {
        'fromArea': fromAreaId,
        'toArea': toAreaId,
        'date': '$formattedDate $formattedTime',
        'isDriver': isDriver,
        'availableSeats': availableSeats,
        'notes': notes ?? '',
        'price': price,
      });

      return record;
    } catch (e) {
      print('Error updating ride: $e');
      return null;
    }
  }

  String getBannerImageUrl() {
    // Use a direct URL to an image for testing
    return 'https://raw.githubusercontent.com/flutter/website/main/src/assets/images/flutter-logo-sharing.png';
  }

  Future<bool> updateUserProfile(String name, String phone) async {
    try {
      print('Starting profile update with name: $name, phone: $phone');

      if (!pb.authStore.isValid) {
        print('User not authenticated');
        throw Exception('User not authenticated');
      }

      // Обновляем данные текущего пользователя
      final updatedRecord = await pb.collection('poputka_users').update(
        pb.authStore.model!.id,
        body: {
          'username': name,
          'name': name,
          'phone': phone,
        },
      );

      print('Profile updated successfully: ${updatedRecord.toJson()}');

      // Обновляем данные в authStore
      pb.authStore.save(pb.authStore.token, updatedRecord);
      await saveAuthState();

      return true;
    } catch (e) {
      print('Error updating user profile: $e');
      print('Error details: ${e.toString()}');
      return false;
    }
  }
}

final pocketBaseService = PocketBaseService();
