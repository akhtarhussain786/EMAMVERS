import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/api_service.dart';

class ArticleQuizView extends StatefulWidget {
  final int articleId;
  final String articleTitle;

  const ArticleQuizView({
    super.key,
    required this.articleId,
    required this.articleTitle,
  });

  @override
  State<ArticleQuizView> createState() => _ArticleQuizViewState();
}

class _ArticleQuizViewState extends State<ArticleQuizView> {
  bool _loading = true;
  String _errorMsg = '';
  List<dynamic> _questions = [];
  int _currentIndex = 0;
  String? _selectedOption;
  bool _hasAnswered = false;
  int _score = 0;
  bool _quizFinished = false;

  @override
  void initState() {
    super.initState();
    _loadOrGenerateQuiz();
  }

  Future<void> _loadOrGenerateQuiz({bool forceNew = false}) async {
    setState(() {
      _loading = true;
      _errorMsg = '';
      _currentIndex = 0;
      _selectedOption = null;
      _hasAnswered = false;
      _score = 0;
      _quizFinished = false;
    });

    try {
      final res = await ApiService.postAuth(
        '/current-affairs/${widget.articleId}/generate-quiz${forceNew ? '?force=1' : ''}',
        {},
      );

      if (mounted) {
        if (res['status'] == 'success') {
          setState(() {
            _questions = res['data']?['questions'] ?? [];
            _loading = false;
          });
        } else {
          setState(() {
            _errorMsg = res['message'] ?? 'Failed to generate quiz';
            _loading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMsg = e.toString();
          _loading = false;
        });
      }
    }
  }

  void _selectOption(String optionKey) {
    if (_hasAnswered) return;

    final currentQ = _questions[_currentIndex];
    final String correct = (currentQ['correct_option'] ?? 'A').toString().toUpperCase();

    setState(() {
      _selectedOption = optionKey;
      _hasAnswered = true;
      if (optionKey == correct) {
        _score++;
      }
    });
  }

  void _nextQuestion() {
    if (_currentIndex < _questions.length - 1) {
      setState(() {
        _currentIndex++;
        _selectedOption = null;
        _hasAnswered = false;
      });
    } else {
      setState(() {
        _quizFinished = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F0F1A),
        title: Text(
          'AI Article Quiz',
          style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white70),
            tooltip: 'Regenerate Questions',
            onPressed: () => _loadOrGenerateQuiz(forceNew: true),
          ),
        ],
      ),
      body: SafeArea(
        child: _loading
            ? _buildLoadingView()
            : _errorMsg.isNotEmpty
                ? _buildErrorView()
                : _quizFinished
                  ? _buildScorecardView()
                  : _buildQuestionPlayer(),
      ),
    );
  }

  Widget _buildLoadingView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 56,
              height: 56,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: Color(0xFF818cf8),
                strokeCap: StrokeCap.round,
              ),
            ),
            const SizedBox(height: 28),
            Text(
              'Analyzing Article with AI...',
              style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              'Formulating exam-standard questions from the facts in:\n"${widget.articleTitle}"',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 12, color: Colors.white54, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.warning_amber_rounded, size: 48, color: Colors.amber),
            const SizedBox(height: 16),
            Text(
              'Quiz Generation Failed',
              style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMsg,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: Colors.white60, fontSize: 13),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => _loadOrGenerateQuiz(forceNew: true),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6366f1)),
              child: Text('Retry Generation', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionPlayer() {
    if (_questions.isEmpty) {
      return Center(
        child: Text('No questions found for this article.', style: GoogleFonts.inter(color: Colors.white54)),
      );
    }

    final q = _questions[_currentIndex];
    final String correct = (q['correct_option'] ?? 'A').toString().toUpperCase();
    final double progress = (_currentIndex + 1) / _questions.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Progress & Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366f1).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Question ${_currentIndex + 1} of ${_questions.length}',
                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF818cf8)),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Score: $_score / ${_questions.length}',
                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white70),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Linear Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white.withOpacity(0.08),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF6366f1)),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 24),

          // Question Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1a1a2e), Color(0xFF16213e)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: Text(
              q['question_text'] ?? '',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Options List
          for (final optKey in ['A', 'B', 'C', 'D']) ...[
            _buildOptionCard(
              optionKey: optKey,
              optionText: q['option_${optKey.toLowerCase()}'] ?? '',
              correctKey: correct,
            ),
            const SizedBox(height: 10),
          ],

          // Explanation Banner (Shown after answering)
          if (_hasAnswered) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: (_selectedOption == correct ? Colors.green : Colors.amber).withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: (_selectedOption == correct ? Colors.green : Colors.amber).withOpacity(0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        _selectedOption == correct ? Icons.check_circle : Icons.info_outline,
                        size: 18,
                        color: _selectedOption == correct ? Colors.greenAccent : Colors.amberAccent,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _selectedOption == correct ? 'Correct Answer!' : 'Incorrect (Correct: $correct)',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: _selectedOption == correct ? Colors.greenAccent : Colors.amberAccent,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    q['explanation'] ?? 'No explanation available.',
                    style: GoogleFonts.inter(fontSize: 12, color: Colors.white70, height: 1.5),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Next Question Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _nextQuestion,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366f1),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(
                  _currentIndex < _questions.length - 1 ? 'Next Question →' : 'Finish Quiz & View Results',
                  style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildOptionCard({
    required String optionKey,
    required String optionText,
    required String correctKey,
  }) {
    Color borderColor = Colors.white.withOpacity(0.08);
    Color bgColor = Colors.white.withOpacity(0.03);
    Color textColor = Colors.white70;

    if (_hasAnswered) {
      if (optionKey == correctKey) {
        borderColor = Colors.greenAccent;
        bgColor = Colors.green.withOpacity(0.15);
        textColor = Colors.greenAccent;
      } else if (optionKey == _selectedOption) {
        borderColor = Colors.redAccent;
        bgColor = Colors.red.withOpacity(0.15);
        textColor = Colors.redAccent;
      }
    }

    return GestureDetector(
      onTap: () => _selectOption(optionKey),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.06),
              ),
              child: Center(
                child: Text(
                  optionKey,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    color: textColor,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                optionText,
                style: GoogleFonts.inter(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScorecardView() {
    final double percentage = (_score / _questions.length) * 100;
    final bool passed = percentage >= 75;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: (passed ? Colors.green : const Color(0xFF6366f1)).withOpacity(0.15),
                border: Border.all(
                  color: passed ? Colors.greenAccent : const Color(0xFF818cf8),
                  width: 2.5,
                ),
              ),
              child: Center(
                child: Text(
                  '${percentage.toStringAsFixed(0)}%',
                  style: GoogleFonts.inter(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: passed ? Colors.greenAccent : Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            Text(
              passed ? 'Outstanding Recall!' : 'Good Effort!',
              style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white),
            ),
            const SizedBox(height: 6),
            Text(
              'You answered $_score out of ${_questions.length} questions correctly.',
              style: GoogleFonts.inter(fontSize: 13, color: Colors.white60),
            ),
            const SizedBox(height: 24),

            // Summary Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.04),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.06)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Article Reviewed', style: GoogleFonts.inter(fontSize: 12, color: Colors.white54)),
                      Text('Current Affairs', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF818cf8))),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.articleTitle,
                    style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _loadOrGenerateQuiz(forceNew: true),
                    icon: const Icon(Icons.refresh_rounded, size: 16, color: Colors.white70),
                    label: Text('New Quiz', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: Colors.white.withOpacity(0.2)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6366f1),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text('Done', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
