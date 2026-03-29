import '../models/models.dart';

abstract class ReportService {
  Future<void> submitReport(Report report);

  Future<List<Report>> getPendingReports();
}
