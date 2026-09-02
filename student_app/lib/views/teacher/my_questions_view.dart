import 'package:flutter/material.dart';
import '../../core/api_service.dart';
import '../../core/constants.dart';
import '../../widgets/design_system_widgets.dart';
import 'teacher_dashboard_view.dart' show StatusChip;

/// A teacher's own submissions, filterable by review state.
/// Rejected items show the admin's reason so the teacher can act on it.
class MyQuestionsView extends StatefulWidget {
  const MyQuestionsView({super.key});

  @override
  State<MyQuestionsView> createState() => _MyQuestionsViewState();
}

class _MyQuestionsViewState extends State<MyQuestionsView> {
  static const _filters = {
    '': 'All',
    'review': 'In review',
    'published': 'Approved',
    'rejected': 'Needs changes',
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.primaryDark,
      appBar: AppBar(
        backgroundColor: AppConstants.scaffoldDark,
        elevation: 0,
        title: const Text('My Submissions',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        child: Column(children: [
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
                      fontSize: 12.5,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                          color: selected ? AppConstants.accentCyan : AppConstants.cardBorder),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppConstants.accentCyan))
                : _questions.isEmpty
                    ? EmptyStateWidget(
                        icon: _error != null ? Icons.cloud_off : Icons.inbox_outlined,
                        title: _error != null ? 'Could not load submissions' : 'Nothing here yet',
                        description: _error ?? 'Questions you submit will appear here with their review status.',
                        buttonLabel: _error != null ? 'Try again' : null,
                        onButtonPressed: _error != null ? _load : null,
                      )
                    : RefreshIndicator(
                        onRefresh: _load,
                        color: AppConstants.accentCyan,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(AppConstants.space16),
                          itemCount: _questions.length,
                          itemBuilder: (context, i) => _questionCard(_questions[i]),
                        ),
                      ),
          ),
        ]),
      ),
    );
  }

  Widget _questionCard(dynamic q) {
    final options = (q['options'] as List?) ?? [];
    final rejection = q['rejection_reason']?.toString();

    return ExamVerseCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
            child: Wrap(spacing: 6, runSpacing: 6, children: [
              _tag(q['subject_name']?.toString() ?? 'No subject', AppConstants.accentPurple),
              if (q['topic_name'] != null) _tag(q['topic_name'].toString(), AppConstants.accentBlue),
              _tag(q['difficulty']?.toString() ?? 'medium', AppConstants.accentAmber),
            ]),
          ),
          const SizedBox(width: 8),
          StatusChip(status: q['status']?.toString() ?? ''),
        ]),
        const SizedBox(height: 12),
        Text(q['question_text']?.toString() ?? '(no text)',
            style: const TextStyle(
                color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600, height: 1.45)),
        const SizedBox(height: 10),
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
              Text('${o['option_key']}.',
                  style: TextStyle(
                      color: correct ? AppConstants.accentEmerald : AppConstants.textMuted,
                      fontWeight: FontWeight.bold,
                      fontSize: 12.5)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(o['option_text']?.toString() ?? '',
                    style: TextStyle(
                        color: correct ? AppConstants.accentEmerald : AppConstants.textSecondary,
                        fontSize: 12.5)),
              ),
              if (correct)
                const Icon(Icons.check_circle, color: AppConstants.accentEmerald, size: 15),
            ]),
          );
        }),
        if (rejection != null && rejection.isNotEmpty) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppConstants.accentRose.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border(
                  left: BorderSide(
                      color: AppConstants.accentRose.withValues(alpha: 0.6), width: 3)),
            ),
            child: Text('Reviewer feedback: $rejection',
                style: const TextStyle(
                    color: AppConstants.accentRose, fontSize: 12, height: 1.4)),
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
