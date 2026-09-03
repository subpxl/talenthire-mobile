import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bombay_casting/core/navigation/app_page_route.dart';
import 'package:bombay_casting/app/app_state.dart';
import 'package:bombay_casting/features/premium/screens/premium_screen.dart';
import 'package:bombay_casting/features/creators/models/creator_profile.dart';
import 'package:bombay_casting/features/creators/screens/creator_profile_screen.dart';
import 'package:bombay_casting/features/messaging/models/conversation.dart';
import 'package:bombay_casting/features/jobs/models/agency_profile.dart';
import 'package:bombay_casting/features/jobs/screens/agency_detail_screen.dart';
import 'package:bombay_casting/features/jobs/screens/job_detail_screen.dart';
import 'package:bombay_casting/features/messaging/screens/message_detail_screen.dart';

class AppNavigation {
  AppNavigation._();

  static bool isSubscribed(BuildContext context) {
    return context.read<AppState>().isPremiumUser;
  }

  static void openPremiumScreen(BuildContext context) {
    Navigator.of(context).push(AppModalRoute(page: const PremiumPage()));
  }

  /// Returns true when the user already has premium. Otherwise opens checkout.
  static bool requireSubscription(BuildContext context) {
    if (isSubscribed(context)) return true;
    openPremiumScreen(context);
    return false;
  }

  static void openAgencyDetail(BuildContext context, AgencyProfile agency) {
    Navigator.of(context).push(
      AppPageRoute(page: AgencyDetailScreen(agency: agency)),
    );
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
