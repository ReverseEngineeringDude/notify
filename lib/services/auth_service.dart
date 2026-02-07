import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;



  User? _firebaseUser;
  UserModel? _currentUser;
  bool _isLoading = false;
  bool _isLoadingProfile = true; // Start true to show splash/loading initially

  UserModel? get currentUser => _currentUser;
  User? get firebaseUser => _firebaseUser;
  bool get isLoading => _isLoading;
  bool get isLoadingProfile => _isLoadingProfile;

  AuthService() {
    _auth.authStateChanges().listen(_onAuthStateChanged);
  }

  Future<void> _onAuthStateChanged(User? firebaseUser) async {
    _firebaseUser = firebaseUser;
    
    if (firebaseUser == null) {
      debugPrint("Auth State Change: User is NULL (Logged out)");
      _currentUser = null;
      _isLoadingProfile = false;
      notifyListeners();
      return;
    }

    _isLoadingProfile = true;
    notifyListeners();

    debugPrint("Auth State Change: User Logged In: ${firebaseUser.uid}. Fetching profile...");
    


    // Fetch user details from Firestore
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(firebaseUser.uid).get();
      if (doc.exists) {
        debugPrint("Firestore Profile Found: ${doc.data()}");
        _currentUser = UserModel.fromMap(doc.data() as Map<String, dynamic>);
      } else {
          debugPrint("Firestore Profile NOT FOUND for ${firebaseUser.uid}");
          _currentUser = null; 
          // Access denied or wait for registration
      }
    } catch (e) {
      debugPrint("Error fetching user data: $e");
      _currentUser = null;
    } finally {
      _isLoadingProfile = false;
      notifyListeners();
    }

  }

  // Login
  Future<String?> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();
    try {
      debugPrint("Attempting login for $email...");
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      debugPrint("Firebase Auth successful for $email");
      return null; // Success
    } on FirebaseAuthException catch (e) {
      debugPrint("FirebaseAuthException: ${e.code} - ${e.message}");
      return "Login Failed: ${e.message} (${e.code})";
    } catch (e) {
      debugPrint("Unknown Login Error: $e");
      return "An unknown error occurred: $e";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Logout
  Future<void> logout() async {
    await _auth.signOut();
  }

  // Helper to create a mock user (Useful for initialization/testing)
  Future<void> createMockUser({required String email, required String password, required UserRole role, String? wardId}) async {
    try {
      debugPrint("Creating mock user: $email");
      UserCredential cred = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      debugPrint("User created in Auth: ${cred.user!.uid}");
      
      UserModel newUser = UserModel(
        uid: cred.user!.uid,
        email: email,
        role: role,
        wardId: wardId,
        name: role == UserRole.superAdmin ? "Super Admin" : "Ward Admin $wardId",
      );
      
      await _firestore.collection('users').doc(cred.user!.uid).set(newUser.toMap());
      debugPrint("User saved to Firestore");
    } on FirebaseAuthException catch (e) {
        debugPrint("Failed to create user: ${e.code} - ${e.message}");
        
        if (e.code == 'email-already-in-use') {
            debugPrint("User exists, trying to recover/update Firestore profile...");
            try {
              // Sign in to get the UID
              UserCredential cred = await _auth.signInWithEmailAndPassword(email: email, password: password);
              debugPrint("Signed in as existing user: ${cred.user!.uid}");

              UserModel newUser = UserModel(
                uid: cred.user!.uid,
                email: email,
                role: role,
                wardId: wardId,
                name: role == UserRole.superAdmin ? "Super Admin" : "Ward Admin $wardId",
              );
              
              await _firestore.collection('users').doc(cred.user!.uid).set(newUser.toMap());
              debugPrint("Existing user profile updated/restored in Firestore");
              
            } catch (innerError) {
              debugPrint("Failed to update existing user profile: $innerError");
            }
        }
    } catch (e) {
      debugPrint("Error creating mock user: $e");
    }
  }

  // Initialize User Profile (Self-Repair)
  Future<void> initializeUserProfile() async {
    if (_firebaseUser == null) return;
    
    _isLoadingProfile = true;
    notifyListeners();
    
    try {
      debugPrint("Initializing profile for ${_firebaseUser!.uid}...");
      
      UserModel newUser = UserModel(
        uid: _firebaseUser!.uid,
        email: _firebaseUser!.email ?? "unknown@email.com",
        role: UserRole.superAdmin, // Defaulting to Super Admin for fix
        name: "Super Admin (Recovered)",
      );
      
      await _firestore.collection('users').doc(_firebaseUser!.uid).set(newUser.toMap());
      debugPrint("Profile initialized in Firestore.");
      
      // Force refresh
      await _onAuthStateChanged(_firebaseUser);
    } catch (e) {
      debugPrint("Error initializing profile: $e");
      _isLoadingProfile = false;
      notifyListeners();
    }
    }

  // Helper to create a NEW user (Called by Admin)
  // NOTE: This will sign out the current admin to create the new user, then we expect the UI to handle re-login or stay logged out.
  // In a real app we'd use a Cloud Function.
  Future<void> createNewUser({required String email, required String password, required UserRole role, String? wardId}) async {
    try {
      // 1. Create Auth User
      UserCredential cred = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      
      // 2. Create Firestore Profile
      UserModel newUser = UserModel(
        uid: cred.user!.uid,
        email: email,
        role: role,
        wardId: wardId,
        name: role == UserRole.superAdmin ? "Super Admin" : "Ward Admin $wardId",
      );
      
      await _firestore.collection('users').doc(cred.user!.uid).set(newUser.toMap());
      debugPrint("New user created successfully: $email");
      
      // 3. Sign Out (because we are now logged in as the new user)
      await _auth.signOut();
      
    } catch (e) {
      debugPrint("Error creating new user: $e");
      rethrow;
    }
  }

  // Password Reset (Safest way for Admin to help user)
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      debugPrint("Password reset email sent to $email");
    } catch (e) {
       debugPrint("Error sending password reset: $e");
       rethrow;
    }
  }
}
