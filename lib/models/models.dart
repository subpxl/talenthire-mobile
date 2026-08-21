// ===== Enums =====

enum UserRole { influencer }


enum AccountStatus { active, inactive, suspended }

enum SubscriptionStatus { free, premium, expired }

enum LocationType { remote, online, onsite }

enum JobStatus { draft, published, closed, cancelled }

enum ApplicationStatus { applied, shortlisted, interview, selected, rejected, withdrawn }

enum PaymentStatus { pending, completed, failed }

// ===== Helpers =====

String accountStatusToString(AccountStatus s) => s.name;
AccountStatus accountStatusFromString(String s) =>
    AccountStatus.values.firstWhere((e) => e.name == s, orElse: () => AccountStatus.active);

String subscriptionStatusToString(SubscriptionStatus s) => s.name;
SubscriptionStatus subscriptionStatusFromString(String s) =>
    SubscriptionStatus.values.firstWhere((e) => e.name == s, orElse: () => SubscriptionStatus.free);

String locationTypeToString(LocationType t) => t.name;
LocationType locationTypeFromString(String s) =>
    LocationType.values.firstWhere((e) => e.name == s, orElse: () => LocationType.remote);

String jobStatusToString(JobStatus s) => s.name;
JobStatus jobStatusFromString(String s) {
  // Webapp historically used "open"; treat as published for mobile.
  if (s == 'open') return JobStatus.published;
  return JobStatus.values.firstWhere((e) => e.name == s, orElse: () => JobStatus.draft);
}

DateTime? _parseFlexibleDate(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  try {
    final dynamic maybe = value;
    if (maybe is Object && maybe.runtimeType.toString() == 'Timestamp') {
      return (maybe as dynamic).toDate() as DateTime;
    }
    // Serialized Timestamp maps
    if (maybe is Map && maybe['seconds'] != null) {
      return DateTime.fromMillisecondsSinceEpoch((maybe['seconds'] as num).toInt() * 1000);
    }
  } catch (_) {}
  return DateTime.tryParse(value.toString());
}

String applicationStatusToString(ApplicationStatus s) => s.name;
ApplicationStatus applicationStatusFromString(String s) =>
    ApplicationStatus.values.firstWhere((e) => e.name == s, orElse: () => ApplicationStatus.applied);

String paymentStatusToString(PaymentStatus s) => s.name;
PaymentStatus paymentStatusFromString(String s) =>
    PaymentStatus.values.firstWhere((e) => e.name == s, orElse: () => PaymentStatus.pending);

String userRoleToString(UserRole r) => r.name;
UserRole userRoleFromString(String s) =>
    UserRole.values.firstWhere((e) => e.name == s, orElse: () => UserRole.influencer);

// ===== Social Link =====

class SocialLink {
  final String name;
  final String url;

  SocialLink({required this.name, required this.url});

  factory SocialLink.fromJson(Map<String, dynamic> json) {
    return SocialLink(
      name: json['name'] ?? json['platform'] ?? '',
      url: json['url'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {'name': name, 'url': url};
}

// ===== User =====

class User {
  final String id;
  String mobile;
  String name;
  String email;
  UserRole role;
  int? birthDay;
  int? birthMonth;
  int? birthYear;
  bool isActive;
  DateTime? scheduledDeletionDate;
  final DateTime createdAt;
  DateTime updatedAt;

  User({
    required this.id,
    this.mobile = '',
    this.name = '',
    this.email = '',
    this.role = UserRole.influencer,
    this.birthDay,
    this.birthMonth,
    this.birthYear,
    this.isActive = true,
    this.scheduledDeletionDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  factory User.fromJson(Map<String, dynamic> json) {
    String n = (json['name'] ?? '').toString();
    if (n.isEmpty) n = (json['agencyName'] ?? '').toString();
    if (n.isEmpty) n = (json['agency_name'] ?? '').toString();

    return User(
      id: json['id']?.toString() ?? '',
      mobile: json['mobile'] ?? '',
      name: n,
      email: json['email'] ?? '',
      role: userRoleFromString(json['role'] ?? 'influencer'),
      birthDay: (json['birth_day'] ?? json['birthDay']) as int?,
      birthMonth: (json['birth_month'] ?? json['birthMonth']) as int?,
      birthYear: (json['birth_year'] ?? json['birthYear']) as int?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      isActive: json['is_active'] ?? true,
      scheduledDeletionDate: json['scheduled_deletion_date'] != null
          ? DateTime.tryParse(json['scheduled_deletion_date'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'mobile': mobile,
        'name': name,
        'email': email,
        'role': userRoleToString(role),
        if (birthDay != null) 'birth_day': birthDay,
        if (birthMonth != null) 'birth_month': birthMonth,
        if (birthYear != null) 'birth_year': birthYear,
        'is_active': isActive,
        if (scheduledDeletionDate != null) 'scheduled_deletion_date': scheduledDeletionDate!.toIso8601String(),
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };
}

// ===== Profile (Influencer/Artist) =====

class Profile {
  final String userId;
  String profileImage;
  List<String> photos; // multiple photos, first or selected = profile
  bool isVerified;
  String talent;
  String bio;
  List<SocialLink> socialLinks;
  String contact;
  String address;
  String city;
  String state;
  String pincode;
  String videoInterviewLink;

  // YouTube Shorts links
  String achievementsVideoLink;
  String shortIntroVideoLink;
  String previousWorksVideoLink;

  AccountStatus accountStatus;
  SubscriptionStatus subscriptionStatus;

  int? age;
  String gender; // male, female, other
  String? height;
  String? bodyType; // slim, athletic, average, heavy
  String? ethnicity; // north_indian, south_indian, east_indian, west_indian, central_indian, northeast_indian, other
  String experienceLevel; // fresher, intermediate, experienced
  List<String> languages;
  bool profileCompleted;

  // Free tier tracking
  int freeJobApplicationsUsed;

  Profile({
    required this.userId,
    this.profileImage = '',
    List<String>? photos,
    this.isVerified = false,
    this.talent = 'other',
    this.bio = '',
    List<SocialLink>? socialLinks,
    this.contact = '',
    this.address = '',
    this.city = '',
    this.state = '',
    this.pincode = '',
    this.videoInterviewLink = '',
    this.achievementsVideoLink = '',
    this.shortIntroVideoLink = '',
    this.previousWorksVideoLink = '',
    this.accountStatus = AccountStatus.active,
    this.subscriptionStatus = SubscriptionStatus.free,
    this.age,
    this.gender = '',
    this.height,
    this.bodyType,
    this.ethnicity,
    this.experienceLevel = 'fresher',
    List<String>? languages,
    this.profileCompleted = false,
    this.freeJobApplicationsUsed = 0,
  })  : photos = photos ?? [],
        languages = languages ?? [],
        socialLinks = socialLinks ?? [];

  bool get isPremium => subscriptionStatus == SubscriptionStatus.premium;
  bool get canPostYoutubeLinks => isPremium && isVerified;
  bool get canApplyFreeJob => freeJobApplicationsUsed < 1;

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      userId: json['user_id']?.toString() ?? '',
      profileImage: json['profile_image'] ?? '',
      photos: json['photos'] != null ? List<String>.from(json['photos']) : [],
      isVerified: json['is_verified'] ?? false,
      talent: json['talent'] ?? 'other',
      bio: json['bio'] ?? '',
      socialLinks: json['social_links'] != null
          ? (json['social_links'] as List).map((e) => SocialLink.fromJson(e)).toList()
          : [],
      contact: json['contact'] ?? '',
      address: json['address'] ?? '',
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      pincode: json['pincode'] ?? '',
      videoInterviewLink: json['video_interview_link'] ?? '',
      achievementsVideoLink: json['achievements_video_link'] ?? '',
      shortIntroVideoLink: json['short_intro_video_link'] ?? '',
      previousWorksVideoLink: json['previous_works_video_link'] ?? '',
      accountStatus: accountStatusFromString(json['account_status'] ?? 'active'),
      subscriptionStatus: subscriptionStatusFromString(json['subscription_status'] ?? 'free'),
      age: json['age'],
      gender: json['gender'] ?? '',
      height: json['height'],
      bodyType: json['body_type'],
      ethnicity: json['ethnicity'],
      experienceLevel: json['experience_level'] ?? 'fresher',
      languages: json['languages'] != null ? List<String>.from(json['languages']) : [],
      profileCompleted: json['profile_completed'] ?? false,
      freeJobApplicationsUsed: json['free_job_applications_used'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'profile_image': profileImage,
        'photos': photos,
        'is_verified': isVerified,
        'talent': talent,
        'bio': bio,
        'social_links': socialLinks.map((e) => e.toJson()).toList(),
        'contact': contact,
        'address': address,
        'city': city,
        'state': state,
        'pincode': pincode,
        'video_interview_link': videoInterviewLink,
        'achievements_video_link': achievementsVideoLink,
        'short_intro_video_link': shortIntroVideoLink,
        'previous_works_video_link': previousWorksVideoLink,
        'account_status': accountStatusToString(accountStatus),
        'subscription_status': subscriptionStatusToString(subscriptionStatus),
        'age': age,
        'gender': gender,
        'height': height,
        'body_type': bodyType,
        'ethnicity': ethnicity,
        'experience_level': experienceLevel,
        'languages': languages,
        'profile_completed': profileCompleted,
        'free_job_applications_used': freeJobApplicationsUsed,
      };
}

// ===== Artist =====

class Artist {
  final String id;
  final String name;
  final String role;
  final String location;
  final String description;
  final List<String> skills;
  final String initials;
  final String profileImage;
  final List<String> photos;
  final List<SocialLink> socialLinks;
  final String achievementsVideoLink;
  final String shortIntroVideoLink;
  final String previousWorksVideoLink;
  final int? age;
  final String gender;
  final String? height;
  final String? bodyType;
  final String? ethnicity;
  final String experienceLevel;
  final List<String> languages;

  Artist({
    required this.id,
    required this.name,
    required this.role,
    required this.location,
    required this.description,
    required this.skills,
    required this.initials,
    this.profileImage = '',
    List<String>? photos,
    required this.socialLinks,
    required this.achievementsVideoLink,
    required this.shortIntroVideoLink,
    required this.previousWorksVideoLink,
    this.age,
    this.gender = '',
    this.height,
    this.bodyType,
    this.ethnicity,
    this.experienceLevel = '',
    List<String>? languages,
  }) : photos = photos ?? [],
       languages = languages ?? [];

  factory Artist.fromJson(Map<String, dynamic> json) {
    return Artist(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      role: json['role'] ?? '',
      location: json['location'] ?? '',
      description: json['description'] ?? '',
      skills: json['skills'] != null ? List<String>.from(json['skills']) : [],
      initials: json['initials'] ?? '',
      profileImage: json['profile_image'] ?? '',
      photos: json['photos'] != null ? List<String>.from(json['photos']) : [],
      socialLinks: json['social_links'] != null
          ? (json['social_links'] as List).map((e) => SocialLink.fromJson(e)).toList()
          : [],
      achievementsVideoLink: json['achievements_video_link'] ?? '',
      shortIntroVideoLink: json['short_intro_video_link'] ?? '',
      previousWorksVideoLink: json['previous_works_video_link'] ?? '',
      age: json['age'],
      gender: json['gender'] ?? '',
      height: json['height'],
      bodyType: json['body_type'],
      ethnicity: json['ethnicity'],
      experienceLevel: json['experience_level'] ?? '',
      languages: json['languages'] != null ? List<String>.from(json['languages']) : [],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'role': role,
        'location': location,
        'description': description,
        'skills': skills,
        'initials': initials,
        'profile_image': profileImage,
        'photos': photos,
        'social_links': socialLinks.map((e) => e.toJson()).toList(),
        'achievements_video_link': achievementsVideoLink,
        'short_intro_video_link': shortIntroVideoLink,
        'previous_works_video_link': previousWorksVideoLink,
        'age': age,
        'gender': gender,
        'height': height,
        'body_type': bodyType,
        'ethnicity': ethnicity,
        'experience_level': experienceLevel,
        'languages': languages,
      };
}

// ===== Job =====

class Job {
  final String id;
  final String title;
  String summary;
  final String description;
  final String company;
  final LocationType locationType;
  final String location;
  JobStatus status;
  final DateTime postedAt;
  final DateTime applicationDeadline;
  final String createdBy;

  // Display helpers (from old model for backwards compat)
  final String salary;
  final List<String> tags;
  final int applied;
  final int views;
  final String level;
  final bool urgent;
  final String initials;

  // Webapp / audition fields
  final String requirements;
  final bool isAudition;
  final String auditionScript;
  final int? ageMin;
  final int? ageMax;
  final String genderRequired;
  final String interviewVideoLink;

  Job({
    required this.id,
    required this.title,
    this.summary = '',
    required this.description,
    required this.company,
    this.locationType = LocationType.remote,
    required this.location,
    this.status = JobStatus.published,
    DateTime? postedAt,
    DateTime? applicationDeadline,
    this.createdBy = '',
    this.salary = '',
    List<String>? tags,
    this.applied = 0,
    this.views = 0,
    this.level = '',
    this.urgent = false,
    this.initials = '',
    this.requirements = '',
    this.isAudition = false,
    this.auditionScript = '',
    this.ageMin,
    this.ageMax,
    this.genderRequired = '',
    this.interviewVideoLink = '',
  })  : postedAt = postedAt ?? DateTime.now(),
        applicationDeadline = applicationDeadline ?? DateTime.now().add(const Duration(days: 30)),
        tags = tags ?? [];

  String get timeAgo {
    final diff = DateTime.now().difference(postedAt);
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hours ago';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return '${(diff.inDays / 7).floor()} weeks ago';
  }

  String get agencyId => createdBy;

  factory Job.fromJson(Map<String, dynamic> json) {
    final requirements = (json['requirements'] ?? '').toString();
    List<String> tags = [];
    if (json['tags'] != null) {
      tags = List<String>.from(json['tags']);
    } else if (requirements.isNotEmpty) {
      tags = requirements
          .split(',')
          .map((t) => t.trim())
          .where((t) => t.isNotEmpty)
          .toList();
    }

    final company = (json['company'] ?? '').toString();
    final createdBy =
        (json['created_by'] ?? json['agencyId'] ?? json['agency_id'] ?? '').toString();

    String initials = (json['initials'] ?? '').toString();
    if (initials.isEmpty && company.isNotEmpty) {
      final parts = company.trim().split(RegExp(r'\s+'));
      initials = parts.length >= 2
          ? '${parts[0][0]}${parts[1][0]}'.toUpperCase()
          : company.substring(0, company.length >= 2 ? 2 : 1).toUpperCase();
    }

    final postedAt = _parseFlexibleDate(json['posted_at']) ??
        _parseFlexibleDate(json['createdAt']) ??
        _parseFlexibleDate(json['created_at']) ??
        DateTime.now();

    final deadline = _parseFlexibleDate(json['application_deadline']) ??
        postedAt.add(const Duration(days: 30));

    final isAudition = json['isAudition'] == true ||
        json['is_audition'] == true ||
        (json['isAudition']?.toString() == 'true') ||
        (json['is_audition']?.toString() == 'true');

    final auditionScript =
        (json['auditionScript'] ?? json['audition_script'] ?? '').toString();

    final locationRaw = (json['location'] ?? '').toString();
    final locationTypeRaw = (json['location_type'] ?? 'remote').toString();

    return Job(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      summary: json['summary'] ?? '',
      description: json['description'] ?? '',
      company: company,
      locationType: locationTypeFromString(locationTypeRaw),
      location: locationRaw.isNotEmpty
          ? locationRaw
          : (locationTypeRaw == 'remote' ? 'Remote' : ''),
      status: jobStatusFromString(json['status']?.toString() ?? 'published'),
      postedAt: postedAt,
      applicationDeadline: deadline,
      createdBy: createdBy,
      salary: json['salary'] ?? '',
      tags: tags,
      applied: (json['applied'] as num?)?.toInt() ?? 0,
      views: (json['views'] as num?)?.toInt() ?? 0,
      level: json['level'] ?? '',
      urgent: json['urgent'] == true,
      initials: initials,
      requirements: requirements,
      isAudition: isAudition,
      auditionScript: auditionScript,
      ageMin: (json['age_min'] ?? json['ageMin']) is num
          ? ((json['age_min'] ?? json['ageMin']) as num).toInt()
          : null,
      ageMax: (json['age_max'] ?? json['ageMax']) is num
          ? ((json['age_max'] ?? json['ageMax']) as num).toInt()
          : null,
      genderRequired:
          (json['gender_required'] ?? json['genderRequired'] ?? '').toString(),
      interviewVideoLink: (json['interview_video_link'] ??
              json['interviewVideoLink'] ??
              '')
          .toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'summary': summary,
        'description': description,
        'company': company,
        'location_type': locationTypeToString(locationType),
        'location': location,
        'status': jobStatusToString(status),
        'posted_at': postedAt.toIso8601String(),
        'application_deadline': applicationDeadline.toIso8601String(),
        'created_by': createdBy,
        'agencyId': createdBy,
        'salary': salary,
        'tags': tags,
        'applied': applied,
        'views': views,
        'level': level,
        'urgent': urgent,
        'initials': initials,
        'requirements': requirements,
        'isAudition': isAudition,
        'is_audition': isAudition,
        'auditionScript': auditionScript.isEmpty ? null : auditionScript,
        'audition_script': auditionScript,
        if (ageMin != null) 'age_min': ageMin,
        if (ageMax != null) 'age_max': ageMax,
        if (genderRequired.isNotEmpty) 'gender_required': genderRequired,
        if (interviewVideoLink.isNotEmpty)
          'interview_video_link': interviewVideoLink,
      };

  Job copyWith({int? applied, int? views}) {
    return Job(
      id: id,
      title: title,
      summary: summary,
      description: description,
      company: company,
      locationType: locationType,
      location: location,
      status: status,
      postedAt: postedAt,
      applicationDeadline: applicationDeadline,
      createdBy: createdBy,
      salary: salary,
      tags: tags,
      applied: applied ?? this.applied,
      views: views ?? this.views,
      level: level,
      urgent: urgent,
      initials: initials,
      requirements: requirements,
      isAudition: isAudition,
      auditionScript: auditionScript,
      ageMin: ageMin,
      ageMax: ageMax,
      genderRequired: genderRequired,
      interviewVideoLink: interviewVideoLink,
    );
  }
}

// ===== Application =====

class Application {
  final String id;
  final String userId;
  final String jobId;
  final String jobTitle;
  final String company;
  ApplicationStatus status;
  final DateTime appliedAt;
  DateTime updatedAt;
  String recruiterNote;
  String script;
  String videoUrl;

  Application({
    required this.id,
    this.userId = '',
    this.jobId = '',
    required this.jobTitle,
    required this.company,
    this.status = ApplicationStatus.applied,
    DateTime? appliedAt,
    DateTime? updatedAt,
    this.recruiterNote = '',
    this.script = '',
    this.videoUrl = '',
  })  : appliedAt = appliedAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  String get appliedDate => appliedAt.toString().substring(0, 10);

  String get statusDisplay {
    switch (status) {
      case ApplicationStatus.applied:
        return 'Pending';
      case ApplicationStatus.shortlisted:
        return 'Shortlisted';
      case ApplicationStatus.interview:
        return 'Interview';
      case ApplicationStatus.selected:
        return 'Accepted';
      case ApplicationStatus.rejected:
        return 'Rejected';
      case ApplicationStatus.withdrawn:
        return 'Withdrawn';
    }
  }

  factory Application.fromJson(Map<String, dynamic> json) {
    final script = (json['script'] ?? '').toString();
    var videoUrl = (json['video_url'] ?? json['videoUrl'] ?? '').toString();
    // Back-compat: older apps stored the YouTube link inside script
    if (videoUrl.isEmpty &&
        (script.contains('youtube.com') || script.contains('youtu.be'))) {
      videoUrl = script.trim();
    }

    return Application(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      jobId: json['job_id']?.toString() ?? '',
      jobTitle: json['job_title'] ?? '',
      company: json['company'] ?? '',
      status: applicationStatusFromString(json['status'] ?? 'applied'),
      appliedAt: json['applied_at'] != null
          ? DateTime.tryParse(json['applied_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      recruiterNote: json['recruiter_note'] ?? '',
      script: script,
      videoUrl: videoUrl,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'job_id': jobId,
        'job_title': jobTitle,
        'company': company,
        'status': applicationStatusToString(status),
        'applied_at': appliedAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
        'recruiter_note': recruiterNote,
        'script': script,
        'video_url': videoUrl,
      };
}

// ===== Conversation =====

class Conversation {
  final String id;
  String timeAgo;
  String lastMessage;
  Map<String, int> unreadCounts;
  final List<String> participants;
  DateTime updatedAt;

  final Map<String, String> participantNames;
  final Map<String, String> participantTypes;
  final Map<String, String> participantInitials;

  Conversation({
    required this.id,
    this.timeAgo = '',
    this.lastMessage = '',
    Map<String, int>? unreadCounts,
    List<String>? participants,
    DateTime? updatedAt,
    Map<String, String>? participantNames,
    Map<String, String>? participantTypes,
    Map<String, String>? participantInitials,
  })  : unreadCounts = unreadCounts ?? {},
        participants = participants ?? [],
        updatedAt = updatedAt ?? DateTime.now(),
        participantNames = participantNames ?? {},
        participantTypes = participantTypes ?? {},
        participantInitials = participantInitials ?? {};

  int unreadFor(String userId) => unreadCounts[userId] ?? 0;

  factory Conversation.fromJson(Map<String, dynamic> json) {
    Map<String, int> counts = {};
    if (json['unread_counts'] != null) {
      counts = Map<String, int>.from(
        (json['unread_counts'] as Map).map(
          (k, v) => MapEntry(k.toString(), (v as num).toInt()),
        ),
      );
    } else if (json['unread'] != null) {
      // Legacy single unread field
      counts = {};
    }

    return Conversation(
      id: json['id']?.toString() ?? '',
      timeAgo: json['time_ago'] ?? '',
      lastMessage: json['last_message'] ?? '',
      unreadCounts: counts,
      participants: json['participants'] != null ? List<String>.from(json['participants']) : [],
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      participantNames: json['participant_names'] != null ? Map<String, String>.from(json['participant_names']) : {},
      participantTypes: json['participant_types'] != null ? Map<String, String>.from(json['participant_types']) : {},
      participantInitials: json['participant_initials'] != null ? Map<String, String>.from(json['participant_initials']) : {},
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'time_ago': timeAgo,
        'last_message': lastMessage,
        'unread_counts': unreadCounts,
        'participants': participants,
        'updated_at': updatedAt.toIso8601String(),
        'participant_names': participantNames,
        'participant_types': participantTypes,
        'participant_initials': participantInitials,
      };

  String getOtherParticipantId(String currentUserId) {
    return participants.firstWhere((id) => id != currentUserId, orElse: () => '');
  }

  String getOtherParticipantName(String currentUserId) {
    final otherId = getOtherParticipantId(currentUserId);
    return participantNames[otherId] ?? 'Unknown';
  }

  String getOtherParticipantType(String currentUserId) {
    final otherId = getOtherParticipantId(currentUserId);
    return participantTypes[otherId] ?? 'talent';
  }

  String getOtherParticipantInitials(String currentUserId) {
    final otherId = getOtherParticipantId(currentUserId);
    return participantInitials[otherId] ?? '??';
  }
}

// ===== Chat Message =====

class ChatMessage {
  final String id;
  final String conversationId;
  final String text;
  final String senderId;
  final DateTime createdAt;

  ChatMessage({
    required this.id,
    required this.conversationId,
    required this.text,
    required this.senderId,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    DateTime createdAt = DateTime.now();
    if (json['created_at'] != null) {
      final raw = json['created_at'];
      if (raw is num) {
        createdAt = DateTime.fromMillisecondsSinceEpoch(raw.toInt());
      } else {
        createdAt = DateTime.tryParse(raw.toString()) ?? DateTime.now();
      }
    }

    return ChatMessage(
      id: json['id']?.toString() ?? '',
      conversationId: json['conversation_id']?.toString() ?? '',
      text: json['text'] ?? '',
      senderId: json['sender_id'] ?? json['sender'] ?? '',
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'conversation_id': conversationId,
        'text': text,
        'sender_id': senderId,
        'created_at': createdAt.millisecondsSinceEpoch,
      };
}

// ===== Payment =====

class Payment {
  final String id;
  final String userId;
  final double amount;
  final String purpose; // 'premium_upgrade'
  PaymentStatus status;
  final String? cashfreeOrderId;
  final DateTime createdAt;
  DateTime updatedAt;

  Payment({
    required this.id,
    required this.userId,
    required this.amount,
    this.purpose = '',
    this.status = PaymentStatus.pending,
    this.cashfreeOrderId,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['id']?.toString() ?? '',
      userId: json['userId']?.toString() ?? json['user_id']?.toString() ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      purpose: json['purpose'] ?? '',
      status: paymentStatusFromString(json['status'] ?? 'pending'),
      cashfreeOrderId: json['cashfreeOrderId'] ?? json['cashfree_order_id'],
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'amount': amount,
        'purpose': purpose,
        'status': paymentStatusToString(status),
        'cashfree_order_id': cashfreeOrderId,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };
}

// ===== Subscription =====

class Subscription {
  final String id;
  final String userId;
  final String plan; // 'influencer_premium'
  final double amount;
  PaymentStatus status;
  final String paymentId;
  final DateTime createdAt;
  DateTime updatedAt;
  final DateTime expiresAt;

  Subscription({
    required this.id,
    required this.userId,
    required this.plan,
    required this.amount,
    this.status = PaymentStatus.pending,
    this.paymentId = '',
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? expiresAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now(),
        expiresAt = expiresAt ?? DateTime.now().add(const Duration(days: 30));

  bool get isActive =>
      status == PaymentStatus.completed && expiresAt.isAfter(DateTime.now());

  factory Subscription.fromJson(Map<String, dynamic> json) {
    return Subscription(
      id: json['id']?.toString() ?? '',
      userId: json['userId']?.toString() ?? json['user_id']?.toString() ?? '',
      plan: json['plan'] ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      status: paymentStatusFromString(json['status'] ?? 'pending'),
      paymentId: json['paymentId']?.toString() ?? json['payment_id']?.toString() ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      expiresAt: _parseFlexibleDate(json['expiresAt'] ?? json['expires_at']) ??
          DateTime.now().add(const Duration(days: 30)),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'plan': plan,
        'amount': amount,
        'status': paymentStatusToString(status),
        'payment_id': paymentId,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
        'expires_at': expiresAt.toIso8601String(),
      };
}

// ===== Notification =====

class AppNotification {
  final String id;
  final String userId;
  final String title;
  final String message;
  bool isRead;
  final DateTime createdAt;

  AppNotification({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    this.isRead = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      isRead: json['is_read'] ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'title': title,
        'message': message,
        'is_read': isRead,
        'created_at': createdAt.toIso8601String(),
      };
}

// ===== Pricing Constants =====

class AppPricing {
  static const double premiumUpgrade = 200.0;
  static const double agencySubscription = 500.0;
  static const int freeJobApplicationLimit = 1;
}
