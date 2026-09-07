enum FirstLoginStep {
  none,
  mobile,
  language,
  photo;

  String get storageValue => switch (this) {
        FirstLoginStep.none => 'done',
        FirstLoginStep.mobile => 'mobile',
        FirstLoginStep.language => 'language',
        FirstLoginStep.photo => 'photo',
      };

  int get setupIndex => switch (this) {
        FirstLoginStep.none => -1,
        FirstLoginStep.mobile => 0,
        FirstLoginStep.language => 1,
        FirstLoginStep.photo => 2,
      };

  static const setupStepCount = 3;

  static FirstLoginStep fromStorage(String? value, {required bool completed}) {
    if (completed) return FirstLoginStep.none;
    return switch (value) {
      'mobile' => FirstLoginStep.mobile,
      'language' => FirstLoginStep.language,
      'photo' => FirstLoginStep.photo,
      'done' => FirstLoginStep.none,
      _ => FirstLoginStep.mobile,
    };
  }
}
