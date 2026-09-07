import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bombay_casting/l10n/app_localizations.dart';
import 'package:bombay_casting/core/models/models.dart';
import 'package:bombay_casting/core/widgets/app_success_toast.dart';
import 'package:bombay_casting/features/jobs/models/job_listing.dart';
import 'package:bombay_casting/app/app_state.dart';
import 'package:bombay_casting/core/theme/app_theme.dart';

Future<String?> showOptionPicker({
  required BuildContext context,
  required String title,
  required List<String> options,
  String? selected,
}) {
  final screenHeight = MediaQuery.sizeOf(context).height;
  return showModalBottomSheet<String>(
    context: context,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      return SafeArea(
        child: Container(
          constraints: BoxConstraints(maxHeight: screenHeight * 0.65),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 8, bottom: 4),
                width: 32,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () => Navigator.pop(context),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, thickness: 0.5),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  itemCount: options.length,
                  itemBuilder: (context, index) {
                    final option = options[index];
                    final isSelected = option == selected;
                    return InkWell(
                      onTap: () => Navigator.pop(context, option),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        margin: const EdgeInsets.symmetric(vertical: 1),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary.withValues(alpha: 0.07)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                option,
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                                  color: isSelected ? AppColors.primary : AppColors.textPrimary,
                                ),
                              ),
                            ),
                            if (isSelected)
                              const Icon(
                                Icons.check,
                                color: AppColors.primary,
                                size: 18,
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

bool _savingProfileSection = false;

Future<void> saveProfileSection({
  required BuildContext context,
  required String section,
  required Map<String, dynamic> data,
  Profile Function(Profile current)? extra,
  bool pop = true,
  String? successMessage,
  bool showSuccessToast = true,
}) async {
  if (_savingProfileSection) return;
  final appState = context.read<AppState>();
  final profile = appState.profile;
  if (profile == null) return;
  var updated = profile.mergeFormSection(section, data);
  if (extra != null) updated = extra(updated);
  _savingProfileSection = true;
  try {
    await appState.updateProfile(updated);
    if (context.mounted && showSuccessToast) {
      showAppSuccessToast(
        context,
        successMessage ?? AppLocalizations.of(context)!.saved,
      );
    }
    if (pop && context.mounted) Navigator.pop(context);
  } catch (_) {
    if (context.mounted) {
      showAppToast(
        context,
        AppLocalizations.of(context)!.couldNotSaveDocuments,
        type: AppToastType.error,
      );
    }
  } finally {
    _savingProfileSection = false;
  }
}

class ProfileOptions {
  ProfileOptions._();

  static const languages = [
    'Hindi',
    'English',
    'Gujarati',
    'Marathi',
    'Punjabi',
    'Tamil',
    'Telugu',
    'Kannada',
    'Malayalam',
    'Bengali',
    'Urdu',
    'Other',
  ];

  static const cities = [
    'Indore, Madhya Pradesh',
    'Mumbai, Maharashtra',
    'Delhi NCR',
    'Pune, Maharashtra',
    'Bengaluru, Karnataka',
    'Hyderabad, Telangana',
    'Jaipur, Rajasthan',
    'Ahmedabad, Gujarat',
    'Chennai, Tamil Nadu',
    'Kolkata, West Bengal',
    'Remote',
  ];

  static const salaries = [
    '₹ 0 - ₹ 25,000',
    '₹ 25,000 - ₹ 50,000',
    '₹ 50,000 - ₹ 1,00,000',
    '₹ 1,00,000 - ₹ 1,50,000',
    '₹ 1,50,000 - ₹ 2,00,000',
    '₹ 2,00,000 - ₹ 3,00,000',
    '₹ 3,00,000+',
  ];

  static const collabPays = [
    '₹ 5,000 - ₹ 15,000',
    '₹ 15,000 - ₹ 40,000',
    '₹ 40,000 - ₹ 80,000',
    '₹ 80,000 - ₹ 1,50,000',
    '₹ 1,50,000 - ₹ 3,00,000',
    '₹ 3,00,000+',
    'Negotiable',
  ];

  static const genders = [
    'Female',
    'Male',
    'Other',
  ];

  static const creatorTypes = [
    'Full-time creator',
    'Part-time creator',
    'Student creator',
    'Agency managed',
  ];

  static const creatorRoles = [
    'Influencer',
    'UGC creator',
    'Model',
    'Streamer',
    'Reviewer',
  ];

  static const experienceLevels = [
    'New (0-1 yr)',
    'Growing (1-3 yrs)',
    'Established (3-5 yrs)',
    'Pro (5+ yrs)',
  ];

  static const platforms = [
    'Instagram',
    'YouTube',
    'Facebook',
    'Twitter / X',
    'LinkedIn',
    'Snapchat',
  ];

  static const followerRanges = [
    'Under 1K',
    '1K - 10K',
    '10K - 50K',
    '50K - 100K',
    '100K - 500K',
    '500K - 1M',
    '1M+',
  ];

  static const engagementRates = [
    'Under 1%',
    '1-3%',
    '3-5%',
    '5%+',
  ];

  static const audiences = [
    'Gen Z',
    'Millennials',
    'Gen X',
    'Mixed',
  ];

  static const jobCategories = [
    'Fashion',
    'Beauty',
    'Lifestyle',
    'Food',
    'Travel',
    'Fitness',
    'Tech',
    'Gaming',
    'Film & TV',
    'Audio & Voice',
    'Comedy',
  ];

  static const niches = [
    'Cooking',
    'Food',
    'Fashion',
    'Beauty',
    'Skincare',
    'Lifestyle',
    'Travel',
    'Fitness',
    'Health',
    'Tech',
    'Gadgets',
    'Gaming',
    'Education',
    'Finance',
    'Parenting',
    'Comedy',
    'Music',
    'Dance',
    'Home & Decor',
    'Pets',
    'Automobile',
    'Sports',
    'Art',
    'Books',
    'Sustainability',
  ];

  static const contentTypes = [
    'Reviews',
    'Unboxing',
    'Tutorial',
    'Informative',
    'Blogs',
    'Storytelling',
    'Podcast',
  ];

  static const creatorCollabTypes = [
    'Paid',
    'Barter',
    'Affiliate',
  ];

  static const creatorPlatforms = [
    'Instagram',
    'YouTube',
    'Facebook',
  ];

  static const creatorContentFormats = [
    'Reels/Shorts',
    'Stories',
    'Posts',
  ];

  static const creatorWorkModes = [
    'On-site',
    'Online',
    'Hybrid',
    'Remote',
  ];

  static const contentFormats = [
    'Reels',
    'Stories',
    'Posts',
    'YouTube videos',
    'Lives',
    'Shorts',
  ];

  static const collabTypes = [
    'Paid',
    'Barter / product',
    'Both',
  ];

  static const jobCollabTypes = [
    'Paid',
    'Barter',
    'Affiliate',
    'Ambassadorship',
  ];

  static const availability = [
    'Immediate',
    'This week',
    '2 weeks',
    '1 month',
  ];

  static const workModes = [
    'Remote',
    'On-site',
    'Hybrid',
  ];

  static List<String> get talentCategories {
    if (_dynamicTalentCategories != null && _dynamicTalentCategories!.isNotEmpty) {
      return _dynamicTalentCategories!;
    }
    return defaultTalentCategories;
  }

  static List<String>? _dynamicTalentCategories;

  static void setDynamicTalentCategories(List<String> categories) {
    if (categories.isNotEmpty) {
      _dynamicTalentCategories = List.unmodifiable(categories);
    }
  }

  static const defaultTalentCategories = [
    'Actor',
    'Model',
    'Influencer',
    'Makeup Artist',
    'Singer',
    'Dancer',
  ];

  static String shortCity(String location) => shortJobCity(location);

  static List<String> get cityNames {
    final seen = <String>{};
    final names = <String>[];
    for (final city in cities) {
      final name = shortCity(city);
      if (name.toLowerCase() == 'remote') continue;
      if (seen.add(name.toLowerCase())) names.add(name);
    }
    return names;
  }

  static const jobDurations = [
    'One-off',
    'Campaign',
    'Long-term',
  ];

  static List<String> get ages {
    return [
      for (var age = 18; age <= 100; age++) '$age',
    ];
  }
}
