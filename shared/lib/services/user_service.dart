import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../utils/app_constants.dart';
import '../utils/app_logger.dart';

class UserService {
  UserService._();
  static final UserService instance = UserService._();

  final _db = FirebaseFirestore.instance;

  Future<void> saveUser(UserModel user) async {
    await _db
        .collection(AppConstants.colUsers)
        .doc(user.id)
        .set(user.toMap(), SetOptions(merge: true));
    AppLogger.auth('User saved: ${user.name}');
  }

  Future<UserModel?> getUser(String userId) async {
    final doc = await _db.collection(AppConstants.colUsers).doc(userId).get();
    if (!doc.exists) return null;
    return UserModel.fromMap(doc.data()!);
  }

  Stream<UserModel?> userStream(String userId) {
    return _db
        .collection(AppConstants.colUsers)
        .doc(userId)
        .snapshots()
        .map((snap) => snap.exists ? UserModel.fromMap(snap.data()!) : null);
  }

  Future<List<UserModel>> getTrainers() async {
    final snap = await _db
        .collection(AppConstants.colUsers)
        .where('role', isEqualTo: 'trainer')
        .get();
    return snap.docs.map((d) => UserModel.fromMap(d.data())).toList();
  }

  Future<List<UserModel>> getMembersForTrainer(String trainerId) async {
    final snap = await _db
        .collection(AppConstants.colUsers)
        .where('role', isEqualTo: 'member')
        .where('assignedTrainerId', isEqualTo: trainerId)
        .get();
    return snap.docs.map((d) => UserModel.fromMap(d.data())).toList();
  }

  /// Seeds DK and Aarav if they don't already exist.
  Future<void> seedDefaultUsers() async {
    final aarav = UserModel(
      id: AppConstants.trainerAaravId,
      name: 'Aarav',
      email: 'aarav@wtfgym.com',
      role: 'trainer',
    );
    final dk = UserModel(
      id: AppConstants.memberDkId,
      name: 'DK',
      email: 'dk@wtfgym.com',
      role: 'member',
      assignedTrainerId: AppConstants.trainerAaravId,
    );
    await _db
        .collection(AppConstants.colUsers)
        .doc(aarav.id)
        .set(aarav.toMap(), SetOptions(merge: true));
    await _db
        .collection(AppConstants.colUsers)
        .doc(dk.id)
        .set(dk.toMap(), SetOptions(merge: true));
    AppLogger.auth('Default users seeded');
  }
}
