import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bombay_casting/navigation/app_page_route.dart';
import 'package:bombay_casting/providers/app_state.dart';
import 'package:bombay_casting/screens/premium_screen.dart';
import 'package:bombay_casting/data/creator_profiles.dart';
import 'package:bombay_casting/screens/creator_profile_screen.dart';
import 'package:bombay_casting/data/conversations.dart';
import 'package:bombay_casting/screens/job_detail_screen.dart';
import 'package:bombay_casting/screens/message_detail_screen.dart';

class AppNavigation {
  AppNavigation._();

  static bool isSubscribed(BuildContext context) {
    return context.read<AppState>().profile?.isPremium ?? false;
  }

  static void openPremiumScreen(BuildContext context) {
    Navigator.of(context).push(AppModalRoute(page: const PremiumPage()));
  }

  /// Returns true when the user already has premium. Otherwise opens benefits
  /// (checkout is not live yet).
  static bool requireSubscription(BuildContext context) {
    if (isSubscribed(context)) return true;
    openPremiumScreen(context);
    return false;
  }

  static void openJobDetail(BuildContext context, JobDetailData profile) {
    Navigator.of(context).push(
      AppPageRoute(page: JobDetailScreen(profile: profile)),
    );
  }

  static void openCreatorProfile(BuildContext context, CreatorProfile creator) {
    Navigator.of(context).push(
      AppPageRoute(page: CreatorProfileScreen(creator: creator)),
    );
  }

  static void openMessageDetail(
    BuildContext context,
    ConversationThread conversation,
  ) {
    Navigator.of(context).push(
      AppPageRoute(page: MessageDetailScreen(conversation: conversation)),
    );
  }

  static void push(BuildContext context, Widget page) {
    Navigator.of(context).push(AppPageRoute(page: page));
  }
}
