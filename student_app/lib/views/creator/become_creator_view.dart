import 'package:flutter/material.dart';
import '../../core/constants.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/api_service.dart';

class BecomeCreatorView extends StatefulWidget {
  const BecomeCreatorView({super.key});

  @override
  State<BecomeCreatorView> createState() => _BecomeCreatorViewState();
}

class _BecomeCreatorViewState extends State<BecomeCreatorView> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _aboutCtrl = TextEditingController();
  final _upiCtrl = TextEditingController();
  final _bankAccountCtrl = TextEditingController();
  final _bankIfscCtrl = TextEditingController();
  final _bankNameCtrl = TextEditingController();

  bool _loading = false;
  bool _submitted = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _aboutCtrl.dispose();
    _upiCtrl.dispose();
    _bankAccountCtrl.dispose();
    _bankIfscCtrl.dispose();
    _bankNameCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      await ApiService.postAuth('/v1/creator/register', {
        'display_name': _nameCtrl.text.trim(),
        'about': _aboutCtrl.text.trim(),
        'upi_id': _upiCtrl.text.trim(),
        'bank_account_number': _bankAccountCtrl.text.trim(),
        'bank_ifsc': _bankIfscCtrl.text.trim(),
        'bank_account_name': _bankNameCtrl.text.trim(),
      });

      if (mounted) {
        setState(() {
          _loading = false;
          _submitted = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.primaryDark,
      appBar: AppBar(
        backgroundColor: AppConstants.primaryDark,
        title: Text(
          'Become a Creator',
          style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: AppConstants.textPrimary),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppConstants.textPrimary, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _submitted ? _buildSuccessView() : _buildFormView(),
    );
  }

  Widget _buildSuccessView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.15),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.green.shade400, width: 2),
              ),
              child: Icon(Icons.verified_user_outlined, size: 48, color: Colors.green.shade400),
            ),
            const SizedBox(height: 24),
            Text(
              'Application Submitted!',
              style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w800, color: AppConstants.textPrimary),
            ),
            const SizedBox(height: 10),
            Text(
              'Your creator application is under review by the ExamVerse team. Once approved, you can start uploading study materials and earning 80% revenue share!',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 13, color: AppConstants.textSecondary, height: 1.5),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.accentYellow,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                'Back to Marketplace',
                style: GoogleFonts.inter(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppConstants.accentYellowDeep, AppConstants.accentYellow],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(Icons.monetization_on_outlined, color: AppConstants.textPrimary, size: 36),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Earn with ExamVerse',
                          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800, color: AppConstants.textPrimary),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Upload PDFs, notes & mock test papers. Keep 80% of every sale directly to your UPI/Bank.',
                          style: GoogleFonts.inter(fontSize: 11, color: AppConstants.textPrimary.withValues(alpha: 0.85)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            Text(
              'Profile Details',
              style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: AppConstants.textPrimary),
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _nameCtrl,
              style: GoogleFonts.inter(color: AppConstants.textPrimary),
              decoration: _inputDec('Creator / Brand Display Name *', Icons.badge_outlined),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter display name' : null,
            ),
            const SizedBox(height: 14),

            TextFormField(
              controller: _aboutCtrl,
              maxLines: 3,
              style: GoogleFonts.inter(color: AppConstants.textPrimary),
              decoration: _inputDec('About You / Teaching Experience', Icons.info_outline),
            ),

            const SizedBox(height: 24),

            Text(
              'Payout Information (UPI / Bank)',
              style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: AppConstants.textPrimary),
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _upiCtrl,
              style: GoogleFonts.inter(color: AppConstants.textPrimary),
              decoration: _inputDec('UPI ID (e.g. name@okhdfcbank)', Icons.qr_code),
            ),
            const SizedBox(height: 14),

            TextFormField(
              controller: _bankAccountCtrl,
              style: GoogleFonts.inter(color: AppConstants.textPrimary),
              decoration: _inputDec('Bank Account Number (Optional)', Icons.account_balance),
            ),
            const SizedBox(height: 14),

            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _bankIfscCtrl,
                    style: GoogleFonts.inter(color: AppConstants.textPrimary),
                    decoration: _inputDec('IFSC Code', Icons.numbers),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _bankNameCtrl,
                    style: GoogleFonts.inter(color: AppConstants.textPrimary),
                    decoration: _inputDec('Account Holder', Icons.person_outline),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _loading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.accentYellow,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: _loading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(color: AppConstants.textPrimary, strokeWidth: 2.5),
                      )
                    : Text(
                        'Submit Application',
                        style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700),
                      ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDec(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.inter(color: AppConstants.textMuted, fontSize: 13),
      prefixIcon: Icon(icon, color: AppConstants.textMuted, size: 20),
      filled: true,
      fillColor: AppConstants.textPrimary.withValues(alpha: 0.05),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppConstants.textPrimary.withValues(alpha: 0.1)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppConstants.textPrimary.withValues(alpha: 0.1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppConstants.accentYellow),
      ),
    );
  }
}
