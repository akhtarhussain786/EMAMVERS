import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../core/api_service.dart';
import '../../models/map_models.dart';
import '../../widgets/design_system_widgets.dart';
import 'india_map_view.dart';
import 'map_quiz_view.dart';

class MapLearningHomeView extends StatefulWidget {
  const MapLearningHomeView({super.key});

  @override
  State<MapLearningHomeView> createState() => _MapLearningHomeViewState();
}

class _MapLearningHomeViewState extends State<MapLearningHomeView> {
  bool isLoading = true;
  List<MapCategory> categories = [];
  List<MapLocation> locations = [];
  String selectedCatSlug = '';
  final searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() async {
    setState(() => isLoading = true);
    try {
      final resCats = await ApiService.get('/v1/map/categories');
      final resLocs = await ApiService.get('/v1/map/locations');

      setState(() {
        categories = (resCats['categories'] as List? ?? []).map((c) => MapCategory.fromJson(c)).toList();
        locations = (resLocs['locations'] as List? ?? []).map((l) => MapLocation.fromJson(l)).toList();
        isLoading = false;
      });
    } catch (_) {
      setState(() => isLoading = false);
    }
  }

  void _filterLocations() async {
    setState(() => isLoading = true);
    try {
      String query = '/v1/map/locations?q=${Uri.encodeComponent(searchController.text.trim())}';
      if (selectedCatSlug.isNotEmpty) {
        query += '&category=$selectedCatSlug';
      }
      final resLocs = await ApiService.get(query);
      setState(() {
        locations = (resLocs['locations'] as List? ?? []).map((l) => MapLocation.fromJson(l)).toList();
        isLoading = false;
      });
    } catch (_) {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.primaryDark,
      appBar: AppBar(
        backgroundColor: AppConstants.scaffoldDark,
        title: const Text('ExamVerse Map Learning', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.quiz_outlined, color: AppConstants.accentCyan),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MapQuizView())),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.space20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // HERO MAP CALLOUT CARD
              ExamVerseCard(
                gradient: AppConstants.aiGradient,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('VISUAL MAP LEARNING', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.8)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.25), borderRadius: BorderRadius.circular(10)),
                          child: const Text('EXPLORE INDIA', style: TextStyle(color: AppConstants.accentCyan, fontSize: 11, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppConstants.space12),
                    const Text(
                      'Learn National Parks, Rivers, Dams & Monuments Visually',
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'High-frequency Geography & General Awareness PYQs mapped spatially for long-term retention.',
                      style: TextStyle(color: Colors.white70, fontSize: 12.5),
                    ),
                    const SizedBox(height: AppConstants.space16),
                    Row(
                      children: [
                        Expanded(
                          child: PrimaryButton(
                            label: 'Open Interactive India Map 🗺️',
                            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => IndiaMapView(locations: locations))),
                          ),
                        ),
                        const SizedBox(width: 10),
                        SecondaryButton(
                          label: 'Map Quiz',
                          icon: Icons.sports_esports,
                          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MapQuizView())),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppConstants.space24),

              // SEARCH BAR
              TextField(
                controller: searchController,
                onSubmitted: (_) => _filterLocations(),
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Search Kaziranga, Narmada, Tehri Dam, Nalanda...',
                  hintStyle: const TextStyle(color: AppConstants.textMuted, fontSize: 13),
                  prefixIcon: const Icon(Icons.search, color: AppConstants.accentCyan),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.arrow_forward, color: AppConstants.accentCyan),
                    onPressed: _filterLocations,
                  ),
                  filled: true,
                  fillColor: AppConstants.cardDark,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppConstants.radiusMedium), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: AppConstants.space16),

              // CATEGORIES FILTER BAR
              SizedBox(
                height: 38,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _buildCatChip('All Places', ''),
                    ...categories.map((c) => _buildCatChip(c.name, c.slug)),
                  ],
                ),
              ),
              const SizedBox(height: AppConstants.space24),

              // LOCATIONS LIST
              SectionHeader(
                title: selectedCatSlug.isEmpty ? 'Important Exam Locations' : 'Category Locations',
                actionLabel: 'Interactive Map →',
                onActionTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => IndiaMapView(locations: locations))),
              ),
              const SizedBox(height: AppConstants.space12),

              isLoading
                  ? const Center(child: Padding(padding: EdgeInsets.all(30), child: CircularProgressIndicator(color: AppConstants.accentCyan)))
                  : locations.isEmpty
                      ? const EmptyStateWidget(icon: Icons.map_outlined, title: 'No Map Locations Found', description: 'Try searching for another place, river, dam, or national park.')
                      : ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: locations.length,
                          separatorBuilder: (_, __) => const SizedBox(height: AppConstants.space12),
                          itemBuilder: (context, i) {
                            final loc = locations[i];
                            return ExamVerseCard(
                              onTap: () => _showLocationDetails(context, loc),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(color: AppConstants.accentCyan.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
                                    child: const Icon(Icons.place, color: AppConstants.accentCyan, size: 24),
                                  ),
                                  const SizedBox(width: AppConstants.space12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(loc.categoryName, style: const TextStyle(color: AppConstants.accentCyan, fontSize: 10.5, fontWeight: FontWeight.bold)),
                                            const SizedBox(width: 6),
                                            Text('• ${loc.state.isNotEmpty ? loc.state : loc.country}', style: const TextStyle(color: AppConstants.textMuted, fontSize: 10.5)),
                                          ],
                                        ),
                                        const SizedBox(height: 2),
                                        Text(loc.name, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                                        const SizedBox(height: 2),
                                        Text(loc.shortDescription, style: const TextStyle(color: AppConstants.textSecondary, fontSize: 11.5), maxLines: 1, overflow: TextOverflow.ellipsis),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(color: AppConstants.accentEmerald.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                                    child: Text('${loc.pyqCount} PYQs', style: const TextStyle(color: AppConstants.accentEmerald, fontSize: 10.5, fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCatChip(String label, String slug) {
    final isSelected = selectedCatSlug == slug;
    return GestureDetector(
      onTap: () {
        setState(() => selectedCatSlug = slug);
        _filterLocations();
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppConstants.accentCyan : AppConstants.cardDark,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? AppConstants.accentCyan : AppConstants.cardBorder),
        ),
        child: Text(
          label,
          style: TextStyle(color: isSelected ? Colors.black : Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  void _showLocationDetails(BuildContext context, MapLocation loc) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppConstants.cardDark,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(AppConstants.space24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: AppConstants.accentCyan.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                  child: Text(loc.categoryName, style: const TextStyle(color: AppConstants.accentCyan, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
                IconButton(icon: const Icon(Icons.close, color: Colors.white70), onPressed: () => Navigator.pop(ctx)),
              ],
            ),
            const SizedBox(height: 8),
            Text(loc.name, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
            Text('${loc.state.isNotEmpty ? loc.state + ', ' : ''}${loc.country}', style: const TextStyle(color: AppConstants.textSecondary, fontSize: 13)),
            const SizedBox(height: AppConstants.space16),

            Text(loc.shortDescription, style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.4)),
            const SizedBox(height: AppConstants.space16),

            const Text('Exam Key Facts:', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            ...loc.facts.map((f) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• ', style: TextStyle(color: AppConstants.accentCyan, fontSize: 14, fontWeight: FontWeight.bold)),
                  Expanded(child: Text(f, style: const TextStyle(color: AppConstants.textSecondary, fontSize: 12.5))),
                ],
              ),
            )),
            const SizedBox(height: AppConstants.space16),

            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppConstants.surfaceElevated, borderRadius: BorderRadius.circular(10)),
              child: Row(
                children: [
                  const Icon(Icons.bar_chart, color: AppConstants.accentEmerald, size: 18),
                  const SizedBox(width: 8),
                  Expanded(child: Text('Exam Relevance: ${loc.examRelevance}', style: const TextStyle(color: AppConstants.accentEmerald, fontSize: 12, fontWeight: FontWeight.bold))),
                ],
              ),
            ),
            const SizedBox(height: AppConstants.space20),

            PrimaryButton(
              label: 'Practice ${loc.name} Questions →',
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const MapQuizView()));
              },
            ),
          ],
        ),
      ),
    );
  }
}
