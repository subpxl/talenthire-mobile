import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../widgets/app_avatar.dart';
import '../widgets/app_card.dart';
import '../widgets/app_tag.dart';
import '../widgets/empty_state.dart';
import 'agency_detail_screen.dart';
import 'job_detail_screen.dart';

class JobsScreen extends StatefulWidget {
  const JobsScreen({super.key});

  @override
  State<JobsScreen> createState() => _JobsScreenState();
}

class _JobsScreenState extends State<JobsScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _locationFilter = 'All';

  // Advanced filters
  String _genderFilter = 'Any';
  String _typeFilter = 'Any';
  String _urgencyFilter = 'Any';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Job> _filterJobs(List<Job> jobs) {
    return jobs.where((job) {
      final query = _searchQuery.toLowerCase();
      final matchesSearch = query.isEmpty ||
          job.title.toLowerCase().contains(query) ||
          job.company.toLowerCase().contains(query) ||
          job.location.toLowerCase().contains(query) ||
          job.description.toLowerCase().contains(query) ||
          job.tags.any((t) => t.toLowerCase().contains(query));

      final matchesLocation = _locationFilter == 'All' ||
          locationTypeToString(job.locationType).toUpperCase() ==
              _locationFilter.toUpperCase();

      final matchesGender = _genderFilter == 'Any' ||
          job.genderRequired.isEmpty ||
          job.genderRequired.toLowerCase() == 'any' ||
          job.genderRequired.toLowerCase() == _genderFilter.toLowerCase();

      final matchesType = _typeFilter == 'Any' ||
          (_typeFilter == 'Audition Only' ? job.isAudition : true);

      final matchesUrgency = _urgencyFilter == 'Any' ||
          (_urgencyFilter == 'Urgent Only' ? job.urgent : true);

      return matchesSearch && matchesLocation && matchesGender && matchesType && matchesUrgency;
    }).toList();
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          const Text(
                            'Filter Jobs',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: () {
                              setSheetState(() {
                                _genderFilter = 'Any';
                                _typeFilter = 'Any';
                                _urgencyFilter = 'Any';
                                _locationFilter = 'All';
                              });
                              setState(() {});
                            },
                            child: const Text('Reset'),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.all(16.0),
                        shrinkWrap: true,
                        children: [
                          const Text('Gender', style: TextStyle(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            children: ['Any', 'Male', 'Female', 'Other'].map((g) {
                              return ChoiceChip(
                                label: Text(g),
                                selected: _genderFilter == g,
                                onSelected: (val) {
                                  if (val) setSheetState(() => _genderFilter = g);
                                },
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 24),
                          const Text('Job Type', style: TextStyle(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            children: ['Any', 'Audition Only'].map((t) {
                              return ChoiceChip(
                                label: Text(t),
                                selected: _typeFilter == t,
                                onSelected: (val) {
                                  if (val) setSheetState(() => _typeFilter = t);
                                },
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 24),
                          const Text('Urgency', style: TextStyle(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            children: ['Any', 'Urgent Only'].map((u) {
                              return ChoiceChip(
                                label: Text(u),
                                selected: _urgencyFilter == u,
                                onSelected: (val) {
                                  if (val) setSheetState(() => _urgencyFilter = u);
                                },
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          setState(() {});
                          Navigator.pop(context);
                        },
                        child: const Text('Apply Filters'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _openAgency(Job job) {
    if (job.createdBy.isEmpty) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AgencyDetailScreen(
          agencyId: job.createdBy,
          fallbackName: job.company,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final filteredJobs = _filterJobs(state.jobs);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Available Jobs'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterBottomSheet,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: InputDecoration(
                hintText: 'Search jobs, agency, location...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
              ),
            ),
          ),
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: ['All', 'Remote', 'Online', 'Onsite'].map((filter) {
                final selected = _locationFilter == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(filter),
                    selected: selected,
                    onSelected: (_) => setState(() => _locationFilter = filter),
                    labelStyle: TextStyle(
                      color: selected ? AppColors.onPrimary : AppColors.textPrimary,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: filteredJobs.isEmpty
                ? RefreshIndicator(
                    onRefresh: () => context.read<AppState>().refreshData(),
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.6,
                          child: EmptyState(
                            icon: Icons.work_off_outlined,
                            title: state.jobs.isEmpty
                                ? 'No jobs available'
                                : 'No jobs match your search',
                            subtitle: state.jobs.isEmpty
                                ? null
                                : 'Try a different search or filter',
                          ),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: () => context.read<AppState>().refreshData(),
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16.0),
                      itemCount: filteredJobs.length,
                      itemBuilder: (context, index) {
                        final job = filteredJobs[index];
                        final hasApplied = state.hasApplied(job.id);
                        final summary = job.summary.isNotEmpty
                            ? job.summary
                            : (job.description.length > 100
                                ? '${job.description.substring(0, 100)}…'
                                : job.description);

                        return AppCard(
                          margin: const EdgeInsets.only(bottom: 14),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => JobDetailScreen(job: job),
                              ),
                            );
                          },
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  GestureDetector(
                                    onTap: () => _openAgency(job),
                                    child: AppAvatar(
                                      radius: 26,
                                      initials: job.initials.isNotEmpty
                                          ? job.initials
                                          : 'AG',
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          job.title,
                                          style: context.text.titleMedium?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 2),
                                        GestureDetector(
                                          onTap: () => _openAgency(job),
                                          child: Text(
                                            job.company.isNotEmpty
                                                ? job.company
                                                : 'Agency',
                                            style: TextStyle(
                                              color: context.colors.primary,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        job.timeAgo,
                                        style: const TextStyle(
                                          color: AppColors.textMuted,
                                          fontSize: 11,
                                        ),
                                      ),
                                      if (hasApplied) ...[
                                        const SizedBox(height: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 3,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppColors.success.withAlpha(30),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: const Text(
                                            'Applied',
                                            style: TextStyle(
                                              color: AppColors.success,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                              if (summary.isNotEmpty) ...[
                                const SizedBox(height: 10),
                                Text(
                                  summary,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    height: 1.35,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 8,
                                runSpacing: 6,
                                children: [
                                  _MetaChip(
                                    icon: Icons.location_on_outlined,
                                    label: job.location.isNotEmpty
                                        ? job.location
                                        : locationTypeToString(job.locationType)
                                            .toUpperCase(),
                                  ),
                                  _MetaChip(
                                    icon: Icons.public,
                                    label: locationTypeToString(job.locationType)
                                        .toUpperCase(),
                                  ),
                                  if (job.isAudition)
                                    const _MetaChip(
                                      icon: Icons.videocam,
                                      label: 'Audition',
                                      emphasize: true,
                                    ),
                                  if (job.urgent)
                                    const _MetaChip(
                                      icon: Icons.priority_high,
                                      label: 'Urgent',
                                      danger: true,
                                    ),
                                ],
                              ),
                              if (job.tags.isNotEmpty) ...[
                                const SizedBox(height: 10),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 4,
                                  children: job.tags
                                      .take(4)
                                      .map((tag) => AppTag(label: tag))
                                      .toList(),
                                ),
                              ],
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Text(
                                    job.salary.isNotEmpty
                                        ? job.salary
                                        : 'Salary not listed',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    '${job.applied} applied',
                                    style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(
                                    Icons.chevron_right,
                                    size: 18,
                                    color: context.colors.primary,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool emphasize;
  final bool danger;

  const _MetaChip({
    required this.icon,
    required this.label,
    this.emphasize = false,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = danger
        ? AppColors.error
        : emphasize
            ? context.colors.primary
            : AppColors.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(22),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
