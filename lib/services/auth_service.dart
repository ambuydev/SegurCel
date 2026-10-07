import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  FirebaseAuth? get _auth {
    try {
      return FirebaseAuth.instance;
    } catch (_) {
      return null;
    }
  }

  User? get currentUser {
    try {
      return _auth?.currentUser;
    } catch (_) {
      return null;
    }
  }

  Stream<User?> get authStateChanges {
    try {
      return _auth?.authStateChanges() ?? const Stream.empty();
    } catch (_) {
      return const Stream.empty();
    }
  }

  /// Configura la persistencia de sesión temporal (SESSION) en Web para borrar rastros al cerrar la pestaña.
  Future<void> _configureWebPersistence() async {
    if (kIsWeb && _auth != null) {
      try {
        await _auth!.setPersistence(Persistence.SESSION);
      } catch (_) {}
    }
  }

  /// Registra un nuevo usuario en Firebase Auth y crea su documento estándar en Firestore.
  Future<UserCredential> registerWithEmail(String email, String password) async {
    final auth = _auth;
    if (auth == null) throw Exception('Firebase no está disponible.');
    try {
      await _configureWebPersistence();
      final userCred = await auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      final user = userCred.user;
      if (user != null) {
        try {
          await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
            'uid': user.uid,
            'email': user.email ?? email.trim(),
            'isPremium': false,
            'subscriptionType': 'free',
            'selfDestructedAt': null,
            'gracePeriodExpiresAt': null,
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        } catch (_) {}
      }

      return userCred;
    } on FirebaseAuthException catch (e) {
      throw Exception(_parseAuthError(e.code));
    } catch (e) {
      throw Exception('Error al registrar usuario: $e');
    }
  }

  /// Inicia sesión con correo y contraseña.
  Future<UserCredential> loginWithEmail(String email, String password) async {
    final auth = _auth;
    if (auth == null) throw Exception('Firebase no está disponible.');
    try {
      await _configureWebPersistence();
      return await auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
    } on FirebaseAuthException catch (e) {
      throw Exception(_parseAuthError(e.code));
    } catch (e) {
      throw Exception('Error al iniciar sesión: $e');
    }
  }

  /// Cambia la contraseña de la cuenta Firebase del usuario.
  Future<void> changeAccountPassword(String currentPassword, String newPassword) async {
    final user = currentUser;
    if (user == null || user.email == null) {
      throw Exception('No hay una sesión de usuario activa.');
    }

    try {
      final cred = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword.trim(),
      );
      await user.reauthenticateWithCredential(cred);
      await user.updatePassword(newPassword.trim());
    } on FirebaseAuthException catch (e) {
      throw Exception(_parseAuthError(e.code));
    } catch (e) {
      throw Exception('Error al actualizar la contraseña: $e');
    }
  }

  /// Re-autentica y elimina permanentemente la cuenta de usuario de Firebase Auth.
  Future<void> deleteAccount(String password) async {
    final user = currentUser;
    if (user == null || user.email == null) {
      throw Exception('No hay una sesión de usuario activa.');
    }

    try {
      final cred = EmailAuthProvider.credential(
        email: user.email!,
        password: password.trim(),
      );
      await user.reauthenticateWithCredential(cred);
      await user.delete();
    } on FirebaseAuthException catch (e) {
      throw Exception(_parseAuthError(e.code));
    } catch (e) {
      throw Exception('Error al eliminar la cuenta: $e');
    }
  }

  /// Envía correo para restablecer la contraseña de la cuenta Firebase.
  Future<void> sendPasswordReset(String email) async {
    final auth = _auth;
    if (auth == null) throw Exception('Firebase no está disponible.');
    try {
      await auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw Exception(_parseAuthError(e.code));
    } catch (e) {
      throw Exception('Error al enviar correo de recuperación: $e');
    }
  }

  /// Cierra la sesión activa.
  Future<void> signOut() async {
    try {
      await _auth?.signOut();
    } catch (_) {}
  }

  String _parseAuthError(String errorCode) {
    switch (errorCode) {
      case 'user-not-found':
        return 'No existe ningún usuario registrado con este correo.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'La contraseña actual ingresada es incorrecta.';
      case 'email-already-in-use':
        return 'Este correo electrónico ya está registrado.';
      case 'invalid-email':
        return 'El formato del correo electrónico es inválido.';
      case 'weak-password':
        return 'La nueva contraseña es demasiado débil (mínimo 6 caracteres).';
      case 'network-request-failed':
        return 'Error de conexión. Revisa tu acceso a internet.';
      default:
        return 'Error de autenticación ($errorCode).';
    }
  }
}
