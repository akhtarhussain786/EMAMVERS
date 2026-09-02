import 'package:flutter/material.dart';
import '../../core/api_service.dart';
import '../../core/constants.dart';
import '../../widgets/design_system_widgets.dart';

/// Form a teacher uses to author one MCQ.
///
/// Everything submitted here lands in the review queue — it is never visible to
/// students until an admin approves it, and the UI says so explicitly.
class SubmitQuestionView extends StatefulWidget {
  const SubmitQuestionView({super.key});

  @override
  State<SubmitQuestionView> createState() => _SubmitQuestionViewState();
}

class _SubmitQuestionViewState extends State<SubmitQuestionView> {
  final _formKey = GlobalKey<FormState>();
  final _questionCtrl = TextEditingController();
  final _explanationCtrl = TextEditingController();
  final _optionCtrls = List.generate(4, (_) => TextEditingController());

  static const _keys = ['A', 'B', 'C', 'D'];

  bool _loadingTaxonomy = true;
  bool _submitting = false;
  String? _taxonomyError;

  List<dynamic> _subjects = [];
  List<dynamic> _topics = [];
  int? _subjectId;
  int? _topicId;
  String _difficulty = 'medium';
  String? _correctKey;

  @override
  void initState() {
    super.initState();
    _loadTaxonomy();
  }

  @override
  void dispose() {
    _questionCtrl.dispose();
    _explanationCtrl.dispose();
    for (final c in _optionCtrls) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _loadTaxonomy() async {
    setState(() {
      _loadingTaxonomy = true;
      _taxonomyError = null;
    });
    try {
      final res = await ApiService.get('/v1/teacher/taxonomy');
      if (!mounted) return;
      setState(() {
        _subjects = (res is Map ? res['subjects'] : null) as List? ?? [];
        _loadingTaxonomy = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingTaxonomy = false;
        _taxonomyError = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  void _onSubjectChanged(int? id) {
    setState(() {
      _subjectId = id;
      // Topics belong to a subject, so a subject change invalidates the choice.
      _topicId = null;
      final subject = _subjects.firstWhere(
        (s) => s['id'] == id,
        orElse: () => null,
      );
      _topics = (subject == null ? null : subject['topics'] as List?) ?? [];
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_correctKey == null) {
      _snack('Mark which option is the correct answer', isError: true);
      return;
    }

    // Two identical options make the question unanswerable — catch it here
    // rather than letting the reviewer find it.
    final texts = _optionCtrls.map((c) => c.text.trim().toLowerCase()).toList();
    if (texts.toSet().length != texts.length) {
      _snack('Two options are identical. Every option must be distinct.', isError: true);
      return;
    }

    setState(() => _submitting = true);
    try {
      await ApiService.post('/v1/teacher/questions', {
        'subject_id': _subjectId,
        'topic_id': _topicId,
        'difficulty': _difficulty,
        'question_text': _questionCtrl.text.trim(),
        'explanation': _explanationCtrl.text.trim(),
        'correct_option': _correctKey,
        'options': [
          for (var i = 0; i < 4; i++) {'option_key': _keys[i], 'option_text': _optionCtrls[i].text.trim()}
        ],
      });
      if (!mounted) return;
      _snack('Submitted for review. It goes live once an admin approves it.', isError: false);
      _resetForm();
    } catch (e) {
      if (!mounted) return;
      _snack(e.toString().replaceAll('Exception: ', ''), isError: true);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _resetForm() {
    _questionCtrl.clear();
    _explanationCtrl.clear();
    for (final c in _optionCtrls) {
      c.clear();
    }
    setState(() {
      _correctKey = null;
      _topicId = null;
    });
  }

  void _snack(String msg, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? AppConstants.accentRose : AppConstants.accentEmerald,
      duration: const Duration(seconds: 3),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.primaryDark,
      appBar: AppBar(
        backgroundColor: AppConstants.scaffoldDark,
        elevation: 0,
        title: const Text('New Question',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        child: _loadingTaxonomy
            ? const Center(child: CircularProgressIndicator(color: AppConstants.accentCyan))
            : _taxonomyError != null
                ? EmptyStateWidget(
                    icon: Icons.cloud_off,
                    title: 'Could not load subjects',
                    description: _taxonomyError!,
                    buttonLabel: 'Try again',
                    onButtonPressed: _loadTaxonomy,
                  )
                : _buildForm(),
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(AppConstants.space20),
        children: [
          Container(
            padding: const EdgeInsets.all(AppConstants.space12),
            decoration: BoxDecoration(
              color: AppConstants.accentCyan.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
              border: Border.all(color: AppConstants.accentCyan.withValues(alpha: 0.25)),
            ),
            child: const Row(children: [
              Icon(Icons.info_outline, color: AppConstants.accentCyan, size: 18),
              SizedBox(width: 10),
              Expanded(
                child: Text('Submitted questions are reviewed by an admin before students can see them.',
                    style: TextStyle(color: AppConstants.textSecondary, fontSize: 12.5, height: 1.4)),
              ),
            ]),
          ),
          const SizedBox(height: AppConstants.space24),

          _label('Subject'),
          DropdownButtonFormField<int>(
            initialValue: _subjectId,
            dropdownColor: AppConstants.cardDark,
            decoration: _fieldDecoration('Which subject does this belong to?'),
            style: const TextStyle(color: Colors.white, fontSize: 14),
            items: [
              for (final s in _subjects)
                DropdownMenuItem<int>(value: s['id'] as int, child: Text(s['name']?.toString() ?? '')),
            ],
            validator: (v) => v == null ? 'Select a subject' : null,
            onChanged: _onSubjectChanged,
          ),
          const SizedBox(height: AppConstants.space16),

          _label('Topic (optional)'),
          DropdownButtonFormField<int>(
            initialValue: _topicId,
            dropdownColor: AppConstants.cardDark,
            decoration: _fieldDecoration(
                _topics.isEmpty ? 'Choose a subject first' : 'Narrow it down to a topic'),
            style: const TextStyle(color: Colors.white, fontSize: 14),
            items: [
              for (final t in _topics)
                DropdownMenuItem<int>(value: t['id'] as int, child: Text(t['name']?.toString() ?? '')),
            ],
            onChanged: _topics.isEmpty ? null : (v) => setState(() => _topicId = v),
          ),
          const SizedBox(height: AppConstants.space16),

          _label('Difficulty'),
          Row(
            children: ['easy', 'medium', 'hard'].map((d) {
              final selected = _difficulty == d;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _difficulty = d),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: selected ? AppConstants.accentCyan.withValues(alpha: 0.18) : AppConstants.cardDark,
                      borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
                      border: Border.all(
                          color: selected ? AppConstants.accentCyan : AppConstants.cardBorder),
                    ),
                    child: Center(
                      child: Text(d[0].toUpperCase() + d.substring(1),
                          style: TextStyle(
                              color: selected ? AppConstants.accentCyan : AppConstants.textSecondary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600)),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: AppConstants.space24),

          _label('Question'),
          TextFormField(
            controller: _questionCtrl,
            maxLines: 4,
            maxLength: 2000,
            style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.5),
            decoration: _fieldDecoration('Type the full question as a student will read it'),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Question text is required' : null,
          ),
          const SizedBox(height: AppConstants.space8),

          _label('Options — tap the circle to mark the correct answer'),
          for (var i = 0; i < 4; i++) _optionField(i),
          const SizedBox(height: AppConstants.space16),

          _label('Explanation'),
          TextFormField(
            controller: _explanationCtrl,
            maxLines: 3,
            style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.5),
            decoration: _fieldDecoration('Explain why the correct answer is correct'),
            validator: (v) => (v == null || v.trim().isEmpty)
                ? 'An explanation is required so students learn from the answer'
                : null,
          ),
          const SizedBox(height: AppConstants.space24),

          PrimaryButton(
            label: _submitting ? 'Submitting…' : 'Submit for Review',
            onPressed: _submitting ? null : _submit,
            isLoading: _submitting,
          ),
          const SizedBox(height: AppConstants.space32),
        ],
      ),
    );
  }

  Widget _optionField(int i) {
    final key = _keys[i];
    final isCorrect = _correctKey == key;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: () => setState(() => _correctKey = key),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCorrect ? AppConstants.accentEmerald : AppConstants.cardDark,
                border: Border.all(
                    color: isCorrect ? AppConstants.accentEmerald : AppConstants.cardBorder, width: 1.5),
              ),
              child: Center(
                child: isCorrect
                    ? const Icon(Icons.check, color: Colors.white, size: 18)
                    : Text(key,
                        style: const TextStyle(
                            color: AppConstants.textSecondary, fontWeight: FontWeight.bold, fontSize: 13)),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextFormField(
              controller: _optionCtrls[i],
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: _fieldDecoration('Option $key'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Option $key cannot be empty' : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8, top: 4),
        child: Text(text,
            style: const TextStyle(
                color: AppConstants.textSecondary, fontSize: 12.5, fontWeight: FontWeight.w600)),
      );

  InputDecoration _fieldDecoration(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppConstants.textMuted, fontSize: 13),
        filled: true,
        fillColor: AppConstants.cardDark,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
          borderSide: const BorderSide(color: AppConstants.cardBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
          borderSide: const BorderSide(color: AppConstants.cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
          borderSide: const BorderSide(color: AppConstants.accentCyan),
        ),
      );
}
