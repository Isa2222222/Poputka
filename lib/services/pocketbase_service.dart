import 'package:pocketbase/pocketbase.dart';

class PocketBaseService {
  static final PocketBaseService _instance = PocketBaseService._internal();
  final pb = PocketBase('http://127.0.0.1:8090');

  factory PocketBaseService() {
    return _instance;
  }

  PocketBaseService._internal();

  Future<List<RecordModel>> getAreas() async {
    try {
      final records = await pb.collection('areas').getFullList(
            sort: '-created',
            filter: 'active = true',
          );
      return records;
    } catch (e) {
      print('Error fetching areas: $e');
      return [
        RecordModel(
            id: '1', data: {'name': 'Ала-Тоо'}, created: '', updated: ''),
        RecordModel(
            id: '2', data: {'name': 'Новотель'}, created: '', updated: ''),
        RecordModel(id: '3', data: {'name': 'Центр'}, created: '', updated: ''),
        RecordModel(
            id: '4', data: {'name': 'Восток-5'}, created: '', updated: ''),
      ];
    }
  }
}
