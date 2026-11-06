import 'package:flutter/material.dart';
import '../../core/api_service.dart';
import '../../core/constants.dart';
import '../../widgets/design_system_widgets.dart';
import 'teacher_dashboard_view.dart' show StatusChip;
import 'submit_question_view.dart';

/// A teacher's own submissions, filterable by review state.
/// Supports viewing admin comments, and editing/resubmitting questions.
class MyQuestionsView extends StatefulWidget {
  const MyQuestionsView({super.key});

  @override
  State<MyQuestionsView> createState() => _MyQuestionsViewState();
}

class _MyQuestionsViewState extends State<MyQuestionsView> {
  static const _filters = {
    '': 'All',
    'review': 'Pending (In Review)',
    'changes_requested': 'Changes Requested',
    'published': 'Approved (Live)',
    'rejected': 'Rejected',
    'draft': 'Drafts',
  };

  String _filter = '';
  bool _loading = true;
  String? _error;
  List<dynamic> _questions = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await ApiService.get('/v1/teacher/questions',
          params: _filter.isEmpty ? null : {'status': _filter});
      if (!mounted) return;
      setState(() {
        _questions = (res is Map ? res['questions'] : null) as List? ?? [];
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  Future<void> _openEdit(Map<String, dynamic> question) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SubmitQuestionView(initialData: question),
      ),
    );
    if (result == true) {
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.primaryDark,
      appBar: AppBar(
        backgroundColor: AppConstants.scaffoldDark,
        elevation: 0,
        title: const Text('My Questions & Submissions',
            style: TextStyle(color: AppConstants.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppConstants.textSecondary),
            onPressed: _load,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppConstants.accentCyan,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add),
        label: const Text('New Question', style: TextStyle(fontWeight: FontWeight.bold)),
        onPressed: () async {
          final res = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SubmitQuestionView()),
          );
          if (res == true) _load();
        },
      ),
      body: SafeArea(
        child: Column(children: [
          // Filter Chips
          SizedBox(
            height: 52,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppConstants.space16, vertical: 8),
              children: _filters.entries.map((e) {
                final selected = _filter == e.key;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(e.value),
                    selected: selected,
                    onSelected: (_) {
                      setState(() => _filter = e.key);
                      _load();
                    },
                    selectedColor: AppConstants.accentCyan.withValues(alpha: 0.25),
                    backgroundColor: AppConstants.cardDark,
                    labelStyle: TextStyle(
                      color: selected ? AppConstants.accentCyan : AppConstants.textSecondary,
                      fontSize: 12,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: selected ? AppConstants.accentCyan : AppConstants.cardBorder,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // Questions List
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppConstants.accentCyan))
                : _questions.isEmpty
                    ? EmptyStateWidget(
                        icon: _error != null ? Icons.cloud_off : Icons.inbox_outlined,
                        title: _error != null ? 'Could not load questions' : 'No questions found',
                        description: _error ?? 'Questions you create or submit for approval will appear here.',
                        buttonLabel: _error != null ? 'Try again' : null,
                        onButtonPressed: _error != null ? _load : null,
                      )
                    : RefreshIndicator(
                        onRefresh: _load,
                        color: AppConstants.accentCyan,
                        child: ListView.builder(
                          padding: const EdgeInsets.only(
                            left: AppConstants.space16,
                            right: AppConstants.space16,
                            top: AppConstants.space8,
                            bottom: 80,
                          ),
                          itemCount: _questions.length,
                          itemBuilder: (context, i) => _questionCard(_questions[i] as Map<String, dynamic>),
                        ),
                      ),
          ),
        ]),
      ),
    );
  }

  Widget _questionCard(Map<String, dynamic> q) {
    final options = (q['options'] as List?) ?? [];
    final status = q['status']?.toString() ?? 'draft';
    final adminComment = (q['admin_comment']?.toString() ?? q['rejection_reason']?.toString()) ?? '';
    final imageUrl = q['image_url']?.toString();
    final canEdit = status == 'draft' || status == 'changes_requested' || status == 'rejected';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppConstants.cardDark,
        borderRadius: BorderRadius.circular(AppConstants.radiusCard),
        border: Border.all(
          color: status == 'changes_requested'
              ? AppConstants.accentPurple.withValues(alpha: 0.5)
              : (status == 'rejected'
                  ? AppConstants.accentRose.withValues(alpha: 0.4)
                  : AppConstants.cardBorder),
        ),
      ),
      padding: const EdgeInsets.all(AppConstants.space16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Meta header
        Row(children: [
          Expanded(
            child: Wrap(spacing: 6, runSpacing: 6, children: [
              _tag(q['subject_name']?.toString() ?? 'Subject', AppConstants.accentPurple),
              if (q['chapter_name'] != null && q['chapter_name'].toString().isNotEmpty)
                _tag(q['chapter_name'].toString(), AppConstants.accentBlue),
              if (q['topic_name'] != null && q['topic_name'].toString().isNotEmpty)
                _tag(q['topic_name'].toString(), AppConstants.accentCyan),
              _tag(q['difficulty']?.toString() ?? 'medium', AppConstants.accentAmber),
            ]),
          ),
          const SizedBox(width: 8),
          StatusChip(status: status),
        ]),
        const SizedBox(height: 12),

        // Question Statement
        Text(
          q['question_text']?.toString() ?? '(no text)',
          style: const TextStyle(
            color: AppConstants.textPrimary,
            fontSize: 14.5,
            fontWeight: FontWeight.w600,
            height: 1.45,
          ),
        ),

        // Attached image preview if available
        if (imageUrl != null && imageUrl.isNotEmpty) ...[
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              color: AppConstants.surfaceElevated,
              padding: const EdgeInsets.all(4),
              child: Image.network(
                imageUrl.startsWith('http') ? imageUrl : (AppConstants.formatImageUrl(imageUrl) ?? imageUrl),
                height: 120,
                width: double.infinity,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
              ),
            ),
          ),
        ],
        const SizedBox(height: 10),

        // 4 Options
        ...options.map((o) {
          final correct = o['is_correct'] == 1 || o['is_correct'] == true;
          return Container(
            margin: const EdgeInsets.only(bottom: 4),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: correct
                  ? AppConstants.accentEmerald.withValues(alpha: 0.12)
                  : AppConstants.surfaceElevated,
              borderRadius: BorderRadius.circular(8),
              border: correct
                  ? Border.all(color: AppConstants.accentEmerald.withValues(alpha: 0.4))
                  : null,
            ),
            child: Row(children: [
              Text(
                '${o['option_key']}.',
                style: TextStyle(
                  color: correct ? AppConstants.accentEmerald : AppConstants.textMuted,
                  fontWeight: FontWeight.bold,
                  fontSize: 12.5,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  o['option_text']?.toString() ?? '',
                  style: TextStyle(
                    color: correct ? AppConstants.accentEmerald : AppConstants.textSecondary,
                    fontSize: 12.5,
                  ),
                ),
              ),
              if (correct)
                const Icon(Icons.check_circle, color: AppConstants.accentEmerald, size: 15),
            ]),
          );
        }),

        // Solution
        if (q['explanation'] != null && q['explanation'].toString().isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppConstants.accentCyan.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(8),
              border: Border(left: BorderSide(color: AppConstants.accentCyan.withValues(alpha: 0.5), width: 3)),
            ),
            child: Text(
              'Solution: ${q['explanation']}',
              style: const TextStyle(color: AppConstants.textSecondary, fontSize: 12, height: 1.4),
            ),
          ),
        ],

        // Admin Feedback / Reviewer Instructions Banner
        if (adminComment.isNotEmpty) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: status == 'changes_requested'
                  ? AppConstants.accentPurple.withValues(alpha: 0.12)
                  : AppConstants.accentRose.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border(
                left: BorderSide(
                  color: status == 'changes_requested'
                      ? AppConstants.accentPurple.withValues(alpha: 0.8)
                      : AppConstants.accentRose.withValues(alpha: 0.8),
                  width: 3.5,
                ),
              ),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Icon(
                  status == 'changes_requested' ? Icons.info_outline : Icons.error_outline,
                  color: status == 'changes_requested' ? AppConstants.accentPurple : AppConstants.accentRose,
                  size: 15,
                ),
                const SizedBox(width: 6),
                Text(
                  status == 'changes_requested' ? 'Admin Revision Instructions:' : 'Rejection Reason:',
                  style: TextStyle(
                    color: status == 'changes_requested' ? AppConstants.accentPurple : AppConstants.accentRose,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ]),
              const SizedBox(height: 4),
              Text(
                adminComment,
                style: const TextStyle(color: AppConstants.textPrimary, fontSize: 12.5, height: 1.4),
              ),
            ]),
          ),
        ],

        // Edit & Resubmit Action Button
        if (canEdit) ...[
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: status == 'changes_requested'
                    ? AppConstants.accentPurple
                    : (status == 'rejected' ? AppConstants.accentRose : AppConstants.accentCyan),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              icon: const Icon(Icons.edit_note, size: 17),
              label: Text(
                status == 'changes_requested'
                    ? 'Apply Changes & Resubmit'
                    : (status == 'rejected' ? 'Edit & Resubmit' : 'Edit & Submit'),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
              ),
              onPressed: () => _openEdit(q),
            ),
          ),
        ],
      ]),
    );
  }

  Widget _tag(String text, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(99),
        ),
        child: Text(text, style: TextStyle(color: color, fontSize: 10.5, fontWeight: FontWeight.w600)),
      );
}
