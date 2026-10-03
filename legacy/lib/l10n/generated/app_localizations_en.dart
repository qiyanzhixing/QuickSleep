// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'QuickSleep';

  @override
  String get introTitle => 'Let your breath slow';

  @override
  String get introSubtitle => 'Guided breaths · Quiet company';

  @override
  String get durationTitle => 'Session duration';

  @override
  String minutes(int count) {
    return '$count min';
  }

  @override
  String get customDuration => 'Custom';

  @override
  String get durationHint => 'Guidance included · Fades in the last 15 seconds';

  @override
  String get soundMode => 'Sound mode';

  @override
  String get change => 'Change';

  @override
  String get modeMoon => 'Moonlit Whispers';

  @override
  String get modeMountain => 'Mountain Stillness';

  @override
  String get modeForest => 'Forest Evening Breeze';

  @override
  String get descMoon => 'Soft synthesized female voice · Ambient music';

  @override
  String get descMountain =>
      'Calm synthesized male voice · Guqin-inspired synthesis';

  @override
  String get descForest => 'Quiet synthesized voice · Wind and leaves';

  @override
  String get mixedHint => 'Voice and background are already balanced';

  @override
  String get start => 'Begin relaxing';

  @override
  String get lockHint => 'Keeps playing with your screen locked';

  @override
  String get soundHint => 'Choose a sound to settle into';

  @override
  String get preview => 'Preview';

  @override
  String get stopPreview => 'Stop preview';

  @override
  String get close => 'Close';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get customTitle => 'Custom duration';

  @override
  String get customHint => 'Enter a whole number from 2 to 60';

  @override
  String get customError => 'Use a whole number from 2 to 60';

  @override
  String get settings => 'Settings';

  @override
  String get language => 'Language';

  @override
  String get theme => 'Appearance';

  @override
  String get system => 'Use system setting';

  @override
  String get night => 'Night';

  @override
  String get light => 'Light';

  @override
  String get chinese => '简体中文';

  @override
  String get english => 'English';

  @override
  String get sessionTitle => 'Relaxation session';

  @override
  String get pause => 'Pause';

  @override
  String get resume => 'Resume';

  @override
  String get end => 'End session';

  @override
  String get backHome => 'Back to home';

  @override
  String get loading => 'Preparing your sounds';

  @override
  String get paused => 'Paused';

  @override
  String get completed => 'Rest quietly';

  @override
  String get inhale => 'Breathe in';

  @override
  String get hold => 'Hold gently';

  @override
  String get exhale => 'Breathe out';

  @override
  String get natural => 'Breathe naturally';

  @override
  String get fading => 'Settling into quiet';

  @override
  String round(int count) {
    return 'Round $count of 4';
  }

  @override
  String remaining(String time) {
    return '$time remaining';
  }

  @override
  String get audioError => 'Audio could not play. Go back and try again';

  @override
  String get startupError =>
      'Could not load bundled sounds. Retry or reinstall the app';

  @override
  String get retry => 'Retry';

  @override
  String get saveError => 'Settings could not be saved for your next visit';

  @override
  String get safetyHint =>
      'If breathing feels uncomfortable, stop and breathe naturally';

  @override
  String get offlineNote => 'Fully offline · No account · No tracking';

  @override
  String get syntheticNote =>
      'Voices and backgrounds are synthesized. Guqin-inspired sounds are not a real guqin performance';

  @override
  String get nextSessionHint =>
      'Language and sound changes apply to your next session';

  @override
  String get previewError => 'Preview could not play. Try again';

  @override
  String get restartRequired =>
      'The audio service could not start. Fully close QuickSleep and reopen it.';
}
