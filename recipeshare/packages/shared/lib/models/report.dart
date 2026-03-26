import 'enums.dart';

class Report {
  final String id;
  final String reporterUserId;
  final ReportTargetType targetType;
  final String targetId;
  final ReportReason reason;
  final String? description;
  final ReportStatus status;
  final DateTime createdAt;

  const Report({
    required this.id,
    required this.reporterUserId,
    required this.targetType,
    required this.targetId,
    required this.reason,
    this.description,
    required this.status,
    required this.createdAt,
  });

  factory Report.fromJson(Map<String, dynamic> json) {
    return Report(
      id: json['id'] as String,
      reporterUserId: json['reporterUserId'] as String,
      targetType: enumFromString(
        ReportTargetType.values,
        json['targetType'] as String,
        fallback: ReportTargetType.recipe,
      ),
      targetId: json['targetId'] as String,
      reason: enumFromString(
        ReportReason.values,
        json['reason'] as String,
        fallback: ReportReason.spam,
      ),
      description: json['description'] as String?,
      status: enumFromString(
        ReportStatus.values,
        json['status'] as String,
        fallback: ReportStatus.pending,
      ),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'reporterUserId': reporterUserId,
      'targetType': targetType.name,
      'targetId': targetId,
      'reason': reason.name,
      'description': description,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}