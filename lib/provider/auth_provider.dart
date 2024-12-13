// ignore_for_file: unused_local_variable, non_constant_identifier_names, no_leading_underscores_for_local_identifiers, avoid_print

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

final _fireAuth = FirebaseAuth.instance;

class AuthProvider extends ChangeNotifier {
  final form = GlobalKey<FormState>();

  var islogin = true;
  var enteredEmail = '';
  var enteredPassword = '';

  void submit() async {
    final _isvalid = form.currentState!.validate();

    if (!_isvalid) {
      return;
    }

    form.currentState!.save();

    try {
      if (islogin) {
        final UserCredential = await _fireAuth.signInWithEmailAndPassword(
            email: enteredEmail, password: enteredPassword);
      } else {
        final UserCredential = await _fireAuth.createUserWithEmailAndPassword(
            email: enteredEmail, password: enteredPassword);
      }
    } catch (e) {
      if (e is FirebaseAuthException) {
        if (e.code == 'email-already-in-use') {
          print("email already in use");
        }
      }
    }

    notifyListeners();
  }
}
