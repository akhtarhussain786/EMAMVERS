import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/api_service.dart';
import 'current_affairs_article_view.dart';

class CurrentAffairsView extends StatefulWidget {
  const CurrentAffairsView({super.key});

  @override
  State<CurrentAffairsView> createState() => _CurrentAffairsViewState();
}

class _CurrentAffairsViewState extends State<CurrentAffairsView> {
  final TextEditingController _searchCtrl = TextEditingController();
  bool _loading = true;
  String _errorMsg = '';
  List<dynamic> _articles = [];
  List<String> _categories = ['All'];
  List<String> _recentDates = [];
  String _selectedCategory = 'All';
  String _selectedDate = '';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadArticles();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadArticles() async {
    setState(() {
      _loading = true;
      _errorMsg = '';
    });

    try {
      final params = {
        if (_selectedCategory != 'All') 'category': _selectedCategory,
        if (_selectedDate.isNotEmpty) 'date': _selectedDate,
        if (_searchQuery.isNotEmpty) 'q': _searchQuery,
        'limit': '30',
      };

      final data = await ApiService.get('/v1/current-affairs', params: params);

      if (mounted) {
        final rawCats = (data['categories'] as List?)?.map((e) => e.toString()).toList() ?? [];

        setState(() {
          _articles = (data['articles'] as List?) ?? [];
          _categories = ['All', ...rawCats];
          _recentDates = (data['recent_dates'] as List?)?.map((e) => e.toString()).toList() ?? [];
          _loading = false;
          _errorMsg = '';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMsg = e.toString().replaceAll('Exception: ', '');
          _loading = false;
        });
      }
    }
  }

  void _onArticleTap(int id) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CurrentAffairsArticleView(articleId: id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F0F1A),
        title: Text(
          'Daily Current Affairs',
          style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white70),
            onPressed: _loadArticles,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search & Filters Header
            _buildSearchAndFilters(),

            // Main Article List
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF818cf8)))
                  : _errorMsg.isNotEmpty
                      ? _buildErrorState()
                      : _articles.isEmpty
                          ? _buildEmptyState()
                          : _buildArticleList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F0F1A),
        border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.06))),
      ),
      child: Column(
        children: [
          // Search Field
          TextField(
            controller: _searchCtrl,
            style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Search events, topics, policies...',
              hintStyle: GoogleFonts.inter(color: Colors.white38, fontSize: 13),
              prefixIcon: const Icon(Icons.search, color: Colors.white38, size: 20),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.close, color: Colors.white38, size: 18),
                      onPressed: () {
                        _searchCtrl.clear();
                        setState(() => _searchQuery = '');
                        _loadArticles();
                      },
                    )
                  : null,
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.05),
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            onSubmitted: (val) {
              setState(() => _searchQuery = val.trim());
              _loadArticles();
            },
          ),
          const SizedBox(height: 12),

          // Categories Horizontal List
          SizedBox(
            height: 34,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              itemBuilder: (ctx, i) {
                final cat = _categories[i];
                final isSelected = cat == _selectedCategory;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(cat),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _selectedCategory = cat);
                        _loadArticles();
                      }
                    },
                    selectedColor: const Color(0xFF6366f1),
                    backgroundColor: Colors.white.withValues(alpha: 0.05),
                    labelStyle: GoogleFonts.inter(
                      fontSize: 11.5,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? Colors.white : Colors.white60,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: isSelected ? const Color(0xFF818cf8) : Colors.white.withValues(alpha: 0.08),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (_recentDates.isNotEmpty) ...[
            const SizedBox(height: 10),
            SizedBox(
              height: 34,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _recentDates.length + 1,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final isAllDates = i == 0;
                  final date = isAllDates ? '' : _recentDates[i - 1];
                  final isSelected = _selectedDate == date;

                  return ChoiceChip(
                    label: Text(isAllDates ? 'All dates' : date),
                    selected: isSelected,
                    onSelected: (_) {
                      setState(() => _selectedDate = date);
                      _loadArticles();
                    },
                    selectedColor: const Color(0xFF6366f1),
                    backgroundColor: Colors.white.withValues(alpha: 0.05),
                    labelStyle: GoogleFonts.inter(
                      fontSize: 11.5,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? Colors.white : Colors.white60,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: isSelected ? const Color(0xFF818cf8) : Colors.white.withValues(alpha: 0.08),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildArticleList() {
    return RefreshIndicator(
      onRefresh: _loadArticles,
      color: const Color(0xFF818cf8),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _articles.length,
        itemBuilder: (ctx, i) {
          final a = _articles[i];
          final bool isHero = i == 0 && _searchQuery.isEmpty && _selectedCategory == 'All';

          if (isHero) {
            return _buildHeroCard(a);
          }
          return _buildArticleCard(a);
        },
      ),
    );
  }

  Widget _buildHeroCard(Map<String, dynamic> a) {
    return GestureDetector(
      onTap: () => _onArticleTap(a['id']),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            colors: [Color(0xFF1e1b4b), Color(0xFF312e81)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: const Color(0xFF818cf8).withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFef4444).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFef4444).withValues(alpha: 0.4)),
                        ),
                        child: Text(
                          'BREAKING FOCUS',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFFf87171),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        a['category'] ?? '',
                        style: GoogleFonts.inter(fontSize: 11, color: Colors.white70),
                      ),
                      const Spacer(),
                      const Icon(Icons.auto_awesome, size: 14, color: Color(0xFF818cf8)),
                      const SizedBox(width: 4),
                      Text(
                        'AI Quiz',
                        style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF818cf8)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    a['title'] ?? '',
                    style: GoogleFonts.inter(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      height: 1.35,
                    ),
                  ),
                  if ((a['summary'] ?? '').isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      a['summary'] ?? '',
                      style: GoogleFonts.inter(fontSize: 12, color: Colors.white60, height: 1.4),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Text(
                        '${a['publish_date']} · ${a['read_time_minutes'] ?? 3} min read',
                        style: GoogleFonts.inter(fontSize: 11, color: Colors.white38),
                      ),
                      const Spacer(),
                      Text(
                        'Read & Practice →',
                        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF818cf8)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArticleCard(Map<String, dynamic> a) {
    return GestureDetector(
      onTap: () => _onArticleTap(a['id']),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366f1).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    a['category'] ?? 'General',
                    style: GoogleFonts.inter(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF818cf8),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  a['publish_date'] ?? '',
                  style: GoogleFonts.inter(fontSize: 11, color: Colors.white38),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.psychology_outlined, size: 12, color: Color(0xFF818cf8)),
                      const SizedBox(width: 3),
                      Text(
                        'Quiz Ready',
                        style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              a['title'] ?? '',
              style: GoogleFonts.inter(
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              a['summary'] ?? a['content_body'] ?? '',
              style: GoogleFonts.inter(fontSize: 12, color: Colors.white54, height: 1.4),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if ((a['exam_relevance'] ?? '').isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                'Exam Targets: ${a['exam_relevance']}',
                style: GoogleFonts.inter(fontSize: 10.5, color: const Color(0xFF818cf8).withValues(alpha: 0.8), fontWeight: FontWeight.w500),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.newspaper_outlined, size: 54, color: Colors.white24),
            const SizedBox(height: 16),
            Text(
              'No Current Affairs Found',
              style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white70),
            ),
            const SizedBox(height: 6),
            Text(
              'Try changing your category or search term.',
              style: GoogleFonts.inter(fontSize: 12, color: Colors.white38),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.warning_amber_rounded, size: 48, color: Colors.amber),
            const SizedBox(height: 14),
            Text(_errorMsg, style: GoogleFonts.inter(color: Colors.white70, fontSize: 13), textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadArticles,
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6366f1)),
              child: Text('Retry', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }
}
