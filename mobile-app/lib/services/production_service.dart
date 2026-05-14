import '../models/production.dart';
import 'base_service.dart';

class ProductionService extends BaseService<Production> {
  ProductionService() : super('productions');

  @override
  Production fromJson(Map<String, dynamic> json) {
    return Production.fromJson(json);
  }

  // Example of a specific method for this service
  Future<List<Production>> getByFactoryId(String factoryId) async {
    return await getAll(filters: {'factory_id': factoryId}, orderBy: 'created_at', ascending: false);
  }
}
