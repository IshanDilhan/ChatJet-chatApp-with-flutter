import 'package:chatapp/controlers/user_controler.dart';
import 'package:chatapp/screens/SignInPages/loging_screen.dart';
import 'package:chatapp/screens/main_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:logger/logger.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final UserController _userController = UserController();
  final Logger _logger = Logger();

  String? _username;
  String? _mobileNumber;
  String? _email;
  String? _password;
  String? _bio;
  String? _location;
  final List<String> _interests = [];
  String? _errorMessage;

  Future<void> _signUp(context) async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      try {
        await _userController.signUp(
          username: _username!,
          mobileNumber: _mobileNumber!,
          email: _email!,
          password: _password!,
          bio: _bio ?? '',
          location: _location ?? '',
          interests: _interests,
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
      } catch (error) {
        setState(() {
          _errorMessage = error.toString();
        });
      }
    } else {
      _logger.w("Form validation failed.");
    }
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;

    return Scaffold(
      // ignore: sized_box_for_whitespace
      body: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: SizedBox(
            width: double.infinity,
            height: size.height,
            child: Stack(
              alignment: Alignment.center,
              children: <Widget>[
                Positioned(
                  top: 0,
                  right: 0,
                  child: Image.asset(
                    "assets/images/top1.png",
                    width: size.width,
                  ),
                ),
                Positioned(
                  top: 0,
                  right: 0,
                  child: Image.asset(
                    "assets/images/top2.png",
                    width: size.width,
                  ),
                ),
                Positioned(
                  top: -45,
                  right: -45,
                  child: Image.asset(
                    "assets/1.png",
                    width: size.width * 0.63,
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Image.asset(
                    "assets/images/bottom1.png",
                    width: size.width,
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Image.asset(
                    "assets/images/bottom2.png",
                    width: size.width,
                  ),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Container(
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: Text(
                        "REGISTER",
                        style: GoogleFonts.acme(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue, // Green color
                          fontSize: 42,
                        ),
                        textAlign: TextAlign.left,
                      ),
                    ),
                    SizedBox(height: size.height * 0.03),
                    Container(
                      alignment: Alignment.center,
                      margin: const EdgeInsets.symmetric(horizontal: 40),
                      child: TextFormField(
                        decoration:
                            const InputDecoration(labelText: "UserName"),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your username';
                          }
                          return null;
                        },
                        onSaved: (value) {
                          _username = value;
                        },
                      ),
                    ),
                    SizedBox(height: size.height * 0.03),
                    Container(
                      alignment: Alignment.center,
                      margin: const EdgeInsets.symmetric(horizontal: 40),
                      child: TextFormField(
                        keyboardType: TextInputType.number,
                        decoration:
                            const InputDecoration(labelText: "Mobile Number"),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your mobile number';
                          }
                          return null;
                        },
                        onSaved: (value) {
                          _mobileNumber = value;
                        },
                      ),
                    ),
                    SizedBox(height: size.height * 0.03),
                    Container(
                      alignment: Alignment.center,
                      margin: const EdgeInsets.symmetric(horizontal: 40),
                      child: TextFormField(
                        decoration: const InputDecoration(labelText: "Email"),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your email';
                          }
                          return null;
                        },
                        onSaved: (value) {
                          _email = value;
                        },
                      ),
                    ),
                    SizedBox(height: size.height * 0.03),
                    Container(
                      alignment: Alignment.center,
                      margin: const EdgeInsets.symmetric(horizontal: 40),
                      child: TextFormField(
                        decoration:
                            const InputDecoration(labelText: "Password"),
                        obscureText: true,
                        validator: (value) {
                          if (value == null || value.length < 6) {
                            return 'Password must be at least 6 characters long';
                          }
                          return null;
                        },
                        onSaved: (value) {
                          _password = value;
                        },
                      ),
                    ),
                    if (_errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 40, vertical: 10),
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    SizedBox(height: size.height * 0.05),
                    Container(
                      alignment: Alignment.centerRight,
                      margin: const EdgeInsets.symmetric(
                          horizontal: 40, vertical: 10),
                      child: ElevatedButton(
                        onPressed: () {
                          _signUp(context);
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.all(0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(80.0),
                          ),
                        ),
                        child: Container(
                          alignment: Alignment.center,
                          height: 50.0,
                          width: size.width * 0.5,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(80.0),
                            color: const Color.fromARGB(
                                255, 36, 211, 74), // Green color
                          ),
                          padding: const EdgeInsets.all(0),
                          child: Text(
                            "SIGN UP",
                            textAlign: TextAlign.center,
                            style: GoogleFonts.acme(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                fontSize: 19),
                          ),
                        ),
                      ),
                    ),
                    Container(
                      alignment: Alignment.centerRight,
                      margin: const EdgeInsets.symmetric(
                          horizontal: 50, vertical: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          const Text(
                            "Already Have an Account?  ",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const LoginScreen(),
                                ),
                              );
                            },
                            child: const Text(
                              "Sign In",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2661FA),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
