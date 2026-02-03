import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/program_model.dart';
import '../models/submission_model.dart';
import '../models/user_model.dart';

class FirestoreService extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --- Program Methods ---

  // Add new program
  Future<void> createProgram(ProgramModel program) async {
    try {
      // Use set instead of add to specify ID if needed, 
      // but usually we generate ID first or let firestore do it. 
      // Here assuming program.id is already generated or we use a new doc ref.
      DocumentReference ref = _db.collection('programs').doc(program.id.isEmpty ? null : program.id);
      // If id was empty, ref.id is the new one.
      // But we passed id in model, so we should probably ensure consistency.
      // Best practice: generated ID from caller or let Firestore generate.
      
      await ref.set(program.toMap());
    } catch (e) {
      debugPrint("Error creating program: $e");
      rethrow;
    }
  }

  // Stream of all programs
  Stream<List<ProgramModel>> getProgramsStream() {
    return _db.collection('programs')
        .orderBy('startDate', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ProgramModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Toggle active status
  Future<void> toggleProgramStatus(String programId, bool isActive) async {
    await _db.collection('programs').doc(programId).update({'isActive': isActive});
  }

  // Delete program
  Future<void> deleteProgram(String programId) async {
    try {
      await _db.collection('programs').doc(programId).delete();
    } catch (e) {
      debugPrint("Error deleting program: $e");
      rethrow;
    }
  }

  // --- Submission Methods ---

  // Submit entry
  Future<void> submitEntry(SubmissionModel submission) async {
    try {
      await _db.collection('submissions').doc(submission.id).set(submission.toMap());
    } catch (e) {
      debugPrint("Error submitting entry: $e");
      rethrow;
    }
  }

  // Stream of submissions for a program
  Stream<List<SubmissionModel>> getSubmissionsForProgram(String programId) {
    return _db.collection('submissions')
        .where('programId', isEqualTo: programId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => SubmissionModel.fromMap(doc.data(), doc.id))
            .toList());
  }
  
  // Get total stats (Example: Sum of "amount" fields)
  // This is complex because "amount" key is dynamic.
  // We'll handle aggregation on client side for now as requested in admins dashboard requirements.

  // --- User Management Methods ---

  // Stream of all users
  Stream<List<UserModel>> getUsersStream() {
    return _db.collection('users')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => UserModel.fromMap(doc.data()))
            .toList());
  }

  // Create User Profile (Used when Admin creates a new user)
  Future<void> createUserProfile(UserModel user) async {
    try {
      await _db.collection('users').doc(user.uid).set(user.toMap());
    } catch (e) {
      debugPrint("Error creating user profile: $e");
      rethrow;
    }
  }

  // Update existing user
  Future<void> updateUser(UserModel user) async {
    try {
      await _db.collection('users').doc(user.uid).update(user.toMap());
    } catch (e) {
      debugPrint("Error updating user: $e");
      rethrow;
    }
  }

  // Delete user
  Future<void> deleteUser(String uid) async {
    try {
      await _db.collection('users').doc(uid).delete();
    } catch (e) {
      debugPrint("Error deleting user: $e");
      rethrow;
    }
  }

  // Get specific user by UID
  Future<UserModel?> getUser(String uid) async {
    try {
      DocumentSnapshot doc = await _db.collection('users').doc(uid).get();
      if (doc.exists) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      debugPrint("Error fetching user $uid: $e");
      return null;
    }
  }
}
