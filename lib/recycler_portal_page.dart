import 'package:flutter/material.dart';
import 'compliance_report_service.dart';
import 'localization_service.dart';
import 'models.dart';
import 'sarvam_service.dart';

const primaryDark = Color(0xFF0F382A);
const accentLime = Color(0xFFC6F24D);
const mintGlow = Color(0xFF4DF2C6);
const inkDark = Color(0xFF081510);
const cardBorder = Color(0x334DF2C6);

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
        backgroundColor: const Color(0xFF0F382A),
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
      backgroundColor: const Color(0xFF081510),
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
                  colors: [inkDark, Color(0xFF0F261E)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0x334DF2C6), width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(60),
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
                        child: const Text(
                          'PORTAL MODE',
                          style: TextStyle(
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
                        label: 'Total Lots Checked',
                        value: '${widget.lots.length}',
                        color: Colors.white,
                      ),
                      _buildHeaderMetric(
                        label: 'Pending Intake',
                        value: '${widget.lots.where((l) => l.status != 'handed_over').length}',
                        color: accentLime,
                      ),
                      _buildHeaderMetric(
                        label: 'Verified & Settled',
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
                      hintText: 'Search Lot ID, Material or Location...',
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
                      fillColor: const Color(0xFF0F261E),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0x334DF2C6)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0x334DF2C6)),
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
                _buildFilterChip('all', 'All Intake Lots'),
                const SizedBox(width: 8),
                _buildFilterChip('pending', 'Pending Verification'),
                const SizedBox(width: 8),
                _buildFilterChip('settled', 'Completed & Paid'),
              ],
            ),

            const SizedBox(height: 16),

            // Lots List or Empty Placeholder
            if (filteredLots.isEmpty)
              Container(
                padding: const EdgeInsets.all(32),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFF0F261E),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0x334DF2C6)),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.inbox_rounded, size: 48, color: mintGlow),
                    const SizedBox(height: 12),
                    Text(
                      widget.lots.isEmpty
                          ? 'No scrap lots created yet.\nCreate a lot from the Collector view to inspect it here.'
                          : 'No lots matching this search filter.',
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
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: isSettled ? const Color(0x334DF2C6) : const Color(0xFFE2E6DF),
                        width: isSettled ? 1.5 : 1,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
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
                                      color: primaryDark.withAlpha(20),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(Icons.inventory_2_rounded, color: primaryDark, size: 18),
                                  ),
                                  const SizedBox(width: 8),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Lot #${lot.id.substring(0, 8)}',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                      ),
                                      Text(
                                        lot.category,
                                        style: const TextStyle(fontSize: 12, color: primaryDark, fontWeight: FontWeight.w600),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isSettled ? Colors.green.shade50 : Colors.amber.shade50,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isSettled ? Colors.green.shade300 : Colors.amber.shade400,
                                  ),
                                ),
                                child: Text(
                                  isSettled ? 'VERIFIED & PAID' : 'PENDING INTAKE',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: isSettled ? Colors.green.shade800 : Colors.amber.shade900,
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
                                'Weight: ${lot.weight.toStringAsFixed(1)} kg',
                                style: const TextStyle(fontSize: 13, color: Colors.black87),
                              ),
                              Text(
                                'Payout: ₹${(lot.finalPrice > 0 ? lot.finalPrice : lot.quotedPrice).toStringAsFixed(0)}',
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: primaryDark),
                              ),
                            ],
                          ),
                          if (lot.compositionBreakdown.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              'AI Analysis: ${lot.compositionBreakdown}',
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                            ),
                          ],
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              if (!isSettled)
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () => _verifyAndSettleLot(lot),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: primaryDark,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      padding: const EdgeInsets.symmetric(vertical: 10),
                                    ),
                                    icon: const Icon(Icons.check_circle_outline_rounded, size: 16),
                                    label: const Text('Verify & Settle Payout', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
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
                                      side: const BorderSide(color: primaryDark),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      padding: const EdgeInsets.symmetric(vertical: 10),
                                    ),
                                    icon: const Icon(Icons.picture_as_pdf_rounded, size: 16, color: primaryDark),
                                    label: const Text('Export MPCB Audit Manifest', style: TextStyle(color: primaryDark, fontSize: 12)),
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
          color: isSelected ? accentLime : const Color(0xFF0F261E),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? accentLime : const Color(0x334DF2C6),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? const Color(0xFF081510) : Colors.white70,
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
