import 'package:flutter/material.dart';
import '../../core/constants.dart';
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
                          onPressed: () {},
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
