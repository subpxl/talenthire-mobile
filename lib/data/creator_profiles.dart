import 'package:bombay_casting/models/models.dart';

class CreatorPhoto {
  const CreatorPhoto({
    this.url = '',
    this.imageIndex = 1,
  });

  final String url;
  final int imageIndex;
}

class CreatorProfile {
  const CreatorProfile({
    required this.id,
    required this.name,
    required this.title,
    required this.location,
    required this.photos,
    this.isVerified = false,
    this.aboutInfo = const [],
    this.workInfo = const [],
  });

  final String id;
  final String name;
  final String title;
  final String location;
  final List<CreatorPhoto> photos;
  final bool isVerified;
  final List<MapEntry<String, String>> aboutInfo;
  final List<MapEntry<String, String>> workInfo;

  CreatorPhoto get cover =>
      photos.isNotEmpty ? photos.first : const CreatorPhoto();

  factory CreatorProfile.fromRecords({
    required User user,
    required Profile profile,
    required int fallbackIndex,
  }) {
    final location = [
      profile.city,
      profile.state,
    ].where((item) => item.isNotEmpty).join(', ');
    final title = profile.formValue('work', 'role', '').trim().isNotEmpty
        ? profile.formValue('work', 'role')
        : (profile.talent.isNotEmpty ? profile.talent : 'Creator');
    final gallery = profile.galleryPhotos;
    final photos = List<CreatorPhoto>.generate(
      gallery.isEmpty ? 1 : gallery.length.clamp(1, Profile.maxPhotos),
      (index) {
        return CreatorPhoto(
          url: index < gallery.length ? gallery[index] : '',
          imageIndex: fallbackIndex + index,
        );
      },
    );
    return CreatorProfile(
      id: user.id.isNotEmpty ? user.id : profile.userId,
      name: user.name.trim().isEmpty ? 'Creator' : user.name.trim(),
      title: title,
      location: location.isEmpty ? 'India' : location,
      photos: photos,
      isVerified: profile.isVerified,
      aboutInfo: [
        if (profile.gender.isNotEmpty) MapEntry('Gender', profile.gender),
        if (profile.age != null) MapEntry('Age', '${profile.age}'),
        if (profile.languages.isNotEmpty)
          MapEntry('Languages', profile.languages.join(', ')),
        MapEntry(
          'Content language',
          profile.formValue('personal', 'language', 'Hindi'),
        ),
      ],
      workInfo: [
        MapEntry('Role', title),
        if (profile.niches.isNotEmpty)
          MapEntry('Niches', profile.niches.take(3).join(', ')),
        MapEntry(
          'Experience',
          profile.formValue('work', 'experience', 'Growing (1-3 yrs)'),
        ),
        MapEntry(
          'Open to',
          profile.formValue('personal', 'looking_for', 'Brand deals'),
        ),
      ],
    );
  }
}
