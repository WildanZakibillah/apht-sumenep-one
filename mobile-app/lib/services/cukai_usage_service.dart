import '../models/cukai_usage.dart';
import 'base_service.dart';

class CukaiUsageService extends BaseService<CukaiUsage> {
  CukaiUsageService() : super('cukai_usage_log');

  @override
  CukaiUsage fromJson(Map<String, dynamic> json) {
    return CukaiUsage.fromJson(json);
  }

  Future<List<CukaiUsage>> getByFactoryId(String factoryId) async {
    return await getAll(
      filters: {'factory_id': factoryId},
      orderBy: 'created_at',
      ascending: false,
    );
  }
}
