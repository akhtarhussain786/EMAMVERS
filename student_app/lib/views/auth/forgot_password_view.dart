import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../core/api_service.dart';
import '../../widgets/design_system_widgets.dart';

class ForgotPasswordView extends StatefulWidget {
  const ForgotPasswordView({super.key});

  @override
  State<ForgotPasswordView> createState() => _ForgotPasswordViewState();
}

class _ForgotPasswordViewState extends State<ForgotPasswordView> {
  int _step = 1; // 1: Send OTP, 2: Verify OTP, 3: Reset Password, 4: Success
  bool _isLoading = false;

  final _identityController = TextEditingController();
  final _otpController = TextEditingController();
  final _newPasswordController = TextEditingController();

  void _showSnackBar(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppConstants.accentRose : AppConstants.accentEmerald,
      ),
    );
  }

  void _handleSendOtp() async {
    if (_identityController.text.trim().isEmpty) {
      _showSnackBar('Please enter your Registered Mobile Number or Email');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final res = await ApiService.post('/v1/auth/send-otp', {
        'identity': _identityController.text.trim(),
      });
      _showSnackBar(res['message'] ?? 'OTP sent successfully', isError: false);
      setState(() => _step = 2);
    } catch (e) {
      _showSnackBar(e.toString().replaceAll('Exception: ', ''));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _handleVerifyOtp() async {
    if (_otpController.text.trim().isEmpty) {
      _showSnackBar('Please enter the 6-digit OTP code');
      return;
    }

    setState(() => _isLoading = true);
    try {
      await ApiService.post('/v1/auth/verify-otp', {
        'identity': _identityController.text.trim(),
        'otp': _otpController.text.trim(),
      });
      _showSnackBar('OTP Verified Successfully!', isError: false);
      setState(() => _step = 3);
    } catch (e) {
      _showSnackBar(e.toString().replaceAll('Exception: ', ''));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _handleResetPassword() async {
    if (_newPasswordController.text.trim().length < 6) {
      _showSnackBar('New Password must be at least 6 characters');
      return;
    }

    setState(() => _isLoading = true);
    try {
      await ApiService.post('/v1/auth/reset-password', {
        'identity': _identityController.text.trim(),
        'otp': _otpController.text.trim(),
        'new_password': _newPasswordController.text.trim(),
      });
      setState(() => _step = 4);
    } catch (e) {
      _showSnackBar(e.toString().replaceAll('Exception: ', ''));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.primaryDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.space24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppConstants.accentCyan.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.lock_reset, color: AppConstants.accentCyan, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('Forgot Password', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
                      SizedBox(height: 2),
                      Text('Secure Account Recovery', style: TextStyle(color: AppConstants.textSecondary, fontSize: 12.5)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: AppConstants.space32),

              if (_step == 1) ...[
                CustomTextField(
                  controller: _identityController,
                  label: 'Registered Mobile or Email',
                  hint: 'e.g. 9876543210 or candidate@examverse.com',
                  prefixIcon: Icons.contact_mail_outlined,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: AppConstants.space24),
                PrimaryButton(
                  label: 'Send OTP Code →',
                  onPressed: _handleSendOtp,
                  isLoading: _isLoading,
                ),
              ] else if (_step == 2) ...[
                Text(
                  'OTP sent to ${_identityController.text}',
                  style: const TextStyle(color: AppConstants.accentCyan, fontSize: 13, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: AppConstants.space16),
                CustomTextField(
                  controller: _otpController,
                  label: '6-Digit OTP Code',
                  hint: 'Enter 123456 (Demo OTP)',
                  prefixIcon: Icons.pin_outlined,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: AppConstants.space24),
                PrimaryButton(
                  label: 'Verify OTP →',
                  onPressed: _handleVerifyOtp,
                  isLoading: _isLoading,
                ),
              ] else if (_step == 3) ...[
                CustomTextField(
                  controller: _newPasswordController,
                  label: 'Create New Password',
                  hint: 'Minimum 6 characters',
                  prefixIcon: Icons.lock_outline,
                  isPassword: true,
                ),
                const SizedBox(height: AppConstants.space24),
                PrimaryButton(
                  label: 'Confirm New Password →',
                  onPressed: _handleResetPassword,
                  isLoading: _isLoading,
                ),
              ] else if (_step == 4) ...[
                EmptyStateWidget(
                  icon: Icons.check_circle_outline,
                  title: 'Password Reset Successful!',
                  description: 'Your ExamVerse password has been updated. You can now log in with your new password.',
                  buttonLabel: 'Back to Login',
                  onButtonPressed: () => Navigator.pop(context),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
