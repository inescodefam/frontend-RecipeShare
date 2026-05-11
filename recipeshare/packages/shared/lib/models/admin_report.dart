import 'enums.dart';

class AdminReportSummary {
  const AdminReportSummary({
    required this.id,
    required this.targetType,
    required this.targetId,
    required this.reporterUsername,
    required this.reportedUsername,
    required this.reason,
    this.description,
    required this.status,
    required this.createdAt,
  });

  final int id;
  final ReportTargetType targetType;
  final int targetId;
  final String reporterUsername;
  final String reportedUsername;
  final ReportReason reason;
  final String? description;
  final ReportStatus status;
  final DateTime createdAt;

  factory AdminReportSummary.fromJson(Map<String, dynamic> json) {
    return AdminReportSummary(
      id: json['id'] as int,
      targetType: reportTargetTypeFromApi(json['targetType'] as String? ?? ''),
      targetId: json['targetId'] as int? ?? 0,
      reporterUsername: json['reporterUsername'] as String? ?? '',
      reportedUsername: json['reportedUsername'] as String? ?? '',
      reason: reportReasonFromApi(json['reason'] as String? ?? ''),
      description: json['description'] as String?,
      status: reportStatusFromApi(json['status'] as String? ?? ''),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

class AdminReportDetail {
  const AdminReportDetail({
    required this.id,
    required this.targetType,
    required this.targetId,
    required this.reporterUsername,
    required this.reporterId,
    required this.reportedUsername,
    required this.reportedUserId,
    required this.reason,
    this.description,
    required this.status,
    required this.contentAction,
    required this.userAction,
    this.adminNote,
    this.resolvedByAdminUsername,
    required this.createdAt,
    this.resolvedAt,
    this.targetContent,
  });

  final int id;
  final ReportTargetType targetType;
  final int targetId;
  final String reporterUsername;
  final int reporterId;
  final String reportedUsername;
  final int reportedUserId;
  final ReportReason reason;
  final String? description;
  final ReportStatus status;
  final AdminAction contentAction;
  final AdminAction userAction;
  final String? adminNote;
  final String? resolvedByAdminUsername;
  final DateTime createdAt;
  final DateTime? resolvedAt;
  final String? targetContent;

  factory AdminReportDetail.fromJson(Map<String, dynamic> json) {
    return AdminReportDetail(
      id: json['id'] as int,
      targetType: reportTargetTypeFromApi(json['targetType'] as String? ?? ''),
      targetId: json['targetId'] as int? ?? 0,
      reporterUsername: json['reporterUsername'] as String? ?? '',
      reporterId: json['reporterId'] as int? ?? 0,
      reportedUsername: json['reportedUsername'] as String? ?? '',
      reportedUserId: json['reportedUserId'] as int? ?? 0,
      reason: reportReasonFromApi(json['reason'] as String? ?? ''),
      description: json['description'] as String?,
      status: reportStatusFromApi(json['status'] as String? ?? ''),
      contentAction: adminActionFromApi(json['contentAction'] as String? ?? 'None'),
      userAction: adminActionFromApi(json['userAction'] as String? ?? 'None'),
      adminNote: json['adminNote'] as String?,
      resolvedByAdminUsername: json['resolvedByAdminUsername'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      resolvedAt: json['resolvedAt'] == null
          ? null
          : DateTime.parse(json['resolvedAt'] as String),
      targetContent: json['targetContent'] as String?,
    );
  }
}

ReportTargetType reportTargetTypeFromApi(String raw) {
  final normalized = raw.toLowerCase();
  if (normalized == 'recipe') return ReportTargetType.recipe;
  if (normalized == 'comment') return ReportTargetType.comment;
  if (normalized == 'user') return ReportTargetType.user;
  return ReportTargetType.recipe;
}

ReportReason reportReasonFromApi(String raw) {
  final normalized = raw.toLowerCase();
  if (normalized == 'spam') return ReportReason.spam;
  if (normalized.contains('offensive')) return ReportReason.offensive;
  if (normalized.contains('inappropriate')) return ReportReason.inappropriate;
  return ReportReason.spam;
}

ReportStatus reportStatusFromApi(String raw) {
  final normalized = raw.toLowerCase();
  if (normalized == 'pending') return ReportStatus.pending;
  if (normalized == 'resolved' || normalized == 'approved') {
    return ReportStatus.resolved;
  }
  if (normalized == 'dismissed' || normalized == 'rejected') {
    return ReportStatus.dismissed;
  }
  return ReportStatus.pending;
}

AdminAction adminActionFromApi(String raw) {
  switch (raw) {
    case 'Warning':
      return AdminAction.warning;
    case 'Block':
      return AdminAction.block;
    case 'SoftDelete':
      return AdminAction.softDelete;
    case 'None':
    default:
      return AdminAction.none;
  }
}

String adminActionToApi(AdminAction action) {
  switch (action) {
    case AdminAction.warning:
      return 'Warning';
    case AdminAction.block:
      return 'Block';
    case AdminAction.softDelete:
      return 'SoftDelete';
    case AdminAction.none:
      return 'None';
  }
}

String reportStatusToApi(ReportStatus status) {
  switch (status) {
    case ReportStatus.pending:
      return 'Pending';
    case ReportStatus.resolved:
      return 'Resolved';
    case ReportStatus.dismissed:
      return 'Dismissed';
  }
}
