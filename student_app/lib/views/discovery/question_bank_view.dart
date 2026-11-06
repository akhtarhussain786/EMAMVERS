import 'package:flutter/material.dart';
import '../../core/api_service.dart';
import '../../core/constants.dart';
import '../../widgets/design_system_widgets.dart';

/// Student Question Bank & Interactive Practice View.
/// Fetches approved and published questions with server-side filters and pagination.
class StudentQuestionBankView extends StatefulWidget {
  final int? initialSubjectId;
  final int? initialCategoryId;

  const StudentQuestionBankView({
    super.key,
    this.initialSubjectId,
    this.initialCategoryId,
  });

  @override
  State<StudentQuestionBankView> createState() => _StudentQuestionBankViewState();
}

class _StudentQuestionBankViewState extends State<StudentQuestionBankView> {
  bool _loading = true;
  String? _error;
  List<dynamic> _questions = [];
  int _page = 1;
  int _totalPages = 1;
  int _totalCount = 0;

  // Filter options
  List<dynamic> _subjects = [];
  int? _selectedSubjectId;
  int? _selectedCategoryId;
  String _selectedDifficulty = '';

  // User interactive answers in practice mode: questionId -> selectedOptionKey
  final Map<int, String> _userAnswers = {};
  final Set<int> _revealedSolutions = {};

  @override
  void initState() {
    super.initState();
    _selectedSubjectId = widget.initialSubjectId;
    _selectedCategoryId = widget.initialCategoryId;
    _loadMetadata();
    _loadQuestions(1);
  }

  Future<void> _loadMetadata() async {
    try {
      final subjRes = await ApiService.get('/v1/practice/options');
      if (!mounted) return;
      setState(() {
        _subjects = (subjRes['subjects'] as List? ?? []);
      });
    } catch (_) {}
  }

  Future<void> _loadQuestions(int page) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final params = <String, dynamic>{
        'page': page,
        'limit': 10,
        'show_solution': 'true',
        if (_selectedSubjectId != null && _selectedSubjectId! > 0)
          'subject_id': _selectedSubjectId,
        if (_selectedCategoryId != null && _selectedCategoryId! > 0)
          'category_id': _selectedCategoryId,
        if (_selectedDifficulty.isNotEmpty)
          'difficulty': _selectedDifficulty,
      };

      final res = await ApiService.get('/v1/questions', params: params);
      if (!mounted) return;

      final data = res as Map<String, dynamic>;
      setState(() {
        _page = page;
        _questions = (data['questions'] as List? ?? []);
        _totalPages = (data['pages'] as int?) ?? 1;
        _totalCount = (data['total'] as int?) ?? 0;
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
        title: const Text(
          'Question Bank & Practice',
          style: TextStyle(color: AppConstants.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: Column(children: [
          // Filter Row
          _buildFilterBar(),

          // Questions List
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppConstants.accentCyan))
                : _error != null
                    ? EmptyStateWidget(
                        icon: Icons.cloud_off,
                        title: 'Could not load questions',
                        description: _error!,
                        buttonLabel: 'Try Again',
                        onButtonPressed: () => _loadQuestions(1),
                      )
                    : _questions.isEmpty
                        ? const EmptyStateWidget(
                            icon: Icons.search_off,
                            title: 'No questions found',
                            description: 'No approved questions match the selected filters.',
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(AppConstants.space16),
                            itemCount: _questions.length + 1,
                            itemBuilder: (context, i) {
                              if (i == _questions.length) {
                                return _buildPaginationNav();
                              }
                              return _buildQuestionCard(_questions[i] as Map<String, dynamic>);
                            },
                          ),
          ),
        ]),
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: AppConstants.scaffoldDark,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(children: [
          // Difficulty Chips
          _diffChip('', 'All Levels'),
          const SizedBox(width: 6),
          _diffChip('easy', 'Easy'),
          const SizedBox(width: 6),
          _diffChip('medium', 'Medium'),
          const SizedBox(width: 6),
          _diffChip('hard', 'Hard'),
          const SizedBox(width: 14),

          // Subject Chips
          if (_subjects.isNotEmpty) ...[
            ..._subjects.take(5).map((s) {
              final sid = s['subject_id'] as int?;
              final sname = s['subject_name']?.toString() ?? '';
              final selected = _selectedSubjectId == sid;
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: GestureDetector(
                  onTap: () {
                    setState(() => _selectedSubjectId = selected ? null : sid);
                    _loadQuestions(1);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: selected ? AppConstants.accentPurple.withValues(alpha: 0.25) : AppConstants.surfaceElevated,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: selected ? AppConstants.accentPurple : AppConstants.cardBorder),
                    ),
                    child: Text(
                      sname,
                      style: TextStyle(
                        color: selected ? AppConstants.accentPurple : AppConstants.textSecondary,
                        fontSize: 12,
                        fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(width: 8),
          ],

          // Total Count Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppConstants.surfaceElevated,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppConstants.cardBorder),
            ),
            child: Text(
              '$_totalCount Questions',
              style: const TextStyle(color: AppConstants.accentCyan, fontSize: 11.5, fontWeight: FontWeight.bold),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _diffChip(String val, String label) {
    final selected = _selectedDifficulty == val;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedDifficulty = val);
        _loadQuestions(1);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppConstants.accentCyan.withValues(alpha: 0.2) : AppConstants.surfaceElevated,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppConstants.accentCyan : AppConstants.cardBorder,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? AppConstants.accentCyan : AppConstants.textSecondary,
            fontSize: 12,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildQuestionCard(Map<String, dynamic> q) {
    final qId = (q['id'] as num).toInt();
    final options = (q['options'] as List? ?? []);
    final selectedKey = _userAnswers[qId];
    final isSolutionRevealed = _revealedSolutions.contains(qId);
    final imageUrl = q['image_url']?.toString();
    final explanation = q['explanation']?.toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(AppConstants.space16),
      decoration: BoxDecoration(
        color: AppConstants.cardDark,
        borderRadius: BorderRadius.circular(AppConstants.radiusCard),
        border: Border.all(color: AppConstants.cardBorder),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Meta header
        Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppConstants.accentPurple.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              q['subject_name']?.toString() ?? 'General',
              style: const TextStyle(color: AppConstants.accentPurple, fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ),
          if (q['chapter_name'] != null && q['chapter_name'].toString().isNotEmpty) ...[
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                '• ${q['chapter_name']}',
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppConstants.textMuted, fontSize: 11),
              ),
            ),
          ],
          const Spacer(),
          _buildDiffBadge(q['difficulty']?.toString() ?? 'medium'),
        ]),
        const SizedBox(height: 12),

        // Question Statement
        Text(
          q['question_text']?.toString() ?? '',
          style: const TextStyle(
            color: AppConstants.textPrimary,
            fontSize: 14.5,
            fontWeight: FontWeight.w600,
            height: 1.45,
          ),
        ),

        // Attached image if available
        if (imageUrl != null && imageUrl.isNotEmpty) ...[
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              imageUrl.startsWith('http') ? imageUrl : (AppConstants.formatImageUrl(imageUrl) ?? imageUrl),
              height: 140,
              width: double.infinity,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
            ),
          ),
        ],
        const SizedBox(height: 12),

        // Interactive Options
        ...options.map((opt) {
          final key = opt['option_key']?.toString() ?? '';
          final text = opt['option_text']?.toString() ?? '';
          final isCorrect = opt['is_correct'] == 1 || opt['is_correct'] == true;
          final isUserSelected = selectedKey == key;

          Color borderColor = AppConstants.cardBorder;
          Color bgColor = AppConstants.surfaceElevated;
          Color textColor = AppConstants.textSecondary;
          IconData icon = Icons.radio_button_unchecked;
          Color iconColor = AppConstants.textMuted;

          if (selectedKey != null) {
            if (isCorrect) {
              borderColor = AppConstants.accentEmerald;
              bgColor = AppConstants.accentEmerald.withValues(alpha: 0.12);
              textColor = AppConstants.accentEmerald;
              icon = Icons.check_circle;
              iconColor = AppConstants.accentEmerald;
            } else if (isUserSelected) {
              borderColor = AppConstants.accentRose;
              bgColor = AppConstants.accentRose.withValues(alpha: 0.12);
              textColor = AppConstants.accentRose;
              icon = Icons.cancel;
              iconColor = AppConstants.accentRose;
            }
          }

          return GestureDetector(
            onTap: () {
              if (selectedKey == null) {
                setState(() {
                  _userAnswers[qId] = key;
                  _revealedSolutions.add(qId);
                });
              }
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: borderColor),
              ),
              child: Row(children: [
                Icon(icon, color: iconColor, size: 16),
                const SizedBox(width: 8),
                Text(
                  '$key.',
                  style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    text,
                    style: TextStyle(color: textColor, fontSize: 13),
                  ),
                ),
              ]),
            ),
          );
        }),

        // Solution Accordion
        if (selectedKey != null && explanation != null && explanation.isNotEmpty) ...[
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () {
              setState(() {
                if (isSolutionRevealed) {
                  _revealedSolutions.remove(qId);
                } else {
                  _revealedSolutions.add(qId);
                }
              });
            },
            child: Row(children: [
              Icon(
                isSolutionRevealed ? Icons.visibility_off_outlined : Icons.lightbulb_outline,
                color: AppConstants.accentCyan,
                size: 15,
              ),
              const SizedBox(width: 6),
              Text(
                isSolutionRevealed ? 'Hide Explanation' : 'View Detailed Solution',
                style: const TextStyle(color: AppConstants.accentCyan, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ]),
          ),
          if (isSolutionRevealed) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppConstants.accentCyan.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border(left: BorderSide(color: AppConstants.accentCyan.withValues(alpha: 0.6), width: 3)),
              ),
              child: Text(
                explanation,
                style: const TextStyle(color: AppConstants.textPrimary, fontSize: 12.5, height: 1.45),
              ),
            ),
          ],
        ],
      ]),
    );
  }

  Widget _buildDiffBadge(String diff) {
    Color color;
    switch (diff.toLowerCase()) {
      case 'easy':
        color = AppConstants.accentEmerald;
        break;
      case 'hard':
        color = AppConstants.accentRose;
        break;
      default:
        color = AppConstants.accentAmber;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        diff.toUpperCase(),
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildPaginationNav() {
    if (_totalPages <= 1) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        if (_page > 1)
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppConstants.cardDark),
            onPressed: () => _loadQuestions(_page - 1),
            child: const Text('Previous', style: TextStyle(color: AppConstants.textPrimary)),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Page $_page of $_totalPages',
            style: const TextStyle(color: AppConstants.textSecondary, fontSize: 13),
          ),
        ),
        if (_page < _totalPages)
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppConstants.cardDark),
            onPressed: () => _loadQuestions(_page + 1),
            child: const Text('Next', style: TextStyle(color: AppConstants.textPrimary)),
          ),
      ]),
    );
  }
}

