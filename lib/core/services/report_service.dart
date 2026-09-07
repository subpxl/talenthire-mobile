import 'package:bombay_casting/core/widgets/app_success_toast.dart';
import 'package:bombay_casting/core/widgets/report_dialog.dart';
import 'package:bombay_casting/l10n/app_localizations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

enum ReportType {
  creator('creator'),
  job('job'),
  agency('agency'),
  conversation('conversation');

  const ReportType(this.storageValue);

  final String storageValue;

  static ReportType? fromStorage(String? value) {
    if (value == null || value.isEmpty) return null;
    for (final type in ReportType.values) {
      if (type.storageValue == value) return type;
    }
    return null;
  }
}

class ReportTarget {
  const ReportTarget({
    required this.type,
    required this.targetId,
    this.targetLabel,
  });

  final ReportType type;
  final String targetId;
  final String? targetLabel;
}

class ReportService {
  ReportService._();

  static final ReportService instance = ReportService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> submit({
    required String reporterId,
    required ReportTarget target,
    required ReportResult result,
  }) async {
    if (target.targetId.trim().isEmpty) {
      throw StateError('Report target id is required.');
    }

    await _firestore.collection('reports').add({
      'type': target.type.storageValue,
      'reporterId': reporterId,
      'targetId': target.targetId.trim(),
      if (target.targetLabel != null && target.targetLabel!.trim().isNotEmpty)
        'targetLabel': target.targetLabel!.trim(),
      'reason': result.reason.name,
      if (result.otherDetails != null && result.otherDetails!.trim().isNotEmpty)
        'details': result.otherDetails!.trim(),
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Shows the shared report modal, writes to Firestore, and surfaces toasts.
  Future<bool> submitFromDialog(
    BuildContext context, {
    required String dialogTitle,
    required String successMessage,
    required ReportTarget target,
  }) async {
    final result = await showReportDialog(context, title: dialogTitle);
    if (result == null || !context.mounted) return false;

    final l10n = AppLocalizations.of(context)!;
    final reporterId = FirebaseAuth.instance.currentUser?.uid;
    if (reporterId == null) {
      showAppToast(context, l10n.reportFailed, type: AppToastType.error);
      return false;
    }

    try {
      await submit(
        reporterId: reporterId,
        target: target,
        result: result,
      );
      if (context.mounted) {
        showAppSuccessToast(context, successMessage);
      }
      return true;
    } catch (error) {
      debugPrint('Report submit failed: $error');
      if (context.mounted) {
        showAppToast(context, l10n.reportFailed, type: AppToastType.error);
      }
      return false;
    }
  }
}
