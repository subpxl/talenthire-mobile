import 'package:bombay_casting/core/models/model_helpers.dart';
import 'package:bombay_casting/core/services/report_service.dart';
import 'package:bombay_casting/l10n/app_localizations.dart';

class AppReport {
  const AppReport({
    required this.id,
    required this.type,
    required this.reporterId,
    required this.targetId,
    this.targetLabel = '',
    this.reason = '',
    this.details = '',
    this.status = 'pending',
    this.createdAt,
  });

  final String id;
  final ReportType type;
  final String reporterId;
  final String targetId;
  final String targetLabel;
  final String reason;
  final String details;
  final String status;
  final DateTime? createdAt;

  factory AppReport.fromFirestore(String id, Map<String, dynamic> data) {
    final legacyCreatorId = (data['reportedUserId'] ?? '').toString();
    final type = ReportType.fromStorage(data['type']?.toString()) ??
        (legacyCreatorId.isNotEmpty ? ReportType.creator : ReportType.creator);
    return AppReport(
      id: id,
      type: type,
      reporterId: (data['reporterId'] ?? '').toString(),
      targetId: (data['targetId'] ?? legacyCreatorId).toString(),
      targetLabel: (data['targetLabel'] ?? '').toString(),
      reason: (data['reason'] ?? '').toString(),
      details: (data['details'] ?? '').toString(),
      status: (data['status'] ?? 'pending').toString(),
      createdAt: parseFlexibleDate(data['createdAt']),
    );
  }

  String typeLabel(AppLocalizations l10n) {
    switch (type) {
      case ReportType.creator:
        return l10n.reportTypeCreator;
      case ReportType.job:
        return l10n.reportTypeJob;
      case ReportType.agency:
        return l10n.reportTypeAgency;
      case ReportType.conversation:
        return l10n.reportTypeConversation;
    }
  }

  String reasonLabel(AppLocalizations l10n) {
    switch (reason) {
      case 'spam':
        return l10n.reportReasonSpam;
      case 'inappropriate':
        return l10n.reportReasonInappropriate;
      case 'other':
        return l10n.reportReasonOther;
      default:
        return reason.isNotEmpty ? reason : l10n.reportReasonOther;
    }
  }
}
