import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'localization_service.dart';
import 'models.dart';
import 'sarvam_service.dart';

typedef LotSaver = Future<void> Function(WasteLot lot);

class HandoverPage extends StatefulWidget {
  const HandoverPage({
    super.key,
    required this.lot,
    required this.recycler,
    required this.onSave,
    required this.language,
    required this.sarvam,
  });

  final WasteLot lot;
  final RecyclerInfo recycler;
  final LotSaver onSave;
  final IndicLanguage language;
  final SarvamAiService sarvam;

  @override
  State<HandoverPage> createState() => _HandoverPageState();
}

class _HandoverPageState extends State<HandoverPage> {
  String paymentMode = 'Cash';
  bool confirmed = false;

  void _shareOnWhatsApp() async {
    final text = '''
*✅ E-KABADI SETU - OFFICIAL HANDOVER PASS*
---------------------------------------
*Lot ID:* ${widget.lot.id}
*Material:* ${widget.lot.category}
*Weight:* ${widget.lot.weight} kg
*Authorized Recycler:* ${widget.recycler.name}
*Govt Authorization:* ${widget.recycler.authorization}
*Agreed Settlement:* ₹${widget.lot.quotedPrice.toStringAsFixed(0)}
*Handover Status:* Verified & Recorded
*Date:* ${widget.lot.createdAt.day}/${widget.lot.createdAt.month}/${widget.lot.createdAt.year}
---------------------------------------
_Digital sovereign e-waste circular compliance under CPCB & State PCB guidelines._
''';
    final url = Uri.parse('https://wa.me/?text=${Uri.encodeComponent(text)}');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = jsonEncode({
      'lot_id': widget.lot.id,
      'category': widget.lot.category,
      'weight': widget.lot.weight,
      'recycler_id': widget.recycler.id,
      'authorization': widget.recycler.authorization,
      'timestamp': widget.lot.createdAt.toIso8601String(),
      'location': widget.lot.location,
      'digital_signature': 'SETHU-SECURE-${widget.lot.id.hashCode.abs()}',
    });

    final lang = widget.language;

    return Scaffold(
      backgroundColor: const Color(0xFF0C241B),
      appBar: AppBar(
        title: Text(
          LocalizationService.text(lang, 'digital_handover_title', fallback: 'Digital Handover & Pass'),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF0C241B),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF163E2E), Color(0xFF1F543F)],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0x554DF2C6), width: 1.4),
            ),
            child: Row(
              children: [
                const Icon(Icons.verified_user_rounded, size: 40, color: Color(0xFFC6F24D)),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        LocalizationService.text(lang, 'verified_pass', fallback: 'VERIFIED PASS'),
                        style: const TextStyle(color: Color(0xFFC6F24D), fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        widget.lot.id,
                        style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0x664DF2C6), width: 2),
                boxShadow: const [
                  BoxShadow(color: Colors.black26, blurRadius: 14, offset: Offset(0, 4)),
                ],
              ),
              child: QrImageView(data: data, size: 200),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            color: const Color(0xFF163E2E),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: Color(0x554DF2C6), width: 1.4),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _detailRow(
                    LocalizationService.text(lang, 'material_label', fallback: 'Material'),
                    LocalizationService.categoryName(lang, widget.lot.category),
                    highlight: true,
                  ),
                  _detailRow(
                    LocalizationService.text(lang, 'approx_weight', fallback: 'Approx. Weight'),
                    '${widget.lot.weight} kg',
                  ),
                  _detailRow(
                    LocalizationService.text(lang, 'agreed_value', fallback: 'Agreed Value'),
                    '₹${widget.lot.quotedPrice.toStringAsFixed(0)}',
                    isGold: true,
                  ),
                  _detailRow(
                    LocalizationService.text(lang, 'recycler_label', fallback: 'Recycler'),
                    widget.recycler.name,
                  ),
                  _detailRow(
                    LocalizationService.text(lang, 'govt_auth', fallback: 'Govt Auth'),
                    widget.recycler.authorization,
                  ),
                  _detailRow(
                    LocalizationService.text(lang, 'composition', fallback: 'Composition'),
                    widget.lot.compositionBreakdown,
                  ),
                  _detailRow(
                    LocalizationService.text(lang, 'hazard_level', fallback: 'Hazard Level'),
                    widget.lot.hazardLevel,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: _shareOnWhatsApp,
            icon: const Icon(Icons.share_rounded, color: Color(0xFF38BDF8)),
            label: Text(
              LocalizationService.text(lang, 'whatsapp_share', fallback: 'Share Pass on WhatsApp'),
              style: const TextStyle(color: Color(0xFF38BDF8), fontWeight: FontWeight.bold),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: const BorderSide(color: Color(0xFF38BDF8), width: 1.4),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 14),
          SegmentedButton<String>(
            segments: [
              ButtonSegment(
                value: 'Cash',
                icon: const Icon(Icons.payments_rounded),
                label: Text(LocalizationService.text(lang, 'cash_mode', fallback: 'Cash')),
              ),
              ButtonSegment(
                value: 'Digital UPI',
                icon: const Icon(Icons.qr_code_rounded),
                label: Text(LocalizationService.text(lang, 'digital_upi_mode', fallback: 'Digital UPI')),
              ),
            ],
            selected: {paymentMode},
            onSelectionChanged: (s) => setState(() => paymentMode = s.first),
          ),
          const SizedBox(height: 10),
          CheckboxListTile(
            value: confirmed,
            onChanged: (v) => setState(() => confirmed = v ?? false),
            title: Text(
              LocalizationService.text(lang, 'handover_confirm_text', fallback: 'Authorized buyer verified material and confirmed settlement'),
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
            ),
            subtitle: Text(
              LocalizationService.text(lang, 'cpcb_rule_text', fallback: 'Compliant transaction under E-Waste (Management) Rules.'),
              style: const TextStyle(color: Colors.white60),
            ),
            controlAffinity: ListTileControlAffinity.leading,
          ),
          const SizedBox(height: 10),
          FilledButton.icon(
            onPressed: !confirmed
                ? null
                : () async {
                    final credits = (widget.lot.weight * 25).toInt();
                    final completed = widget.lot.copyWith(
                      finalPrice: widget.lot.quotedPrice,
                      status: 'Handed over',
                      paymentStatus: 'Paid',
                      paymentMode: paymentMode,
                      synced: false,
                      greenCreditsEarned: credits,
                    );
                    await widget.onSave(completed);

                    // Voice announcement via Sarvam
                    final voiceMsg = lang == IndicLanguage.hindi
                        ? 'हस्तांतरण सफलतापूर्वक पूरा हुआ। आपको $credits ग्रीन क्रेडिट मिले।'
                        : lang == IndicLanguage.marathi
                            ? 'हस्तांतरण यशस्वीरीत्या पूर्ण झाले. तुम्हाला $credits ग्रीन क्रेडिट मिळाले.'
                            : 'Handover complete. You earned $credits Green Credits.';
                    widget.sarvam.speakText(text: voiceMsg, language: lang);

                    if (!context.mounted) return;
                    showDialog<void>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        backgroundColor: const Color(0xFF0F261E),
                        icon: const Icon(Icons.check_circle_rounded, color: Color(0xFFC6F24D), size: 55),
                        title: Text(
                          LocalizationService.text(lang, 'handover_verified_dialog', fallback: 'Handover Verified!'),
                          style: const TextStyle(color: Colors.white),
                        ),
                        content: Text('Lot ${widget.lot.id} successfully recorded. Earned +$credits ESG Green Credits.', style: const TextStyle(color: Colors.white70)),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.pop(ctx);
                              Navigator.pop(context);
                            },
                            child: Text(
                              LocalizationService.text(lang, 'done', fallback: 'Done'),
                              style: const TextStyle(color: Color(0xFFC6F24D)),
                            ),
                          )
                        ],
                      ),
                    );
                  },
            icon: const Icon(Icons.handshake_rounded),
            label: Text(
              LocalizationService.text(lang, 'btn_complete_handover', fallback: 'Complete Verified Handover'),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFC6F24D),
              foregroundColor: const Color(0xFF081510),
              minimumSize: const Size.fromHeight(54),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value, {bool highlight = false, bool isGold = false}) {
    Color valueColor = Colors.white;
    if (isGold) {
      valueColor = const Color(0xFFFFD54F);
    } else if (highlight) {
      valueColor = const Color(0xFF4DF2C6);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 120, child: Text(label, style: const TextStyle(color: Colors.white60, fontSize: 13))),
          Expanded(child: Text(value, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: valueColor))),
        ],
      ),
    );
  }
}
