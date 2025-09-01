import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../delivery.dart';

class DeliverySignup extends StatefulWidget {
  @override
  _DeliverySignupState createState() => _DeliverySignupState();
}

class _DeliverySignupState extends State<DeliverySignup> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Color?> _color1;
  late Animation<Color?> _color2;
  bool _isLoading = false; // Added for loading state

  final List<List<Color>> gradientColors = [
    [Colors.deepPurple, Colors.pink],
    [Colors.blueAccent, Colors.teal],
    [Colors.deepOrange, Colors.amber],
    [Colors.indigo, Colors.cyan],
  ];

  int index = 0;

  final _formKey = GlobalKey<FormState>();

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1000), // Adjusted for faster loading animation
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          setState(() {
            index = (index + 1) % gradientColors.length;
          });
          _startAnimation();
        }
      });

    _startAnimation();
  }

  void _startAnimation() {
    final nextIndex = (index + 1) % gradientColors.length;

    _color1 = ColorTween(
      begin: gradientColors[index][0],
      end: gradientColors[nextIndex][0],
    ).animate(_controller);

    _color2 = ColorTween(
      begin: gradientColors[index][1],
      end: gradientColors[nextIndex][1],
    ).animate(_controller);

    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  void _showStyledSnackBar(BuildContext context, String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.poppins(color: Colors.white, fontSize: 14),
        ),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        duration: Duration(seconds: 3),
      ),
    );
  }

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your full name';
    }
    if (value.trim().length < 3) {
      return 'Name must be at least 3 characters';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your email';
    }
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Please enter a valid email';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter password';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != passwordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) {
        return Scaffold(
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _color1.value ?? Colors.purple,
                  _color2.value ?? Colors.pink
                ],
                begin: Alignment.bottomLeft,
                end: Alignment.topRight,
              ),
            ),
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Container(
                  padding: const EdgeInsets.all(24.0),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.92),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 12,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircleAvatar(
                          radius: 32,
                          backgroundColor: Colors.teal.shade100,
                          child: Icon(
                            Icons.delivery_dining,
                            color: Colors.deepPurple,
                            size: 32,
                          ),
                        ),
                        SizedBox(height: 16),
                        Text(
                          "Delivery Boy Signup",
                          style: GoogleFonts.poppins(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          "Join as a delivery partner",
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.black54,
                          ),
                        ),
                        SizedBox(height: 24),

                        TextFormField(
                          controller: nameController,
                          validator: _validateName,
                          decoration: InputDecoration(
                            labelText: "Full Name",
                            prefixIcon: Icon(Icons.person),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        SizedBox(height: 16),

                        TextFormField(
                          controller: emailController,
                          keyboardType: TextInputType.emailAddress,
                          validator: _validateEmail,
                          decoration: InputDecoration(
                            labelText: "Email Address",
                            prefixIcon: Icon(Icons.email),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        SizedBox(height: 16),

                        TextFormField(
                          controller: passwordController,
                          obscureText: !_isPasswordVisible,
                          validator: _validatePassword,
                          decoration: InputDecoration(
                            labelText: "Password",
                            prefixIcon: Icon(Icons.lock),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _isPasswordVisible
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                              ),
                              onPressed: () {
                                setState(() {
                                  _isPasswordVisible = !_isPasswordVisible;
                                });
                              },
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        SizedBox(height: 16),

                        TextFormField(
                          controller: confirmPasswordController,
                          obscureText: !_isConfirmPasswordVisible,
                          validator: _validateConfirmPassword,
                          decoration: InputDecoration(
                            labelText: "Confirm Password",
                            prefixIcon: Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _isConfirmPasswordVisible
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                              ),
                              onPressed: () {
                                setState(() {
                                  _isConfirmPasswordVisible =
                                      !_isConfirmPasswordVisible;
                                });
                              },
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        SizedBox(height: 24),

                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: _isLoading
                                    ? [Colors.deepPurple.shade700, Colors.pink.shade700]
                                    : [Colors.deepPurple, Colors.pinkAccent],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.deepPurple.withOpacity(_isLoading ? 0.3 : 0.5),
                                  blurRadius: _isLoading ? 12 : 8,
                                  spreadRadius: _isLoading ? 2 : 0,
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: _isLoading
                                    ? null
                                    : () async {
                                        if (_formKey.currentState!.validate()) {
                                          setState(() {
                                            _isLoading = true;
                                          });
                                          try {
                                            final credential = await FirebaseAuth.instance
                                                .createUserWithEmailAndPassword(
                                              email: emailController.text.trim(),
                                              password: passwordController.text.trim(),
                                            );

                                            await credential.user
                                                ?.updateDisplayName(nameController.text.trim());

                                            _showStyledSnackBar(context, 'Sign up successful!');

                                            Navigator.pushReplacement(
                                              context,
                                              MaterialPageRoute(builder: (_) => DashboardScreen()),
                                            );
                                          } on FirebaseAuthException catch (e) {
                                            String message = 'Signup failed';
                                            if (e.code == 'email-already-in-use') {
                                              message = 'Email already in use';
                                            } else if (e.code == 'invalid-email') {
                                              message = 'Invalid email';
                                            } else if (e.code == 'weak-password') {
                                              message = 'Weak password';
                                            } else if (e.code == 'operation-not-allowed') {
                                              message = 'Email/password accounts are not enabled';
                                            }

                                            _showStyledSnackBar(context, message, isError: true);
                                          } catch (e) {
                                            _showStyledSnackBar(context, 'Something went wrong: $e',
                                                isError: true);
                                          } finally {
                                            setState(() {
                                              _isLoading = false;
                                            });
                                          }
                                        }
                                      },
                                child: Center(
                                  child: AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 300),
                                    transitionBuilder: (child, animation) => FadeTransition(
                                      opacity: animation,
                                      child: ScaleTransition(
                                        scale: animation.drive(Tween(begin: 0.8, end: 1.0)),
                                        child: child,
                                      ),
                                    ),
                                    child: _isLoading
                                        ? Row(
                                            key: const ValueKey("loading"),
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              SizedBox(
                                                width: 20,
                                                height: 20,
                                                child: AnimatedBuilder(
                                                  animation: _controller,
                                                  builder: (context, child) {
                                                    return Transform.rotate(
                                                      angle: _controller.value * 2 * 3.14159,
                                                      child: Icon(
                                                        Icons.autorenew,
                                                        size: 20,
                                                        color: Colors.white,
                                                      ),
                                                    );
                                                  },
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              ShaderMask(
                                                shaderCallback: (bounds) {
                                                  return LinearGradient(
                                                    colors: [Colors.white, Colors.white.withOpacity(0.5)],
                                                    stops: [0.0, _controller.value],
                                                    tileMode: TileMode.mirror,
                                                  ).createShader(bounds);
                                                },
                                                child: Text(
                                                  "Signing Up...",
                                                  style: GoogleFonts.poppins(
                                                    fontSize: 16,
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          )
                                        : Row(
                                            key: const ValueKey("signUp"),
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.person_add,
                                                size: 20,
                                                color: Colors.white,
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                "Sign Up",
                                                style: GoogleFonts.poppins(
                                                  fontSize: 18,
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 16),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Already have an account? ",
                              style: GoogleFonts.poppins(fontSize: 13),
                            ),
                            GestureDetector(
                              onTap: () {
                                Navigator.pop(context);
                              },
                              child: Text(
                                "Sign in",
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  color: Colors.deepPurple,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}