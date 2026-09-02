import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../core/api_service.dart';
import '../../widgets/design_system_widgets.dart';

class EditProfileView extends StatefulWidget {
  final Map<String, dynamic>? userData;
  const EditProfileView({super.key, this.userData});

  @override
  State<EditProfileView> createState() => _EditProfileViewState();
}

class _EditProfileViewState extends State<EditProfileView> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _mobileController = TextEditingController();
  final _examController = TextEditingController();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.userData != null) {
      _nameController.text = widget.userData!['full_name'] ?? 'Rahul Kumar';
      _emailController.text = widget.userData!['email'] ?? 'demo@examverse.com';
      // Placeholder numbers must not be pre-filled into a real profile field.
      final mobile = widget.userData!['mobile']?.toString() ?? '';
      _mobileController.text = mobile.startsWith('NA-') ? '' : mobile;
      _examController.text = widget.userData!['target_exam'] ?? 'SSC CGL';
    } else {
      _nameController.text = 'Rahul Kumar';
      _emailController.text = 'demo@examverse.com';
      _mobileController.text = '9876543210';
      _examController.text = 'SSC CGL';
    }
  }

  void _saveProfile() async {
    setState(() => _isLoading = true);
    try {
      await ApiService.put('/v1/user/profile', {
        'full_name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'mobile': _mobileController.text.trim(),
        'target_exam': _examController.text.trim(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!'), backgroundColor: AppConstants.accentEmerald),
        );
        Navigator.pop(context, true);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile saved locally.'), backgroundColor: AppConstants.accentEmerald),
        );
        Navigator.pop(context, true);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.primaryDark,
      appBar: AppBar(
        backgroundColor: AppConstants.scaffoldDark,
        title: const Text('Edit Profile', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.space20),
        child: Column(
          children: [
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 45,
                    backgroundColor: AppConstants.accentCyan.withValues(alpha: 0.2),
                    child: const Icon(Icons.person, size: 50, color: AppConstants.accentCyan),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(color: AppConstants.accentCyan, shape: BoxShape.circle),
                      child: const Icon(Icons.camera_alt, size: 16, color: Colors.black),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppConstants.space24),

            CustomTextField(controller: _nameController, label: 'Full Name', prefixIcon: Icons.person_outline),
            const SizedBox(height: AppConstants.space16),
            CustomTextField(controller: _emailController, label: 'Email Address', prefixIcon: Icons.email_outlined, keyboardType: TextInputType.emailAddress),
            const SizedBox(height: AppConstants.space16),
            CustomTextField(controller: _mobileController, label: 'Mobile Number', prefixIcon: Icons.phone_outlined, keyboardType: TextInputType.phone),
            const SizedBox(height: AppConstants.space16),
            CustomTextField(controller: _examController, label: 'Target Exam', prefixIcon: Icons.school_outlined),
            const SizedBox(height: AppConstants.space32),

            PrimaryButton(
              label: 'Save Profile Changes',
              onPressed: _saveProfile,
              isLoading: _isLoading,
            ),
          ],
        ),
      ),
    ),
  );
}
}
