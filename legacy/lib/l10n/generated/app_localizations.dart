import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
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
    Locale('en'),
    Locale('zh'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'QuickSleep'**
  String get appTitle;

  /// No description provided for @introTitle.
  ///
  /// In en, this message translates to:
  /// **'Let your breath slow'**
  String get introTitle;

  /// No description provided for @introSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Guided breaths · Quiet company'**
  String get introSubtitle;

  /// No description provided for @durationTitle.
  ///
  /// In en, this message translates to:
  /// **'Session duration'**
  String get durationTitle;

  /// No description provided for @minutes.
  ///
  /// In en, this message translates to:
  /// **'{count} min'**
  String minutes(int count);

  /// No description provided for @customDuration.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get customDuration;

  /// No description provided for @durationHint.
  ///
  /// In en, this message translates to:
  /// **'Guidance included · Fades in the last 15 seconds'**
  String get durationHint;

  /// No description provided for @soundMode.
  ///
  /// In en, this message translates to:
  /// **'Sound mode'**
  String get soundMode;

  /// No description provided for @change.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get change;

  /// No description provided for @modeMoon.
  ///
  /// In en, this message translates to:
  /// **'Moonlit Whispers'**
  String get modeMoon;

  /// No description provided for @modeMountain.
  ///
  /// In en, this message translates to:
  /// **'Mountain Stillness'**
  String get modeMountain;

  /// No description provided for @modeForest.
  ///
  /// In en, this message translates to:
  /// **'Forest Evening Breeze'**
  String get modeForest;

  /// No description provided for @descMoon.
  ///
  /// In en, this message translates to:
  /// **'Soft synthesized female voice · Ambient music'**
  String get descMoon;

  /// No description provided for @descMountain.
  ///
  /// In en, this message translates to:
  /// **'Calm synthesized male voice · Guqin-inspired synthesis'**
  String get descMountain;

  /// No description provided for @descForest.
  ///
  /// In en, this message translates to:
  /// **'Quiet synthesized voice · Wind and leaves'**
  String get descForest;

  /// No description provided for @mixedHint.
  ///
  /// In en, this message translates to:
  /// **'Voice and background are already balanced'**
  String get mixedHint;

  /// No description provided for @start.
  ///
  /// In en, this message translates to:
  /// **'Begin relaxing'**
  String get start;

  /// No description provided for @lockHint.
  ///
  /// In en, this message translates to:
  /// **'Keeps playing with your screen locked'**
  String get lockHint;

  /// No description provided for @soundHint.
  ///
  /// In en, this message translates to:
  /// **'Choose a sound to settle into'**
  String get soundHint;

  /// No description provided for @preview.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get preview;

  /// No description provided for @stopPreview.
  ///
  /// In en, this message translates to:
  /// **'Stop preview'**
  String get stopPreview;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @customTitle.
  ///
  /// In en, this message translates to:
  /// **'Custom duration'**
  String get customTitle;

  /// No description provided for @customHint.
  ///
  /// In en, this message translates to:
  /// **'Enter a whole number from 2 to 60'**
  String get customHint;

  /// No description provided for @customError.
  ///
  /// In en, this message translates to:
  /// **'Use a whole number from 2 to 60'**
  String get customError;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get theme;

  /// No description provided for @system.
  ///
  /// In en, this message translates to:
  /// **'Use system setting'**
  String get system;

  /// No description provided for @night.
  ///
  /// In en, this message translates to:
  /// **'Night'**
  String get night;

  /// No description provided for @light.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get light;

  /// No description provided for @chinese.
  ///
  /// In en, this message translates to:
  /// **'简体中文'**
  String get chinese;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @sessionTitle.
  ///
  /// In en, this message translates to:
  /// **'Relaxation session'**
  String get sessionTitle;

  /// No description provided for @pause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get pause;

  /// No description provided for @resume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get resume;

  /// No description provided for @end.
  ///
  /// In en, this message translates to:
  /// **'End session'**
  String get end;

  /// No description provided for @backHome.
  ///
  /// In en, this message translates to:
  /// **'Back to home'**
  String get backHome;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Preparing your sounds'**
  String get loading;

  /// No description provided for @paused.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get paused;

  /// No description provided for @completed.
  ///
  /// In en, this message translates to:
  /// **'Rest quietly'**
  String get completed;

  /// No description provided for @inhale.
  ///
  /// In en, this message translates to:
  /// **'Breathe in'**
  String get inhale;

  /// No description provided for @hold.
  ///
  /// In en, this message translates to:
  /// **'Hold gently'**
  String get hold;

  /// No description provided for @exhale.
  ///
  /// In en, this message translates to:
  /// **'Breathe out'**
  String get exhale;

  /// No description provided for @natural.
  ///
  /// In en, this message translates to:
  /// **'Breathe naturally'**
  String get natural;

  /// No description provided for @fading.
  ///
  /// In en, this message translates to:
  /// **'Settling into quiet'**
  String get fading;

  /// No description provided for @round.
  ///
  /// In en, this message translates to:
  /// **'Round {count} of 4'**
  String round(int count);

  /// No description provided for @remaining.
  ///
  /// In en, this message translates to:
  /// **'{time} remaining'**
  String remaining(String time);

  /// No description provided for @audioError.
  ///
  /// In en, this message translates to:
  /// **'Audio could not play. Go back and try again'**
  String get audioError;

  /// No description provided for @startupError.
  ///
  /// In en, this message translates to:
  /// **'Could not load bundled sounds. Retry or reinstall the app'**
  String get startupError;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @saveError.
  ///
  /// In en, this message translates to:
  /// **'Settings could not be saved for your next visit'**
  String get saveError;

  /// No description provided for @safetyHint.
  ///
  /// In en, this message translates to:
  /// **'If breathing feels uncomfortable, stop and breathe naturally'**
  String get safetyHint;

  /// No description provided for @offlineNote.
  ///
  /// In en, this message translates to:
  /// **'Fully offline · No account · No tracking'**
  String get offlineNote;

  /// No description provided for @syntheticNote.
  ///
  /// In en, this message translates to:
  /// **'Voices and backgrounds are synthesized. Guqin-inspired sounds are not a real guqin performance'**
  String get syntheticNote;

  /// No description provided for @nextSessionHint.
  ///
  /// In en, this message translates to:
  /// **'Language and sound changes apply to your next session'**
  String get nextSessionHint;

  /// No description provided for @previewError.
  ///
  /// In en, this message translates to:
  /// **'Preview could not play. Try again'**
  String get previewError;

  /// No description provided for @restartRequired.
  ///
  /// In en, this message translates to:
  /// **'The audio service could not start. Fully close QuickSleep and reopen it.'**
  String get restartRequired;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
