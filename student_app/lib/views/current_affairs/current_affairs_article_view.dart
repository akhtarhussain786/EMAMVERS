import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/api_service.dart';
import 'article_quiz_view.dart';

class CurrentAffairsArticleView extends StatefulWidget {
  final int articleId;

  const CurrentAffairsArticleView({
    super.key,
    required this.articleId,
  });

  @override
  State<CurrentAffairsArticleView> createState() => _CurrentAffairsArticleViewState();
}

class _CurrentAffairsArticleViewState extends State<CurrentAffairsArticleView> {
  bool _loading = true;
  String _errorMsg = '';
  Map<String, dynamic>? _article;

  @override
  void initState() {
    super.initState();
    _loadArticle();
  }

  Future<void> _loadArticle() async {
    setState(() {
      _loading = true;
      _errorMsg = '';
    });

    try {
      final res = await ApiService.get('/current-affairs/${widget.articleId}');
      if (mounted) {
        if (res['status'] == 'success') {
          setState(() {
            _article = res['data'];
            _loading = false;
          });
        } else {
          setState(() {
            _errorMsg = res['message'] ?? 'Failed to load article';
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

  void _openQuiz() {
    if (_article == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ArticleQuizView(
          articleId: widget.articleId,
          articleTitle: _article!['title'] ?? 'Current Affairs Article',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF818cf8)))
          : _errorMsg.isNotEmpty
              ? _buildErrorView()
              : _buildArticleContent(),
      bottomNavigationBar: _article != null ? _buildBottomCta() : null,
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
            const SizedBox(height: 16),
            Text(
              _errorMsg,
              style: GoogleFonts.inter(color: Colors.white70, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loadArticle,
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6366f1)),
              child: Text('Retry', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArticleContent() {
    final a = _article!;
    final String title = a['title'] ?? '';
    final String category = a['category'] ?? 'General';
    final String publishDate = a['publish_date'] ?? '';
    final String summary = a['summary'] ?? '';
    final String content = a['content_body'] ?? '';
    final String examRelevance = a['exam_relevance'] ?? '';
    final String source = a['source_name'] ?? 'ExamVerse News Desk';
    final int readTime = a['read_time_minutes'] ?? 3;
    final List related = (a['related_articles'] as List?) ?? [];

    return CustomScrollView(
      slivers: [
        // Custom App Bar with Hero Image / Gradient
        SliverAppBar(
          expandedHeight: 220,
          pinned: true,
          backgroundColor: const Color(0xFF0F0F1A),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 18),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.auto_awesome, color: Color(0xFF818cf8)),
              tooltip: 'Practice AI Quiz',
              onPressed: _openQuiz,
            ),
          ],
          flexibleSpace: FlexibleSpaceBar(
            background: Stack(
              fit: StackFit.expand,
              children: [
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: _getCategoryGradient(category),
                    ),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        const Color(0xFF0F0F1A).withOpacity(0.8),
                        const Color(0xFF0F0F1A),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  bottom: 16,
                  left: 20,
                  right: 20,
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withOpacity(0.2)),
                        ),
                        child: Text(
                          category,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '· $publishDate · $readTime min read',
                        style: GoogleFonts.inter(fontSize: 11, color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // Article Body
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Headline
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    height: 1.35,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 12),

                // Source Info
                Row(
                  children: [
                    const Icon(Icons.verified_outlined, size: 14, color: Color(0xFF818cf8)),
                    const SizedBox(width: 6),
                    Text(
                      'Source: $source',
                      style: GoogleFonts.inter(fontSize: 11, color: Colors.white54),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // AI Quiz Quick Action Banner
                GestureDetector(
                  onTap: _openQuiz,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF312e81), Color(0xFF4338ca)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFF818cf8).withOpacity(0.4)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.psychology_outlined, color: Colors.white, size: 24),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Practice AI Quiz (4 MCQs)',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Test your knowledge on facts from this article',
                                style: GoogleFonts.inter(fontSize: 11, color: Colors.white70),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 14),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Key Takeaways Box
                if (summary.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: const Color(0xFF818cf8).withOpacity(0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFF818cf8).withOpacity(0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.lightbulb_outline, size: 18, color: Color(0xFF818cf8)),
                            const SizedBox(width: 8),
                            Text(
                              'Key Takeaways',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF818cf8),
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          summary,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: Colors.white.withOpacity(0.85),
                            height: 1.6,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Exam Relevance Section
                if (examRelevance.isNotEmpty) ...[
                  Text(
                    'Exam Relevance',
                    style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: examRelevance.split(',').map((tag) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withOpacity(0.1)),
                        ),
                        child: Text(
                          tag.trim(),
                          style: GoogleFonts.inter(fontSize: 11, color: Colors.white70, fontWeight: FontWeight.w600),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                ],

                // Main Article Content
                Text(
                  'Detailed Analysis',
                  style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white),
                ),
                const SizedBox(height: 12),
                Text(
                  content,
                  style: GoogleFonts.inter(
                    fontSize: 14.5,
                    color: Colors.white.withOpacity(0.8),
                    height: 1.7,
                  ),
                ),
                const SizedBox(height: 36),

                // Related Articles
                if (related.isNotEmpty) ...[
                  Text(
                    'Related Current Affairs',
                    style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white),
                  ),
                  const SizedBox(height: 14),
                  ...related.map((rel) => GestureDetector(
                        onTap: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CurrentAffairsArticleView(articleId: rel['id']),
                            ),
                          );
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.04),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white.withOpacity(0.06)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF6366f1).withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.article_outlined, color: Color(0xFF818cf8), size: 18),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      rel['title'] ?? '',
                                      style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w600, color: Colors.white),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      '${rel['category']} · ${rel['publish_date']}',
                                      style: GoogleFonts.inter(fontSize: 10.5, color: Colors.white38),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.arrow_forward_ios, size: 12, color: Colors.white38),
                            ],
                          ),
                        ),
                      )),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomCta() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      decoration: BoxDecoration(
        color: const Color(0xFF1a1a2e),
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.08))),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton.icon(
          onPressed: _openQuiz,
          icon: const Icon(Icons.auto_awesome, size: 18),
          label: Text(
            'Practice AI Quiz on this Article',
            style: GoogleFonts.inter(fontSize: 14.5, fontWeight: FontWeight.w800),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6366f1),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
      ),
    );
  }

  List<Color> _getCategoryGradient(String category) {
    final c = category.toLowerCase();
    if (c.contains('bank') || c.contains('econ')) {
      return [const Color(0xFF065f46), const Color(0xFF047857)];
    }
    if (c.contains('science') || c.contains('tech') || c.contains('space')) {
      return [const Color(0xFF4c1d95), const Color(0xFF6d28d9)];
    }
    if (c.contains('internat') || c.contains('diploma')) {
      return [const Color(0xFF1e3a8a), const Color(0xFF2563eb)];
    }
    if (c.contains('environ') || c.contains('eco')) {
      return [const Color(0xFF14532d), const Color(0xFF15803d)];
    }
    if (c.contains('gov') || c.contains('policy')) {
      return [const Color(0xFF7c2d12), const Color(0xFFc2410c)];
    }
    return [const Color(0xFF1e1b4b), const Color(0xFF4338ca)];
  }
}
