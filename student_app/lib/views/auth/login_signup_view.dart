import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../core/api_service.dart';

class LoginSignupView extends StatefulWidget {
  final VoidCallback onAuthenticated;
  const LoginSignupView({super.key, required this.onAuthenticated});

  @override
  State<LoginSignupView> createState() => _LoginSignupViewState();
}

class _LoginSignupViewState extends State<LoginSignupView> {
  bool isSignUp = false;
  bool isOtpMode = false;
  bool isLoading = false;

  final emailMobileController = TextEditingController();
  final passwordController = TextEditingController();
  final fullNameController = TextEditingController();
  final otpController = TextEditingController();

  List<dynamic> states = [];
  List<dynamic> qualifications = [];
  int? selectedStateId;
  int? selectedQualId;

  @override
  void initState() {
    super.initState();
    _loadMetadata();
  }

  void _loadMetadata() async {
    try {
      final res = await ApiService.get('/v1/auth/meta');
      setState(() {
        states = res['states'] ?? [];
        qualifications = res['qualifications'] ?? [];
        if (states.isNotEmpty) selectedStateId = states[0]['id'];
        if (qualifications.isNotEmpty) selectedQualId = qualifications[0]['id'];
      });
    } catch (_) {}
  }

  void _handleLogin() async {
    if (emailMobileController.text.isEmpty || passwordController.text.isEmpty) {
      _showSnackBar('Please fill in Email/Mobile and Password');
      return;
    }

    setState(() => isLoading = true);
    try {
      final res = await ApiService.post('/v1/auth/login', {
        'identity': emailMobileController.text.trim(),
        'password': passwordController.text.trim(),
      });
      ApiService.authToken = res['token'];
      widget.onAuthenticated();
    } catch (e) {
      _showSnackBar(e.toString().replaceAll('Exception: ', ''));
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _handleSignup() async {
    if (fullNameController.text.isEmpty || emailMobileController.text.isEmpty || passwordController.text.isEmpty) {
      _showSnackBar('Please fill in all required fields');
      return;
    }

    setState(() => isLoading = true);
    try {
      final res = await ApiService.post('/v1/auth/signup', {
        'full_name': fullNameController.text.trim(),
        'email': emailMobileController.text.trim(),
        'mobile': '98' + DateTime.now().millisecondsSinceEpoch.toString().substring(5, 13),
        'password': passwordController.text.trim(),
        'state_id': selectedStateId,
        'qualification_id': selectedQualId,
      });
      ApiService.authToken = res['token'];
      widget.onAuthenticated();
    } catch (e) {
      _showSnackBar(e.toString().replaceAll('Exception: ', ''));
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.redAccent));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.primaryDark,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 420),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppConstants.cardDark,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppConstants.cardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('EXAM', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                    Text('VERSE', style: TextStyle(color: AppConstants.accentBlue, fontSize: 28, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'India\'s AI Exam Performance & Career Platform',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppConstants.textSecondary, fontSize: 12),
                ),
                const SizedBox(height: 32),

                if (isSignUp) ...[
                  TextField(
                    controller: fullNameController,
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDecoration('Full Name', Icons.person),
                  ),
                  const SizedBox(height: 16),
                ],

                TextField(
                  controller: emailMobileController,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration('Email or Mobile Number', Icons.email),
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: passwordController,
                  obscureText: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration('Password', Icons.lock),
                ),
                const SizedBox(height: 16),

                if (isSignUp) ...[
                  // State Picker
                  DropdownButtonFormField<int>(
                    value: selectedStateId,
                    dropdownColor: AppConstants.cardDark,
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDecoration('State (For State Rankings)', Icons.map),
                    items: states.map((s) => DropdownMenuItem<int>(value: s['id'], child: Text(s['name']))).toList(),
                    onChanged: (v) => setState(() => selectedStateId = v),
                  ),
                  const SizedBox(height: 16),

                  // Qualification Picker
                  DropdownButtonFormField<int>(
                    value: selectedQualId,
                    dropdownColor: AppConstants.cardDark,
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDecoration('Educational Qualification', Icons.school),
                    items: qualifications.map((q) => DropdownMenuItem<int>(value: q['id'], child: Text(q['name']))).toList(),
                    onChanged: (v) => setState(() => selectedQualId = v),
                  ),
                  const SizedBox(height: 16),
                ],

                const SizedBox(height: 8),

                ElevatedButton(
                  onPressed: isLoading ? null : (isSignUp ? _handleSignup : _handleLogin),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.accentBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: isLoading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text(isSignUp ? 'Create Account & Continue' : 'Log In to ExamVerse', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),

                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(isSignUp ? 'Already have an account? ' : 'New candidate on ExamVerse? ', style: const TextStyle(color: AppConstants.textSecondary, fontSize: 13)),
                    GestureDetector(
                      onTap: () => setState(() => isSignUp = !isSignUp),
                      child: Text(isSignUp ? 'Log In' : 'Sign Up', style: const TextStyle(color: AppConstants.accentBlue, fontWeight: FontWeight.bold, fontSize: 13)),
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

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      prefixIcon: Icon(icon, color: AppConstants.textSecondary, size: 20),
      hintText: hint,
      hintStyle: const TextStyle(color: AppConstants.textMuted, fontSize: 14),
      filled: true,
      fillColor: AppConstants.primaryDark,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppConstants.cardBorder)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppConstants.cardBorder)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppConstants.accentBlue)),
    );
  }
}
