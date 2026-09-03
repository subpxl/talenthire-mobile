import 'package:bombay_casting/features/jobs/models/job_listing.dart';

class JobDiscoveryPreset {
  const JobDiscoveryPreset({
    required this.label,
    required this.searchQuery,
  });

  final String label;
  final String searchQuery;

  HomeJobFilter toFilter() => HomeJobFilter(searchQuery: searchQuery);
}

const jobDiscoveryPresets = [
  JobDiscoveryPreset(
    label: 'Mumbai Actress 25',
    searchQuery: 'mumbai actress 25',
  ),
  JobDiscoveryPreset(
    label: 'Delhi Fashion Model',
    searchQuery: 'delhi fashion model',
  ),
  JobDiscoveryPreset(
    label: 'Bengaluru Lifestyle',
    searchQuery: 'bengaluru lifestyle',
  ),
  JobDiscoveryPreset(
    label: 'Remote UGC Creator',
    searchQuery: 'remote ugc',
  ),
  JobDiscoveryPreset(
    label: 'Pune Actor 20',
    searchQuery: 'pune actor 20',
  ),
];
