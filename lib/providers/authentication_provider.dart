import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_it/get_it.dart';

//Services
import '../services/database_service.dart';
import '../services/navigation_service.dart';
import '../services/snackbar_service.dart';

//Models
import '../models/chat_user.dart';

class AuthenticationProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late final NavigationService _navigationService;
  late final DatabaseService _databaseService;
  late final SnackBarService _snackBarService;
  late ChatUser user;

  AuthenticationProvider() {
    _navigationService = GetIt.instance.get<NavigationService>();
    _databaseService = GetIt.instance.get<DatabaseService>();
    _snackBarService = SnackBarService.instance;


    _auth.authStateChanges().listen((_user) async {
      if (_user != null) {
        try {
          print("Logged In: ${_user.uid}");
          // Update last seen time
          _databaseService.updateUserLastSeenTime(_user.uid);
          _databaseService.getUser(_user.uid).then(
                (_snapshot) {
              Map<String, dynamic> _userData =
              _snapshot.data()! as Map<String, dynamic>;
              user = ChatUser.fromJSON(
                {
                  "uid": _user.uid,
                  "name": _userData["name"],
                  "email": _userData["email"],
                  "last_active": _userData["last_active"],
                  "image": _userData["image"],
                },
              );
              _navigationService.removeAndNavigateToRoute('/home');
            },
          );
        } catch (e) {
          print('Error updating last seen time: $e');
          // Optionally show a snackbar or handle the error
          _snackBarService.showSnackBarError('Failed to update user status');
        }
      } else {
        print("Not Authenticated");
        if (_navigationService.getCurrentRoute() != '/login') {
          _navigationService.removeAndNavigateToRoute('/login');
        }
      }
    });
  }

  Future<void> loginUsingEmailAndPassword(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
    } on FirebaseAuthException catch (e) {
      // Detailed error handling
      String errorMessage = 'Login failed';
      // Show error to user
      _snackBarService.showSnackBarError(
        errorMessage,
      );
      // Log the full error for debugging
      print('Firebase Auth Error: ${e.code} - $errorMessage');
    } catch (e) {
      // Catch any other unexpected errors
      _snackBarService.showSnackBarError(
        'An unexpected error occurred',
      );
      print('Unexpected login error: $e');
    }

  }
  Future<String?> registerUserUsingEmailAndPassword(
      String email, String password) async {
    try {
      UserCredential credentials = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
      return credentials.user!.uid;
    } on FirebaseAuthException {
      print("Error registering user.");
    } catch (e) {
      print(e);
    }
    return null;
  }

  // Additional authentication methods can be added here
  Future<void> logout() async {
    await _auth.signOut();
    _navigationService.navigateToRoute('/login');
  }
}