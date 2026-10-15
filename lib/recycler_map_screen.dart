import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'localization_service.dart';
import 'models.dart';

class RecyclerMapScreen extends StatefulWidget {
  const RecyclerMapScreen({
    super.key,
    required this.recyclers,
    required this.language,
  });

  final List<RecyclerInfo> recyclers;
  final IndicLanguage language;

  @override
  State<RecyclerMapScreen> createState() => _RecyclerMapScreenState();
}

class _RecyclerMapScreenState extends State<RecyclerMapScreen> {
  final MapController _mapController = MapController();
  String _selectedRegion = 'All India';

  static const _indiaCenter = LatLng(21.5, 78.9);

  void _moveTo(LatLng center, double zoom, String region) {
    setState(() => _selectedRegion = region);
    _mapController.move(center, zoom);
  }

  @override
  Widget build(BuildContext context) {
    const primaryDark = Color(0xFF0F382A);
    const accentLime = Color(0xFFC6F24D);
    const mintGlow = Color(0xFF4DF2C6);
    const inkDark = Color(0xFF081510);
    const surfaceEmerald = Color(0xFF0F261E);

    return Scaffold(
      backgroundColor: inkDark,
      appBar: AppBar(
        title: Text(
          widget.language == IndicLanguage.hindi
              ? 'अखिल भारतीय अधिकृत रीसायकलर'
              : widget.language == IndicLanguage.marathi
                  ? 'अखिल भारतीय अधिकृत रिसायकलर'
                  : 'All-India Authorized Recyclers Map',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        backgroundColor: primaryDark,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: const MapOptions(
              initialCenter: _indiaCenter,
              initialZoom: 4.8,
              minZoom: 3.5,
              maxZoom: 18.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.ekabadi.setu',
              ),
              MarkerLayer(
                markers: widget.recyclers.map((rec) {
                  return Marker(
                    point: rec.latLng,
                    width: 50,
                    height: 50,
                    child: GestureDetector(
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          backgroundColor: surfaceEmerald,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                            side: BorderSide(color: Color(0x334DF2C6)),
                          ),
                          builder: (ctx) => Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.verified_rounded, color: accentLime, size: 28),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        rec.name,
                                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text('${rec.location} • ${rec.distanceKm} km away', style: const TextStyle(color: mintGlow)),
                                const SizedBox(height: 6),
                                Text('Govt Auth: ${rec.authorization}', style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.white70)),
                                const SizedBox(height: 12),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  children: rec.categories
                                      .map((c) => Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: primaryDark,
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(color: const Color(0x334DF2C6)),
                                            ),
                                            child: Text(c, style: const TextStyle(fontSize: 12, color: Colors.white)),
                                          ))
                                      .toList(),
                                ),
                                const SizedBox(height: 16),
                                FilledButton.icon(
                                  onPressed: () async {
                                    final uri = Uri.parse('tel:${rec.phone.replaceAll(' ', '')}');
                                    if (await canLaunchUrl(uri)) launchUrl(uri);
                                  },
                                  style: FilledButton.styleFrom(
                                    backgroundColor: accentLime,
                                    foregroundColor: inkDark,
                                    minimumSize: const Size.fromHeight(48),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  icon: const Icon(Icons.call_rounded),
                                  label: Text('Contact ${rec.phone}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: primaryDark,
                          shape: BoxShape.circle,
                          border: Border.all(color: accentLime, width: 2),
                          boxShadow: const [
                            BoxShadow(color: Colors.black45, blurRadius: 6),
                          ],
                        ),
                        child: const Icon(Icons.factory_rounded, color: accentLime, size: 24),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),

          // Floating Indian Region Quick Jump Bar
          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _regionChip('All India', _indiaCenter, 4.8),
                  const SizedBox(width: 6),
                  _regionChip('Karnataka', const LatLng(13.6, 76.6), 7.2),
                  const SizedBox(width: 6),
                  _regionChip('Maharashtra', const LatLng(18.9, 74.5), 7.0),
                  const SizedBox(width: 6),
                  _regionChip('Delhi NCR', const LatLng(28.5, 77.2), 8.5),
                  const SizedBox(width: 6),
                  _regionChip('Tamil Nadu', const LatLng(12.5, 79.5), 7.2),
                  const SizedBox(width: 6),
                  _regionChip('Telangana', const LatLng(17.4, 78.5), 8.0),
                  const SizedBox(width: 6),
                  _regionChip('Gujarat', const LatLng(22.8, 72.3), 7.5),
                  const SizedBox(width: 6),
                  _regionChip('West Bengal', const LatLng(22.6, 88.3), 7.5),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _regionChip(String title, LatLng target, double zoom) {
    final active = _selectedRegion == title;
    return GestureDetector(
      onTap: () => _moveTo(target, zoom, title),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active ? const Color(0xFFC6F24D) : const Color(0xFF0F261E),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF4DF2C6)),
          boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 4)],
        ),
        child: Text(
          title,
          style: TextStyle(
            color: active ? const Color(0xFF081510) : Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
