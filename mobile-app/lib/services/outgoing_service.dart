import '../models/outgoing_good.dart';
import 'base_service.dart';

class OutgoingService extends BaseService<OutgoingGood> {
  OutgoingService() : super('outgoing_goods');

  @override
  OutgoingGood fromJson(Map<String, dynamic> json) {
    return OutgoingGood.fromJson(json);
  }

  Future<List<OutgoingGood>> getByFactoryId(String factoryId) async {
    return await getAll(
      filters: {'factory_id': factoryId},
      orderBy: 'created_at',
      ascending: false,
    );
  }
}
