import '../models/models.dart';

abstract class ReportService {
  static const String duplicateReportMessage = 'You have already reported this content.';

  Future<void> submitReport(Report report);

  Future<void> submitContentReport({
    required ReportTargetType targetType,
    required int targetId,
    required ReportReason reason,
    String? description,
    String? reporterUserId,
  });

  Future<bool> hasReported({
    required String reporterUserId,
    required ReportTargetType targetType,
    required int targetId,
  });

  Future<List<Report>> getPendingReports();
}
