import 'admin_report.dart';
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
      status: reportStatusFromApi(json['status'] as String? ?? ''),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Report copyWith({
    String? id,
    String? reporterUserId,
    ReportTargetType? targetType,
    String? targetId,
    ReportReason? reason,
    String? description,
    ReportStatus? status,
    DateTime? createdAt,
  }) {
    return Report(
      id: id ?? this.id,
      reporterUserId: reporterUserId ?? this.reporterUserId,
      targetType: targetType ?? this.targetType,
      targetId: targetId ?? this.targetId,
      reason: reason ?? this.reason,
      description: description ?? this.description,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
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

int reportTargetTypeToApi(ReportTargetType targetType) {
  switch (targetType) {
    case ReportTargetType.recipe:
      return 0;
    case ReportTargetType.comment:
      return 1;
    case ReportTargetType.user:
      throw ArgumentError('User reports are not supported by the API.');
  }
}

int reportReasonToApi(ReportReason reason) {
  switch (reason) {
    case ReportReason.spam:
      return 0;
    case ReportReason.offensive:
      return 1;
    case ReportReason.inappropriate:
      return 2;
  }
}

String reportReasonLabel(ReportReason reason) {
  switch (reason) {
    case ReportReason.spam:
      return 'Spam';
    case ReportReason.offensive:
      return 'Offensive content';
    case ReportReason.inappropriate:
      return 'Inappropriate content';
  }
}