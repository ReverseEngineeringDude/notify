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

  // Delete program and associated submissions
  Future<void> deleteProgram(String programId) async {
    try {
      // 1. Get all submissions for this program
      final submissionsSnapshot = await _db.collection('submissions')
          .where('programId', isEqualTo: programId)
          .get();

      // 2. Batch delete submissions
      WriteBatch batch = _db.batch();
      int operationCount = 0;

      for (var doc in submissionsSnapshot.docs) {
        batch.delete(doc.reference);
        operationCount++;

        // Commit batch if it reaches the limit (Firestores limit is 500)
        if (operationCount >= 450) {
          await batch.commit();
          batch = _db.batch();
          operationCount = 0;
        }
      }

      // 3. Delete the program document
      // We include it in the final batch for efficiency/atomicity
      DocumentReference programRef = _db.collection('programs').doc(programId);
      batch.delete(programRef);

      // Commit the final batch
      await batch.commit();
      
    } catch (e) {
      debugPrint("Error deleting program and submissions: $e");
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
  Stream<List<SubmissionModel>> getSubmissionsForProgram(String programId, {int limit = 50}) {
    return _db.collection('submissions')
        .where('programId', isEqualTo: programId)
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => SubmissionModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  Future<List<SubmissionModel>> getSubmissionsForProgramFuture(String programId) async {
    final snapshot = await _db.collection('submissions')
        .where('programId', isEqualTo: programId)
        .orderBy('timestamp', descending: true)
        .get();
    return snapshot.docs
        .map((doc) => SubmissionModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  // Delete submission
  Future<void> deleteSubmission(String submissionId) async {
    try {
      await _db.collection('submissions').doc(submissionId).delete();
    } catch (e) {
      debugPrint("Error deleting submission: $e");
      rethrow;
    }
  }

  Future<List<UserModel>> getUsersFuture() async {
    final snapshot = await _db.collection('users').get();
    return snapshot.docs.map((doc) => UserModel.fromMap(doc.data())).toList();
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
