import 'package:flutter/material.dart';
import 'compliance_report_service.dart';
import 'localization_service.dart';
import 'models.dart';
import 'sarvam_service.dart';

const primaryDark = Color(0xFF0B7A0B);
const accentLime = Color(0xFFC6F24D);
const mintGlow = Color(0xFF4DF2C6);
const inkDark = Color(0xFF0C241B);
const surfaceEmerald = Color(0xFF163E2E);
const cardBorder = Color(0x554DF2C6);
const goldenAmber = Color(0xFFFFD54F);
const skyBlue = Color(0xFF38BDF8);

class RecyclerPortalPage extends StatefulWidget {
  final IndicLanguage language;
  final List<WasteLot> lots;
  final Function(WasteLot) onSaveLot;
  final SarvamAiService sarvam;
  final String recyclerName;

  const RecyclerPortalPage({
    super.key,
    required this.language,
    required this.lots,
    required this.onSaveLot,
    required this.sarvam,
    this.recyclerName = 'EcoRecycle Corp (MPCB Verified)',
  });

  @override
  State<RecyclerPortalPage> createState() => _RecyclerPortalPageState();
}

class _RecyclerPortalPageState extends State<RecyclerPortalPage> {
  final searchCtrl = TextEditingController();
  String selectedFilter = 'all'; // 'all', 'pending', 'settled'
  WasteLot? selectedLotForInspection;

  @override
  void dispose() {
    searchCtrl.dispose();
    super.dispose();
  }

  void _verifyAndSettleLot(WasteLot lot) {
    final updated = lot.copyWith(
      status: 'handed_over',
      paymentStatus: 'paid',
      paymentMode: 'UPI_DIRECT',
      greenCreditsEarned: (lot.weight * 25).round(),
    );
    widget.onSaveLot(updated);
    setState(() {
      selectedLotForInspection = updated;
    });

    final message = widget.language == IndicLanguage.hindi
        ? 'लॉट सफलतापूर्वक सत्यापित हुआ और डिजिटल भुगतान पूरा हुआ।'
        : widget.language == IndicLanguage.marathi
            ? 'लॉट यशस्वीरित्या पडताळला गेला आणि डिजिटल पेमेंट पूर्ण झाले.'
            : 'Lot verified and settlement completed successfully.';
    widget.sarvam.speakText(text: message, language: widget.language);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Lot #${lot.id.substring(0, 8)} marked Verified & Paid!'),
        backgroundColor: surfaceEmerald,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final query = searchCtrl.text.trim().toLowerCase();
    final filteredLots = widget.lots.where((l) {
      final matchesSearch = query.isEmpty ||
          l.id.toLowerCase().contains(query) ||
          l.category.toLowerCase().contains(query) ||
          l.location.toLowerCase().contains(query);
      if (!matchesSearch) return false;

      if (selectedFilter == 'pending') {
        return l.status != 'handed_over' && l.status != 'settled';
      } else if (selectedFilter == 'settled') {
        return l.status == 'handed_over' || l.status == 'settled';
      }
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: inkDark,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // MPCB Recycler Header Hero
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [surfaceEmerald, Color(0xFF1F543F)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: cardBorder, width: 1.4),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(50),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: mintGlow.withAlpha(40),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.factory_rounded, color: mintGlow, size: 22),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.recyclerName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const Text(
                                'MPCB / CPCB Tier-1 Authorized Facility',
                                style: TextStyle(color: mintGlow, fontSize: 11),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: accentLime,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          LocalizationService.text(widget.language, 'portal_mode', fallback: 'PORTAL MODE'),
                          style: const TextStyle(
                            color: Color(0xFF081510),
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(color: Colors.white12),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildHeaderMetric(
                        label: LocalizationService.text(widget.language, 'total_lots_checked', fallback: 'Total Lots Checked'),
                        value: '${widget.lots.length}',
                        color: Colors.white,
                      ),
                      _buildHeaderMetric(
                        label: LocalizationService.text(widget.language, 'pending_intake', fallback: 'Pending Intake'),
                        value: '${widget.lots.where((l) => l.status != 'handed_over').length}',
                        color: accentLime,
                      ),
                      _buildHeaderMetric(
                        label: LocalizationService.text(widget.language, 'verified_settled', fallback: 'Verified & Settled'),
                        value: '${widget.lots.where((l) => l.status == 'handed_over').length}',
                        color: mintGlow,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // Search & QR Pass Lookup Field
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: searchCtrl,
                    style: const TextStyle(color: Colors.white),
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: LocalizationService.text(widget.language, 'search_lots_hint', fallback: 'Search Lot ID, Material or Location...'),
                      hintStyle: const TextStyle(color: Colors.white38),
                      prefixIcon: const Icon(Icons.search_rounded, color: accentLime),
                      suffixIcon: searchCtrl.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, color: Colors.white70),
                              onPressed: () {
                                searchCtrl.clear();
                                setState(() {});
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: surfaceEmerald,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: cardBorder),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: cardBorder),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: accentLime, width: 1.5),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // Filter Chips
            Row(
              children: [
                _buildFilterChip('all', LocalizationService.text(widget.language, 'filter_all', fallback: 'All Intake Lots')),
                const SizedBox(width: 8),
                _buildFilterChip('pending', LocalizationService.text(widget.language, 'filter_pending', fallback: 'Pending Verification')),
                const SizedBox(width: 8),
                _buildFilterChip('settled', LocalizationService.text(widget.language, 'filter_completed', fallback: 'Completed & Paid')),
              ],
            ),

            const SizedBox(height: 16),

            // Lots List or Empty Placeholder
            if (filteredLots.isEmpty)
              Container(
                padding: const EdgeInsets.all(32),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: surfaceEmerald,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: cardBorder, width: 1.4),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.inbox_rounded, size: 48, color: mintGlow),
                    const SizedBox(height: 12),
                    Text(
                      widget.lots.isEmpty
                          ? LocalizationService.text(widget.language, 'no_lots_yet', fallback: 'No scrap lots created yet.\nCreate a lot from the Collector view to inspect it here.')
                          : LocalizationService.text(widget.language, 'no_lots_match', fallback: 'No lots matching this search filter.'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredLots.length,
                itemBuilder: (context, index) {
                  final lot = filteredLots[index];
                  final isSettled = lot.status == 'handed_over' || lot.status == 'settled';

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: 0,
                    color: surfaceEmerald,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: isSettled ? mintGlow : cardBorder,
                        width: isSettled ? 1.6 : 1.4,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: mintGlow.withAlpha(35),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: mintGlow.withAlpha(80)),
                                    ),
                                    child: const Icon(Icons.inventory_2_rounded, color: mintGlow, size: 18),
                                  ),
                                  const SizedBox(width: 10),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Lot #${lot.id.substring(0, 8)}',
                                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Colors.white),
                                      ),
                                      Text(
                                        LocalizationService.categoryName(widget.language, lot.category),
                                        style: const TextStyle(fontSize: 13, color: mintGlow, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: isSettled ? const Color(0x334DF2C6) : const Color(0x33FFD54F),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isSettled ? mintGlow : goldenAmber,
                                    width: 1.2,
                                  ),
                                ),
                                child: Text(
                                  isSettled
                                      ? LocalizationService.text(widget.language, 'badge_verified', fallback: 'VERIFIED & PAID')
                                      : LocalizationService.text(widget.language, 'badge_pending', fallback: 'PENDING INTAKE'),
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                    color: isSettled ? mintGlow : goldenAmber,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${LocalizationService.text(widget.language, 'weight_label', fallback: 'Weight')}: ${lot.weight.toStringAsFixed(1)} kg',
                                style: const TextStyle(fontSize: 13, color: Colors.white70, fontWeight: FontWeight.w500),
                              ),
                              Row(
                                children: [
                                  Text(
                                    '${LocalizationService.text(widget.language, 'payout_label', fallback: 'Payout')}: ',
                                    style: const TextStyle(fontSize: 13, color: Colors.white60),
                                  ),
                                  Text(
                                    '₹${(lot.finalPrice > 0 ? lot.finalPrice : lot.quotedPrice).toStringAsFixed(0)}',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900,
                                      color: goldenAmber,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          if (lot.compositionBreakdown.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              '${LocalizationService.text(widget.language, 'ai_analysis', fallback: 'AI Analysis')}: ${lot.compositionBreakdown}',
                              style: const TextStyle(fontSize: 11, color: Color(0xFFB0D5C7)),
                            ),
                          ],
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              if (!isSettled)
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () => _verifyAndSettleLot(lot),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: accentLime,
                                      foregroundColor: inkDark,
                                      elevation: 3,
                                      shadowColor: accentLime.withAlpha(100),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                    ),
                                    icon: const Icon(Icons.check_circle_rounded, size: 18, color: inkDark),
                                    label: Text(
                                      LocalizationService.text(widget.language, 'btn_verify_settle', fallback: 'Verify & Settle Payout'),
                                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: inkDark),
                                    ),
                                  ),
                                )
                              else
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () => ComplianceReportService.generateAndPrintReport(
                                      lots: [lot],
                                      collectorName: 'Verified Collector',
                                      collectorLocation: lot.location.isNotEmpty ? lot.location : 'Pune, Maharashtra',
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      side: const BorderSide(color: skyBlue, width: 1.4),
                                      foregroundColor: skyBlue,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      padding: const EdgeInsets.symmetric(vertical: 11),
                                    ),
                                    icon: const Icon(Icons.picture_as_pdf_rounded, size: 18, color: skyBlue),
                                    label: Text(
                                      LocalizationService.text(widget.language, 'btn_export_manifest', fallback: 'Export MPCB Audit Manifest'),
                                      style: const TextStyle(color: skyBlue, fontSize: 12, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String filterId, String label) {
    final isSelected = selectedFilter == filterId;
    return InkWell(
      onTap: () => setState(() => selectedFilter = filterId),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? accentLime : surfaceEmerald,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? accentLime : cardBorder,
            width: 1.2,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? inkDark : Colors.white70,
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderMetric({required String label, required String value, required Color color}) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 10),
        ),
      ],
    );
  }
}
