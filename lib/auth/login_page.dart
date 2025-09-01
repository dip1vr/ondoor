import 'package:flutter/material.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:ondoor/delivery.dart';

import 'signup_page.dart';

class DeliveryLoginPage extends StatefulWidget {
  const DeliveryLoginPage({super.key});

  @override
  _DeliveryLoginPageState createState() => _DeliveryLoginPageState();
}

class _DeliveryLoginPageState extends State<DeliveryLoginPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late AnimationController _controller;
  late Animation<Color?> _color1;
  late Animation<Color?> _color2;

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool rememberMe = false;
  bool _obscureText = true;
  bool _isLoading = false; // <-- Loading state

  final List<List<Color>> gradientColors = [
    [Colors.teal, Colors.green],
    [Colors.blue, Colors.cyan],
    [Colors.deepOrange, Colors.amber],
    [Colors.purple, Colors.indigo],
  ];

  int index = 0;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 5))
          ..addStatusListener((status) {
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
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _loginUser() async {
  if (_formKey.currentState!.validate()) {
    setState(() => _isLoading = true);

    try {
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      // Login success
      Get.snackbar(
        "Login Successful",
        "Welcome back, ${credential.user?.email ?? 'Delivery Boy'}!",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => DashboardScreen()),
      );
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'user-not-found':
          message = 'User not registered. Please sign up first.';
          break;
        case 'wrong-password':
          message = 'Password is incorrect.';
          break;
        default:
          message = e.message ?? 'Login failed. Please try again.';
      }

      Get.snackbar(
        "Login Failed",
        message,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }
}


  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) {
        return Scaffold(
          body: Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _color1.value ?? Colors.teal,
                      _color2.value ?? Colors.green,
                    ],
                    begin: Alignment.bottomLeft,
                    end: Alignment.topRight,
                  ),
                ),
                child: Form(
                  key: _formKey,
                  child: Center(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.symmetric(
                        horizontal: screenWidth * 0.05,
                        vertical: screenHeight * 0.02,
                      ),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: screenWidth * 0.9,
                          maxHeight: screenHeight * 0.9,
                        ),
                        child: Container(
                          padding: EdgeInsets.all(screenWidth * 0.06),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 12,
                                offset: Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircleAvatar(
                                radius: screenWidth * 0.08,
                                backgroundColor:
                                    Colors.teal.shade100.withOpacity(0.5),
                                child: Icon(
                                  FeatherIcons.truck,
                                  color: Colors.teal.withOpacity(0.6),
                                  size: screenWidth * 0.08,
                                ),
                              ),
                              SizedBox(height: screenHeight * 0.02),
                              Text(
                                "Delivery Boy Login",
                                style: GoogleFonts.poppins(
                                  fontSize: screenWidth * 0.06,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: screenHeight * 0.01),
                              Text(
                                "Sign in to your delivery dashboard",
                                style: GoogleFonts.poppins(
                                  fontSize: screenWidth * 0.035,
                                  color: Colors.black54,
                                ),
                                textAlign: TextAlign.center,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 2,
                              ),
                              SizedBox(height: screenHeight * 0.03),
                              TextFormField(
                                controller: emailController,
                                keyboardType: TextInputType.emailAddress,
                                decoration: InputDecoration(
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: const BorderSide(
                                      color: Colors.teal,
                                      width: 2,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  labelText: "Email Address",
                                  prefixIcon: const Icon(FeatherIcons.mail),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Email is required';
                                  }
                                  final emailRegex = RegExp(
                                    r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                                  );
                                  if (!emailRegex.hasMatch(value)) {
                                    return 'Enter a valid email address';
                                  }
                                  return null;
                                },
                              ),
                              SizedBox(height: screenHeight * 0.02),
                              TextFormField(
                                controller: passwordController,
                                obscureText: _obscureText,
                                decoration: InputDecoration(
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: const BorderSide(
                                      color: Colors.teal,
                                      width: 2,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  labelText: "Password",
                                  prefixIcon: const Icon(FeatherIcons.lock),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscureText
                                          ? Icons.visibility_off
                                          : Icons.visibility,
                                      color: Colors.grey,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _obscureText = !_obscureText;
                                      });
                                    },
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Password is required';
                                  }
                                  if (value.length < 6) {
                                    return 'Password must be at least 6 characters';
                                  }
                                  return null;
                                },
                              ),
                              SizedBox(height: screenHeight * 0.015),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Flexible(
                                    child: Row(
                                      children: [
                                        Checkbox(
                                          checkColor: Colors.white,
                                          activeColor: Colors.teal,
                                          value: rememberMe,
                                          onChanged: (value) {
                                            setState(() => rememberMe = value!);
                                          },
                                        ),
                                        Flexible(
                                          child: Text(
                                            "Remember me",
                                            style: GoogleFonts.poppins(
                                                fontSize: screenWidth * 0.035),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Flexible(
                                    child: TextButton(
                                      onPressed: () async {
                                        if (emailController.text.trim().isEmpty) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                "Enter your email to reset password",
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          );
                                          return;
                                        }
                                        try {
                                          await FirebaseAuth.instance
                                              .sendPasswordResetEmail(
                                            email: emailController.text.trim(),
                                          );
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                "Password reset link sent to your email",
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          );
                                        } catch (e) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                "Error sending reset email",
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          );
                                        }
                                      },
                                      child: Text(
                                        "Forgot password?",
                                        style: GoogleFonts.poppins(
                                          fontSize: screenWidth * 0.035,
                                          color: Colors.black,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: screenHeight * 0.025),
                              SizedBox(
  width: double.infinity,
  height: screenHeight * 0.06,
  child: AnimatedContainer(
    duration: const Duration(milliseconds: 300),
    curve: Curves.easeInOut,
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: _isLoading
            ? [Colors.teal.shade700, Colors.teal.shade900]
            : [Colors.teal, Colors.tealAccent],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Colors.teal.withOpacity(_isLoading ? 0.3 : 0.5),
          blurRadius: _isLoading ? 12 : 8,
          spreadRadius: _isLoading ? 2 : 0,
        ),
      ],
    ),
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: _isLoading ? null : _loginUser,
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
                        width: screenWidth * 0.05,
                        height: screenWidth * 0.05,
                        child: AnimatedBuilder(
                          animation: _controller, // Reuse existing AnimationController
                          builder: (context, child) {
                            return Transform.rotate(
                              angle: _controller.value * 2 * 3.14159,
                              child: Icon(
                                FeatherIcons.loader,
                                size: screenWidth * 0.05,
                                color: Colors.white,
                              ),
                            );
                          },
                        ),
                      ),
                      SizedBox(width: screenWidth * 0.02),
                      ShaderMask(
                        shaderCallback: (bounds) {
                          return LinearGradient(
                            colors: [Colors.white, Colors.white.withOpacity(0.5)],
                            stops: [0.0, _controller.value],
                            tileMode: TileMode.mirror,
                          ).createShader(bounds);
                        },
                        child: Text(
                          "Signing In...",
                          style: GoogleFonts.poppins(
                            fontSize: screenWidth * 0.04,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  )
                : Row(
                    key: const ValueKey("signIn"),
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        FeatherIcons.logIn,
                        size: screenWidth * 0.045,
                        color: Colors.white,
                      ),
                      SizedBox(width: screenWidth * 0.02),
                      Text(
                        "Sign In",
                        style: GoogleFonts.poppins(
                          fontSize: screenWidth * 0.045,
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
                              SizedBox(height: screenHeight * 0.02),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    "Don't have an account? ",
                                    style: GoogleFonts.poppins(
                                        fontSize: screenWidth * 0.035),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  SizedBox(width: 5),
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => DeliverySignup(),
                                        ),
                                      );
                                    },
                                    child: Text(
                                      "Sign up",
                                      style: GoogleFonts.poppins(
                                        fontSize: screenWidth * 0.035,
                                        color: Colors.teal,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      overflow: TextOverflow.ellipsis,
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
              ),
            ],
          ),
        );
      },
    );
  }
}
