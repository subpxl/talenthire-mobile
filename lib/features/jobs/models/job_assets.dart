/// Job poster files live in `assets/jobs/job (1).jpeg` … `job (66).jpeg`.
class JobAssets {
  JobAssets._();

  static const count = 66;

  static String pathFor(int index) {
    final n = ((index - 1) % count) + 1;
    return 'assets/jobs/job ($n).jpeg';
  }
}
