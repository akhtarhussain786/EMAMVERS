import 'package:flutter/material.dart';
import '../../core/api_service.dart';
import '../../core/constants.dart';
import '../../widgets/design_system_widgets.dart';

/// Form a teacher uses to author or edit an MCQ question.
/// Supports Save as Draft and Submit for Approval.
class SubmitQuestionView extends StatefulWidget {
  final Map<String, dynamic>? initialData;

  const SubmitQuestionView({super.key, this.initialData});

  @override
  State<SubmitQuestionView> createState() => _SubmitQuestionViewState();
}

class _SubmitQuestionViewState extends State<SubmitQuestionView> {
  final _formKey = GlobalKey<FormState>();
  final _questionCtrl = TextEditingController();
  final _explanationCtrl = TextEditingController();
  final _imageUrlCtrl = TextEditingController();
  final _marksCtrl = TextEditingController(text: '2.0');
  final _negMarksCtrl = TextEditingController(text: '0.5');
  final _optionCtrls = List.generate(4, (_) => TextEditingController());

  static const _keys = ['A', 'B', 'C', 'D'];

  bool _loadingTaxonomy = true;
  bool _submitting = false;
  String? _taxonomyError;

  List<dynamic> _subjects = [];
  List<dynamic> _chapters = [];
  List<dynamic> _topics = [];
  List<dynamic> _exams = [];
  final Set<int> _examIds = <int>{};

  int? _questionId;
  int? _subjectId;
  int? _chapterId;
  int? _topicId;
  String _difficulty = 'medium';
  String? _correctKey;

  @override
  void initState() {
    super.initState();
    _initFromInitialData();
    _loadTaxonomy();
  }

  void _initFromInitialData() {
    final d = widget.initialData;
    if (d == null) return;

    _questionId = (d['id'] as num?)?.toInt();
    _questionCtrl.text = d['question_text']?.toString() ?? '';
    _explanationCtrl.text = d['explanation']?.toString() ?? '';
    _imageUrlCtrl.text = d['image_url']?.toString() ?? '';
    if (d['marks'] != null) _marksCtrl.text = d['marks'].toString();
    if (d['negative_marks'] != null) _negMarksCtrl.text = d['negative_marks'].toString();
    _difficulty = d['difficulty']?.toString() ?? 'medium';
    _subjectId = (d['subject_id'] as num?)?.toInt();
    _chapterId = (d['chapter_id'] as num?)?.toInt();
    _topicId = (d['topic_id'] as num?)?.toInt();

    final opts = (d['options'] as List?) ?? [];
    for (var i = 0; i < opts.length && i < 4; i++) {
      _optionCtrls[i].text = opts[i]['option_text']?.toString() ?? '';
      if (opts[i]['is_correct'] == 1 || opts[i]['is_correct'] == true) {
        _correctKey = opts[i]['option_key']?.toString();
      }
    }
  }

  @override
  void dispose() {
    _questionCtrl.dispose();
    _explanationCtrl.dispose();
    _imageUrlCtrl.dispose();
    _marksCtrl.dispose();
    _negMarksCtrl.dispose();
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
        _exams = (res is Map ? res['exams'] : null) as List? ?? [];
        _loadingTaxonomy = false;

        if (_subjectId != null) {
          _updateCascadesForSubject(_subjectId!);
        } else if (_subjects.isNotEmpty) {
          _subjectId = _subjects.first['id'] as int?;
          _updateCascadesForSubject(_subjectId!);
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingTaxonomy = false;
        _taxonomyError = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  void _updateCascadesForSubject(int subjectId) {
    final subject = _subjects.firstWhere(
      (s) => s['id'] == subjectId,
      orElse: () => null,
    );
    _chapters = (subject == null ? null : subject['chapters'] as List?) ?? [];
    _topics = (subject == null ? null : subject['topics'] as List?) ?? [];

    if (_chapterId != null && !_chapters.any((c) => c['id'] == _chapterId)) {
      _chapterId = null;
    }
    if (_topicId != null && !_topics.any((t) => t['id'] == _topicId)) {
      _topicId = null;
    }
  }

  void _onSubjectChanged(int? id) {
    if (id == null) return;
    setState(() {
      _subjectId = id;
      _chapterId = null;
      _topicId = null;
      _updateCascadesForSubject(id);
    });
  }

  Future<void> _submit({required bool isDraft}) async {
    if (!isDraft && !_formKey.currentState!.validate()) return;

    if (!isDraft && _correctKey == null) {
      _snack('Mark which option (A, B, C, or D) is the correct answer', isError: true);
      return;
    }

    if (!isDraft) {
      final texts = _optionCtrls.map((c) => c.text.trim().toLowerCase()).toList();
      if (texts.toSet().length != texts.length) {
        _snack('Every option must be distinct. Two options are identical.', isError: true);
        return;
      }
    }

    setState(() => _submitting = true);
    try {
      final payload = {
        if (_questionId != null && _questionId! > 0) 'id': _questionId,
        'subject_id': _subjectId,
        'chapter_id': _chapterId,
        'topic_id': _topicId,
        'exam_ids': _examIds.isNotEmpty ? _examIds.toList() : (_exams.isNotEmpty ? [_exams.first['id']] : []),
        'difficulty': _difficulty,
        'marks': double.tryParse(_marksCtrl.text.trim()) ?? 2.0,
        'negative_marks': double.tryParse(_negMarksCtrl.text.trim()) ?? 0.5,
        'question_text': _questionCtrl.text.trim(),
        'explanation': _explanationCtrl.text.trim(),
        'image_url': _imageUrlCtrl.text.trim(),
        'correct_option': _correctKey ?? 'A',
        'is_draft': isDraft,
        'status': isDraft ? 'draft' : 'review',
        'options': [
          for (var i = 0; i < 4; i++)
            {'option_key': _keys[i], 'option_text': _optionCtrls[i].text.trim()}
        ],
      };

      await ApiService.post('/v1/teacher/questions', payload);
      if (!mounted) return;

      _snack(
        isDraft
            ? 'Question saved as draft!'
            : (_questionId != null ? 'Question updated & resubmitted for admin review!' : 'Question submitted for review. It will go live once approved.'),
        isError: false,
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      _snack(e.toString().replaceAll('Exception: ', ''), isError: true);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
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
    final isEditing = _questionId != null && _questionId! > 0;

    return Scaffold(
      backgroundColor: AppConstants.primaryDark,
      appBar: AppBar(
        backgroundColor: AppConstants.scaffoldDark,
        elevation: 0,
        title: Text(
          isEditing ? 'Edit Question #$_questionId' : 'Author New Question',
          style: const TextStyle(color: AppConstants.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: _loadingTaxonomy
            ? const Center(child: CircularProgressIndicator(color: AppConstants.accentCyan))
            : _taxonomyError != null
                ? EmptyStateWidget(
                    icon: Icons.cloud_off,
                    title: 'Could not load taxonomy',
                    description: _taxonomyError!,
                    buttonLabel: 'Try again',
                    onButtonPressed: _loadTaxonomy,
                  )
                : _buildForm(),
      ),
    );
  }

  Widget _buildForm() {
    final isEditing = _questionId != null && _questionId! > 0;
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(AppConstants.space16),
        children: [
          // Notice banner
          Container(
            padding: const EdgeInsets.all(AppConstants.space12),
            decoration: BoxDecoration(
              color: AppConstants.accentCyan.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
              border: Border.all(color: AppConstants.accentCyan.withValues(alpha: 0.25)),
            ),
            child: const Row(children: [
              Icon(Icons.shield_outlined, color: AppConstants.accentCyan, size: 18),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Questions are reviewed by academic admins before being published to students.',
                  style: TextStyle(color: AppConstants.accentCyan, fontSize: 12, height: 1.35),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 16),

          // Subject dropdown
          const Text('Subject *', style: TextStyle(color: AppConstants.textSecondary, fontSize: 12.5, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          DropdownButtonFormField<int>(
            value: _subjectId,
            dropdownColor: AppConstants.cardDark,
            decoration: _inputDecoration('Choose subject'),
            items: _subjects.map<DropdownMenuItem<int>>((s) {
              return DropdownMenuItem<int>(
                value: s['id'] as int,
                child: Text(s['name']?.toString() ?? '', style: const TextStyle(color: AppConstants.textPrimary, fontSize: 14)),
              );
            }).toList(),
            onChanged: _onSubjectChanged,
            validator: (v) => v == null ? 'Subject is required' : null,
          ),
          const SizedBox(height: 14),

          // Chapter & Topic in row
          Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Chapter (Optional)', style: TextStyle(color: AppConstants.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                DropdownButtonFormField<int?>(
                  value: _chapterId,
                  dropdownColor: AppConstants.cardDark,
                  decoration: _inputDecoration('Select chapter'),
                  items: [
                    const DropdownMenuItem<int?>(value: null, child: Text('None', style: TextStyle(color: AppConstants.textMuted, fontSize: 13))),
                    ..._chapters.map<DropdownMenuItem<int?>>((c) => DropdownMenuItem<int?>(
                          value: c['id'] as int?,
                          child: Text(c['name']?.toString() ?? '', overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppConstants.textPrimary, fontSize: 13)),
                        )),
                  ],
                  onChanged: (v) => setState(() => _chapterId = v),
                ),
              ]),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Topic (Optional)', style: TextStyle(color: AppConstants.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                DropdownButtonFormField<int?>(
                  value: _topicId,
                  dropdownColor: AppConstants.cardDark,
                  decoration: _inputDecoration('Select topic'),
                  items: [
                    const DropdownMenuItem<int?>(value: null, child: Text('None', style: TextStyle(color: AppConstants.textMuted, fontSize: 13))),
                    ..._topics.map<DropdownMenuItem<int?>>((t) => DropdownMenuItem<int?>(
                          value: t['id'] as int?,
                          child: Text(t['name']?.toString() ?? '', overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppConstants.textPrimary, fontSize: 13)),
                        )),
                  ],
                  onChanged: (v) => setState(() => _topicId = v),
                ),
              ]),
            ),
          ]),
          const SizedBox(height: 14),

          // Difficulty & Marks
          Row(children: [
            Expanded(
              flex: 2,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Difficulty', style: TextStyle(color: AppConstants.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: _difficulty,
                  dropdownColor: AppConstants.cardDark,
                  decoration: _inputDecoration('Difficulty'),
                  items: const [
                    DropdownMenuItem(value: 'easy', child: Text('Easy', style: TextStyle(color: AppConstants.accentEmerald))),
                    DropdownMenuItem(value: 'medium', child: Text('Medium', style: TextStyle(color: AppConstants.accentAmber))),
                    DropdownMenuItem(value: 'hard', child: Text('Hard', style: TextStyle(color: AppConstants.accentRose))),
                  ],
                  onChanged: (v) => setState(() => _difficulty = v ?? 'medium'),
                ),
              ]),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Marks (+)', style: TextStyle(color: AppConstants.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _marksCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: _inputDecoration('+2.0'),
                  style: const TextStyle(color: AppConstants.textPrimary, fontSize: 13),
                ),
              ]),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Neg (-)', style: TextStyle(color: AppConstants.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _negMarksCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: _inputDecoration('-0.5'),
                  style: const TextStyle(color: AppConstants.textPrimary, fontSize: 13),
                ),
              ]),
            ),
          ]),
          const SizedBox(height: 16),

          // Question Text
          const Text('Question Text *', style: TextStyle(color: AppConstants.textSecondary, fontSize: 12.5, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          TextFormField(
            controller: _questionCtrl,
            maxLines: 4,
            style: const TextStyle(color: AppConstants.textPrimary, fontSize: 14),
            decoration: _inputDecoration('Enter the full question statement...'),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Question statement is required' : null,
          ),
          const SizedBox(height: 14),

          // Image URL (optional)
          const Text('Optional Diagram / Image URL', style: TextStyle(color: AppConstants.textSecondary, fontSize: 12.5, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          TextFormField(
            controller: _imageUrlCtrl,
            style: const TextStyle(color: AppConstants.textPrimary, fontSize: 13),
            decoration: _inputDecoration('https://... or /uploads/questions/...'),
          ),
          const SizedBox(height: 18),

          // 4 Options
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: const [
            Text('Options & Answer Key *', style: TextStyle(color: AppConstants.textSecondary, fontSize: 13, fontWeight: FontWeight.w700)),
            Text('● Tap circle to mark correct', style: TextStyle(color: AppConstants.accentEmerald, fontSize: 11)),
          ]),
          const SizedBox(height: 8),

          ...List.generate(4, (i) {
            final key = _keys[i];
            final isCorrect = _correctKey == key;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: isCorrect ? AppConstants.accentEmerald.withValues(alpha: 0.1) : AppConstants.surfaceElevated,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isCorrect ? AppConstants.accentEmerald : AppConstants.cardBorder,
                  width: isCorrect ? 1.5 : 1,
                ),
              ),
              child: Row(children: [
                IconButton(
                  icon: Icon(
                    isCorrect ? Icons.check_circle : Icons.radio_button_unchecked,
                    color: isCorrect ? AppConstants.accentEmerald : AppConstants.textMuted,
                  ),
                  onPressed: () => setState(() => _correctKey = key),
                ),
                Text(
                  '$key.',
                  style: TextStyle(
                    color: isCorrect ? AppConstants.accentEmerald : AppConstants.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: _optionCtrls[i],
                    style: const TextStyle(color: AppConstants.textPrimary, fontSize: 13.5),
                    decoration: const InputDecoration(
                      hintText: 'Option text...',
                      hintStyle: TextStyle(color: AppConstants.textMuted, fontSize: 13),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 10),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Option $key cannot be empty' : null,
                  ),
                ),
              ]),
            );
          }),
          const SizedBox(height: 14),

          // Explanation
          const Text('Explanation / Solution *', style: TextStyle(color: AppConstants.textSecondary, fontSize: 12.5, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          TextFormField(
            controller: _explanationCtrl,
            maxLines: 3,
            style: const TextStyle(color: AppConstants.textPrimary, fontSize: 13.5),
            decoration: _inputDecoration('Detailed step-by-step solution shown after exam completion...'),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Explanation is required' : null,
          ),
          const SizedBox(height: 24),

          // Actions
          if (_submitting)
            const Center(child: CircularProgressIndicator(color: AppConstants.accentCyan))
          else
            Row(children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppConstants.cardBorder),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () => _submit(isDraft: true),
                  child: const Text('Save as Draft', style: TextStyle(color: AppConstants.textSecondary, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.accentCyan,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.send_rounded, size: 18),
                  label: Text(
                    isEditing ? 'Resubmit for Approval' : 'Submit for Approval',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  onPressed: () => _submit(isDraft: false),
                ),
              ),
            ]),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppConstants.textMuted, fontSize: 13),
      filled: true,
      fillColor: AppConstants.surfaceElevated,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppConstants.cardBorder)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppConstants.cardBorder)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppConstants.accentCyan, width: 1.5)),
    );
  }
}
