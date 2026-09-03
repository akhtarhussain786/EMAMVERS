import 'package:flutter/material.dart';
import '../../core/constants.dart';
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
      backgroundColor: AppConstants.primaryDark,
      appBar: AppBar(
        backgroundColor: AppConstants.primaryDark,
        title: Text(
          'Daily Current Affairs',
          style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: AppConstants.textPrimary),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppConstants.textPrimary, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppConstants.textSecondary),
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
                  ? const Center(child: CircularProgressIndicator(color: AppConstants.accentYellow))
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
        color: AppConstants.primaryDark,
        border: Border(bottom: BorderSide(color: AppConstants.textPrimary.withValues(alpha: 0.06))),
      ),
      child: Column(
        children: [
          // Search Field
          TextField(
            controller: _searchCtrl,
            style: GoogleFonts.inter(color: AppConstants.textPrimary, fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Search events, topics, policies...',
              hintStyle: GoogleFonts.inter(color: AppConstants.textMuted, fontSize: 13),
              prefixIcon: const Icon(Icons.search, color: AppConstants.textMuted, size: 20),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.close, color: AppConstants.textMuted, size: 18),
                      onPressed: () {
                        _searchCtrl.clear();
                        setState(() => _searchQuery = '');
                        _loadArticles();
                      },
                    )
                  : null,
              filled: true,
              fillColor: AppConstants.textPrimary.withValues(alpha: 0.05),
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
                    selectedColor: AppConstants.accentYellow,
                    backgroundColor: AppConstants.textPrimary.withValues(alpha: 0.05),
                    labelStyle: GoogleFonts.inter(
                      fontSize: 11.5,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? AppConstants.textPrimary : AppConstants.textSecondary,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: isSelected ? AppConstants.accentYellow : AppConstants.textPrimary.withValues(alpha: 0.08),
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
                    selectedColor: AppConstants.accentYellow,
                    backgroundColor: AppConstants.textPrimary.withValues(alpha: 0.05),
                    labelStyle: GoogleFonts.inter(
                      fontSize: 11.5,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? AppConstants.textPrimary : AppConstants.textSecondary,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: isSelected ? AppConstants.accentYellow : AppConstants.textPrimary.withValues(alpha: 0.08),
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
      color: AppConstants.accentYellow,
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
            colors: [AppConstants.surfaceElevated, AppConstants.accentYellowDeep],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: AppConstants.accentYellow.withValues(alpha: 0.3)),
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
                          color: AppConstants.accentRose.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppConstants.accentRose.withValues(alpha: 0.4)),
                        ),
                        child: Text(
                          'BREAKING FOCUS',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: AppConstants.accentRose,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        a['category'] ?? '',
                        style: GoogleFonts.inter(fontSize: 11, color: AppConstants.textSecondary),
                      ),
                      const Spacer(),
                      const Icon(Icons.auto_awesome, size: 14, color: AppConstants.accentYellow),
                      const SizedBox(width: 4),
                      Text(
                        'AI Quiz',
                        style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: AppConstants.accentYellow),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    a['title'] ?? '',
                    style: GoogleFonts.inter(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: AppConstants.textPrimary,
                      height: 1.35,
                    ),
                  ),
                  if ((a['summary'] ?? '').isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      a['summary'] ?? '',
                      style: GoogleFonts.inter(fontSize: 12, color: AppConstants.textSecondary, height: 1.4),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Text(
                        '${a['publish_date']} · ${a['read_time_minutes'] ?? 3} min read',
                        style: GoogleFonts.inter(fontSize: 11, color: AppConstants.textMuted),
                      ),
                      const Spacer(),
                      Text(
                        'Read & Practice →',
                        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: AppConstants.accentYellow),
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
          color: AppConstants.textPrimary.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppConstants.textPrimary.withValues(alpha: 0.06)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppConstants.accentYellow.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    a['category'] ?? 'General',
                    style: GoogleFonts.inter(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: AppConstants.accentYellow,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  a['publish_date'] ?? '',
                  style: GoogleFonts.inter(fontSize: 11, color: AppConstants.textMuted),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppConstants.textPrimary.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.psychology_outlined, size: 12, color: AppConstants.accentYellow),
                      const SizedBox(width: 3),
                      Text(
                        'Quiz Ready',
                        style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: AppConstants.textSecondary),
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
                color: AppConstants.textPrimary,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              a['summary'] ?? a['content_body'] ?? '',
              style: GoogleFonts.inter(fontSize: 12, color: AppConstants.textMuted, height: 1.4),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if ((a['exam_relevance'] ?? '').isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                'Exam Targets: ${a['exam_relevance']}',
                style: GoogleFonts.inter(fontSize: 10.5, color: AppConstants.accentYellow.withValues(alpha: 0.8), fontWeight: FontWeight.w500),
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
            const Icon(Icons.newspaper_outlined, size: 54, color: AppConstants.cardBorder),
            const SizedBox(height: 16),
            Text(
              'No Current Affairs Found',
              style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: AppConstants.textSecondary),
            ),
            const SizedBox(height: 6),
            Text(
              'Try changing your category or search term.',
              style: GoogleFonts.inter(fontSize: 12, color: AppConstants.textMuted),
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
            Text(_errorMsg, style: GoogleFonts.inter(color: AppConstants.textSecondary, fontSize: 13), textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadArticles,
              style: ElevatedButton.styleFrom(backgroundColor: AppConstants.accentYellow),
              child: Text('Retry', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }
}
