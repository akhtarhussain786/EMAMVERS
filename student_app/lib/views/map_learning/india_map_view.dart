import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../core/api_service.dart';
import '../../models/map_models.dart';
import '../../widgets/design_system_widgets.dart';

class IndiaMapView extends StatefulWidget {
  final List<MapLocation> locations;
  const IndiaMapView({super.key, required this.locations});

  @override
  State<IndiaMapView> createState() => _IndiaMapViewState();
}

class _IndiaMapViewState extends State<IndiaMapView> {
  MapLocation? selectedLocation;

  /// Loads the full fact list for a location and shows it in a sheet.
  Future<void> _showFacts(MapLocation location) async {
    List<dynamic> facts = [];
    String? error;
    try {
      final res = await ApiService.get('/v1/map/locations/${location.id}');
      final loc = (res is Map ? res['location'] : null) as Map<String, dynamic>?;
      facts = (loc?['facts'] as List?) ?? [];
    } catch (e) {
      error = e.toString().replaceAll('Exception: ', '');
    }
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppConstants.cardDark,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(AppConstants.space20),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(location.name,
              style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('${location.state}, ${location.country}',
              style: const TextStyle(color: AppConstants.accentCyan, fontSize: 12.5)),
          const SizedBox(height: 14),
          if (error != null)
            Text(error, style: const TextStyle(color: AppConstants.accentRose, fontSize: 13))
          else if (facts.isEmpty)
            const Text('No facts have been added for this location yet.',
                style: TextStyle(color: AppConstants.textMuted, fontSize: 13))
          else
            ...facts.map((f) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('•  ', style: TextStyle(color: AppConstants.accentEmerald, fontSize: 14)),
                    Expanded(
                      child: Text(f.toString(),
                          style: const TextStyle(
                              color: AppConstants.textSecondary, fontSize: 13, height: 1.45)),
                    ),
                  ]),
                )),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: PrimaryButton(label: 'Close', onPressed: () => Navigator.pop(ctx)),
          ),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.primaryDark,
      appBar: AppBar(
        backgroundColor: AppConstants.scaffoldDark,
        title: const Text('Interactive Map Learning', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: Stack(
        children: [
          // INTERACTIVE MAP CANVAS
          Positioned.fill(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.space20),
                child: Column(
                  children: [
                    Container(
                      height: 480,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppConstants.cardDark,
                        borderRadius: BorderRadius.circular(AppConstants.radiusHero),
                        border: Border.all(color: AppConstants.cardBorder),
                        boxShadow: AppConstants.cardShadow,
                      ),
                      child: Stack(
                        children: [
                          // MAP OUTLINE PLACEHOLDER BACKGROUND
                          Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(Icons.map, size: 100, color: AppConstants.surfaceElevated),
                                SizedBox(height: 12),
                                Text('INDIA GEOGRAPHY MAP', style: TextStyle(color: AppConstants.textMuted, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                              ],
                            ),
                          ),

                          // SPATIAL MARKERS ON MAP CANVAS
                          ...widget.locations.map((loc) {
                            // Map Lat/Long (8°N to 37°N, 68°E to 97°E) to relative canvas coordinates
                            double topPercent = 1.0 - ((loc.latitude - 8.0) / (37.0 - 8.0)).clamp(0.05, 0.90);
                            double leftPercent = ((loc.longitude - 68.0) / (97.0 - 68.0)).clamp(0.05, 0.90);

                            return Positioned(
                              top: topPercent * 400,
                              left: leftPercent * 300,
                              child: GestureDetector(
                                onTap: () => setState(() => selectedLocation = loc),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: selectedLocation?.id == loc.id ? AppConstants.accentCyan : AppConstants.surfaceElevated,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: AppConstants.accentCyan, width: 1.5),
                                    boxShadow: AppConstants.glowShadow(AppConstants.accentCyan),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.location_on,
                                        size: 14,
                                        color: selectedLocation?.id == loc.id ? Colors.black : AppConstants.accentCyan,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        loc.name,
                                        style: TextStyle(
                                          color: selectedLocation?.id == loc.id ? Colors.black : Colors.white,
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // SELECTED LOCATION DETAILS PANEL
          if (selectedLocation != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: 20,
              child: ExamVerseCard(
                gradient: AppConstants.darkCardGradient,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(selectedLocation!.name, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white70, size: 18),
                          onPressed: () => setState(() => selectedLocation = null),
                        ),
                      ],
                    ),
                    Text('${selectedLocation!.state}, ${selectedLocation!.country}', style: const TextStyle(color: AppConstants.accentCyan, fontSize: 12)),
                    const SizedBox(height: 8),
                    Text(selectedLocation!.shortDescription, style: const TextStyle(color: AppConstants.textSecondary, fontSize: 12.5)),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('PYQs: ${selectedLocation!.pyqCount}', style: const TextStyle(color: AppConstants.accentEmerald, fontSize: 12, fontWeight: FontWeight.bold)),
                        SecondaryButton(
                          label: 'View Facts →',
                          onPressed: () => _showFacts(selectedLocation!),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
