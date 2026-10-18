import 'package:flutter/material.dart';
import '../../core/constants.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/api_service.dart';
import '../../widgets/edu_lottie.dart';
import 'material_detail_screen.dart';

class MarketplaceScreen extends StatefulWidget {
  const MarketplaceScreen({super.key});

  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchCtrl = TextEditingController();
  late TabController _tabCtrl;

  List<dynamic> _materials = [];
  bool _loading = true;
  String _errorMsg = '';
  String _sort = 'newest';
  bool _freeOnly = false;
  String _searchQuery = '';

  final List<Map<String, dynamic>> _categories = [
    {'label': 'All Notes', 'slug': '', 'icon': Icons.auto_stories_rounded},
    {'label': 'UPSC CSE', 'slug': 'upsc', 'icon': Icons.account_balance_rounded},
    {'label': 'SSC CGL', 'slug': 'ssc', 'icon': Icons.business_center_rounded},
    {'label': 'Banking', 'slug': 'banking', 'icon': Icons.account_balance_wallet_rounded},
    {'label': 'Railways', 'slug': 'railways', 'icon': Icons.train_rounded},
    {'label': 'State PSC', 'slug': 'state-psc', 'icon': Icons.domain_rounded},
    {'label': 'Teaching', 'slug': 'teaching', 'icon': Icons.cast_for_education_rounded},
    {'label': 'JEE / NEET', 'slug': 'engineering-entrance', 'icon': Icons.biotech_rounded},
    {'label': 'GATE', 'slug': 'gate-psu', 'icon': Icons.engineering_rounded},
  ];
  String _selectedCategory = '';

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: _categories.length, vsync: this);
    _tabCtrl.addListener(() {
      if (!_tabCtrl.indexIsChanging) {
        setState(() => _selectedCategory = _categories[_tabCtrl.index]['slug']);
        _loadMaterials();
      }
    });
    _loadMaterials();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadMaterials() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final params = {
        'sort': _sort,
        if (_freeOnly) 'free': '1',
        if (_searchQuery.isNotEmpty) 'q': _searchQuery,
        if (_selectedCategory.isNotEmpty) 'exam_category': _selectedCategory,
        'limit': '30',
      };
      final data = await ApiService.get('/v1/marketplace', params: params);
      if (mounted) {
        setState(() {
          _materials = (data is Map ? data['materials'] : null) as List? ?? [];
          _loading = false;
          _errorMsg = '';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _errorMsg = e.toString().replaceAll('Exception: ', '');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.scaffoldDark,
      body: SafeArea(
        bottom: false,
        child: NestedScrollView(
          headerSliverBuilder: (ctx, inner) => [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Educational Hero Header Card
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFF1E3A8A), // Deep Royal Navy
                            Color(0xFF2563EB), // Electric Blue
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF1D4ED8).withValues(alpha: 0.25),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: const [
                                      Icon(Icons.verified_rounded, color: Colors.white, size: 13),
                                      SizedBox(width: 4),
                                      Text(
                                        'ACADEMIC STORE',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0.6,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'Study Notes & PDFs',
                                  style: GoogleFonts.inter(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Handpicked revision sheets, formula books & mocks by top teachers',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: Colors.white.withValues(alpha: 0.85),
                                    height: 1.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Lottie Book / Study Animation
                          EduLottie.study(size: 80),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Search and Filter Bar
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppConstants.cardDark,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppConstants.cardBorder),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.02),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: TextField(
                              controller: _searchCtrl,
                              style: GoogleFonts.inter(
                                color: AppConstants.textPrimary,
                                fontSize: 13.5,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Search notes, PDFs, topics...',
                                hintStyle: GoogleFonts.inter(
                                  color: AppConstants.textMuted,
                                  fontSize: 13,
                                ),
                                prefixIcon: const Icon(
                                  Icons.search_rounded,
                                  color: AppConstants.accentBlue,
                                  size: 22,
                                ),
                                suffixIcon: _searchQuery.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.close, color: AppConstants.textMuted, size: 18),
                                        onPressed: () {
                                          _searchCtrl.clear();
                                          setState(() => _searchQuery = '');
                                          _loadMaterials();
                                        },
                                      )
                                    : null,
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(vertical: 13),
                              ),
                              onSubmitted: (val) {
                                setState(() => _searchQuery = val);
                                _loadMaterials();
                              },
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        InkWell(
                          onTap: _showFilterSheet,
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            padding: const EdgeInsets.all(13),
                            decoration: BoxDecoration(
                              color: AppConstants.cardDark,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppConstants.cardBorder),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.02),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.tune_rounded,
                              color: AppConstants.accentBlue,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),
            // Pinned Tab Bar
            SliverPersistentHeader(
              pinned: true,
              delegate: _SliverTabBarDelegate(
                TabBar(
                  controller: _tabCtrl,
                  isScrollable: true,
                  physics: const BouncingScrollPhysics(),
                  indicatorColor: AppConstants.accentBlue,
                  indicatorWeight: 3,
                  labelColor: AppConstants.accentBlue,
                  unselectedLabelColor: AppConstants.textSecondary,
                  labelStyle: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w700),
                  unselectedLabelStyle: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w500),
                  tabAlignment: TabAlignment.start,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  tabs: _categories.map((c) => Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(c['icon'] as IconData, size: 16),
                        const SizedBox(width: 6),
                        Text(c['label']),
                      ],
                    ),
                  )).toList(),
                ),
              ),
            ),
          ],
          body: _loading
              ? _buildShimmer()
              : _materials.isEmpty
                  ? (_errorMsg.isNotEmpty ? _buildLoadError() : _buildEmpty())
                  : RefreshIndicator(
                      onRefresh: _loadMaterials,
                      color: AppConstants.accentBlue,
                      child: GridView.builder(
                        // 100 bottom padding so cards are never obscured by bottom nav
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 14,
                          childAspectRatio: 0.68,
                        ),
                        itemCount: _materials.length,
                        itemBuilder: (ctx, i) => _MaterialCard(
                          material: _materials[i],
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => MaterialDetailScreen(
                                materialId: _materials[i]['id'],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 85),
        child: FloatingActionButton.extended(
          onPressed: () => Navigator.pushNamed(context, '/become-creator'),
          backgroundColor: AppConstants.accentBlue,
          elevation: 4,
          icon: const Icon(Icons.school_rounded, color: Colors.white, size: 18),
          label: Text(
            'Educator Portal',
            style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: Colors.white, fontSize: 13),
          ),
        ),
      ),
    );
  }

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFE2E8F0),
      highlightColor: const Color(0xFFF8FAFC),
      child: GridView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 14,
          childAspectRatio: 0.68,
        ),
        itemCount: 6,
        itemBuilder: (_, _) => Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 48, color: AppConstants.textMuted),
            const SizedBox(height: 16),
            const Text(
              'Could not load study materials',
              style: TextStyle(color: AppConstants.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMsg,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppConstants.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _loadMaterials,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.accentBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            EduLottie.emptySearch(size: 130),
            const SizedBox(height: 12),
            Text(
              'No Study Materials Found',
              style: GoogleFonts.inter(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppConstants.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _searchQuery.isNotEmpty
                  ? 'No results for "$_searchQuery". Try different keywords.'
                  : 'Be the first educator to upload notes for this category!',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 13, color: AppConstants.textSecondary),
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: () {
                _searchCtrl.clear();
                setState(() {
                  _searchQuery = '';
                  _selectedCategory = '';
                  _tabCtrl.animateTo(0);
                });
                _loadMaterials();
              },
              icon: const Icon(Icons.restart_alt_rounded, size: 16),
              label: const Text('Reset All Filters'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppConstants.accentBlue,
                side: const BorderSide(color: AppConstants.accentBlue),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppConstants.cardDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Filter & Sort Materials',
                    style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w800, color: AppConstants.textPrimary),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const Divider(color: AppConstants.cardBorder),
              const SizedBox(height: 12),
              Text(
                'SORT BY',
                style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w800, color: AppConstants.textMuted, letterSpacing: 0.6),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (var s in [
                    ['newest', 'Fresh Releases'],
                    ['popular', 'Most Downloaded'],
                    ['rating', 'Top Rated ⭐'],
                    ['price_asc', 'Price: Low to High'],
                    ['price_desc', 'Price: High to Low'],
                  ])
                    ChoiceChip(
                      label: Text(s[1]),
                      selected: _sort == s[0],
                      selectedColor: AppConstants.accentBlue,
                      labelStyle: GoogleFonts.inter(
                        color: _sort == s[0] ? Colors.white : AppConstants.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                      backgroundColor: AppConstants.surfaceElevated,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      side: BorderSide(
                        color: _sort == s[0] ? AppConstants.accentBlue : AppConstants.cardBorder,
                      ),
                      onSelected: (_) => setS(() => _sort = s[0]),
                    )
                ],
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppConstants.surfaceElevated,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.card_giftcard_rounded, color: AppConstants.accentEmerald, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Show Free Study Notes Only',
                        style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppConstants.textPrimary),
                      ),
                    ),
                    Switch(
                      value: _freeOnly,
                      activeColor: AppConstants.accentEmerald,
                      onChanged: (v) => setS(() => _freeOnly = v),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _loadMaterials();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.accentBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('Apply Filters', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Sliver Persistent Tab Bar Delegate ─────────────────────────────────────
class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;
  _SliverTabBarDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height + 8;
  @override
  double get maxExtent => _tabBar.preferredSize.height + 8;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: AppConstants.scaffoldDark,
      padding: const EdgeInsets.only(bottom: 6),
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) => false;
}

// ─── Modern Educational Material Card ───────────────────────────────────────
class _MaterialCard extends StatelessWidget {
  final Map<String, dynamic> material;
  final VoidCallback onTap;

  const _MaterialCard({required this.material, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final bool isFree = material['is_free'] == 1 || material['price'] == 0 || (material['price']?.toString() ?? '0') == '0';
    final double price = double.tryParse(material['price']?.toString() ?? '0') ?? 0;
    final double rating = double.tryParse(material['rating_avg']?.toString() ?? '0') ?? 4.8;
    final String subject = material['subject_name'] ?? 'General Studies';
    final String creator = material['creator_name'] ?? 'Verified Faculty';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        decoration: BoxDecoration(
          color: AppConstants.cardDark,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppConstants.cardBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Cover Banner with Educational Palette
            Container(
              height: 100,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(17)),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: _getSubjectGradient(subject),
                ),
              ),
              child: Stack(
                children: [
                  // Educational Icon Watermark
                  Positioned(
                    right: 10,
                    bottom: 10,
                    child: Icon(
                      _getSubjectIcon(subject),
                      size: 52,
                      color: Colors.white.withValues(alpha: 0.22),
                    ),
                  ),
                  // Subject Tag
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(_getSubjectIcon(subject), size: 11, color: Colors.white),
                          const SizedBox(width: 4),
                          Text(
                            subject,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Price Badge
                  Positioned(
                    bottom: 8,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isFree ? const Color(0xFF059669) : Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        isFree ? 'FREE NOTES' : '₹${price.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: isFree ? Colors.white : AppConstants.accentBlue,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Card Body (Title, Creator, Ratings)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      material['title'] ?? 'Comprehensive Exam Notes',
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: AppConstants.textPrimary, // High-contrast crisp text!
                        height: 1.25,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        const Icon(Icons.school_outlined, size: 12, color: AppConstants.accentCyan),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            creator,
                            style: GoogleFonts.inter(
                              fontSize: 10.5,
                              color: AppConstants.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.only(top: 6),
                      decoration: const BoxDecoration(
                        border: Border(top: BorderSide(color: AppConstants.cardBorder)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.star_rounded, size: 13, color: Color(0xFFF59E0B)),
                          const SizedBox(width: 3),
                          Text(
                            rating.toStringAsFixed(1),
                            style: GoogleFonts.inter(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: AppConstants.textPrimary,
                            ),
                          ),
                          const Spacer(),
                          const Icon(Icons.download_rounded, size: 12, color: AppConstants.textMuted),
                          const SizedBox(width: 2),
                          Text(
                            '${material['total_downloads'] ?? 120}',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              color: AppConstants.textMuted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Color> _getSubjectGradient(String subject) {
    final s = subject.toLowerCase();
    if (s.contains('math') || s.contains('quant')) {
      return [const Color(0xFF1E40AF), const Color(0xFF3B82F6)]; // Royal Blue
    }
    if (s.contains('gk') || s.contains('general') || s.contains('affairs')) {
      return [const Color(0xFF047857), const Color(0xFF10B981)]; // Emerald Green
    }
    if (s.contains('english') || s.contains('comprehension')) {
      return [const Color(0xFFD97706), const Color(0xFFF59E0B)]; // Warm Amber
    }
    if (s.contains('science') || s.contains('physics') || s.contains('chemistry')) {
      return [const Color(0xFF6D28D9), const Color(0xFF8B5CF6)]; // Purple
    }
    if (s.contains('history') || s.contains('polity') || s.contains('law')) {
      return [const Color(0xFF991B1B), const Color(0xFFEF4444)]; // Crimson
    }
    if (s.contains('reasoning') || s.contains('logic')) {
      return [const Color(0xFF0E7490), const Color(0xFF06B6D4)]; // Cyan
    }
    return [const Color(0xFF1D4ED8), const Color(0xFF60A5FA)];
  }

  IconData _getSubjectIcon(String subject) {
    final s = subject.toLowerCase();
    if (s.contains('math') || s.contains('quant')) return Icons.calculate_rounded;
    if (s.contains('reasoning')) return Icons.psychology_rounded;
    if (s.contains('english')) return Icons.menu_book_rounded;
    if (s.contains('science') || s.contains('bio')) return Icons.biotech_rounded;
    if (s.contains('history') || s.contains('polity')) return Icons.account_balance_rounded;
    if (s.contains('gk') || s.contains('affairs')) return Icons.public_rounded;
    return Icons.auto_stories_rounded;
  }
}
