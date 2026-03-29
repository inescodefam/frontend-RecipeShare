import '../report_service.dart';
import '../../models/models.dart';
import 'mock_data_service.dart';

class MockReportService implements ReportService {
  MockReportService(this._data);

  final MockDataService _data;

  @override
  Future<void> submitReport(Report report) async {
    await _data.addReport(report);
  }

  @override
  Future<List<Report>> getPendingReports() async {
    final all = await _data.getReports();
    return all.where((r) => r.status == ReportStatus.pending).toList();
  }
}
