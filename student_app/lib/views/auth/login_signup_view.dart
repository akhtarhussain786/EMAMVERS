import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants.dart';
import '../../core/api_service.dart';
import '../../widgets/design_system_widgets.dart';
import 'forgot_password_view.dart';

class LoginSignupView extends StatefulWidget {
  /// Receives the account type returned by the API ('student' or 'teacher'),
  /// so the shell can open the right home screen.
  final void Function(String accountType) onAuthenticated;
  const LoginSignupView({super.key, required this.onAuthenticated});

  @override
  State<LoginSignupView> createState() => _LoginSignupViewState();
}

class _LoginSignupViewState extends State<LoginSignupView> {
  bool isSignUp = false;
  bool rememberMe = true;
  bool isLoading = false;

  final emailMobileController = TextEditingController();
  final passwordController = TextEditingController();
  final fullNameController = TextEditingController();

  List<dynamic> states = [];
  List<dynamic> qualifications = [];
  int? selectedStateId;
  int? selectedQualId;

  @override
  void initState() {
    super.initState();
    _loadSavedPreferences();
    _loadMetadata();
  }

  void _loadSavedPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final savedIdentity = prefs.getString('remembered_identity');
    final savedRememberMe = prefs.getBool('remember_me') ?? true;
    if (!mounted) return;
    setState(() {
      rememberMe = savedRememberMe;
      if (savedIdentity != null && savedIdentity.isNotEmpty && rememberMe) {
        emailMobileController.text = savedIdentity;
      } else {
        emailMobileController.text = 'demo@examverse.com';
        passwordController.text = 'password123';
      }
    });
  }

  Future<void> _savePreferences(String identity) async {
    final prefs = await SharedPreferences.getInstance();
    if (rememberMe) {
      await prefs.setString('remembered_identity', identity);
      await prefs.setBool('remember_me', true);
    } else {
      await prefs.remove('remembered_identity');
      await prefs.setBool('remember_me', false);
    }
  }

  void _loadMetadata() async {
    try {
      final res = await ApiService.get('/v1/auth/meta');
      if (!mounted) return;
      setState(() {
        states = res['states'] ?? [];
        qualifications = res['qualifications'] ?? [];
        if (states.isNotEmpty && selectedStateId == null) selectedStateId = states[0]['id'];
        if (qualifications.isNotEmpty && selectedQualId == null) selectedQualId = qualifications[0]['id'];
      });
    } catch (_) {
      if (mounted && states.isEmpty) {
        setState(() {
          states = [
            {'id': 1, 'name': 'All India / Central'},
            {'id': 2, 'name': 'Uttar Pradesh'},
            {'id': 3, 'name': 'Bihar'},
            {'id': 4, 'name': 'Rajasthan'},
            {'id': 5, 'name': 'Madhya Pradesh'},
            {'id': 6, 'name': 'Delhi NCR'},
            {'id': 7, 'name': 'Maharashtra'},
            {'id': 8, 'name': 'Haryana'},
          ];
          selectedStateId = 1;
        });
      }
    }
  }

  void _showSnackBar(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        backgroundColor: AppConstants.accentRose,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _handleLogin() async {
    final identity = emailMobileController.text.trim();
    final password = passwordController.text.trim();

    if (identity.isEmpty || password.isEmpty) {
      _showSnackBar('Please fill in Mobile Number / Email and Password');
      return;
    }

    setState(() => isLoading = true);
    try {
      final res = await ApiService.post('/v1/auth/login', {
        'identity': identity,
        'password': password,
      });
      final accountType = (res['account_type'] as String?) ?? 'student';
      await ApiService.setSession(res['token'] as String?, remember: rememberMe, type: accountType);
      await _savePreferences(identity);
      if (!mounted) return;
      widget.onAuthenticated(accountType);
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
        'email': identity.contains('@') ? identity : '',
        'mobile': identity.contains('@') ? '' : identity,
        'password': password,
        'state_id': selectedStateId,
        'qualification_id': selectedQualId,
      });
      await ApiService.setSession(res['token'] as String?, remember: rememberMe, type: 'student');
      await _savePreferences(identity);
      if (!mounted) return;
      widget.onAuthenticated('student');
    } catch (e) {
      _showSnackBar(e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.scaffoldDark,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: AppConstants.space24, vertical: AppConstants.space32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // BRAND HEADER
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppConstants.accentBlue, AppConstants.accentCyan],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppConstants.accentBlue.withValues(alpha: 0.3),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.school, color: Colors.white, size: 32),
                  ),
                  const SizedBox(height: AppConstants.space16),
                  const Text(
                    'EXAMVERSE',
                    style: TextStyle(
                      color: AppConstants.textPrimary,
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'India\'s Premier AI Exam Preparation Platform',
                    style: TextStyle(color: AppConstants.textSecondary, fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: AppConstants.space32),

                  // LOGIN / SIGNUP CARD
                  ExamVerseCard(
                    padding: const EdgeInsets.all(AppConstants.space24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isSignUp ? 'Create Candidate Account' : 'Welcome Back',
                          style: const TextStyle(color: AppConstants.textPrimary, fontSize: 20, fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isSignUp ? 'Start your competitive exam journey' : 'Continue your AI performance preparation',
                          style: const TextStyle(color: AppConstants.textSecondary, fontSize: 12.5),
                        ),
                        const SizedBox(height: AppConstants.space24),

                        if (isSignUp) ...[
                          CustomTextField(
                            controller: fullNameController,
                            label: 'Full Name',
                            hint: 'e.g. Rahul Kumar',
                            prefixIcon: Icons.person_outline,
                          ),
                          const SizedBox(height: AppConstants.space16),
                        ],

                        CustomTextField(
                          controller: emailMobileController,
                          label: 'Mobile Number / Email',
                          hint: 'e.g. 9876543210 or candidate@examverse.com',
                          prefixIcon: Icons.contact_mail_outlined,
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: AppConstants.space16),

                        CustomTextField(
                          controller: passwordController,
                          label: 'Password',
                          hint: '••••••••',
                          prefixIcon: Icons.lock_outline,
                          isPassword: true,
                        ),
                        const SizedBox(height: AppConstants.space16),

                        // SIGN UP STATE & QUALIFICATION DROPDOWNS
                        if (isSignUp) ...[
                          // State Dropdown
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Select Your Target State / Region',
                                style: TextStyle(
                                  color: AppConstants.textPrimary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: AppConstants.cardBorder),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<int>(
                                    isExpanded: true,
                                    value: selectedStateId,
                                    icon: const Icon(Icons.keyboard_arrow_down, color: AppConstants.accentCyan),
                                    hint: const Text('Select State', style: TextStyle(color: AppConstants.textSecondary, fontSize: 13)),
                                    items: states.map<DropdownMenuItem<int>>((s) {
                                      return DropdownMenuItem<int>(
                                        value: s['id'] as int?,
                                        child: Row(
                                          children: [
                                            const Icon(Icons.location_on_outlined, size: 18, color: AppConstants.accentCyan),
                                            const SizedBox(width: 8),
                                            Text(
                                              (s['name'] ?? '').toString(),
                                              style: const TextStyle(color: AppConstants.textPrimary, fontSize: 13.5, fontWeight: FontWeight.w500),
                                            ),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                    onChanged: (val) => setState(() => selectedStateId = val),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppConstants.space16),

                          // Qualification Dropdown (if available)
                          if (qualifications.isNotEmpty) ...[
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Highest Qualification',
                                  style: TextStyle(
                                    color: AppConstants.textPrimary,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: AppConstants.cardBorder),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<int>(
                                      isExpanded: true,
                                      value: selectedQualId,
                                      icon: const Icon(Icons.keyboard_arrow_down, color: AppConstants.accentCyan),
                                      items: qualifications.map<DropdownMenuItem<int>>((q) {
                                        return DropdownMenuItem<int>(
                                          value: q['id'] as int?,
                                          child: Row(
                                            children: [
                                              const Icon(Icons.school_outlined, size: 18, color: AppConstants.accentIndigo),
                                              const SizedBox(width: 8),
                                              Text(
                                                (q['name'] ?? '').toString(),
                                                style: const TextStyle(color: AppConstants.textPrimary, fontSize: 13.5, fontWeight: FontWeight.w500),
                                              ),
                                            ],
                                          ),
                                        );
                                      }).toList(),
                                      onChanged: (val) => setState(() => selectedQualId = val),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppConstants.space16),
                          ],
                        ],

                        if (!isSignUp) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              GestureDetector(
                                onTap: () => setState(() => rememberMe = !rememberMe),
                                child: Row(
                                  children: [
                                    SizedBox(
                                      height: 24,
                                      width: 24,
                                      child: Checkbox(
                                        value: rememberMe,
                                        activeColor: AppConstants.accentCyan,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                        onChanged: (val) => setState(() => rememberMe = val ?? true),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Text('Remember Me', style: TextStyle(color: AppConstants.textSecondary, fontSize: 12.5)),
                                  ],
                                ),
                              ),
                              GestureDetector(
                                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ForgotPasswordView())),
                                child: const Text(
                                  'Forgot Password?',
                                  style: TextStyle(color: AppConstants.accentCyan, fontSize: 12.5, fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppConstants.space20),
                        ],

                        PrimaryButton(
                          label: isSignUp ? 'Create ExamVerse Account' : 'Log In to ExamVerse',
                          onPressed: isSignUp ? _handleSignup : _handleLogin,
                          isLoading: isLoading,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppConstants.space24),

                  // TOGGLE LOGIN / SIGNUP
                  Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        isSignUp ? 'Already have an account?' : 'New candidate on ExamVerse?',
                        style: const TextStyle(color: AppConstants.textSecondary, fontSize: 13.5),
                      ),
                      TextButton(
                        onPressed: () => setState(() => isSignUp = !isSignUp),
                        child: Text(
                          isSignUp ? 'Sign In' : 'Sign Up',
                          style: const TextStyle(color: AppConstants.accentCyan, fontSize: 13.5, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppConstants.space12),

                  // DEMO QUICK FILL HELPER
                  if (!isSignUp)
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: [
                        ActionChip(
                          avatar: const Icon(Icons.school, size: 16, color: AppConstants.accentCyan),
                          label: const Text('Demo Student', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                          backgroundColor: AppConstants.accentCyan.withValues(alpha: 0.1),
                          side: BorderSide(color: AppConstants.accentCyan.withValues(alpha: 0.3)),
                          onPressed: () {
                            emailMobileController.text = 'demo@examverse.com';
                            passwordController.text = 'password123';
                            _handleLogin();
                          },
                        ),
                        ActionChip(
                          avatar: const Icon(Icons.psychology, size: 16, color: AppConstants.accentGreen),
                          label: const Text('Demo Teacher', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                          backgroundColor: AppConstants.accentGreen.withValues(alpha: 0.1),
                          side: BorderSide(color: AppConstants.accentGreen.withValues(alpha: 0.3)),
                          onPressed: () {
                            emailMobileController.text = 'teacher@examverse.com';
                            passwordController.text = 'password123';
                            _handleLogin();
                          },
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
}
