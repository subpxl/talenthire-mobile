import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_bn.dart';
import 'app_localizations_en.dart';
import 'app_localizations_gu.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_kn.dart';
import 'app_localizations_ml.dart';
import 'app_localizations_mr.dart';
import 'app_localizations_ta.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('bn'),
    Locale('en'),
    Locale('gu'),
    Locale('hi'),
    Locale('kn'),
    Locale('ml'),
    Locale('mr'),
    Locale('ta'),
  ];

  /// The title for the language selection screen
  ///
  /// In en, this message translates to:
  /// **'Change language'**
  String get changeLanguage;

  /// The prompt to select a language
  ///
  /// In en, this message translates to:
  /// **'Choose your app language'**
  String get chooseYourAppLanguage;

  /// No description provided for @couldNotOpenThisPageRightNow.
  ///
  /// In en, this message translates to:
  /// **'Could not open this page right now.'**
  String get couldNotOpenThisPageRightNow;

  /// No description provided for @bombayCastingCompany.
  ///
  /// In en, this message translates to:
  /// **'Bombay Casting Company'**
  String get bombayCastingCompany;

  /// No description provided for @continueWithGmail.
  ///
  /// In en, this message translates to:
  /// **'Continue with Gmail'**
  String get continueWithGmail;

  /// No description provided for @continueWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get continueWithGoogle;

  /// No description provided for @continueWithEmail.
  ///
  /// In en, this message translates to:
  /// **'Continue with Email'**
  String get continueWithEmail;

  /// No description provided for @alreadyHaveAnAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get alreadyHaveAnAccount;

  /// No description provided for @logIn.
  ///
  /// In en, this message translates to:
  /// **'Log in'**
  String get logIn;

  /// No description provided for @newHere.
  ///
  /// In en, this message translates to:
  /// **'New here?'**
  String get newHere;

  /// No description provided for @createAnAccount.
  ///
  /// In en, this message translates to:
  /// **'Create an account'**
  String get createAnAccount;

  /// No description provided for @or.
  ///
  /// In en, this message translates to:
  /// **'or'**
  String get or;

  /// No description provided for @creators.
  ///
  /// In en, this message translates to:
  /// **'Creators'**
  String get creators;

  /// No description provided for @noCreatorsToShowYet.
  ///
  /// In en, this message translates to:
  /// **'No creators to show yet.'**
  String get noCreatorsToShowYet;

  /// No description provided for @noCreatorsMatchYourSearch.
  ///
  /// In en, this message translates to:
  /// **'No creators match your search.'**
  String get noCreatorsMatchYourSearch;

  /// No description provided for @searchByNameLocationTalent.
  ///
  /// In en, this message translates to:
  /// **'Search by name, location, talent...'**
  String get searchByNameLocationTalent;

  /// No description provided for @searchJobsAgencyLocation.
  ///
  /// In en, this message translates to:
  /// **'Search jobs, agency, location...'**
  String get searchJobsAgencyLocation;

  /// No description provided for @remote.
  ///
  /// In en, this message translates to:
  /// **'Remote'**
  String get remote;

  /// No description provided for @online.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get online;

  /// No description provided for @onsite.
  ///
  /// In en, this message translates to:
  /// **'Onsite'**
  String get onsite;

  /// No description provided for @creator.
  ///
  /// In en, this message translates to:
  /// **'Creator'**
  String get creator;

  /// No description provided for @creatorReported.
  ///
  /// In en, this message translates to:
  /// **'Creator reported'**
  String get creatorReported;

  /// No description provided for @reportProfile.
  ///
  /// In en, this message translates to:
  /// **'Report profile'**
  String get reportProfile;

  /// No description provided for @noJobsMatchYourFiltersPullToRefreshOrChangeFilters.
  ///
  /// In en, this message translates to:
  /// **'No jobs match your filters. Pull to refresh or change filters.'**
  String get noJobsMatchYourFiltersPullToRefreshOrChangeFilters;

  /// No description provided for @noJobsYetPullDownToRefresh.
  ///
  /// In en, this message translates to:
  /// **'No jobs yet. Pull down to refresh.'**
  String get noJobsYetPullDownToRefresh;

  /// No description provided for @job.
  ///
  /// In en, this message translates to:
  /// **'Job'**
  String get job;

  /// No description provided for @jobReported.
  ///
  /// In en, this message translates to:
  /// **'Job reported'**
  String get jobReported;

  /// No description provided for @reportJob.
  ///
  /// In en, this message translates to:
  /// **'Report job'**
  String get reportJob;

  /// No description provided for @thisJobIsNoLongerAvailable.
  ///
  /// In en, this message translates to:
  /// **'This job is no longer available'**
  String get thisJobIsNoLongerAvailable;

  /// No description provided for @jobFilters.
  ///
  /// In en, this message translates to:
  /// **'Job filters'**
  String get jobFilters;

  /// No description provided for @whatKindOfJobsAreYouLookingFor.
  ///
  /// In en, this message translates to:
  /// **'What kind of jobs are you looking for?'**
  String get whatKindOfJobsAreYouLookingFor;

  /// No description provided for @followersRequired.
  ///
  /// In en, this message translates to:
  /// **'Followers required'**
  String get followersRequired;

  /// No description provided for @includeJobsOutsideYourCity.
  ///
  /// In en, this message translates to:
  /// **'Include jobs outside your city?'**
  String get includeJobsOutsideYourCity;

  /// No description provided for @jobType.
  ///
  /// In en, this message translates to:
  /// **'Job type'**
  String get jobType;

  /// No description provided for @payRange.
  ///
  /// In en, this message translates to:
  /// **'Pay range'**
  String get payRange;

  /// No description provided for @yourDataIs100SafeWithUs.
  ///
  /// In en, this message translates to:
  /// **'Your data is 100% safe with us'**
  String get yourDataIs100SafeWithUs;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @update.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get update;

  /// No description provided for @tapBookmarkOnAJobToSaveIt.
  ///
  /// In en, this message translates to:
  /// **'Tap bookmark on a job to save it'**
  String get tapBookmarkOnAJobToSaveIt;

  /// No description provided for @tapBookmarkOnACreatorToSaveIt.
  ///
  /// In en, this message translates to:
  /// **'Tap bookmark on a creator to save it'**
  String get tapBookmarkOnACreatorToSaveIt;

  /// No description provided for @conversationReported.
  ///
  /// In en, this message translates to:
  /// **'Conversation reported'**
  String get conversationReported;

  /// No description provided for @report.
  ///
  /// In en, this message translates to:
  /// **'Report'**
  String get report;

  /// No description provided for @agenciesMessageYouAfterYouApply.
  ///
  /// In en, this message translates to:
  /// **'Agencies message you after you apply'**
  String get agenciesMessageYouAfterYouApply;

  /// No description provided for @howCanWeHelpYou.
  ///
  /// In en, this message translates to:
  /// **'How can we help you?'**
  String get howCanWeHelpYou;

  /// No description provided for @relatedToMyCreatorProfile.
  ///
  /// In en, this message translates to:
  /// **'Related to my creator profile'**
  String get relatedToMyCreatorProfile;

  /// No description provided for @relatedToJobs.
  ///
  /// In en, this message translates to:
  /// **'Related to jobs'**
  String get relatedToJobs;

  /// No description provided for @paymentRelated.
  ///
  /// In en, this message translates to:
  /// **'Payment related'**
  String get paymentRelated;

  /// No description provided for @appPolicies.
  ///
  /// In en, this message translates to:
  /// **'App policies'**
  String get appPolicies;

  /// No description provided for @contactUs.
  ///
  /// In en, this message translates to:
  /// **'Contact us'**
  String get contactUs;

  /// No description provided for @paymentsAreNotAvailableYetYouCanGoBackAndKeepUsingTheApp.
  ///
  /// In en, this message translates to:
  /// **'Payments are not available yet. You can go back and keep using the app.'**
  String get paymentsAreNotAvailableYetYouCanGoBackAndKeepUsingTheApp;

  /// No description provided for @for1DayThen299month.
  ///
  /// In en, this message translates to:
  /// **'For 1 day, then ₹299/Month'**
  String get for1DayThen299month;

  /// No description provided for @phonepe.
  ///
  /// In en, this message translates to:
  /// **'PhonePe'**
  String get phonepe;

  /// No description provided for @change.
  ///
  /// In en, this message translates to:
  /// **'CHANGE'**
  String get change;

  /// No description provided for @payNow1.
  ///
  /// In en, this message translates to:
  /// **'Pay now ₹1'**
  String get payNow1;

  /// No description provided for @accountSettings.
  ///
  /// In en, this message translates to:
  /// **'Account Settings'**
  String get accountSettings;

  /// No description provided for @contactPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Contact privacy'**
  String get contactPrivacy;

  /// No description provided for @subscriptions.
  ///
  /// In en, this message translates to:
  /// **'Subscriptions'**
  String get subscriptions;

  /// No description provided for @recentTransactions.
  ///
  /// In en, this message translates to:
  /// **'Recent transactions'**
  String get recentTransactions;

  /// No description provided for @cancelSubscription.
  ///
  /// In en, this message translates to:
  /// **'Cancel subscription'**
  String get cancelSubscription;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get deleteAccount;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @content.
  ///
  /// In en, this message translates to:
  /// **'Content'**
  String get content;

  /// No description provided for @work.
  ///
  /// In en, this message translates to:
  /// **'Work'**
  String get work;

  /// No description provided for @personal.
  ///
  /// In en, this message translates to:
  /// **'Personal'**
  String get personal;

  /// No description provided for @optional.
  ///
  /// In en, this message translates to:
  /// **'(Optional)'**
  String get optional;

  /// No description provided for @jobPreferences.
  ///
  /// In en, this message translates to:
  /// **'Job preferences'**
  String get jobPreferences;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfile;

  /// No description provided for @chooseFromGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from gallery'**
  String get chooseFromGallery;

  /// No description provided for @takeAPhoto.
  ///
  /// In en, this message translates to:
  /// **'Take a photo'**
  String get takeAPhoto;

  /// No description provided for @couldNotUploadPhoto.
  ///
  /// In en, this message translates to:
  /// **'Could not upload photo'**
  String get couldNotUploadPhoto;

  /// No description provided for @couldNotRemovePhoto.
  ///
  /// In en, this message translates to:
  /// **'Could not remove photo'**
  String get couldNotRemovePhoto;

  /// No description provided for @photos.
  ///
  /// In en, this message translates to:
  /// **'Photos'**
  String get photos;

  /// No description provided for @addUpTo4PhotosFirstPhotoIsYourMainProfilePicture.
  ///
  /// In en, this message translates to:
  /// **'Add up to 4 photos. First photo is your main profile picture.'**
  String get addUpTo4PhotosFirstPhotoIsYourMainProfilePicture;

  /// No description provided for @main.
  ///
  /// In en, this message translates to:
  /// **'Main'**
  String get main;

  /// No description provided for @addPhoto.
  ///
  /// In en, this message translates to:
  /// **'Add photo'**
  String get addPhoto;

  /// No description provided for @looksBetterInPortrait.
  ///
  /// In en, this message translates to:
  /// **'Looks better in portrait'**
  String get looksBetterInPortrait;

  /// No description provided for @rates.
  ///
  /// In en, this message translates to:
  /// **'Rates'**
  String get rates;

  /// No description provided for @social.
  ///
  /// In en, this message translates to:
  /// **'Social'**
  String get social;

  /// No description provided for @couldNotSaveDocuments.
  ///
  /// In en, this message translates to:
  /// **'Could not save documents'**
  String get couldNotSaveDocuments;

  /// No description provided for @profileVerification.
  ///
  /// In en, this message translates to:
  /// **'Profile Verification'**
  String get profileVerification;

  /// No description provided for @uploadAClearPhotoOfEachDocument.
  ///
  /// In en, this message translates to:
  /// **'Upload a clear photo of each document.'**
  String get uploadAClearPhotoOfEachDocument;

  /// No description provided for @yourDocumentsAre100SafeWithUs.
  ///
  /// In en, this message translates to:
  /// **'Your documents are 100% safe with us'**
  String get yourDocumentsAre100SafeWithUs;

  /// No description provided for @tapToUpload.
  ///
  /// In en, this message translates to:
  /// **'Tap to upload'**
  String get tapToUpload;

  /// No description provided for @addDocument.
  ///
  /// In en, this message translates to:
  /// **'Add document'**
  String get addDocument;

  /// No description provided for @updateProfile.
  ///
  /// In en, this message translates to:
  /// **'Update Profile'**
  String get updateProfile;

  /// No description provided for @k1.
  ///
  /// In en, this message translates to:
  /// **'₹1'**
  String get k1;

  /// No description provided for @kemptyStr.
  ///
  /// In en, this message translates to:
  /// **'अ'**
  String get kemptyStr;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navCreators.
  ///
  /// In en, this message translates to:
  /// **'Creators'**
  String get navCreators;

  /// No description provided for @navJobs.
  ///
  /// In en, this message translates to:
  /// **'Jobs'**
  String get navJobs;

  /// No description provided for @navMessages.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get navMessages;

  /// No description provided for @navProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// No description provided for @getHelp.
  ///
  /// In en, this message translates to:
  /// **'Get help'**
  String get getHelp;

  /// No description provided for @youAreAPremiumMember.
  ///
  /// In en, this message translates to:
  /// **'You are a Premium Member'**
  String get youAreAPremiumMember;

  /// No description provided for @becomeAPremiumMember.
  ///
  /// In en, this message translates to:
  /// **'Become a Premium Member'**
  String get becomeAPremiumMember;

  /// No description provided for @active.
  ///
  /// In en, this message translates to:
  /// **'ACTIVE'**
  String get active;

  /// No description provided for @join.
  ///
  /// In en, this message translates to:
  /// **'JOIN'**
  String get join;

  /// No description provided for @applyNow.
  ///
  /// In en, this message translates to:
  /// **'Apply now'**
  String get applyNow;

  /// No description provided for @chatWithAgencies.
  ///
  /// In en, this message translates to:
  /// **'Chat with agencies'**
  String get chatWithAgencies;

  /// No description provided for @premiumApplications.
  ///
  /// In en, this message translates to:
  /// **'Premium applications'**
  String get premiumApplications;

  /// No description provided for @savedAll.
  ///
  /// In en, this message translates to:
  /// **'Saved all'**
  String get savedAll;

  /// No description provided for @saved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get saved;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @subscribeToApply.
  ///
  /// In en, this message translates to:
  /// **'Subscribe to apply and land your next collab'**
  String get subscribeToApply;

  /// No description provided for @seePlans.
  ///
  /// In en, this message translates to:
  /// **'See plans'**
  String get seePlans;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'bn',
    'en',
    'gu',
    'hi',
    'kn',
    'ml',
    'mr',
    'ta',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'bn':
      return AppLocalizationsBn();
    case 'en':
      return AppLocalizationsEn();
    case 'gu':
      return AppLocalizationsGu();
    case 'hi':
      return AppLocalizationsHi();
    case 'kn':
      return AppLocalizationsKn();
    case 'ml':
      return AppLocalizationsMl();
    case 'mr':
      return AppLocalizationsMr();
    case 'ta':
      return AppLocalizationsTa();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
