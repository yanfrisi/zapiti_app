import 'package:shared_preferences/shared_preferences.dart';

class AccountPrivacyService {
  static const _multiplayerKeys = [
    'multiplayer_player_name',
    'multiplayer_player_id',
    'multiplayer_username',
    'multiplayer_password',
    'multiplayer_player_pin',
    'multiplayer_session_token',
    'multiplayer_team_name',
  ];

  const AccountPrivacyService._();

  static Future<void> clearLocalMultiplayerProfile() async {
    final prefs = await SharedPreferences.getInstance();
    for (final key in _multiplayerKeys) {
      await prefs.remove(key);
    }
  }
}
