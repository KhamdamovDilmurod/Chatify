import 'dart:io';

import 'package:family_chatify/services/snackbar_service.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:provider/provider.dart';

//Services
import '../services/media_service.dart';
import '../services/database_service.dart';
import '../services/cloud_storage_service.dart';
import '../services/navigation_service.dart';

//Widgets
import '../widgets/custom_input_fields.dart';
import '../widgets/rounded_button.dart';

//Providers
import '../providers/authentication_provider.dart';

class RegisterPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _RegisterPageState();
  }
}

class _RegisterPageState extends State<RegisterPage> {
  late double _deviceHeight;
  late double _deviceWidth;

  late AuthenticationProvider _auth;
  late DatabaseService _db;
  late CloudStorageService _cloudStorage;
  late NavigationService _navigation;

  TextEditingController _emailController = TextEditingController();
  TextEditingController _nameController = TextEditingController();
  TextEditingController _passwordController = TextEditingController();
  String? _email;
  String? _password;
  String? _name;
  String? _imgUrl;
  File? _profileImage;
  bool _isGoogleSignIn = false;

  final _registerFormKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    // Initialize the auth provider reference
    _auth = Provider.of<AuthenticationProvider>(context, listen: false);
    // Check for Google sign-in data immediately
    _checkAndUpdateGoogleData();
  }

  void _checkAndUpdateGoogleData() {
    if (_auth.googleEmail != null && _email == null) {
      setState(() {
        _email = _auth.googleEmail;
        _name = _auth.googleDisplayName ?? '';
        _isGoogleSignIn = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    _auth = Provider.of<AuthenticationProvider>(context);
    _db = GetIt.instance.get<DatabaseService>();
    _cloudStorage = GetIt.instance.get<CloudStorageService>();
    _navigation = GetIt.instance.get<NavigationService>();
    _deviceHeight = MediaQuery.of(context).size.height;
    _deviceWidth = MediaQuery.of(context).size.width;

    return _buildUI();
  }

  Widget _buildUI() {
    return Scaffold(
      body: SingleChildScrollView(
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: _deviceWidth * 0.03,
            vertical: _deviceHeight * 0.02,
          ),
          height: _deviceHeight * 0.98,
          width: _deviceWidth * 0.97,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _profileImageField(),
              SizedBox(
                height: _deviceHeight * 0.05,
              ),
              _registerForm(),
              SizedBox(
                height: _deviceHeight * 0.05,
              ),
              _registerButton(),
              SizedBox(
                height: _deviceHeight * 0.02,
              ),
              if (!_isGoogleSignIn) _googleSignInButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _profileImageField() {
    return Align(
      alignment: Alignment.center,
      child: GestureDetector(
        onTap: () async {
          File? imageFile = await MediaService.instance.getImageFromLibrary();
          setState(() {
            _profileImage = imageFile;
          });
        },
        child: Container(
          height: _deviceHeight * 0.10,
          width: _deviceHeight * 0.10,
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(500),
            image: DecorationImage(
              fit: BoxFit.cover,
              image: _profileImage != null
                  ? FileImage(_profileImage!)
                  : (_auth.googlePhotoUrl != null && _isGoogleSignIn
                      ? NetworkImage(_auth.googlePhotoUrl!) as ImageProvider
                      : const NetworkImage(
                              "https://cdn0.iconfinder.com/data/icons/occupation-002/64/programmer-programming-occupation-avatar-512.png")
                          as ImageProvider),
            ),
          ),
        ),
      ),
    );
  }

  Widget _registerForm() {
    return Container(
      height: _deviceHeight * 0.35,
      child: Form(
        key: _registerFormKey,
        child: Column(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            TextFormField(
              controller: _nameController,
              cursorColor: Colors.white,
              style: TextStyle(color: Colors.white),
              onSaved: (value) {
                setState(() {
                  _name = value;
                });
              },
              validator: (value) {
                if (value == null || value.length < 2) {
                  return 'Name must be at least 2 characters';
                }
                return null;
              },
              decoration: InputDecoration(
                fillColor: Color.fromRGBO(30, 29, 37, 1.0),
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                  borderSide: BorderSide.none,
                ),
                hintText: "Name",
                hintStyle: TextStyle(color: Colors.white54),
              ),
            ),
            TextFormField(
              controller: _emailController,
              cursorColor: Colors.white,
              style: TextStyle(color: Colors.white),
              enabled: !_isGoogleSignIn,
              onSaved: (value) {
                setState(() {
                  _email = value;
                });
              },
              validator: (value) {
                if (value == null ||
                    !RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+")
                        .hasMatch(value)) {
                  return 'Please enter a valid email';
                }
                return null;
              },
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                fillColor: Color.fromRGBO(30, 29, 37, 1.0),
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                  borderSide: BorderSide.none,
                ),
                hintText: "Email",
                hintStyle: TextStyle(color: Colors.white54),
              ),
            ),
            TextFormField(
              controller: _passwordController,
              cursorColor: Colors.white,
              style: TextStyle(color: Colors.white),
              onSaved: (value) {
                setState(() {
                  _password = value;
                });
              },
              validator: (value) {
                if (value == null || value.length < 8) {
                  return 'Password must be at least 8 characters';
                }
                return null;
              },
              obscureText: true,
              decoration: InputDecoration(
                fillColor: Color.fromRGBO(30, 29, 37, 1.0),
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                  borderSide: BorderSide.none,
                ),
                hintText: "Password",
                hintStyle: TextStyle(color: Colors.white54),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _registerButton() {
    return Consumer<AuthenticationProvider>(
        builder: (context, provider, child) {
      return provider.isLoading
          ? CircularProgressIndicator()
          : RoundedButton(
              name: "Register",
              height: _deviceHeight * 0.065,
              width: _deviceWidth * 0.65,
              onPressed: () async {
                if (_registerFormKey.currentState!.validate()) {
                  if (_profileImage == null && !_isGoogleSignIn) {
                    SnackBarService().showSnackBarError(
                      'Please select profile image',
                    );
                  } else {
                    _registerFormKey.currentState!.save();

                    String? uid;
                    if (_isGoogleSignIn) {
                      // Complete Google registration with password
                      uid =
                          await _auth.completeGoogleSignUp(_password!, _name!);
                    } else {
                      // Normal email/password registration
                      uid = await _auth.registerUserUsingEmailAndPassword(
                          _email!, _password!);
                    }

                    if (uid != null) {
                      String imageURL;
                      if (_profileImage != null) {
                        imageURL = (await _cloudStorage.saveUserImageToStorage(
                            uid, _profileImage!))!;
                      } else {
                        // Use Google profile photo URL
                        imageURL = _auth.googlePhotoUrl ??
                            "https://cdn0.iconfinder.com/data/icons/occupation-002/64/programmer-programming-occupation-avatar-512.png";
                      }

                      await _db.createUser(uid, _email!, _name!, imageURL);

                      if (!_isGoogleSignIn) {
                        await _auth.logout();
                        await _auth.loginUsingEmailAndPassword(
                            _email!, _password!);
                      }
                    } else {
                      SnackBarService().showSnackBarError(
                        'Registration failed. Please try again.',
                      );
                    }
                  }
                }
              },
            );
    });
  }

  Widget _googleSignInButton() {
    return RoundedButton(
      name: "Sign In With Google",
      height: _deviceHeight * 0.065,
      width: _deviceWidth * 0.65,
      onPressed: _handleGoogleSignIn,
    );
  }

  void _handleGoogleSignIn() async {
    try {
      bool success = await _auth.preAuthWithGoogle();
      if (success) {
        setState(() {
          _isGoogleSignIn = true;
          _email = _auth.googleEmail;
          _name = _auth.googleDisplayName;
          _emailController.text = _email ?? "";
          _nameController.text = _name ?? "";
        });
      }
    } catch (e) {
      SnackBarService().showSnackBarError(
        'Failed to sign in with Google. Please try again.',
      );
    }
  }
}
