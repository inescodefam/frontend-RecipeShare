import '../models/models.dart';

abstract class ReportService {
  Future<void> submitReport(Report report);

  Future<void> submitContentReport({
    required ReportTargetType targetType,
    required int targetId,
    required ReportReason reason,
    String? description,
  });

  Future<List<Report>> getPendingReports();
}
