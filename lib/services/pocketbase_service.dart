import 'package:pocketbase/pocketbase.dart';

class PocketBaseService {
  static final PocketBaseService _instance = PocketBaseService._internal();
  final pb = PocketBase('https://restaurant-menu.fly.dev');

  factory PocketBaseService() {
    return _instance;
  }

  PocketBaseService._internal();

  Future<List<RecordModel>> getAreas() async {
    try {
      // Try to fetch areas from the PocketBase 'Area' collection
      final records = await pb.collection('Area').getFullList(
            sort: '-created',
          );

      print('Successfully fetched ${records.length} areas from PocketBase');
      return records;
    } catch (e) {
      print('Error fetching areas from PocketBase: $e');

      // Return fallback data if API fails
      return [
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
    }
  }

  // Method to create a new area (for testing)
  Future<RecordModel?> createArea(String name) async {
    try {
      final record = await pb.collection('Area').create(body: {
        'name': name,
      });
      print('Successfully created area: ${record.data['name']}');
      return record;
    } catch (e) {
      print('Error creating area: $e');
      return null;
    }
  }

  String getBannerImageUrl() {
    // Use a direct URL to an image for testing
    return 'https://raw.githubusercontent.com/flutter/website/main/src/assets/images/flutter-logo-sharing.png';
  }
}
