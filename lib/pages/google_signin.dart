import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';

class GoogleSignInPage extends StatefulWidget {
  @override
  _GoogleSignInPageState createState() => _GoogleSignInPageState();
}

class _GoogleSignInPageState extends State<GoogleSignInPage> {
  User? user;

  Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return null; // User canceled the sign-in process

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);

      setState(() {
        user = userCredential.user;
      });

      return userCredential.user;
    } catch (e) {
      print("Error during Google Sign-In: $e");
      return null;
    }
  }

  Future<void> signOut() async {
    await GoogleSignIn().signOut();
    await FirebaseAuth.instance.signOut();
    setState(() {
      user = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Google Sign-In"),
        actions: [
          if (user != null)
            IconButton(
              icon: Icon(Icons.logout),
              onPressed: () async {
                await signOut();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Signed out successfully")),
                );
              },
            ),
        ],
      ),
      body: Center(
        child: user == null
            ? ElevatedButton(
                onPressed: () async {
                  final user = await signInWithGoogle();
                  if (user != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Signed in as ${user.displayName}")),
                    );
                  }
                },
                child: Text("Sign in with Google"),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Welcome, ${user!.displayName}!"),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () async {
                      await signOut();
                    },
                    child: Text("Sign Out"),
                  ),
                ],
              ),
      ),
    );
  }
}
