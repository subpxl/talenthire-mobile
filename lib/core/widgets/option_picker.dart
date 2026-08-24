import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bombay_casting/core/models/models.dart';
import 'package:bombay_casting/app/app_state.dart';
import 'package:bombay_casting/core/theme/app_theme.dart';

Future<String?> showOptionPicker({
  required BuildContext context,
  required String title,
  required List<String> options,
  String? selected,
}) {
  return showModalBottomSheet<String>(
    context: context,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (context, index) {
                  final option = options[index];
                  final isSelected = option == selected;
                  return ListTile(
                    title: Text(option),
                    trailing: isSelected
                        ? const Icon(Icons.check, color: AppColors.primary)
                        : null,
                    onTap: () => Navigator.pop(context, option),
                  );
                },
              ),
            ),
          ],
        ),
      );
    },
  );
}

Future<void> saveProfileSection({
  required BuildContext context,
  required String section,
  required Map<String, dynamic> data,
  Profile Function(Profile current)? extra,
}) async {
  final appState = context.read<AppState>();
  final profile = appState.profile;
  if (profile == null) return;
  var updated = profile.mergeFormSection(section, data);
  if (extra != null) updated = extra(updated);
  await appState.updateProfile(updated);
  if (context.mounted) Navigator.pop(context);
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
    'Non-binary',
    'Prefer not to say',
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
    'TikTok',
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
    'Fashion',
    'Beauty',
    'Lifestyle',
    'Food',
    'Travel',
    'Fitness',
    'Tech',
    'Gaming',
    'Education',
    'Finance',
    'Parenting',
    'Comedy',
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

  static const talentCategories = [
    'Actor',
    'Dancer',
    'Influencer',
    'Model',
  ];

  static const jobDurations = [
    'One-off',
    'Campaign',
    'Long-term',
  ];

  static List<String> get ages {
    return [
      for (var age = 18; age <= 45; age++) '$age',
      '45+',
    ];
  }
}
