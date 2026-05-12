import 'package:dio/dio.dart';

import '../../models/models.dart';
import '../report_service.dart';
import 'dio_error_message.dart';

class HttpReportService implements ReportService {
  HttpReportService(this._dio);

  final Dio _dio;

  @override
  Future<void> submitContentReport({
    required ReportTargetType targetType,
    required int targetId,
    required ReportReason reason,
    String? description,
    String? reporterUserId,
  }) async {
    try {
      await _dio.post<void>(
        '/api/reports',
        data: <String, dynamic>{
          'targetType': reportTargetTypeToApi(targetType),
          'targetId': targetId,
          'reason': reportReasonToApi(reason),
          if (description != null && description.trim().isNotEmpty)
            'description': description.trim(),
        },
      );
    } on DioException catch (e) {
      throw StateError(messageFromDio(e));
    }
  }

  @override
  Future<void> submitReport(Report report) async {
    final targetId = int.tryParse(report.targetId);
    if (targetId == null) {
      throw StateError('Invalid report target id.');
    }
    await submitContentReport(
      targetType: report.targetType,
      targetId: targetId,
      reason: report.reason,
      description: report.description,
    );
  }

  @override
  Future<bool> hasReported({
    required String reporterUserId,
    required ReportTargetType targetType,
    required int targetId,
  }) async =>
      false;

  @override
  Future<List<Report>> getPendingReports() async => throw UnimplementedError();
}
