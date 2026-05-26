import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../utils/app_constants.dart';
import '../utils/app_logger.dart';

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  Future<void> saveSession(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.prefUserId, user.id);
    await prefs.setString(AppConstants.prefUserName, user.name);
    await prefs.setString(AppConstants.prefUserRole, user.role);
    if (user.role == 'member') {
      await prefs.setBool(AppConstants.prefOnboardingDone, true);
      if (user.assignedTrainerId != null) {
        await prefs.setString(
            AppConstants.prefAssignedTrainerId, user.assignedTrainerId!);
      }
    } else {
      await prefs.setBool(AppConstants.prefIsLoggedIn, true);
    }
    AppLogger.auth('Session saved for ${user.name} (${user.role})');
  }

  Future<String?> getSavedUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.prefUserId);
  }

  Future<bool> isOnboardingDone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(AppConstants.prefOnboardingDone) ?? false;
  }

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(AppConstants.prefIsLoggedIn) ?? false;
  }

  Future<String?> getAssignedTrainerId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.prefAssignedTrainerId);
  }

  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    AppLogger.auth('Session cleared');
  }
}
