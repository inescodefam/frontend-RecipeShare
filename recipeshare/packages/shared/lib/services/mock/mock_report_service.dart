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
  Future<void> submitContentReport({
    required ReportTargetType targetType,
    required int targetId,
    required ReportReason reason,
    String? description,
    String? reporterUserId,
  }) async {
    final reporterId = reporterUserId ?? 'mock_reporter';
    if (await hasReported(
      reporterUserId: reporterId,
      targetType: targetType,
      targetId: targetId,
    )) {
      throw StateError(ReportService.duplicateReportMessage);
    }

    await submitReport(
      Report(
        id: 'rep_${DateTime.now().millisecondsSinceEpoch}',
        reporterUserId: reporterId,
        targetType: targetType,
        targetId: '$targetId',
        reason: reason,
        description: description,
        status: ReportStatus.pending,
        createdAt: DateTime.now().toUtc(),
      ),
    );
  }

  @override
  Future<bool> hasReported({
    required String reporterUserId,
    required ReportTargetType targetType,
    required int targetId,
  }) async {
    final reports = await _data.getReports();
    return reports.any(
      (report) =>
          report.reporterUserId == reporterUserId &&
          report.targetType == targetType &&
          report.targetId == '$targetId',
    );
  }

  @override
  Future<List<Report>> getPendingReports() async {
    final all = await _data.getReports();
    return all.where((r) => r.status == ReportStatus.pending).toList();
  }
}
