import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants.dart';
import '../../core/api_service.dart';

class TeacherDocumentsView extends StatefulWidget {
  const TeacherDocumentsView({super.key});

  @override
  State<TeacherDocumentsView> createState() => _TeacherDocumentsViewState();
}

class _TeacherDocumentsViewState extends State<TeacherDocumentsView> {
  bool _isLoading = true;
  String? _uploadingType;
  int? _deletingDocId;
  Map<String, dynamic>? _application;

  @override
  void initState() {
    super.initState();
    _fetchApplication();
  }

  Future<void> _fetchApplication() async {
    setState(() => _isLoading = true);
    try {
      final res = await ApiService.getAuth('/v1/teacher/application');
      if (res != null && res is Map<String, dynamic>) {
        setState(() {
          _application = res;
        });
      }
    } catch (e) {
      // Error handling
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickAndUpload(String docType, String docTitle) async {
    try {
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
          const SnackBar(
            content: Text('File size exceeds 5MB limit. Please choose a smaller file.'),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }

      setState(() => _uploadingType = docType);

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
            content: Text('$docTitle uploaded successfully! ✓'),
            backgroundColor: Colors.green,
          ),
        );
        await _fetchApplication();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Upload failed: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) setState(() => _uploadingType = null);
    }
  }

  Future<void> _deleteDocument(int docId, String title) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppConstants.cardDark,
        title: Text('Remove $title?', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: AppConstants.textPrimary)),
        content: Text('Are you sure you want to remove this verification document?', style: GoogleFonts.inter(color: AppConstants.textSecondary, fontSize: 13)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: AppConstants.textMuted)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppConstants.accentRose, foregroundColor: Colors.white),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _deletingDocId = docId);
    try {
      await ApiService.delete('/v1/teacher/application/documents/$docId');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Document removed successfully.'), backgroundColor: Colors.orange),
      );
      await _fetchApplication();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to remove document: $e'), backgroundColor: Colors.redAccent),
      );
    } finally {
      if (mounted) setState(() => _deletingDocId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final docs = (_application?['documents'] as List<dynamic>?) ?? [];
    final status = (_application?['status'] ?? 'submitted').toString();

    return Scaffold(
      backgroundColor: AppConstants.primaryDark,
      appBar: AppBar(
        backgroundColor: AppConstants.scaffoldDark,
        elevation: 0,
        title: Text(
          'KYC & Document Center',
          style: GoogleFonts.inter(
            fontSize: 17,
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
            icon: const Icon(Icons.refresh, color: AppConstants.accentCyan),
            tooltip: 'Refresh',
            onPressed: _fetchApplication,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppConstants.accentCyan))
          : RefreshIndicator(
              color: AppConstants.accentCyan,
              backgroundColor: AppConstants.cardDark,
              onRefresh: _fetchApplication,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildStatusOverviewCard(status, docs),
                  const SizedBox(height: 20),
                  Text(
                    'Upload KYC Documents',
                    style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800, color: AppConstants.textPrimary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Upload your government ID and educational qualification certificates for compliance verification.',
                    style: GoogleFonts.inter(fontSize: 12, color: AppConstants.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  
                  // 1. Identity Proof
                  _buildDocCard(
                    type: 'identity',
                    title: 'Government Identity Proof',
                    subtitle: 'Aadhaar Card, PAN Card, Voter ID, or Passport',
                    icon: Icons.badge_outlined,
                    isRequired: true,
                    docs: docs,
                  ),
                  const SizedBox(height: 14),

                  // 2. Qualification Degree
                  _buildDocCard(
                    type: 'qualification',
                    title: 'Educational Degree / Marksheet',
                    subtitle: 'Graduation / Post-Graduation Degree Certificate',
                    icon: Icons.school_outlined,
                    isRequired: true,
                    docs: docs,
                  ),
                  const SizedBox(height: 14),

                  // 3. Experience Proof
                  _buildDocCard(
                    type: 'experience',
                    title: 'Teaching Experience Proof',
                    subtitle: 'Institution Relieving Letter or Work Certificate',
                    icon: Icons.work_outline,
                    isRequired: false,
                    docs: docs,
                  ),
                  const SizedBox(height: 14),

                  // 4. Resume / CV
                  _buildDocCard(
                    type: 'resume',
                    title: 'Teacher Resume / CV',
                    subtitle: 'Latest updated curriculum vitae (PDF)',
                    icon: Icons.description_outlined,
                    isRequired: false,
                    docs: docs,
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _buildStatusOverviewCard(String status, List<dynamic> docs) {
    Color statusColor;
    String statusTitle;
    String statusDesc;
    IconData statusIcon;

    final verifiedCount = docs.where((d) => d['verification_status'] == 'verified').length;

    switch (status) {
      case 'approved':
        statusColor = AppConstants.accentEmerald;
        statusTitle = 'KYC Verified & Faculty Active';
        statusDesc = 'Your faculty profile is fully verified. All authoring privileges are unlocked.';
        statusIcon = Icons.verified_user_rounded;
        break;
      case 'changes_required':
        statusColor = AppConstants.accentPurple;
        statusTitle = 'Action Required: Update Documents';
        statusDesc = 'The review board requested changes. Please re-upload the marked files below.';
        statusIcon = Icons.edit_note_rounded;
        break;
      case 'rejected':
        statusColor = AppConstants.accentRose;
        statusTitle = 'Application Ineligible';
        statusDesc = 'Documents did not meet criteria. Contact support for re-evaluation.';
        statusIcon = Icons.cancel_rounded;
        break;
      default:
        statusColor = AppConstants.accentAmber;
        statusTitle = 'KYC Documents In Review';
        statusDesc = 'Documents submitted and undergoing compliance verification (24-48 hrs).';
        statusIcon = Icons.hourglass_top_rounded;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppConstants.cardDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: statusColor.withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 6,
            offset: const Offset(0, 2),
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
                      statusTitle,
                      style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14.5, color: statusColor),
                    ),
                    Text(
                      '${docs.length} Documents Uploaded • $verifiedCount Verified',
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
        ],
      ),
    );
  }

  Widget _buildDocCard({
    required String type,
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isRequired,
    required List<dynamic> docs,
  }) {
    final matchingDoc = docs.firstWhere(
      (d) => d['document_type'] == type,
      orElse: () => null,
    );
    final hasDoc = (matchingDoc != null);
    final isUploading = (_uploadingType == type);
    final docStatus = hasDoc ? (matchingDoc['verification_status'] ?? 'pending').toString() : 'not_uploaded';
    final docId = hasDoc ? int.tryParse(matchingDoc['id'].toString()) : null;
    final isDeleting = (docId != null && _deletingDocId == docId);

    Color badgeColor;
    String badgeText;
    switch (docStatus) {
      case 'verified':
        badgeColor = AppConstants.accentEmerald;
        badgeText = 'VERIFIED ✓';
        break;
      case 'reupload_required':
      case 'invalid':
        badgeColor = AppConstants.accentRose;
        badgeText = 'RE-UPLOAD NEEDED ⚠️';
        break;
      case 'unclear':
        badgeColor = AppConstants.accentPurple;
        badgeText = 'UNCLEAR';
        break;
      case 'pending':
        badgeColor = AppConstants.accentAmber;
        badgeText = 'PENDING REVIEW ⏳';
        break;
      default:
        badgeColor = isRequired ? AppConstants.accentAmber : AppConstants.textMuted;
        badgeText = isRequired ? 'REQUIRED' : 'OPTIONAL';
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppConstants.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasDoc
              ? (docStatus == 'verified' ? AppConstants.accentEmerald.withValues(alpha: 0.4) : AppConstants.accentYellow.withValues(alpha: 0.35))
              : AppConstants.cardBorder,
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
                  color: hasDoc ? AppConstants.accentEmerald.withValues(alpha: 0.15) : AppConstants.accentCyan.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  hasDoc ? Icons.check_circle_rounded : icon,
                  color: hasDoc ? AppConstants.accentEmerald : AppConstants.accentCyan,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            title,
                            style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13.5, color: AppConstants.textPrimary),
                          ),
                        ),
                        if (isRequired)
                          const Text(' *', style: TextStyle(color: AppConstants.accentRose, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(subtitle, style: GoogleFonts.inter(fontSize: 11.5, color: AppConstants.textMuted)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(color: badgeColor.withValues(alpha: 0.4)),
                ),
                child: Text(
                  badgeText,
                  style: GoogleFonts.inter(fontSize: 9.5, fontWeight: FontWeight.w800, color: badgeColor),
                ),
              ),
            ],
          ),
          if (hasDoc) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: AppConstants.surfaceElevated,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppConstants.cardBorder),
              ),
              child: Row(
                children: [
                  const Icon(Icons.insert_drive_file_outlined, size: 16, color: AppConstants.textSecondary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          matchingDoc['original_name']?.toString() ?? 'Document',
                          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppConstants.textPrimary),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${((matchingDoc['file_size'] ?? 0) / 1024).round()} KB • ${matchingDoc['uploaded_at'] != null ? matchingDoc['uploaded_at'].toString().split(' ').first : 'Uploaded'}',
                          style: GoogleFonts.inter(fontSize: 10.5, color: AppConstants.textMuted),
                        ),
                      ],
                    ),
                  ),
                  if (docId != null)
                    IconButton(
                      icon: isDeleting
                          ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: AppConstants.accentRose))
                          : const Icon(Icons.delete_outline, color: AppConstants.accentRose, size: 18),
                      tooltip: 'Remove document',
                      onPressed: isDeleting ? null : () => _deleteDocument(docId, title),
                    ),
                ],
              ),
            ),
            if (matchingDoc['reviewer_note'] != null && matchingDoc['reviewer_note'].toString().isNotEmpty) ...[
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppConstants.accentRose.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, size: 14, color: AppConstants.accentRose),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Reviewer Note: ${matchingDoc['reviewer_note']}',
                        style: GoogleFonts.inter(fontSize: 11, color: AppConstants.accentRose, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: isUploading ? null : () => _pickAndUpload(type, title),
              icon: isUploading
                  ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: AppConstants.accentCyan))
                  : Icon(hasDoc ? Icons.replay : Icons.upload_file, size: 16, color: AppConstants.accentCyan),
              label: Text(
                isUploading
                    ? 'Uploading Document...'
                    : (hasDoc ? 'Replace / Upload New Version' : 'Select & Upload Document'),
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: AppConstants.accentCyan,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: AppConstants.accentCyan.withValues(alpha: 0.4)),
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
