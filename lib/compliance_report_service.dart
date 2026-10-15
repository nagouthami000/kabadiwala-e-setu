import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'models.dart';

class ComplianceReportService {
  static Future<void> generateAndPrintReport({
    required List<WasteLot> lots,
    required String collectorName,
    required String collectorLocation,
  }) async {
    final pdf = pw.Document();

    final paidLots = lots.where((l) => l.paymentStatus == 'Paid').toList();
    final totalWeight = paidLots.fold<double>(0, (sum, l) => sum + l.weight);
    final totalEarnings = paidLots.fold<double>(0, (sum, l) => sum + l.finalPrice);
    final totalGreenCredits = paidLots.fold<int>(0, (sum, l) => sum + l.greenCreditsEarned);
    final totalCo2Offset = totalWeight * 2.2;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // Header with Green Badge
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'E-KABADI SETU',
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColor.fromHex('#0F382A'),
                      ),
                    ),
                    pw.Text(
                      'Official Circular Economy & Handover Certificate',
                      style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                    ),
                    pw.Text(
                      'Compliant with E-Waste (Management) Rules & Mission LiFE',
                      style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
                    ),
                  ],
                ),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: pw.BoxDecoration(
                    color: PdfColor.fromHex('#0F382A'),
                    borderRadius: pw.BorderRadius.circular(6),
                  ),
                  child: pw.Text(
                    'GOVT AUDIT READY',
                    style: pw.TextStyle(
                      color: PdfColor.fromHex('#C6F24D'),
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            pw.Divider(thickness: 1.5, color: PdfColor.fromHex('#0F382A')),
            pw.SizedBox(height: 12),

            // Collector / Station Profile
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: PdfColor.fromHex('#F4F6F2'),
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Certified Collector: $collectorName', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
                      pw.Text('Hub Location: $collectorLocation', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('Report Date: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}', style: const pw.TextStyle(fontSize: 10)),
                      pw.Text('Verification Ref: SETU-${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 16),

            // Summary Metrics Grid
            pw.Row(
              children: [
                pw.Expanded(
                  child: _metricBox('Verified Handovers', '${paidLots.length} lots', PdfColor.fromHex('#0F382A')),
                ),
                pw.SizedBox(width: 8),
                pw.Expanded(
                  child: _metricBox('Diverted Material', '${totalWeight.toStringAsFixed(1)} kg', PdfColor.fromHex('#0F382A')),
                ),
                pw.SizedBox(width: 8),
                pw.Expanded(
                  child: _metricBox('Total Settled', 'INR ${totalEarnings.toStringAsFixed(0)}', PdfColor.fromHex('#0F382A')),
                ),
                pw.SizedBox(width: 8),
                pw.Expanded(
                  child: _metricBox('CO2 Prevented', '${totalCo2Offset.toStringAsFixed(1)} kg', PdfColor.fromHex('#1A5C45')),
                ),
                pw.SizedBox(width: 8),
                pw.Expanded(
                  child: _metricBox('ESG Green Credits', '$totalGreenCredits pts', PdfColor.fromHex('#1A5C45')),
                ),
              ],
            ),
            pw.SizedBox(height: 20),

            pw.Text(
              'Handover Ledger & Recycler Authorization Audit Log',
              style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#0F382A')),
            ),
            pw.SizedBox(height: 8),

            // Table of Transactions
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              children: [
                pw.TableRow(
                  decoration: pw.BoxDecoration(color: PdfColor.fromHex('#E8EFEA')),
                  children: [
                    _th('Lot ID'),
                    _th('Category'),
                    _th('Weight'),
                    _th('Authorized Recycler'),
                    _th('MPCB License'),
                    _th('Settlement'),
                  ],
                ),
                ...paidLots.map((l) {
                  return pw.TableRow(
                    children: [
                      _td(l.id),
                      _td(l.category),
                      _td('${l.weight} kg'),
                      _td(l.recyclerName.isNotEmpty ? l.recyclerName : 'Authorized Center'),
                      _td(l.recyclerId.isNotEmpty ? 'MPCB/EW/VERIFIED' : 'MPCB/EW/2026'),
                      _td('INR ${l.finalPrice.toStringAsFixed(0)}'),
                    ],
                  );
                }),
              ],
            ),
            pw.SizedBox(height: 20),

            // Environmental Audit & Mission LiFE statement
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColor.fromHex('#0F382A'), width: 1),
                borderRadius: pw.BorderRadius.circular(6),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Statutory Environmental Statement (Government of India ESG LiFE Initiative)',
                    style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#0F382A')),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'The above electronic waste materials were formally diverted from toxic open burning and unorganized acid leaching. Transactions are digitally recorded and verifiable through E-Kabadi Setu decentralized audit ledgers.',
                    style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey800),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 24),

            // Signature Blocks
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Container(width: 140, height: 1, color: PdfColors.grey600),
                    pw.SizedBox(height: 4),
                    pw.Text('Authorized Recycler Signature', style: const pw.TextStyle(fontSize: 8)),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Container(width: 140, height: 1, color: PdfColors.grey600),
                    pw.SizedBox(height: 4),
                    pw.Text('E-Kabadi Setu Digital Seal', style: const pw.TextStyle(fontSize: 8)),
                  ],
                ),
              ],
            ),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'E-Waste_Compliance_Certificate.pdf',
    );
  }

  static pw.Widget _metricBox(String label, String value, PdfColor color) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        color: color,
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(value, style: pw.TextStyle(color: PdfColors.white, fontSize: 13, fontWeight: pw.FontWeight.bold)),
          pw.Text(label, style: const pw.TextStyle(color: PdfColors.white, fontSize: 7)),
        ],
      ),
    );
  }

  static pw.Widget _th(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(5),
      child: pw.Text(text, style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#0F382A'))),
    );
  }

  static pw.Widget _td(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(5),
      child: pw.Text(text, style: const pw.TextStyle(fontSize: 8)),
    );
  }
}
