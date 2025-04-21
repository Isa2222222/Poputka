import 'dart:convert';
import 'package:pocketbase/pocketbase.dart';
import 'package:flutter/material.dart';
import '../models/ride_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PocketBaseService {
  static final PocketBaseService _instance = PocketBaseService._internal();
  final PocketBase pb = PocketBase('https://restaurant-menu.fly.dev');

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

  // Метод для создания поездки
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

      print('Attempting to create record in poputka_ride collection...');

      // Check authentication first
      if (!pb.authStore.isValid || pb.authStore.model == null) {
        print('ERROR: User not authenticated');
        return null;
      }

      print('Current user ID: ${pb.authStore.model!.id}');
      print('Creating ride with data:');
      print('- fromArea: $fromAreaId');
      print('- toArea: $toAreaId');
      print('- date: $formattedDate $formattedTime');
      print('- isDriver: $isDriver');
      print('- availableSeats: $availableSeats');
      print('- notes: $notes');
      print('- price: $price');

      // Verify that fromArea and toArea exist before creating the ride
      try {
        await pb.collection('poputka_area').getOne(fromAreaId);
        await pb.collection('poputka_area').getOne(toAreaId);
        print('Verified that fromArea and toArea exist');
      } catch (e) {
        print('ERROR: Could not verify area IDs - $e');
        return null;
      }

      // Create the record
      final record = await pb.collection('poputka_ride').create(body: {
        'fromArea': fromAreaId,
        'toArea': toAreaId,
        'date': '$formattedDate $formattedTime',
        'isDriver': isDriver,
        'availableSeats': availableSeats,
        'notes': notes ?? '',
        'price': price,
        'status': 'pending', // Начальный статус - "В обработке"
        'driver': pb.authStore.model!.id, // Current user as driver
      });

      print('Record created successfully: ${record.id}');
      print('Record data: ${record.data}');

      // Verify the record was created correctly by fetching it with expand
      try {
        final createdRecord = await pb.collection('poputka_ride').getOne(
              record.id,
              expand: 'fromArea,toArea,driver',
            );
        print('Verified created record: ${createdRecord.id}');
        print('Expand data: ${createdRecord.expand}');
      } catch (e) {
        print('Warning: Could not verify record with expand - $e');
      }

      return record;
    } catch (e) {
      print('Error creating ride: $e');
      print('Stack trace: ${StackTrace.current}');
      return null;
    }
  }

  // Получение поездок пользователя
  Future<List<RideModel>> getUserRides() async {
    try {
      if (!pb.authStore.isValid) {
        print('User not authenticated');
        return [];
      }

      final userId = pb.authStore.model?.id;
      if (userId == null) {
        print('User ID is null');
        return [];
      }

      print('Fetching user rides from PocketBase...');
      print('Current user ID: $userId');
      print('Auth valid: ${pb.authStore.isValid}');
      print('Token: ${pb.authStore.token.substring(0, 10)}...');

      // Check if the collection exists
      try {
        await pb.collection('poputka_ride').getList(page: 1, perPage: 1);
        print('Collection poputka_ride exists and is accessible');
      } catch (e) {
        print('Error accessing poputka_ride collection: $e');
        return [];
      }

      // First, try getting records without expand to see if any exist
      final recordsWithoutExpand =
          await pb.collection('poputka_ride').getFullList(
                sort: '-created',
                filter: 'driver = "$userId"',
              );

      print('Found ${recordsWithoutExpand.length} user rides without expand');

      if (recordsWithoutExpand.isEmpty) {
        print('No rides found for user $userId. Is the filter correct?');
        return [];
      }

      // If records exist, fetch them with expand
      final records = await pb.collection('poputka_ride').getFullList(
            sort: '-created',
            expand: 'fromArea,toArea,driver',
            filter: 'driver = "$userId"',
          );

      print('Found ${records.length} user rides with expand');

      // Debug the first record
      if (records.isNotEmpty) {
        final firstRecord = records.first;
        print('First record ID: ${firstRecord.id}');
        print('First record data: ${firstRecord.data}');
        print('First record expand: ${firstRecord.expand}');

        // Check if the required fields exist
        print('Has fromArea: ${firstRecord.data.containsKey('fromArea')}');
        print('Has toArea: ${firstRecord.data.containsKey('toArea')}');
        print('Has driver: ${firstRecord.data.containsKey('driver')}');

        // Check if these IDs exist in the database
        if (firstRecord.data.containsKey('fromArea')) {
          try {
            final area = await pb
                .collection('poputka_area')
                .getOne(firstRecord.data['fromArea']);
            print('FromArea exists: ${area.id}, ${area.data['name']}');
          } catch (e) {
            print('FromArea does not exist: ${firstRecord.data['fromArea']}');
          }
        }
      }

      // Преобразуем записи в модели
      final rides = <RideModel>[];
      for (final record in records) {
        try {
          print('Processing user ride record: ${record.id}');

          // Безопасно получаем связанные области и водителя
          RecordModel? fromArea;
          RecordModel? toArea;
          RecordModel? driver;

          // Debugging record data
          print('Record data: ${record.data}');
          print('Record expand data: ${record.expand}');

          // В первую очередь получаем данные напрямую по ID
          if (record.data.containsKey('fromArea')) {
            try {
              fromArea = await pb
                  .collection('poputka_area')
                  .getOne(record.data['fromArea']);
              print('Retrieved fromArea directly: ${fromArea.data["name"]}');
            } catch (e) {
              print('Error fetching fromArea directly: $e');
            }
          }

          if (record.data.containsKey('toArea')) {
            try {
              toArea = await pb
                  .collection('poputka_area')
                  .getOne(record.data['toArea']);
              print('Retrieved toArea directly: ${toArea.data["name"]}');
            } catch (e) {
              print('Error fetching toArea directly: $e');
            }
          }

          if (record.data.containsKey('driver')) {
            try {
              driver = await pb
                  .collection('poputka_users')
                  .getOne(record.data['driver']);
              print(
                  'Retrieved driver directly: ${driver.data["name"] ?? driver.data["username"]}');
            } catch (e) {
              print('Error fetching driver directly: $e');
            }
          }

          // Только потом пробуем получить из expand
          if (fromArea == null) {
            fromArea = _getRecordFromExpand(record.expand, 'fromArea');
            if (fromArea != null) {
              print('Retrieved fromArea from expand: ${fromArea.data["name"]}');
            }
          }

          if (toArea == null) {
            toArea = _getRecordFromExpand(record.expand, 'toArea');
            if (toArea != null) {
              print('Retrieved toArea from expand: ${toArea.data["name"]}');
            }
          }

          if (driver == null) {
            driver = _getRecordFromExpand(record.expand, 'driver');
            if (driver != null) {
              print(
                  'Retrieved driver from expand: ${driver.data["name"] ?? driver.data["username"]}');
            }
          }

          // Если driver null, попробуем использовать данные текущего пользователя
          if (driver == null) {
            print('Driver data missing, using current user data');
            try {
              final userData = await getUserData();
              if (userData != null) {
                // Создаем запись из данных пользователя
                driver = RecordModel(
                  id: userId,
                  data: userData,
                  created: '',
                  updated: '',
                );
                print('Created driver placeholder from user data');
              }
            } catch (e) {
              print('Error getting current user data: $e');
            }
          }

          // Если все равно не смогли получить, создаем заглушку
          if (fromArea == null && record.data.containsKey('fromArea')) {
            fromArea = RecordModel(
              id: record.data['fromArea'].toString(),
              data: {'name': 'Unknown Area'},
              created: '',
              updated: '',
            );
            print('Created placeholder for fromArea');
          }

          if (toArea == null && record.data.containsKey('toArea')) {
            toArea = RecordModel(
              id: record.data['toArea'].toString(),
              data: {'name': 'Unknown Area'},
              created: '',
              updated: '',
            );
            print('Created placeholder for toArea');
          }

          // Если области не найдены, пропускаем запись
          if (fromArea == null || toArea == null) {
            print('Skipping record ${record.id} - missing area data');
            continue;
          }

          final ride = RideModel.fromRecord(
            record,
            fromArea: fromArea,
            toArea: toArea,
            userData: driver,
          );

          print(
              'Created user ride model: ${ride.fromAreaName} to ${ride.toAreaName}');
          rides.add(ride);
        } catch (e) {
          print('Error processing record ${record.id}: $e');
          print('Error details: ${e.toString()}');
          print('Stack trace: ${StackTrace.current}');
        }
      }

      print('Total user rides created: ${rides.length}');
      return rides;
    } catch (e) {
      print('Error fetching user rides: $e');
      print('Stack trace: ${StackTrace.current}');
      return [];
    }
  }

  // Получение поездок для публичного просмотра
  Future<List<RideModel>> getAllPublicRides() async {
    try {
      print('==== getAllPublicRides: Начало запроса ====');

      String filter = 'status = "pending"';
      print('Используемый фильтр: $filter');

      // Check if the collection exists
      try {
        await pb.collection('poputka_ride').getList(page: 1, perPage: 1);
        print('Collection poputka_ride exists and is accessible');
      } catch (e) {
        print('Error accessing poputka_ride collection: $e');
        return [];
      }

      // First, try getting records without expand to see if any exist
      final recordsWithoutExpand =
          await pb.collection('poputka_ride').getFullList(
                sort: '-created',
                filter: filter,
              );

      print('Found ${recordsWithoutExpand.length} public rides without expand');

      if (recordsWithoutExpand.isEmpty) {
        print('No public rides found with filter: $filter');
        return [];
      }

      print('Запрос к коллекции poputka_ride с expand...');

      // Пробуем получить записи с использованием expand
      final records = await pb.collection('poputka_ride').getFullList(
            sort: '-created',
            filter: filter,
            expand: 'fromArea,toArea,driver',
          );

      print('Получено ${records.length} поездок из PocketBase');

      if (records.isEmpty) {
        print('Нет доступных поездок в базе данных.');
        return [];
      }

      // Выводим данные первой записи для отладки
      if (records.isNotEmpty) {
        print('Пример данных первой записи:');
        print('ID: ${records.first.id}');
        print('Data: ${records.first.data}');
        print('Expand: ${records.first.expand}');

        // Check if the required fields exist
        print('Has fromArea: ${records.first.data.containsKey('fromArea')}');
        print('Has toArea: ${records.first.data.containsKey('toArea')}');
        print('Has driver: ${records.first.data.containsKey('driver')}');
      }

      final ridesList = <RideModel>[];

      print('Начинаем обработку записей...');
      for (var i = 0; i < records.length; i++) {
        final record = records[i];
        try {
          print('Обработка записи $i с ID: ${record.id}');

          // В первую очередь получаем данные напрямую по ID
          RecordModel? fromArea;
          RecordModel? toArea;
          RecordModel? driver;

          if (record.data.containsKey('fromArea')) {
            try {
              fromArea = await pb
                  .collection('poputka_area')
                  .getOne(record.data['fromArea']);
              print(
                  'Получена область fromArea напрямую: ${fromArea.id}, ${fromArea.data['name']}');
            } catch (e) {
              print('Ошибка при получении области напрямую: $e');
            }
          }

          if (record.data.containsKey('toArea')) {
            try {
              toArea = await pb
                  .collection('poputka_area')
                  .getOne(record.data['toArea']);
              print(
                  'Получена область toArea напрямую: ${toArea.id}, ${toArea.data['name']}');
            } catch (e) {
              print('Ошибка при получении области напрямую: $e');
            }
          }

          if (record.data.containsKey('driver')) {
            try {
              driver = await pb
                  .collection('poputka_users')
                  .getOne(record.data['driver']);
              print(
                  'Получен водитель напрямую: ${driver.id}, ${driver.data['name'] ?? driver.data['username']}');
            } catch (e) {
              print('Ошибка при получении водителя напрямую: $e');
            }
          }

          // Только потом пробуем получить из expand
          if (fromArea == null) {
            fromArea = _getRecordFromExpand(record.expand, 'fromArea');
            if (fromArea != null) {
              print(
                  'Получена область fromArea из expand: ${fromArea.data["name"]}');
            }
          }

          if (toArea == null) {
            toArea = _getRecordFromExpand(record.expand, 'toArea');
            if (toArea != null) {
              print(
                  'Получена область toArea из expand: ${toArea.data["name"]}');
            }
          }

          if (driver == null) {
            driver = _getRecordFromExpand(record.expand, 'driver');
            if (driver != null) {
              print(
                  'Получен водитель из expand: ${driver.data["name"] ?? driver.data["username"]}');
            }
          }

          // Пропускаем записи без областей
          if (fromArea == null || toArea == null) {
            print(
                'Пропускаем запись ${record.id} - отсутствуют данные об областях');

            // Создаем заглушки для отладки, чтобы увидеть хоть какие-то данные
            final dummyFromArea = fromArea ??
                RecordModel(
                  id: record.data['fromArea']?.toString() ?? 'unknown',
                  data: {'name': 'Неизвестная область'},
                  created: '',
                  updated: '',
                );

            final dummyToArea = toArea ??
                RecordModel(
                  id: record.data['toArea']?.toString() ?? 'unknown',
                  data: {'name': 'Неизвестная область'},
                  created: '',
                  updated: '',
                );

            // Создаем модель для отладки
            final dummyRide = RideModel.fromRecord(
              record,
              fromArea: dummyFromArea,
              toArea: dummyToArea,
              userData: driver,
            );

            print(
                'Создана модель с заглушками: ${dummyRide.fromAreaName} → ${dummyRide.toAreaName}');
            ridesList.add(dummyRide);
            continue;
          }

          // Создаем объект маршрута
          final ride = RideModel.fromRecord(
            record,
            fromArea: fromArea,
            toArea: toArea,
            userData: driver,
          );

          print(
              'Добавлена поездка: ${ride.fromAreaName} → ${ride.toAreaName} (${ride.statusText})');
          ridesList.add(ride);
        } catch (e) {
          print('ОШИБКА при обработке записи ${record.id}: $e');
          print('Трассировка: ${StackTrace.current}');
        }
      }

      print('Всего моделей поездок: ${ridesList.length}');
      return ridesList;
    } catch (e) {
      print('ОШИБКА при получении публичных поездок: $e');
      print('Трассировка: ${StackTrace.current}');
      return [];
    }
  }

  // Получение активной поездки пользователя (в статусе "В обработке")
  Future<RideModel?> getActiveRide() async {
    try {
      // Check if user is authenticated
      if (!pb.authStore.isValid) {
        print('User not authenticated');
        return null;
      }

      final userId = pb.authStore.model?.id;
      if (userId == null) {
        print('User ID is null');
        return null;
      }

      print('Fetching active ride for user $userId');

      // Используем коллекцию 'poputka_ride' вместо 'poputka_rides'
      final records = await pb.collection('poputka_ride').getList(
            filter: 'status = "pending" && driver = "$userId"',
            sort: '-created',
            expand: 'fromArea,toArea,driver',
            page: 1,
            perPage: 1,
          );

      if (records.items.isEmpty) {
        print('No active ride found for user $userId');
        return null;
      }

      final record = records.items.first;
      print('Found active ride: ${record.id}');
      print('Record data: ${record.data}');
      print('Expand data: ${record.expand}');

      // Безопасно получаем связанные области
      RecordModel? fromArea;
      RecordModel? toArea;
      RecordModel? driver;

      // В первую очередь получаем данные напрямую по ID
      if (record.data.containsKey('fromArea')) {
        try {
          fromArea = await pb
              .collection('poputka_area')
              .getOne(record.data['fromArea']);
          print('Retrieved fromArea directly: ${fromArea.data["name"]}');
        } catch (e) {
          print('Error fetching fromArea: $e');
        }
      }

      if (record.data.containsKey('toArea')) {
        try {
          toArea =
              await pb.collection('poputka_area').getOne(record.data['toArea']);
          print('Retrieved toArea directly: ${toArea.data["name"]}');
        } catch (e) {
          print('Error fetching toArea: $e');
        }
      }

      if (record.data.containsKey('driver')) {
        try {
          driver = await pb
              .collection('poputka_users')
              .getOne(record.data['driver']);
          print(
              'Retrieved driver directly: ${driver.data["name"] ?? driver.data["username"]}');
        } catch (e) {
          print('Error fetching driver: $e');
        }
      }

      // Только потом пробуем получить из expand
      if (fromArea == null) {
        fromArea = _getRecordFromExpand(record.expand, 'fromArea');
        if (fromArea != null) {
          print('Retrieved fromArea from expand: ${fromArea.data["name"]}');
        }
      }

      if (toArea == null) {
        toArea = _getRecordFromExpand(record.expand, 'toArea');
        if (toArea != null) {
          print('Retrieved toArea from expand: ${toArea.data["name"]}');
        }
      }

      if (driver == null) {
        driver = _getRecordFromExpand(record.expand, 'driver');
        if (driver != null) {
          print(
              'Retrieved driver from expand: ${driver.data["name"] ?? driver.data["username"]}');
        }
      }

      // Если все равно не смогли получить, создаем заглушку
      if (fromArea == null && record.data.containsKey('fromArea')) {
        fromArea = RecordModel(
          id: record.data['fromArea'].toString(),
          data: {'name': 'Unknown Area'},
          created: '',
          updated: '',
        );
        print('Created placeholder for fromArea');
      }

      if (toArea == null && record.data.containsKey('toArea')) {
        toArea = RecordModel(
          id: record.data['toArea'].toString(),
          data: {'name': 'Unknown Area'},
          created: '',
          updated: '',
        );
        print('Created placeholder for toArea');
      }

      // If driver is still null, use current user data
      if (driver == null) {
        print('Driver data missing, using current user data');
        try {
          final userData = await getUserData();
          if (userData != null) {
            driver = RecordModel(
              id: userId,
              data: userData,
              created: '',
              updated: '',
            );
            print('Created driver placeholder from user data');
          }
        } catch (e) {
          print('Error getting current user data: $e');
        }
      }

      // Если области не найдены, пропускаем запись
      if (fromArea == null || toArea == null) {
        print('Missing area data for ride ${record.id}');
        return null;
      }

      return RideModel.fromRecord(
        record,
        fromArea: fromArea,
        toArea: toArea,
        userData: driver,
      );
    } catch (e) {
      print('Error fetching active ride: $e');
      print('Stack trace: ${StackTrace.current}');
      return null;
    }
  }

  // Отмена поездки
  Future<bool> cancelRide(String rideId) async {
    try {
      // Используем коллекцию 'poputka_ride' вместо 'poputka_rides'
      await pb.collection('poputka_ride').update(rideId, body: {
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

      // Используем коллекцию 'poputka_ride' вместо 'poputka_rides'
      final record = await pb.collection('poputka_ride').update(rideId, body: {
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

  // Вспомогательный метод для безопасного извлечения RecordModel из expand
  RecordModel? _getRecordFromExpand(Map<String, dynamic> expand, String key) {
    if (expand.isEmpty) {
      print('Expand map is empty');
      return null;
    }

    if (!expand.containsKey(key)) {
      print(
          'Key "$key" not found in expand map. Available keys: ${expand.keys.join(', ')}');
      return null;
    }

    final data = expand[key];
    print('Expand data for key "$key": $data');

    if (data is RecordModel) {
      print('Data is RecordModel');
      return data;
    } else if (data is List && data.isNotEmpty) {
      print('Data is List with ${data.length} items');
      final item = data.first;
      if (item is RecordModel) {
        return item;
      } else {
        print('First item is not RecordModel, but ${item.runtimeType}');
      }
    } else {
      print('Data is neither RecordModel nor List, but ${data.runtimeType}');
    }
    return null;
  }

  // Получение данных пользователя по ID
  Future<Map<String, dynamic>?> getUserById(String userId) async {
    try {
      print('Fetching user data for user ID: $userId');

      if (userId.isEmpty) {
        print('Error: Empty user ID provided');
        return null;
      }

      // Получаем данные пользователя из коллекции poputka_users
      final record = await pb.collection('poputka_users').getOne(userId);
      print('User data fetched successfully for ID: $userId');

      return record.toJson();
    } catch (e) {
      print('Error fetching user data by ID $userId: $e');
      return null;
    }
  }

  // Create demo rides for testing
  Future<bool> createDemoRides() async {
    try {
      if (!pb.authStore.isValid) {
        print('User not authenticated');
        return false;
      }

      print('Creating demo rides...');

      // Get available areas
      final areas = await getAreas();
      if (areas.isEmpty) {
        print('No areas available to create demo rides');
        return false;
      }

      // Choose random areas for rides
      final fromArea = areas[0]; // First area
      final toArea =
          areas.length > 1 ? areas[1] : areas[0]; // Second area or first again

      print('Using areas:');
      print('- From: ${fromArea.data['name']} (${fromArea.id})');
      print('- To: ${toArea.data['name']} (${toArea.id})');

      // Create 3 demo rides
      final DateTime now = DateTime.now();
      final TimeOfDay timeNow = TimeOfDay.now();

      // Demo ride 1 - Driver ride today
      await createRide(
        fromAreaId: fromArea.id,
        toAreaId: toArea.id,
        date: now,
        time: TimeOfDay(hour: timeNow.hour + 1, minute: 0),
        isDriver: true,
        availableSeats: 3,
        price: 500,
        notes: 'Demo driver ride',
      );

      // Demo ride 2 - Passenger ride tomorrow
      await createRide(
        fromAreaId: toArea.id,
        toAreaId: fromArea.id,
        date: now.add(const Duration(days: 1)),
        time: TimeOfDay(hour: 10, minute: 30),
        isDriver: false,
        availableSeats: 1,
        notes: 'Demo passenger ride',
      );

      // Demo ride 3 - Driver ride next week
      await createRide(
        fromAreaId: fromArea.id,
        toAreaId: toArea.id,
        date: now.add(const Duration(days: 7)),
        time: TimeOfDay(hour: 15, minute: 0),
        isDriver: true,
        availableSeats: 2,
        price: 600,
        notes: 'Demo driver ride next week',
      );

      print('Successfully created 3 demo rides');
      return true;
    } catch (e) {
      print('Error creating demo rides: $e');
      print('Stack trace: ${StackTrace.current}');
      return false;
    }
  }

  // Получение доступных поездок
  Future<List<RideModel>> getAvailableRides() async {
    try {
      // Получаем записи из коллекции поездок со статусом "pending"
      final records = await pb.collection('poputka_ride').getFullList(
            sort: '-created',
            expand: 'fromArea,toArea',
            filter: 'status = "pending"',
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
      print('Error fetching available rides: $e');
      return [];
    }
  }
}

final pocketBaseService = PocketBaseService();
