import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../core/api_service.dart';

class BecomeTeacherView extends StatefulWidget {
  const BecomeTeacherView({super.key});

  @override
  State<BecomeTeacherView> createState() => _BecomeTeacherViewState();
}

class _BecomeTeacherViewState extends State<BecomeTeacherView> {
  bool _isLoading = true;
  bool _isSubmitting = false;
  Map<String, dynamic>? _application;

  // Form controllers
  final _formKey = GlobalKey<FormState>();
  final _highestQualController = TextEditingController(text: 'Bachelor Degree');
  final _degreeController = TextEditingController();
  final _specController = TextEditingController();
  final _institutionController = TextEditingController();
  final _yearController = TextEditingController(text: '2024');
  final _expController = TextEditingController(text: '1.0');
  final _orgController = TextEditingController();
  bool _declarationAccepted = false;

  @override
  void initState() {
    super.initState();
    _fetchApplication();
  }

  Future<void> _fetchApplication() async {
    setState(() => _isLoading = true);
    try {
      final res = await ApiService.getAuth('/v1/teacher/application');
      if (res != null && res['status'] == 'success' && res['data'] != null) {
        setState(() {
          _application = res['data'];
          _highestQualController.text = _application!['highest_qualification'] ?? 'Bachelor Degree';
          _degreeController.text = _application!['degree_name'] ?? '';
          _specController.text = _application!['specialization'] ?? '';
          _institutionController.text = _application!['institution_name'] ?? '';
          _yearController.text = (_application!['passing_year'] ?? 2024).toString();
          _expController.text = (_application!['experience_years'] ?? 1.0).toString();
          _orgController.text = _application!['current_organization'] ?? '';
          _declarationAccepted = _application!['declaration_accepted'] == 1;
        });
      }
    } catch (e) {
      // No active application or network error
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveDraft() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);
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
      if (res['status'] == 'success') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Draft saved successfully!')),
        );
        _fetchApplication();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res['message'] ?? 'Failed to save draft')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _submitApplication() async {
    if (!_declarationAccepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please accept the declaration to submit.')),
      );
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      final res = await ApiService.postAuth('/v1/teacher/application/submit', {
        'declaration_accepted': true,
      });
      if (!mounted) return;
      if (res['status'] == 'success') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Application submitted for verification!')),
        );
        _fetchApplication();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res['message'] ?? 'Submission failed')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Become a Verified Teacher'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatusCard(),
                  const SizedBox(height: 20),
                  if (_application == null || _application!['status'] == 'draft' || _application!['status'] == 'changes_required')
                    _buildApplicationForm()
                  else
                    _buildSubmittedInfo(),
                ],
              ),
            ),
    );
  }

  Widget _buildStatusCard() {
    final status = _application?['status'] ?? 'not_started';
    Color statusColor;
    String statusText;
    IconData statusIcon;

    switch (status) {
      case 'submitted':
      case 'under_review':
        statusColor = Colors.orange;
        statusText = 'Under Review by Admin';
        statusIcon = Icons.hourglass_top_rounded;
        break;
      case 'approved':
        statusColor = Colors.green;
        statusText = 'Verified Teacher Active';
        statusIcon = Icons.verified_user_rounded;
        break;
      case 'changes_required':
        statusColor = Colors.purple;
        statusText = 'Action Required / Re-upload Docs';
        statusIcon = Icons.edit_note_rounded;
        break;
      case 'rejected':
        statusColor = Colors.red;
        statusText = 'Application Denied';
        statusIcon = Icons.cancel_rounded;
        break;
      default:
        statusColor = Colors.blue;
        statusText = 'Application in Draft';
        statusIcon = Icons.assignment_outlined;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(statusIcon, color: statusColor, size: 36),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  statusText,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: statusColor),
                ),
                if (_application?['application_no'] != null)
                  Text(
                    'App ID: ${_application!['application_no']}',
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                if (_application?['reviewer_message'] != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'Admin Note: ${_application!['reviewer_message']}',
                      style: const TextStyle(fontSize: 12, color: Colors.purple, fontWeight: FontWeight.w500),
                    ),
                  ),
              ],
            ),
          ),
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
          const Text('Academic & Professional Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          TextFormField(
            controller: _highestQualController,
            decoration: const InputDecoration(labelText: 'Highest Qualification (e.g. Master, B.Tech, M.Sc)', border: OutlineInputBorder()),
            validator: (v) => v!.isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _degreeController,
            decoration: const InputDecoration(labelText: 'Degree Name (e.g. M.Sc Mathematics)', border: OutlineInputBorder()),
            validator: (v) => v!.isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _institutionController,
            decoration: const InputDecoration(labelText: 'University / Institution Name', border: OutlineInputBorder()),
            validator: (v) => v!.isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _yearController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Passing Year', border: OutlineInputBorder()),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _expController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Experience (Years)', border: OutlineInputBorder()),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _orgController,
            decoration: const InputDecoration(labelText: 'Current Organization / Coaching (Optional)', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 20),
          const Text('Verification Documents', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Please upload your Government ID and Qualification Degree Proof for review.', style: TextStyle(fontSize: 13, color: Colors.black54)),
          const SizedBox(height: 12),
          _buildDocUploadTile('Identity Proof (Aadhaar / PAN / Passport)', 'identity'),
          const SizedBox(height: 8),
          _buildDocUploadTile('Qualification Degree Certificate / Marksheet', 'qualification'),
          const SizedBox(height: 20),
          CheckboxListTile(
            value: _declarationAccepted,
            onChanged: (v) => setState(() => _declarationAccepted = v ?? false),
            title: const Text('I hereby declare that all provided information and documents are authentic and abide by EXAMVERSE content integrity guidelines.', style: TextStyle(fontSize: 12)),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _isSubmitting ? null : _saveDraft,
                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                  child: const Text('Save Draft'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitApplication,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.accentYellow,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Submit for Verification', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDocUploadTile(String label, String type) {
    final docs = _application?['documents'] as List<dynamic>? ?? [];
    final matchingDoc = docs.firstWhere((d) => d['document_type'] == type, orElse: () => null);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Icon(matchingDoc != null ? Icons.check_circle : Icons.upload_file, color: matchingDoc != null ? Colors.green : Colors.grey),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                if (matchingDoc != null)
                  Text(
                    '${matchingDoc['original_name']} • ${matchingDoc['verification_status'].toString().toUpperCase()}',
                    style: const TextStyle(fontSize: 11, color: Colors.green),
                  )
                else
                  const Text('Pending upload (PDF/JPG)', style: TextStyle(fontSize: 11, color: Colors.black45)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmittedInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Submitted Application Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const Divider(height: 20),
          _infoRow('Qualification', '${_application?['highest_qualification']} in ${_application?['degree_name']}'),
          _infoRow('Institution', '${_application?['institution_name']} (${_application?['passing_year']})'),
          _infoRow('Experience', '${_application?['experience_years']} Years'),
          _infoRow('Submitted On', _application?['submitted_at'] ?? 'N/A'),
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
          SizedBox(width: 110, child: Text(label, style: const TextStyle(color: Colors.black54, fontSize: 13))),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13))),
        ],
      ),
    );
  }
}
