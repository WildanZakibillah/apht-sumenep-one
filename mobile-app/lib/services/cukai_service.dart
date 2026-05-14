import '../models/cukai_request.dart';
import 'base_service.dart';

class CukaiService extends BaseService<CukaiRequest> {
  CukaiService() : super('cukai_requests');

  @override
  CukaiRequest fromJson(Map<String, dynamic> json) {
    return CukaiRequest.fromJson(json);
  }

  Future<List<CukaiRequest>> getRequestsByFactoryId(String factoryId) async {
    return await getAll(filters: {'factory_id': factoryId}, orderBy: 'created_at', ascending: false);
  }
}
