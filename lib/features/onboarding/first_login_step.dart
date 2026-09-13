enum FirstLoginStep {
  none,
  mobile,
  language,
  photo,
  category,
  creator,
  social;

  String get storageValue => switch (this) {
        FirstLoginStep.none => 'done',
        FirstLoginStep.mobile => 'mobile',
        FirstLoginStep.language => 'language',
        FirstLoginStep.photo => 'photo',
        FirstLoginStep.category => 'category',
        FirstLoginStep.creator => 'creator',
        FirstLoginStep.social => 'social',
      };

  int get setupIndex => switch (this) {
        FirstLoginStep.none => -1,
        FirstLoginStep.mobile => 0,
        FirstLoginStep.language => 1,
        FirstLoginStep.photo => 2,
        FirstLoginStep.category => 3,
        FirstLoginStep.creator => 4,
        FirstLoginStep.social => 5,
      };

  static const setupStepCount = 6;

  static FirstLoginStep fromStorage(String? value, {required bool completed}) {
    if (completed) return FirstLoginStep.none;
    return switch (value) {
      'mobile' => FirstLoginStep.mobile,
      'language' => FirstLoginStep.language,
      'photo' => FirstLoginStep.photo,
      'category' => FirstLoginStep.category,
      'creator' => FirstLoginStep.creator,
      'social' => FirstLoginStep.social,
      'done' => FirstLoginStep.none,
      _ => FirstLoginStep.mobile,
    };
  }
}
