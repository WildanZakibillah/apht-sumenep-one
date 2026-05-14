import '../models/report.dart';
import 'base_service.dart';

class ReportService extends BaseService<Report> {
  ReportService() : super('reports');

  @override
  Report fromJson(Map<String, dynamic> json) {
    return Report.fromJson(json);
  }

  Future<List<Report>> getReportsByFactoryId(String factoryId) async {
    return await getAll(filters: {'factory_id': factoryId}, orderBy: 'created_at', ascending: false);
  }
}
