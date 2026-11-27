import '../../services/knowledge_base_service.dart';
import 'health_repository.dart';

class LocalHealthRepository implements HealthRepository {
  @override
  Future<List<KbEntry>> loadEntries() async {
    return await KnowledgeBaseService.load();
  }
}
