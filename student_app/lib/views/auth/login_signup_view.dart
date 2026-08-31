import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../learning/learning_theme.dart';
import '../../core/api_service.dart';
import 'forgot_password_view.dart';

class LoginSignupView extends StatefulWidget {
  final VoidCallback onAuthenticated;
  const LoginSignupView({super.key, required this.onAuthenticated});

  @override
  State<LoginSignupView> createState() => _LoginSignupViewState();
}

class _LoginSignupViewState extends State<LoginSignupView> {
  bool isSignUp = false;
  bool rememberMe = true;
  bool isLoading = false;
  bool isPasswordVisible = false;

  final emailMobileController = TextEditingController();
  final passwordController = TextEditingController();
  final fullNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSavedPreferences();
  }

  void _loadSavedPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final savedIdentity = prefs.getString('remembered_identity');
    final savedRememberMe = prefs.getBool('remember_me') ?? true;
    setState(() {
      rememberMe = savedRememberMe;
      if (savedIdentity != null && savedIdentity.isNotEmpty && rememberMe) {
        emailMobileController.text = savedIdentity;
      }
    });
  }

  void _savePreferences(String identity) async {
    final prefs = await SharedPreferences.getInstance();
    if (rememberMe) {
      await prefs.setString('remembered_identity', identity);
      await prefs.setBool('remember_me', true);
    } else {
      await prefs.remove('remembered_identity');
      await prefs.setBool('remember_me', false);
    }
  }

  void _handleLogin() async {
    final identity = emailMobileController.text.trim();
    final password = passwordController.text.trim();

    if (identity.isEmpty || password.isEmpty) {
      _showSnackBar('Please fill in Email/Mobile and Password');
      return;
    }

    setState(() => isLoading = true);
    try {
      final res = await ApiService.post('/v1/auth/login', {
        'identity': identity,
        'password': password,
      });
      ApiService.authToken = res['token'];
      _savePreferences(identity);
      widget.onAuthenticated();
    } catch (e) {
      _showSnackBar(e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _handleSignup() async {
    final fullName = fullNameController.text.trim();
    final identity = emailMobileController.text.trim();
    final password = passwordController.text.trim();

    if (fullName.isEmpty || identity.isEmpty || password.isEmpty) {
      _showSnackBar('Please fill in all required fields');
      return;
    }

    setState(() => isLoading = true);
    try {
      final res = await ApiService.post('/v1/auth/signup', {
        'full_name': fullName,
        'email': identity.contains('@') ? identity : '$identity@examverse.com',
        'mobile': identity.contains('@') ? '9876543210' : identity,
        'password': password,
      });
      ApiService.authToken = res['token'];
      _savePreferences(identity);
      widget.onAuthenticated();
    } catch (e) {
      _showSnackBar(e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LearningTheme.scaffoldLightBg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // BRAND HEADER
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: LearningTheme.softPurpleBg,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.school_rounded,
                      size: 40,
                      color: LearningTheme.primaryPurple,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isSignUp ? 'Create Your Account' : 'Welcome Back 👋',
                    style: const TextStyle(
                      color: LearningTheme.textDark,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isSignUp
                        ? 'Join 10,000+ learners achieving their goals'
                        : 'Sign in to continue your learning journey',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: LearningTheme.textMuted,
                      fontSize: 14,
                    ),
                  ),

                  const SizedBox(height: 32),

                  // CARD FORM CONTAINER
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: LearningTheme.cardShadow,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (isSignUp) ...[
                          _buildTextField(
                            controller: fullNameController,
                            label: 'Full Name',
                            hint: 'e.g. Ayesha Sharma',
                            icon: Icons.person_outline_rounded,
                          ),
                          const SizedBox(height: 18),
                        ],

                        _buildTextField(
                          controller: emailMobileController,
                          label: 'Email or Mobile Number',
                          hint: 'e.g. ayesha@example.com',
                          icon: Icons.mail_outline_rounded,
                          keyboardType: TextInputType.emailAddress,
                        ),

                        const SizedBox(height: 18),

                        _buildTextField(
                          controller: passwordController,
                          label: 'Password',
                          hint: '••••••••',
                          icon: Icons.lock_outline_rounded,
                          isPassword: true,
                        ),

                        const SizedBox(height: 14),

                        if (!isSignUp) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              GestureDetector(
                                onTap: () => setState(() => rememberMe = !rememberMe),
                                child: Row(
                                  children: [
                                    SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: Checkbox(
                                        value: rememberMe,
                                        activeColor: LearningTheme.primaryPurple,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                        onChanged: (val) => setState(() => rememberMe = val ?? true),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'Remember me',
                                      style: TextStyle(color: LearningTheme.textMedium, fontSize: 13),
                                    ),
                                  ],
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => const ForgotPasswordView()),
                                  );
                                },
                                child: const Text(
                                  'Forgot Password?',
                                  style: TextStyle(
                                    color: LearningTheme.primaryPurple,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                        ],

                        // SUBMIT BUTTON
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: isLoading ? null : (isSignUp ? _handleSignup : _handleLogin),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: LearningTheme.primaryPurple,
                              foregroundColor: Colors.white,
                              elevation: 4,
                              shadowColor: LearningTheme.primaryPurple.withValues(alpha: 0.4),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(26),
                              ),
                            ),
                            child: isLoading
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                                  )
                                : Text(
                                    isSignUp ? 'Create Account' : 'Log In',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  // TOGGLE LINK
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        isSignUp ? 'Already have an account? ' : 'Don\'t have an account? ',
                        style: const TextStyle(color: LearningTheme.textMedium, fontSize: 14),
                      ),
                      GestureDetector(
                        onTap: () => setState(() => isSignUp = !isSignUp),
                        child: Text(
                          isSignUp ? 'Log In' : 'Sign Up',
                          style: const TextStyle(
                            color: LearningTheme.primaryPurple,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
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
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: LearningTheme.textDark,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          obscureText: isPassword && !isPasswordVisible,
          keyboardType: keyboardType,
          style: const TextStyle(color: LearningTheme.textDark, fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: LearningTheme.textMuted, fontSize: 14),
            prefixIcon: Icon(icon, color: LearningTheme.textMuted, size: 20),
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(
                      isPasswordVisible ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                      color: LearningTheme.textMuted,
                      size: 20,
                    ),
                    onPressed: () => setState(() => isPasswordVisible = !isPasswordVisible),
                  )
                : null,
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: LearningTheme.borderLight),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: LearningTheme.primaryPurple, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
