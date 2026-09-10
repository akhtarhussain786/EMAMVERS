import 'package:flutter/material.dart';
import '../../core/api_service.dart';
import '../../core/constants.dart';
import '../../widgets/design_system_widgets.dart';

/// Lets a student assemble their own practice mock: exam, subjects, how many
/// questions and how long. The paper is drawn fresh from the bank on Start.
class BuildPracticeView extends StatefulWidget {
  /// Called with the new attempt id and duration once the paper is ready.
  final void Function(int attemptId, int durationMinutes) onStarted;
  const BuildPracticeView({super.key, required this.onStarted});

  @override
  State<BuildPracticeView> createState() => _BuildPracticeViewState();
}

class _BuildPracticeViewState extends State<BuildPracticeView> {
  bool _loading = true;
  bool _starting = false;
  String? _error;

  List<dynamic> _exams = [];
  List<dynamic> _subjects = [];
  List<dynamic> _presets = [];

  int? _examId;
  final Set<int> _subjectIds = <int>{};
  int _questionCount = 25;
  int _durationMinutes = 25;
  String? _difficulty;

  int _minQuestions = 5, _maxQuestions = 100;
  int _minMinutes = 1, _maxMinutes = 180;

  @override
  void initState() {
    super.initState();
    _loadOptions();
  }

  Future<void> _loadOptions({int? examId}) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await ApiService.get('/v1/practice/options',
          params: examId == null ? null : {'exam_id': examId});
      if (!mounted) return;
      final d = res as Map<String, dynamic>;
      setState(() {
        _exams = (d['exams'] as List?) ?? [];
        _subjects = (d['subjects'] as List?) ?? [];
        _presets = (d['presets'] as List?) ?? [];
        _minQuestions = (d['question_range']?['min'] as int?) ?? 5;
        _maxQuestions = (d['question_range']?['max'] as int?) ?? 100;
        _minMinutes = (d['minute_range']?['min'] as int?) ?? 1;
        _maxMinutes = (d['minute_range']?['max'] as int?) ?? 180;
        _examId ??= _exams.isNotEmpty ? _exams.first['id'] as int : null;
        // Drop subjects that are no longer offered for the chosen exam.
        _subjectIds.retainWhere((id) => _subjects.any((s) => s['subject_id'] == id));
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

  int get _available => _subjects
      .where((s) => _subjectIds.contains(s['subject_id']))
      .fold<int>(0, (sum, s) => sum + ((s['available'] as int?) ?? 0));

  Future<void> _start() async {
    if (_examId == null) {
      _snack('Choose an exam first');
      return;
    }
    if (_subjectIds.isEmpty) {
      _snack('Choose at least one subject');
      return;
    }

    setState(() => _starting = true);
    try {
      final res = await ApiService.post('/v1/practice/start', {
        'exam_id': _examId,
        'subject_ids': _subjectIds.toList(),
        'question_count': _questionCount,
        'duration_minutes': _durationMinutes,
        if (_difficulty != null) 'difficulty': _difficulty,
      });
      if (!mounted) return;
      final d = res as Map<String, dynamic>;

      final short = (d['short_by'] as int?) ?? 0;
      if (short > 0) {
        _snack('Only ${d['question_count']} questions were available — starting with those.');
      }
      widget.onStarted(d['attempt_id'] as int, (d['duration_minutes'] as int?) ?? _durationMinutes);
    } catch (e) {
      if (!mounted) return;
      _snack(e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: AppConstants.accentRose,
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
        title: const Text('Build Your Test',
            style: TextStyle(color: AppConstants.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: AppConstants.accentCyan))
            : _error != null
                ? EmptyStateWidget(
                    icon: Icons.cloud_off,
                    title: 'Could not load options',
                    description: _error!,
                    buttonLabel: 'Try again',
                    onButtonPressed: _loadOptions,
                  )
                : _buildForm(),
      ),
    );
  }

  Widget _buildForm() {
    return ListView(
      key: const Key('practice_form'),
      padding: const EdgeInsets.all(AppConstants.space20),
      children: [
        _label('Exam'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final e in _exams)
              ChoiceChip(
                key: Key('exam_${e['id']}'),
                label: Text(e['title']?.toString() ?? ''),
                selected: _examId == e['id'],
                onSelected: (_) {
                  setState(() => _examId = e['id'] as int);
                  _loadOptions(examId: e['id'] as int);
                },
                selectedColor: AppConstants.accentCyan.withValues(alpha: 0.22),
                backgroundColor: AppConstants.cardDark,
                labelStyle: TextStyle(
                  color: _examId == e['id'] ? AppConstants.accentCyan : AppConstants.textSecondary,
                  fontSize: 12.5,
                  fontWeight: _examId == e['id'] ? FontWeight.w700 : FontWeight.w500,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                      color: _examId == e['id'] ? AppConstants.accentCyan : AppConstants.cardBorder),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppConstants.space20),

        _label('Subjects'),
        if (_subjects.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text('No questions are available for this exam yet.',
                style: TextStyle(color: AppConstants.textMuted, fontSize: 13)),
          )
        else
          ..._subjects.map((s) {
            final id = s['subject_id'] as int;
            final selected = _subjectIds.contains(id);
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                key: Key('subject_$id'),
                onTap: () => setState(() {
                  selected ? _subjectIds.remove(id) : _subjectIds.add(id);
                }),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: selected ? AppConstants.surfaceElevated : AppConstants.cardDark,
                    borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
                    border: Border.all(
                        color: selected ? AppConstants.accentCyan : AppConstants.cardBorder),
                  ),
                  child: Row(children: [
                    Icon(selected ? Icons.check_box : Icons.check_box_outline_blank,
                        color: selected ? AppConstants.accentCyan : AppConstants.textMuted, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(s['subject_name']?.toString() ?? '',
                          style: const TextStyle(color: AppConstants.textPrimary, fontSize: 14)),
                    ),
                    Text('${s['available']} available',
                        style: const TextStyle(color: AppConstants.textMuted, fontSize: 11.5)),
                  ]),
                ),
              ),
            );
          }),
        const SizedBox(height: AppConstants.space20),

        if (_presets.isNotEmpty) ...[
          _label('Quick presets'),
          Wrap(
            spacing: 8,
            children: [
              for (final p in _presets)
                ActionChip(
                  key: Key('preset_${p['questions']}'),
                  label: Text(p['label']?.toString() ?? ''),
                  backgroundColor: AppConstants.cardDark,
                  labelStyle: const TextStyle(color: AppConstants.accentCyan, fontSize: 12.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: const BorderSide(color: AppConstants.cardBorder),
                  ),
                  onPressed: () => setState(() {
                    _questionCount = (p['questions'] as int).clamp(_minQuestions, _maxQuestions);
                    _durationMinutes = (p['minutes'] as int).clamp(_minMinutes, _maxMinutes);
                  }),
                ),
            ],
          ),
          const SizedBox(height: AppConstants.space20),
        ],

        _label('Questions: $_questionCount'),
        Slider(
          key: const Key('question_slider'),
          value: _questionCount.toDouble().clamp(_minQuestions.toDouble(), _maxQuestions.toDouble()),
          min: _minQuestions.toDouble(),
          max: _maxQuestions.toDouble(),
          divisions: ((_maxQuestions - _minQuestions) / 5).round().clamp(1, 100),
          label: '$_questionCount',
          activeColor: AppConstants.accentCyan,
          onChanged: (v) => setState(() => _questionCount = v.round()),
        ),
        if (_subjectIds.isNotEmpty && _available < _questionCount)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'Only $_available questions are in the bank for these subjects — '
              'your test will be shorter.',
              style: const TextStyle(color: AppConstants.accentAmber, fontSize: 11.5),
            ),
          ),

        _label('Time limit: $_durationMinutes min'),
        Slider(
          key: const Key('duration_slider'),
          value: _durationMinutes.toDouble().clamp(_minMinutes.toDouble(), _maxMinutes.toDouble()),
          min: _minMinutes.toDouble(),
          max: _maxMinutes.toDouble(),
          divisions: ((_maxMinutes - _minMinutes) / 5).round().clamp(1, 100),
          label: '$_durationMinutes',
          activeColor: AppConstants.accentCyan,
          onChanged: (v) => setState(() => _durationMinutes = v.round()),
        ),
        const SizedBox(height: AppConstants.space16),

        _label('Difficulty'),
        Row(
          children: [
            for (final d in [null, 'easy', 'medium', 'hard'])
              Expanded(
                child: GestureDetector(
                  key: Key('difficulty_${d ?? 'mixed'}'),
                  onTap: () => setState(() => _difficulty = d),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: _difficulty == d
                          ? AppConstants.accentCyan.withValues(alpha: 0.18)
                          : AppConstants.cardDark,
                      borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
                      border: Border.all(
                          color: _difficulty == d ? AppConstants.accentCyan : AppConstants.cardBorder),
                    ),
                    child: Center(
                      child: Text(d == null ? 'Mixed' : d[0].toUpperCase() + d.substring(1),
                          style: TextStyle(
                              color: _difficulty == d
                                  ? AppConstants.accentCyan
                                  : AppConstants.textSecondary,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600)),
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppConstants.space32),

        PrimaryButton(
          key: const Key('start_practice'),
          label: _starting ? 'Building your test…' : 'Start Test',
          onPressed: _starting ? null : _start,
          isLoading: _starting,
        ),
        const SizedBox(height: AppConstants.space32),
      ],
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8, top: 4),
        child: Text(text,
            style: const TextStyle(
                color: AppConstants.textSecondary, fontSize: 12.5, fontWeight: FontWeight.w600)),
      );
}
