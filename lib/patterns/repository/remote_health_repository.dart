import '../../services/knowledge_base_service.dart';
import 'health_repository.dart';

class RemoteHealthRepository implements HealthRepository {
  @override
  Future<List<KbEntry>> loadEntries() async {
    throw UnimplementedError(
      'Remote repository will be implemented during synchronization phase.',
    );
  }
}