import 'package:bombay_casting/core/theme/app_theme.dart';
import 'package:bombay_casting/core/widgets/app_search_filters.dart';
import 'package:bombay_casting/features/admin/models/app_report.dart';
import 'package:bombay_casting/l10n/app_localizations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AdminReportsScreen extends StatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  State<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends State<AdminReportsScreen> {
  final _selectedTypes = <String>{};

  static const _typeFilters = [
    'All',
    'Creator',
    'Job',
    'Agency',
    'Conversation',
  ];

  String? _typeStorageValue(String chip) {
    switch (chip) {
      case 'Creator':
        return 'creator';
      case 'Job':
        return 'job';
      case 'Agency':
        return 'agency';
      case 'Conversation':
        return 'conversation';
      default:
        return null;
    }
  }

  void _toggleTypeFilter(String chip) {
    setState(() {
      if (chip == 'All') {
        _selectedTypes.clear();
        return;
      }
      if (_selectedTypes.contains(chip)) {
        _selectedTypes.remove(chip);
      } else {
        _selectedTypes
          ..clear()
          ..add(chip);
      }
    });
  }

  Query<Map<String, dynamic>> _reportsQuery() {
    return FirebaseFirestore.instance
        .collection('reports')
        .orderBy('createdAt', descending: true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: Text(
          l10n.adminReports,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screenH,
              8,
              AppSpacing.screenH,
              8,
            ),
            child: AppFilterChipRow(
              options: _typeFilters,
              selectedChips: _selectedTypes,
              onToggle: _toggleTypeFilter,
              solidYellow: true,
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _reportsQuery().snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      l10n.reportFailed,
                      style: context.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  );
                }
                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  );
                }

                final reports = snapshot.data!.docs
                    .map((doc) => AppReport.fromFirestore(doc.id, doc.data()))
                    .where((report) {
                  if (_selectedTypes.isEmpty) return true;
                  final chip = _selectedTypes.first;
                  final storage = _typeStorageValue(chip);
                  return storage != null && report.type.storageValue == storage;
                }).toList();

                if (reports.isEmpty) {
                  return Center(
                    child: Text(
                      l10n.noReportsYet,
                      style: context.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.screenH,
                    0,
                    AppSpacing.screenH,
                    24,
                  ),
                  itemCount: reports.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    return _ReportTile(report: reports[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportTile extends StatelessWidget {
  const _ReportTile({required this.report});

  final AppReport report;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final created = report.createdAt;
    final timeLabel = created == null
        ? ''
        : DateFormat('d MMM yyyy, h:mm a').format(created.toLocal());
    final target = report.targetLabel.isNotEmpty
        ? report.targetLabel
        : report.targetId;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _TagPill(
                label: report.typeLabel(l10n),
                color: AppColors.primary,
              ),
              _TagPill(
                label: report.reasonLabel(l10n),
                color: AppColors.textSecondary,
              ),
              _TagPill(
                label: report.status == 'pending'
                    ? l10n.reportStatusPending
                    : l10n.reportStatusResolved,
                color: report.status == 'pending'
                    ? AppColors.brandRed
                    : AppColors.chatGreen,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            target,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          if (report.details.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              report.details,
              style: context.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            '${l10n.reportReporter}: ${report.reporterId}',
            style: context.caption.copyWith(color: AppColors.textSecondary),
          ),
          if (timeLabel.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              timeLabel,
              style: context.caption,
            ),
          ],
        ],
      ),
    );
  }
}

class _TagPill extends StatelessWidget {
  const _TagPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
