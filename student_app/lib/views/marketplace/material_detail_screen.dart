import 'package:flutter/material.dart';
import '../../core/constants.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/api_service.dart';
import 'purchase_flow_screen.dart';

class MaterialDetailScreen extends StatefulWidget {
  final int materialId;
  const MaterialDetailScreen({super.key, required this.materialId});

  @override
  State<MaterialDetailScreen> createState() => _MaterialDetailScreenState();
}

class _MaterialDetailScreenState extends State<MaterialDetailScreen> {
  Map<String, dynamic>? _material;
  bool _loading = true;
  bool _isPurchased = false;

  @override
  void initState() {
    super.initState();
    _loadDetail();
    _checkPurchased();
  }

  Future<void> _loadDetail() async {
    try {
      final data = await ApiService.get('/v1/marketplace/${widget.materialId}');
      if (mounted) setState(() { _material = data as Map<String, dynamic>?; _loading = false; });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _checkPurchased() async {
    try {
      final data = await ApiService.getAuth('/v1/marketplace/my-purchases');
      final purchases = data as List? ?? [];
      if (mounted) {
        setState(() => _isPurchased = purchases.any((p) => p['material_id'] == widget.materialId));
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: AppConstants.primaryDark,
        body: Center(child: CircularProgressIndicator(color: AppConstants.accentYellow)),
      );
    }
    if (_material == null) {
      return const Scaffold(
        backgroundColor: AppConstants.primaryDark,
        body: Center(child: Text('Material not found', style: TextStyle(color: AppConstants.textPrimary))),
      );
    }

    final m = _material!;
    final bool isFree = m['is_free'] == 1 || (m['price']?.toString() ?? '0') == '0';
    final double price = double.tryParse(m['price']?.toString() ?? '0') ?? 0;
    final double rating = double.tryParse(m['rating_avg']?.toString() ?? '0') ?? 0;
    final int ratingCount = m['rating_count'] ?? 0;
    final List reviews = m['reviews'] ?? [];

    return Scaffold(
      backgroundColor: AppConstants.primaryDark,
      body: CustomScrollView(
        slivers: [
          // Hero Header
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: AppConstants.primaryDark,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: AppConstants.textPrimary, size: 18),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF1a0533), Color(0xFF0d1b3e)],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 48, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Category chip
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppConstants.accentYellow.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppConstants.accentYellow.withValues(alpha: 0.3)),
                          ),
                          child: Text(m['exam_title'] ?? m['subject_name'] ?? 'Study Material',
                              style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppConstants.accentYellow)),
                        ),
                        const SizedBox(height: 12),
                        Text(m['title'] ?? '',
                            style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800, color: AppConstants.onAccent),
                            maxLines: 2),
                        const SizedBox(height: 8),
                        Row(children: [
                          CircleAvatar(radius: 14, backgroundColor: AppConstants.accentYellow,
                              child: Text((m['creator_name'] ?? 'C')[0].toUpperCase(),
                                  style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w800, color: AppConstants.textPrimary))),
                          const SizedBox(width: 8),
                          Text(m['creator_name'] ?? '',
                              style: GoogleFonts.inter(fontSize: 12, color: AppConstants.textSecondary, fontWeight: FontWeight.w600)),
                          const Spacer(),
                          // Rating
                          Icon(Icons.star, size: 14, color: Colors.amber.shade400),
                          const SizedBox(width: 4),
                          Text('$rating ($ratingCount)',
                              style: GoogleFonts.inter(fontSize: 12, color: AppConstants.textSecondary)),
                        ]),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                // Stats Row
                Row(children: [
                  _StatChip(icon: Icons.description_outlined, label: '${m['total_pages'] ?? '?'} Pages'),
                  const SizedBox(width: 10),
                  _StatChip(icon: Icons.storage_outlined,
                      label: _formatSize(m['file_size_kb'] ?? 0)),
                  const SizedBox(width: 10),
                  _StatChip(icon: Icons.download_outlined, label: '${m['total_downloads'] ?? 0} Downloads'),
                  const SizedBox(width: 10),
                  _StatChip(icon: Icons.people_outlined, label: '${m['total_buyers'] ?? 0} Buyers'),
                ]),

                const SizedBox(height: 24),

                // Preview Info
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppConstants.accentYellow.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppConstants.accentYellow.withValues(alpha: 0.2)),
                  ),
                  child: Row(children: [
                    const Icon(Icons.preview_outlined, color: AppConstants.accentYellow, size: 22),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Free Preview', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: AppConstants.textPrimary)),
                      Text('${m['preview_pages'] ?? 5} pages free — buy to unlock full content',
                          style: GoogleFonts.inter(fontSize: 12, color: AppConstants.textMuted)),
                    ])),
                  ]),
                ),

                const SizedBox(height: 24),

                // Description
                Text('About this material',
                    style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: AppConstants.textPrimary)),
                const SizedBox(height: 10),
                Text(m['description'] ?? 'No description provided.',
                    style: GoogleFonts.inter(fontSize: 13, color: AppConstants.textSecondary, height: 1.6)),

                // Tags
                if ((m['tags'] ?? '').isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Wrap(spacing: 8, runSpacing: 6,
                    children: (m['tags'] as String).split(',').map((tag) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                          color: AppConstants.textPrimary.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(20)),
                      child: Text(tag.trim(), style: GoogleFonts.inter(fontSize: 11, color: AppConstants.textMuted)),
                    )).toList(),
                  ),
                ],

                const SizedBox(height: 28),

                // Reviews
                if (reviews.isNotEmpty) ...[
                  Text('Reviews', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: AppConstants.textPrimary)),
                  const SizedBox(height: 12),
                  ...reviews.take(3).map((r) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                          color: AppConstants.textPrimary.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(12)),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          Text(r['full_name'] ?? 'Student',
                              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppConstants.textPrimary)),
                          const Spacer(),
                          ...List.generate(5, (i) => Icon(
                              i < (r['rating'] ?? 0) ? Icons.star : Icons.star_border,
                              size: 12,
                              color: Colors.amber.shade400)),
                        ]),
                        if (r['review_text'] != null && r['review_text'].isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(r['review_text'], style: GoogleFonts.inter(fontSize: 12, color: AppConstants.textMuted)),
                        ],
                      ]),
                    ),
                  )),
                ],

                const SizedBox(height: 100), // Bottom padding for FAB
              ]),
            ),
          ),
        ],
      ),

      // Bottom Buy Bar
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        decoration: BoxDecoration(
          color: AppConstants.cardDark,
          border: Border(top: BorderSide(color: AppConstants.textPrimary.withValues(alpha: 0.08))),
        ),
        child: Row(children: [
          // Price
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Price', style: GoogleFonts.inter(fontSize: 11, color: AppConstants.textMuted)),
            Text(isFree ? 'FREE' : '₹${price.toStringAsFixed(0)}',
                style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w900,
                    color: isFree ? Colors.green.shade400 : AppConstants.textPrimary)),
          ]),
          const SizedBox(width: 20),
          // Action Button
          Expanded(child: _isPurchased
              ? ElevatedButton.icon(
                  onPressed: () {/* download */},
                  icon: const Icon(Icons.download, size: 18),
                  label: Text('Download Now', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))))
              : ElevatedButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(
                      builder: (_) => PurchaseFlowScreen(material: m))),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppConstants.accentYellow,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                  child: Text(isFree ? 'Get for Free' : 'Buy Now — ₹${price.toStringAsFixed(0)}',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 15)),
                )),
        ]),
      ),
    );
  }

  String _formatSize(int kb) {
    if (kb < 1024) return '${kb}KB';
    return '${(kb / 1024).toStringAsFixed(1)}MB';
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _StatChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
          color: AppConstants.textPrimary.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(8)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 12, color: AppConstants.textMuted),
        const SizedBox(width: 5),
        Text(label, style: GoogleFonts.inter(fontSize: 11, color: AppConstants.textMuted)),
      ]),
    );
  }
}
