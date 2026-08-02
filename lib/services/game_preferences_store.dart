import 'package:shared_preferences/shared_preferences.dart';

class GamePreferencesData {
  const GamePreferencesData({
    this.selectedCharacterId,
    this.selectedDifficulty,
    this.audioEnabled,
    this.audioVolume,
    this.botSpeedName,
    this.showGameplayHelp,
    this.confirmCardPlay,
    this.languageCode,
  });

  final String? selectedCharacterId;
  final int? selectedDifficulty;
  final bool? audioEnabled;
  final double? audioVolume;
  final String? botSpeedName;
  final bool? showGameplayHelp;
  final bool? confirmCardPlay;
  final String? languageCode;
}

class GamePreferencesStore {
  const GamePreferencesStore();

  Future<GamePreferencesData> load({
    required String selectedCharacterKey,
    required String selectedDifficultyKey,
    required String audioEnabledKey,
    required String audioVolumeKey,
    required String botSpeedKey,
    required String showGameplayHelpKey,
    required String confirmCardPlayKey,
    required String languageKey,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    return GamePreferencesData(
      selectedCharacterId: prefs.getString(selectedCharacterKey),
      selectedDifficulty: prefs.getInt(selectedDifficultyKey),
      audioEnabled: prefs.getBool(audioEnabledKey),
      audioVolume: prefs.getDouble(audioVolumeKey),
      botSpeedName: prefs.getString(botSpeedKey),
      showGameplayHelp: prefs.getBool(showGameplayHelpKey),
      confirmCardPlay: prefs.getBool(confirmCardPlayKey),
      languageCode: prefs.getString(languageKey),
    );
  }

  Future<void> saveSelectedSettings({
    required String selectedCharacterKey,
    required String selectedCharacterId,
    required String selectedDifficultyKey,
    required int selectedDifficulty,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(selectedCharacterKey, selectedCharacterId);
    await prefs.setInt(selectedDifficultyKey, selectedDifficulty);
  }

  Future<void> saveMenuOptions({
    required String audioEnabledKey,
    required bool audioEnabled,
    required String audioVolumeKey,
    required double audioVolume,
    required String botSpeedKey,
    required String botSpeedName,
    required String showGameplayHelpKey,
    required bool showGameplayHelp,
    required String confirmCardPlayKey,
    required bool confirmCardPlay,
    required String languageKey,
    required String languageCode,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(audioEnabledKey, audioEnabled);
    await prefs.setDouble(audioVolumeKey, audioVolume);
    await prefs.setString(botSpeedKey, botSpeedName);
    await prefs.setBool(showGameplayHelpKey, showGameplayHelp);
    await prefs.setBool(confirmCardPlayKey, confirmCardPlay);
    await prefs.setString(languageKey, languageCode);
  }
}
