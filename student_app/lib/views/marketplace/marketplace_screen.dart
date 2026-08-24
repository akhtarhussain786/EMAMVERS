import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/api_service.dart';
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
  String _sort = 'newest';
  bool _freeOnly = false;
  String _searchQuery = '';

  final List<Map<String, dynamic>> _categories = [
    {'label': 'All', 'slug': ''},
    {'label': 'UPSC', 'slug': 'upsc'},
    {'label': 'SSC', 'slug': 'ssc'},
    {'label': 'Banking', 'slug': 'banking'},
    {'label': 'Railways', 'slug': 'railways'},
    {'label': 'State PSC', 'slug': 'state-psc'},
    {'label': 'Teaching', 'slug': 'teaching'},
    {'label': 'JEE/NEET', 'slug': 'engineering-entrance'},
    {'label': 'Gate', 'slug': 'gate-psu'},
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
      final data = await ApiService.get('/marketplace', params: params);
      if (mounted) {
        setState(() {
          _materials = data['data']?['materials'] ?? [];
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      body: NestedScrollView(
        headerSliverBuilder: (ctx, inner) => [
          SliverAppBar(
            expandedHeight: 160,
            floating: false,
            pinned: true,
            backgroundColor: const Color(0xFF0F0F1A),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF1a0533), Color(0xFF0F0F1A)],
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(20, 60, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('📚 Study Marketplace',
                        style: GoogleFonts.inter(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Colors.white)),
                    const SizedBox(height: 4),
                    Text('Quality notes & materials from top creators',
                        style: GoogleFonts.inter(
                            fontSize: 13,
                            color: Colors.white54)),
                  ],
                ),
              ),
              title: Text('Marketplace',
                  style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white)),
              centerTitle: false,
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.filter_list, color: Colors.white70),
                onPressed: _showFilterSheet,
              ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(90),
              child: Column(
                children: [
                  // Search bar
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: TextField(
                      controller: _searchCtrl,
                      style: GoogleFonts.inter(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Search notes, PDFs, materials...',
                        hintStyle: GoogleFonts.inter(color: Colors.white38, fontSize: 13),
                        prefixIcon: const Icon(Icons.search, color: Colors.white38, size: 20),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.close, color: Colors.white38, size: 18),
                                onPressed: () {
                                  _searchCtrl.clear();
                                  setState(() => _searchQuery = '');
                                  _loadMaterials();
                                })
                            : null,
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.07),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      onSubmitted: (val) {
                        setState(() => _searchQuery = val);
                        _loadMaterials();
                      },
                    ),
                  ),
                  // Category tabs
                  TabBar(
                    controller: _tabCtrl,
                    isScrollable: true,
                    indicatorColor: const Color(0xFF818cf8),
                    indicatorWeight: 2,
                    labelColor: const Color(0xFF818cf8),
                    unselectedLabelColor: Colors.white38,
                    labelStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
                    tabs: _categories.map((c) => Tab(text: c['label'])).toList(),
                  ),
                ],
              ),
            ),
          ),
        ],
        body: _loading
            ? _buildShimmer()
            : _materials.isEmpty
                ? _buildEmpty()
                : RefreshIndicator(
                    onRefresh: _loadMaterials,
                    color: const Color(0xFF818cf8),
                    child: GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 0.72,
                      ),
                      itemCount: _materials.length,
                      itemBuilder: (ctx, i) => _MaterialCard(
                        material: _materials[i],
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => MaterialDetailScreen(
                                materialId: _materials[i]['id']),
                          ),
                        ),
                      ),
                    ),
                  ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, '/become-creator'),
        backgroundColor: const Color(0xFF6366f1),
        icon: const Icon(Icons.star, size: 18),
        label: Text('Become Creator', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
      ),
    );
  }

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: const Color(0xFF1e1e2e),
      highlightColor: const Color(0xFF2a2a3e),
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 0.72),
        itemCount: 8,
        itemBuilder: (_, __) => Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14))),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.store_outlined, size: 64, color: Colors.white24),
        const SizedBox(height: 16),
        Text('No materials found',
            style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white60)),
        const SizedBox(height: 8),
        Text('Be the first to upload study materials!',
            style: GoogleFonts.inter(fontSize: 13, color: Colors.white38)),
      ]),
    );
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1e1e2e),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Filter & Sort', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
            const SizedBox(height: 20),
            Text('Sort By', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white54)),
            const SizedBox(height: 8),
            Wrap(spacing: 8, children: [
              for (var s in [['newest','Newest'], ['popular','Popular'], ['price_asc','Price ↑'], ['price_desc','Price ↓'], ['rating','Rating']])
                ChoiceChip(
                  label: Text(s[1]),
                  selected: _sort == s[0],
                  selectedColor: const Color(0xFF6366f1),
                  labelStyle: GoogleFonts.inter(color: _sort == s[0] ? Colors.white : Colors.white60, fontSize: 12),
                  backgroundColor: Colors.white10,
                  onSelected: (_) => setS(() => _sort = s[0]),
                )
            ]),
            const SizedBox(height: 16),
            Row(children: [
              Switch(value: _freeOnly, onChanged: (v) => setS(() => _freeOnly = v), activeColor: const Color(0xFF818cf8)),
              const SizedBox(width: 8),
              Text('Free materials only', style: GoogleFonts.inter(color: Colors.white70)),
            ]),
            const SizedBox(height: 20),
            SizedBox(width: double.infinity,
              child: ElevatedButton(
                onPressed: () { Navigator.pop(ctx); _loadMaterials(); },
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366f1),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: Text('Apply Filters', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
              )),
          ]),
        ),
      ),
    );
  }
}

// ─── Material Card Widget ─────────────────────────────────────────────────

class _MaterialCard extends StatelessWidget {
  final Map<String, dynamic> material;
  final VoidCallback onTap;
  const _MaterialCard({required this.material, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final bool isFree = material['is_free'] == 1 || material['price'] == 0;
    final double price = double.tryParse(material['price']?.toString() ?? '0') ?? 0;
    final double rating = double.tryParse(material['rating_avg']?.toString() ?? '0') ?? 0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1a1a2e), Color(0xFF16213e)],
          ),
          border: Border.all(color: Colors.white.withOpacity(0.07)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover / Thumbnail
            Container(
              height: 110,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                gradient: LinearGradient(
                  colors: _getGradient(material['subject_name'] ?? ''),
                ),
              ),
              child: Stack(children: [
                Center(child: Icon(_getIcon(material['subject_name'] ?? ''),
                    size: 40, color: Colors.white.withOpacity(0.3))),
                Positioned(top: 8, right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                          color: isFree ? Colors.green.shade700 : Colors.black54,
                          borderRadius: BorderRadius.circular(20)),
                      child: Text(isFree ? 'FREE' : '₹${price.toStringAsFixed(0)}',
                          style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white)),
                    )),
              ]),
            ),
            // Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(material['title'] ?? '',
                      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white),
                      maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text(material['creator_name'] ?? '',
                      style: GoogleFonts.inter(fontSize: 10, color: Colors.white38),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  const Spacer(),
                  Row(children: [
                    const Icon(Icons.star, size: 11, color: Color(0xFFfbbf24)),
                    const SizedBox(width: 3),
                    Text(rating.toStringAsFixed(1),
                        style: GoogleFonts.inter(fontSize: 10, color: Colors.white60)),
                    const Spacer(),
                    Icon(Icons.download_outlined, size: 11, color: Colors.white38),
                    const SizedBox(width: 2),
                    Text('${material['total_downloads'] ?? 0}',
                        style: GoogleFonts.inter(fontSize: 10, color: Colors.white38)),
                  ]),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Color> _getGradient(String subject) {
    final s = subject.toLowerCase();
    if (s.contains('math') || s.contains('quant')) return [const Color(0xFF1d4ed8), const Color(0xFF3b82f6)];
    if (s.contains('gk') || s.contains('general')) return [const Color(0xFF065f46), const Color(0xFF059669)];
    if (s.contains('english') || s.contains('reasoning')) return [const Color(0xFF7c2d12), const Color(0xFFea580c)];
    if (s.contains('science') || s.contains('physics') || s.contains('chemistry')) return [const Color(0xFF4c1d95), const Color(0xFF7c3aed)];
    if (s.contains('history') || s.contains('polity')) return [const Color(0xFF7f1d1d), const Color(0xFFdc2626)];
    return [const Color(0xFF1e1b4b), const Color(0xFF4338ca)];
  }

  IconData _getIcon(String subject) {
    final s = subject.toLowerCase();
    if (s.contains('math') || s.contains('quant')) return Icons.calculate_outlined;
    if (s.contains('reasoning')) return Icons.psychology_outlined;
    if (s.contains('english')) return Icons.abc;
    if (s.contains('science') || s.contains('bio')) return Icons.biotech_outlined;
    if (s.contains('history') || s.contains('polity')) return Icons.account_balance_outlined;
    return Icons.menu_book_outlined;
  }
}
