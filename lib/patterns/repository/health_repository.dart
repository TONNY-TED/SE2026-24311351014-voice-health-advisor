import '../../services/knowledge_base_service.dart';

abstract class HealthRepository {
  Future<List<KbEntry>> loadEntries();
}