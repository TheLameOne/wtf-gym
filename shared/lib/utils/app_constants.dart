class AppConstants {
  AppConstants._();

  // Seeded user IDs
  static const String memberDkId = 'member_dk';
  static const String trainerAaravId = 'trainer_aarav';

  // SharedPrefs keys
  static const String prefUserId = 'user_id';
  static const String prefUserName = 'user_name';
  static const String prefUserRole = 'user_role';
  static const String prefOnboardingDone = 'onboarding_done';
  static const String prefIsLoggedIn = 'is_logged_in';
  static const String prefAssignedTrainerId = 'assigned_trainer_id';

  // 100ms
  static const String hmsTrainerRole = 'host';
  static const String hmsMemberRole = 'guest';
  static const String hmsTrainerTemplateId = '6a1494d14a799ad17a8b5c54';
  static const String hmsMemberTemplateId = '6a1495136a2d2723ac9ef4e3';

  // Token server: 10.0.2.2 is localhost from Android emulator
  static const String tokenServerUrl = 'http://10.0.2.2:3000';

  // Chat
  static const List<String> quickReplies = [
    'Got it 👍',
    'Can we talk at 6?',
    'Share plan?',
  ];

  // Schedule
  static const int scheduleDaysAhead = 3;
  static const int slotDurationMinutes = 30;

  // Firestore collections
  static const String colUsers = 'users';
  static const String colChats = 'chats';
  static const String colMessages = 'messages';
  static const String colCallRequests = 'call_requests';
  static const String colSessionLogs = 'session_logs';
  static const String colRoomMetas = 'room_metas';
  static const String colTyping = 'typing';
}
