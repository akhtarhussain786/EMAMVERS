import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants.dart';
import '../../core/api_service.dart';
import 'teacher_dashboard_view.dart';

class BecomeTeacherView extends StatefulWidget {
  const BecomeTeacherView({super.key});

  @override
  State<BecomeTeacherView> createState() => _BecomeTeacherViewState();
}

class _BecomeTeacherViewState extends State<BecomeTeacherView> {
  bool _isLoading = true;
  bool _isSavingDraft = false;
  bool _isSubmitting = false;
  String? _uploadingDocType;
  Map<String, dynamic>? _application;

  // Form controllers
  final _formKey = GlobalKey<FormState>();
  final _highestQualController = TextEditingController(text: 'Master Degree / B.Ed');
  final _degreeController = TextEditingController();
  final _specController = TextEditingController();
  final _institutionController = TextEditingController();
  final _yearController = TextEditingController(text: '2023');
  final _expController = TextEditingController(text: '2.5');
  final _orgController = TextEditingController();
  bool _declarationAccepted = false;

  @override
  void initState() {
    super.initState();
    _fetchApplication();
  }

  @override
  void dispose() {
    _highestQualController.dispose();
    _degreeController.dispose();
    _specController.dispose();
    _institutionController.dispose();
    _yearController.dispose();
    _expController.dispose();
    _orgController.dispose();
    super.dispose();
  }

  Future<void> _fetchApplication() async {
    setState(() => _isLoading = true);
    try {
      final res = await ApiService.getAuth('/v1/teacher/application');
      if (res != null && res is Map<String, dynamic>) {
        setState(() {
          _application = res;
          if (_application!['highest_qualification'] != null && _application!['highest_qualification'].toString().isNotEmpty) {
            _highestQualController.text = _application!['highest_qualification'].toString();
          }
          if (_application!['degree_name'] != null) {
            _degreeController.text = _application!['degree_name'].toString();
          }
          if (_application!['specialization'] != null) {
            _specController.text = _application!['specialization'].toString();
          }
          if (_application!['institution_name'] != null) {
            _institutionController.text = _application!['institution_name'].toString();
          }
          if (_application!['passing_year'] != null) {
            _yearController.text = _application!['passing_year'].toString();
          }
          if (_application!['experience_years'] != null) {
            _expController.text = _application!['experience_years'].toString();
          }
          if (_application!['current_organization'] != null) {
            _orgController.text = _application!['current_organization'].toString();
          }
          _declarationAccepted = (_application!['declaration_accepted'] == 1 || _application!['declaration_accepted'] == true);
        });
      }
    } catch (e) {
      // No active application or draft exists yet
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveDraft() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSavingDraft = true);
    try {
      final body = {
        'highest_qualification': _highestQualController.text.trim(),
        'degree_name': _degreeController.text.trim(),
        'specialization': _specController.text.trim(),
        'institution_name': _institutionController.text.trim(),
        'passing_year': int.tryParse(_yearController.text.trim()) ?? 2024,
        'experience_years': double.tryParse(_expController.text.trim()) ?? 0.0,
        'current_organization': _orgController.text.trim(),
      };
      final res = await ApiService.postAuth('/v1/teacher/application', body);
      if (!mounted) return;
      if (res != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Draft saved successfully! You can upload KYC documents next.'),
            backgroundColor: Colors.green,
          ),
        );
        await _fetchApplication();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving draft: $e'), backgroundColor: Colors.redAccent),
      );
    } finally {
      if (mounted) setState(() => _isSavingDraft = false);
    }
  }

  Future<void> _pickAndUploadDocument(String docType) async {
    try {
      // First save draft if not saved yet
      if (_application == null) {
        final body = {
          'highest_qualification': _highestQualController.text.trim().isNotEmpty ? _highestQualController.text.trim() : 'Master Degree',
          'degree_name': _degreeController.text.trim().isNotEmpty ? _degreeController.text.trim() : 'General',
          'specialization': _specController.text.trim(),
          'institution_name': _institutionController.text.trim().isNotEmpty ? _institutionController.text.trim() : 'University',
          'passing_year': int.tryParse(_yearController.text.trim()) ?? 2024,
          'experience_years': double.tryParse(_expController.text.trim()) ?? 0.0,
          'current_organization': _orgController.text.trim(),
        };
        await ApiService.postAuth('/v1/teacher/application', body);
      }

      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'webp'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      if (file.size > 5 * 1024 * 1024) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('File size exceeds 5MB limit. Please choose a smaller file.'), backgroundColor: Colors.redAccent),
        );
        return;
      }

      setState(() => _uploadingDocType = docType);

      final res = await ApiService.uploadMultipart(
        '/v1/teacher/application/documents',
        fields: {
          'document_type': docType,
          'document_side': 'single',
        },
        fileField: 'document',
        filePath: file.path ?? '',
        fileBytes: file.bytes,
        filename: file.name,
      );

      if (!mounted) return;
      if (res != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${docType == 'identity' ? 'Identity ID' : 'Qualification Certificate'} uploaded successfully! ✓'),
            backgroundColor: Colors.green,
          ),
        );
        await _fetchApplication();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Upload failed: $e'), backgroundColor: Colors.redAccent),
      );
    } finally {
      if (mounted) setState(() => _uploadingDocType = null);
    }
  }

  Future<void> _submitApplication() async {
    if (!_declarationAccepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please accept the integrity declaration to submit your KYC.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Check if mandatory documents exist
    final docs = (_application?['documents'] as List<dynamic>?) ?? [];
    final hasIdentity = docs.any((d) => d['document_type'] == 'identity');
    final hasQualification = docs.any((d) => d['document_type'] == 'qualification');

    if (!hasIdentity || !hasQualification) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please upload both Identity Proof (PAN/Aadhaar) and Qualification Proof before submitting.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final res = await ApiService.postAuth('/v1/teacher/application/submit', {
        'declaration_accepted': true,
      });
      if (!mounted) return;
      if (res != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Application submitted successfully! Our faculty review board will verify it.'),
            backgroundColor: Colors.green,
          ),
        );
        await _fetchApplication();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Submission failed: $e'), backgroundColor: Colors.redAccent),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = _application?['status'] ?? 'draft';

    return Scaffold(
      backgroundColor: AppConstants.primaryDark,
      appBar: AppBar(
        backgroundColor: AppConstants.scaffoldDark,
        elevation: 0,
        title: Text(
          'Become Verified Faculty',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppConstants.textPrimary,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppConstants.textPrimary, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppConstants.accentYellow),
            tooltip: 'Refresh Status',
            onPressed: _fetchApplication,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppConstants.accentYellow))
          : RefreshIndicator(
              color: AppConstants.accentYellow,
              backgroundColor: AppConstants.cardDark,
              onRefresh: _fetchApplication,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeaderBanner(),
                    const SizedBox(height: 16),
                    _buildStatusCard(),
                    const SizedBox(height: 20),
                    if (status == 'approved')
                      _buildApprovedView()
                    else if (status == 'submitted' || status == 'under_review')
                      _buildUnderReviewView()
                    else
                      _buildApplicationForm(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildHeaderBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppConstants.accentYellow.withValues(alpha: 0.2),
            AppConstants.accentYellowDeep.withValues(alpha: 0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppConstants.accentYellow.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppConstants.accentYellow.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppConstants.accentYellow),
            ),
            child: const Center(
              child: Text('🎓', style: TextStyle(fontSize: 24)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'EXAMVERSE Faculty KYC',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppConstants.accentYellow,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Verify your credentials to unlock question authoring, test creation, and national student reach.',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppConstants.textSecondary,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    final status = _application?['status'] ?? 'draft';
    Color statusColor;
    String statusText;
    String statusDesc;
    IconData statusIcon;

    switch (status) {
      case 'submitted':
      case 'under_review':
        statusColor = AppConstants.accentAmber;
        statusText = 'Under Review by Admin Board';
        statusDesc = 'Your KYC documents & credentials are being verified. Review takes 24-48 hours.';
        statusIcon = Icons.hourglass_top_rounded;
        break;
      case 'approved':
        statusColor = AppConstants.accentEmerald;
        statusText = 'Verified Faculty Status Active';
        statusDesc = 'Congratulations! You have full question authoring and mock test creation access.';
        statusIcon = Icons.verified_user_rounded;
        break;
      case 'changes_required':
        statusColor = AppConstants.accentPurple;
        statusText = 'Action Required: Re-upload / Fix Details';
        statusDesc = 'The review board requested changes or clearer documents. See instructions below.';
        statusIcon = Icons.edit_note_rounded;
        break;
      case 'rejected':
        statusColor = AppConstants.accentRose;
        statusText = 'Application Ineligible / Denied';
        statusDesc = 'Credentials did not meet current faculty eligibility criteria.';
        statusIcon = Icons.cancel_rounded;
        break;
      default:
        statusColor = AppConstants.accentCyan;
        statusText = 'Application in Draft';
        statusDesc = 'Fill out your academic credentials and upload KYC documents to submit.';
        statusIcon = Icons.assignment_outlined;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppConstants.cardDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: statusColor.withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(statusIcon, color: statusColor, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      statusText,
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700,
                        fontSize: 14.5,
                        color: statusColor,
                      ),
                    ),
                    if (_application?['application_no'] != null)
                      Text(
                        'Application ID: ${_application!['application_no']}',
                        style: GoogleFonts.inter(fontSize: 11.5, color: AppConstants.textMuted),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            statusDesc,
            style: GoogleFonts.inter(fontSize: 12.5, color: AppConstants.textSecondary, height: 1.3),
          ),
          if (_application?['reviewer_message'] != null && _application!['reviewer_message'].toString().isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppConstants.accentPurple.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppConstants.accentPurple.withValues(alpha: 0.3)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline, color: AppConstants.accentPurple, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Reviewer Feedback:',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                            color: AppConstants.accentPurple,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _application!['reviewer_message'].toString(),
                          style: GoogleFonts.inter(fontSize: 12, color: AppConstants.textPrimary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildApplicationForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeading('1. Academic & Professional Credentials'),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _highestQualController,
            label: 'Highest Qualification',
            hint: 'e.g. Master of Science, Ph.D, B.Tech, M.Ed',
            icon: Icons.school,
            validator: (v) => v!.trim().isEmpty ? 'Highest qualification is required' : null,
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _degreeController,
            label: 'Degree & Major',
            hint: 'e.g. M.Sc Mathematics, B.Tech Computer Science',
            icon: Icons.history_edu,
            validator: (v) => v!.trim().isEmpty ? 'Degree name is required' : null,
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _specController,
            label: 'Subject Specialization',
            hint: 'e.g. Quantitative Aptitude, General Studies, Physics',
            icon: Icons.menu_book,
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _institutionController,
            label: 'University / Institute',
            hint: 'e.g. Delhi University, IIT Bombay, Anna University',
            icon: Icons.account_balance,
            validator: (v) => v!.trim().isEmpty ? 'Institution name is required' : null,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _yearController,
                  label: 'Passing Year',
                  hint: 'e.g. 2022',
                  icon: Icons.calendar_today,
                  keyboardType: TextInputType.number,
                  validator: (v) => (int.tryParse(v ?? '') == null) ? 'Valid year required' : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTextField(
                  controller: _expController,
                  label: 'Teaching Exp. (Years)',
                  hint: 'e.g. 3.5',
                  icon: Icons.work_history,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _orgController,
            label: 'Current Institution / Coaching (Optional)',
            hint: 'e.g. Allen Career Institute, Unacademy, Self-employed',
            icon: Icons.business,
          ),
          const SizedBox(height: 24),
          _buildSectionHeading('2. KYC Verification Documents'),
          const SizedBox(height: 6),
          Text(
            'Upload government ID proof and your highest qualification degree certificate (PDF or Image, max 5MB each).',
            style: GoogleFonts.inter(fontSize: 12, color: AppConstants.textMuted),
          ),
          const SizedBox(height: 14),
          _buildDocUploadTile(
            title: 'Government Identity Proof',
            subtitle: 'Aadhaar Card / PAN Card / Voter ID / Passport',
            type: 'identity',
            icon: Icons.badge,
          ),
          const SizedBox(height: 12),
          _buildDocUploadTile(
            title: 'Degree Certificate / Marksheet',
            subtitle: 'Highest qualification graduation or post-grad degree',
            type: 'qualification',
            icon: Icons.workspace_premium,
          ),
          const SizedBox(height: 20),
          _buildDeclarationCheckbox(),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _isSavingDraft || _isSubmitting ? null : _saveDraft,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppConstants.textPrimary,
                    side: const BorderSide(color: AppConstants.cardBorder),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: _isSavingDraft
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppConstants.textPrimary))
                      : Text('Save Draft', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13.5)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: _isSubmitting || _isSavingDraft ? null : _submitApplication,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.accentYellow,
                    foregroundColor: AppConstants.primaryDark,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                  child: _isSubmitting
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppConstants.primaryDark))
                      : Text(
                          'Submit for Verification',
                          style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 14),
                        ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildSectionHeading(String text) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: AppConstants.textPrimary,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      style: GoogleFonts.inter(color: AppConstants.textPrimary, fontSize: 13.5),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: GoogleFonts.inter(color: AppConstants.textMuted.withValues(alpha: 0.6), fontSize: 12.5),
        labelStyle: GoogleFonts.inter(color: AppConstants.textSecondary, fontSize: 13),
        prefixIcon: Icon(icon, color: AppConstants.accentYellow, size: 20),
        filled: true,
        fillColor: AppConstants.cardDark,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppConstants.cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppConstants.accentYellow, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppConstants.accentRose),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppConstants.accentRose, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildDocUploadTile({
    required String title,
    required String subtitle,
    required String type,
    required IconData icon,
  }) {
    final docs = (_application?['documents'] as List<dynamic>?) ?? [];
    final matchingDoc = docs.firstWhere(
      (d) => d['document_type'] == type,
      orElse: () => null,
    );
    final isUploading = (_uploadingDocType == type);
    final hasDoc = (matchingDoc != null);
    final docStatus = hasDoc ? (matchingDoc['verification_status'] ?? 'pending').toString() : 'pending';

    Color badgeColor;
    String badgeText;
    switch (docStatus) {
      case 'verified':
        badgeColor = AppConstants.accentEmerald;
        badgeText = 'VERIFIED';
        break;
      case 'reupload_required':
      case 'invalid':
        badgeColor = AppConstants.accentRose;
        badgeText = 'RE-UPLOAD REQUIRED';
        break;
      case 'unclear':
        badgeColor = AppConstants.accentPurple;
        badgeText = 'UNCLEAR';
        break;
      default:
        badgeColor = AppConstants.accentAmber;
        badgeText = 'UPLOADED / PENDING';
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppConstants.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasDoc ? (docStatus == 'verified' ? AppConstants.accentEmerald.withValues(alpha: 0.4) : AppConstants.accentYellow.withValues(alpha: 0.3)) : AppConstants.cardBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: hasDoc ? AppConstants.accentEmerald.withValues(alpha: 0.15) : AppConstants.accentYellow.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  hasDoc ? Icons.check_circle_rounded : icon,
                  color: hasDoc ? AppConstants.accentEmerald : AppConstants.accentYellow,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700,
                        fontSize: 13.5,
                        color: AppConstants.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(fontSize: 11.5, color: AppConstants.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (hasDoc) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppConstants.surfaceElevated,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppConstants.cardBorder),
              ),
              child: Row(
                children: [
                  const Icon(Icons.description_outlined, size: 15, color: AppConstants.textSecondary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '${matchingDoc['original_name'] ?? 'document'} (${((matchingDoc['file_size'] ?? 0) / 1024).round()} KB)',
                      style: GoogleFonts.inter(fontSize: 11.5, color: AppConstants.textSecondary),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: badgeColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: badgeColor.withValues(alpha: 0.4)),
                    ),
                    child: Text(
                      badgeText,
                      style: GoogleFonts.inter(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        color: badgeColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: isUploading ? null : () => _pickAndUploadDocument(type),
              icon: isUploading
                  ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: AppConstants.accentYellow))
                  : Icon(hasDoc ? Icons.replay : Icons.upload_file, size: 16, color: AppConstants.accentYellow),
              label: Text(
                isUploading
                    ? 'Uploading File...'
                    : (hasDoc ? 'Change / Re-upload File' : 'Select & Upload Document'),
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: AppConstants.accentYellow,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: AppConstants.accentYellow.withValues(alpha: 0.4)),
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeclarationCheckbox() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppConstants.surfaceElevated,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppConstants.cardBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Checkbox(
            value: _declarationAccepted,
            activeColor: AppConstants.accentYellow,
            checkColor: AppConstants.primaryDark,
            onChanged: (v) => setState(() => _declarationAccepted = v ?? false),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'I hereby certify that all educational qualifications, certificates, and identity information submitted are authentic. I agree to adhere to EXAMVERSE question authoring guidelines.',
                style: GoogleFonts.inter(fontSize: 11.5, color: AppConstants.textSecondary, height: 1.35),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnderReviewView() {
    return Column(
      children: [
        _buildSubmittedSummaryCard(),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppConstants.cardDark,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppConstants.cardBorder),
          ),
          child: Column(
            children: [
              const Icon(Icons.access_time_rounded, color: AppConstants.accentAmber, size: 36),
              const SizedBox(height: 10),
              Text(
                'Verification In Progress',
                style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15, color: AppConstants.textPrimary),
              ),
              const SizedBox(height: 6),
              Text(
                'Our administrative compliance team verifies every credential for accuracy and question authenticity. You will receive an in-app notification upon approval.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 12.5, color: AppConstants.textSecondary, height: 1.35),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildApprovedView() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppConstants.cardDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppConstants.accentEmerald.withValues(alpha: 0.4)),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppConstants.accentEmerald.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(color: AppConstants.accentEmerald, width: 2),
            ),
            child: const Icon(Icons.verified_rounded, color: AppConstants.accentEmerald, size: 36),
          ),
          const SizedBox(height: 14),
          Text(
            'Verified Faculty Member',
            style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, color: AppConstants.textPrimary),
          ),
          const SizedBox(height: 6),
          Text(
            'Your educator credentials have been verified. You can now author and publish MCQs directly to national test series.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 13, color: AppConstants.textSecondary, height: 1.35),
          ),
          const SizedBox(height: 20),
          _buildSubmittedSummaryCard(),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                await ApiService.setSession(ApiService.authToken, type: 'teacher');
                if (!mounted) return;
                final nav = Navigator.of(context);
                nav.pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (ctx) => TeacherDashboardView(
                      onLogout: () async {
                        await ApiService.setSession(ApiService.authToken, type: 'student');
                        Navigator.of(ctx).pushNamedAndRemoveUntil('/', (route) => false);
                      },
                    ),
                  ),
                  (route) => false,
                );
              },
              icon: const Icon(Icons.dashboard_customize_rounded, size: 18),
              label: Text('Open Teacher Panel & Studio', style: GoogleFonts.inter(fontWeight: FontWeight.w800)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.accentYellow,
                foregroundColor: AppConstants.primaryDark,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmittedSummaryCard() {
    final docs = (_application?['documents'] as List<dynamic>?) ?? [];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppConstants.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppConstants.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Application Summary',
            style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14, color: AppConstants.accentYellow),
          ),
          const Divider(height: 18, color: AppConstants.cardBorder),
          _infoRow('Degree / Major', '${_application?['highest_qualification']} • ${_application?['degree_name']}'),
          _infoRow('Specialization', _application?['specialization'] ?? 'General'),
          _infoRow('Institution', '${_application?['institution_name']} (${_application?['passing_year']})'),
          _infoRow('Experience', '${_application?['experience_years']} Years'),
          _infoRow('Documents', '${docs.length} files attached'),
          if (_application?['submitted_at'] != null)
            _infoRow('Submitted On', _application!['submitted_at'].toString().split('T').first),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label, style: GoogleFonts.inter(color: AppConstants.textMuted, fontSize: 12)),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 12.5, color: AppConstants.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}
