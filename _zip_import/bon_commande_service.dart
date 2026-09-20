import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../core/models/quote_request.dart';
import '../../core/models/app_user.dart';

class BonCommandeService {
  // ── Generate PDF ──────────────────────────────────────────────────────────
  static Future<Uint8List> generate({
    required QuoteRequest request,
    required AppUser customer,
  }) async {
    final pdf   = pw.Document();
    final fmt   = DateFormat('dd/MM/yyyy');
    final now   = DateTime.now();
    final ref   = 'BC-${DateFormat('yyyyMMdd').format(now)}'
                  '-${request.id.substring(0, 6).toUpperCase()}';

    // Use PDF built-in fonts — no asset files needed
    final fontNormal = pw.Font.helvetica();
    final fontBold   = pw.Font.helveticaBold();

    const navy   = PdfColor.fromInt(0xFF1A237E);
    const gold   = PdfColor.fromInt(0xFFD4A853);
    const grey50 = PdfColor.fromInt(0xFFF8F9FC);
    const grey   = PdfColor.fromInt(0xFF6B7280);
    const darkText = PdfColor.fromInt(0xFF374151);

    final details = request.details;
    final isGift  = request.type == RequestType.gift;

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (ctx) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [

              // ── Top header bar ──────────────────────────────────────
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                    horizontal: 20, vertical: 16),
                decoration: const pw.BoxDecoration(color: navy),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('INWIN',
                          style: pw.TextStyle(
                            font: fontBold, fontSize: 22,
                            color: PdfColors.white,
                            letterSpacing: 1.5)),
                        pw.Text('FROM IDEA TO REALISATION',
                          style: pw.TextStyle(
                            font: fontNormal, fontSize: 8,
                            color: gold, letterSpacing: 2)),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text('BON DE COMMANDE',
                          style: pw.TextStyle(
                            font: fontBold, fontSize: 14,
                            color: PdfColors.white)),
                        pw.SizedBox(height: 4),
                        pw.Text(ref,
                          style: pw.TextStyle(
                            font: fontNormal, fontSize: 10,
                            color: gold)),
                      ],
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),

              // ── Client + order info ─────────────────────────────────
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(child: pw.Container(
                    padding: const pw.EdgeInsets.all(14),
                    decoration: const pw.BoxDecoration(
                      color: grey50,
                      borderRadius: pw.BorderRadius.all(
                          pw.Radius.circular(4))),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('CLIENT',
                          style: pw.TextStyle(
                            font: fontBold, fontSize: 9,
                            color: navy, letterSpacing: 1)),
                        pw.SizedBox(height: 8),
                        pw.Text(customer.fullName,
                          style: pw.TextStyle(
                            font: fontBold, fontSize: 12)),
                        pw.Text(customer.companyName,
                          style: pw.TextStyle(
                            font: fontNormal, fontSize: 11)),
                        pw.SizedBox(height: 4),
                        pw.Text(customer.email,
                          style: pw.TextStyle(
                            font: fontNormal,
                            fontSize: 9, color: grey)),
                        pw.Text(customer.phone,
                          style: pw.TextStyle(
                            font: fontNormal,
                            fontSize: 9, color: grey)),
                      ],
                    ),
                  )),
                  pw.SizedBox(width: 12),
                  pw.Expanded(child: pw.Container(
                    padding: const pw.EdgeInsets.all(14),
                    decoration: const pw.BoxDecoration(
                      color: grey50,
                      borderRadius: pw.BorderRadius.all(
                          pw.Radius.circular(4))),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('COMMANDE',
                          style: pw.TextStyle(
                            font: fontBold, fontSize: 9,
                            color: navy, letterSpacing: 1)),
                        pw.SizedBox(height: 8),
                        _infoRow(fontBold, fontNormal,
                          'Référence', ref),
                        _infoRow(fontBold, fontNormal,
                          'Date', fmt.format(now)),
                        _infoRow(fontBold, fontNormal,
                          'Type',
                          isGift
                            ? "Cadeau d'entreprise"
                            : 'Événement'),
                        _infoRow(fontBold, fontNormal,
                          'Statut', 'Devis accepté'),
                      ],
                    ),
                  )),
                ],
              ),
              pw.SizedBox(height: 20),

              // ── Details table ───────────────────────────────────────
              pw.Text('DÉTAIL DE LA COMMANDE',
                style: pw.TextStyle(
                  font: fontBold, fontSize: 9,
                  color: navy, letterSpacing: 1)),
              pw.SizedBox(height: 8),
              pw.Table(
                border: pw.TableBorder.all(
                  color: const PdfColor.fromInt(0xFFE8EAED),
                  width: 0.5),
                columnWidths: {
                  0: const pw.FlexColumnWidth(1),
                  1: const pw.FlexColumnWidth(2),
                },
                children: [
                  // Header
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: navy),
                    children: [
                      _th(fontBold, 'Désignation'),
                      _th(fontBold, 'Détail'),
                    ],
                  ),
                  // Body rows
                  if (details['category'] != null)
                    _tr(fontNormal, fontBold, 'Catégorie',
                        details['category'], true),
                  if (details['model'] != null)
                    _tr(fontNormal, fontBold, 'Modèle',
                        details['model'], false),
                  if (details['material'] != null)
                    _tr(fontNormal, fontBold, 'Matière',
                        details['material'], true),
                  if (details['quantity'] != null)
                    _tr(fontNormal, fontBold, 'Quantité',
                        '${details['quantity']} unités', false),
                  if (details['eventType'] != null)
                    _tr(fontNormal, fontBold, "Type d'événement",
                        details['eventType'], true),
                  if (details['eventDate'] != null)
                    _tr(fontNormal, fontBold, "Date de l'événement",
                        fmt.format(DateTime.parse(
                            details['eventDate'])), false),
                  if (details['location'] != null)
                    _tr(fontNormal, fontBold, 'Lieu',
                        details['location'], true),
                  if (details['participants'] != null)
                    _tr(fontNormal, fontBold, 'Participants',
                        '${details['participants']}', false),
                  if (details['ambiance'] != null)
                    _tr(fontNormal, fontBold, 'Ambiance',
                        details['ambiance'], true),
                  if (details['note'] != null &&
                      details['note'].toString().isNotEmpty)
                    _tr(fontNormal, fontBold, 'Note client',
                        details['note'], false),
                  if (details['logoPosition'] != null)
                    _tr(fontNormal, fontBold, 'Position logo',
                        "Définie via l'app INWIN", true),
                ],
              ),
              pw.SizedBox(height: 20),

              // ── Financial summary ───────────────────────────────────
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Container(
                    width: 260,
                    child: pw.Column(children: [
                      _fin(fontNormal, fontBold,
                        'Montant HT',
                        _ht(request.quotedPrice!)),
                      _fin(fontNormal, fontBold,
                        'TVA (19%)',
                        _tva(request.quotedPrice!)),
                      pw.Container(
                        height: 0.5,
                        color: const PdfColor.fromInt(0xFFE8EAED)),
                      _fin(fontNormal, fontBold,
                        'TOTAL TTC',
                        '${request.quotedPrice!.toStringAsFixed(3)} TND',
                        isTotal: true),
                      pw.SizedBox(height: 4),
                      _fin(fontNormal, fontBold,
                        'Acompte dû (50%)',
                        _half(request.quotedPrice!),
                        highlight: true),
                      _fin(fontNormal, fontBold,
                        'Solde à la livraison (50%)',
                        _half(request.quotedPrice!)),
                    ]),
                  ),
                ],
              ),
              pw.SizedBox(height: 20),

              // ── Payment instructions ────────────────────────────────
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: const PdfColor.fromInt(0xFFFFF8E6),
                  border: pw.Border.all(color: gold, width: 0.8),
                  borderRadius: const pw.BorderRadius.all(
                      pw.Radius.circular(4))),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('MODALITÉS DE PAIEMENT',
                      style: pw.TextStyle(
                        font: fontBold, fontSize: 9,
                        color: const PdfColor.fromInt(0xFF8B6400),
                        letterSpacing: 1)),
                    pw.SizedBox(height: 6),
                    pw.Text(
                      '• Virement bancaire : [RIB INWIN à compléter]\n'
                      '• Chèque à l\'ordre de INWIN\n'
                      '• Espèces (remise en main propre)\n\n'
                      "L'acompte de 50% est exigé avant tout démarrage "
                      'de production. Aucune commande ne sera traitée '
                      'sans réception du présent bon de commande signé '
                      'accompagné de l\'acompte.',
                      style: pw.TextStyle(
                        font: fontNormal,
                        fontSize: 9,
                        color: const PdfColor.fromInt(0xFF5C4000),
                        lineSpacing: 3)),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),

              // ── Signature blocks ────────────────────────────────────
              pw.Row(children: [
                pw.Expanded(child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Signature et cachet du client',
                      style: pw.TextStyle(
                        font: fontBold, fontSize: 9, color: navy)),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Précédée de la mention :\n'
                      '"Lu et approuvé — Bon pour accord"',
                      style: pw.TextStyle(
                        font: fontNormal,
                        fontSize: 8, color: grey)),
                    pw.SizedBox(height: 50),
                    pw.Container(height: 0.5,
                      color: const PdfColor.fromInt(0xFFD1D5DB)),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      '${customer.fullName}  —  ${customer.companyName}',
                      style: pw.TextStyle(
                        font: fontNormal, fontSize: 8, color: grey)),
                    pw.Text(fmt.format(now),
                      style: pw.TextStyle(
                        font: fontNormal, fontSize: 8, color: grey)),
                  ],
                )),
                pw.SizedBox(width: 30),
                pw.Expanded(child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Pour INWIN',
                      style: pw.TextStyle(
                        font: fontBold, fontSize: 9, color: navy)),
                    pw.SizedBox(height: 4),
                    pw.Text('Responsable commercial',
                      style: pw.TextStyle(
                        font: fontNormal, fontSize: 8, color: grey)),
                    pw.SizedBox(height: 50),
                    pw.Container(height: 0.5,
                      color: const PdfColor.fromInt(0xFFD1D5DB)),
                    pw.SizedBox(height: 4),
                    pw.Text('INWIN  —  Tunis, Tunisie',
                      style: pw.TextStyle(
                        font: fontNormal, fontSize: 8, color: grey)),
                  ],
                )),
              ]),
              pw.SizedBox(height: 14),

              // ── Legal footer ────────────────────────────────────────
              pw.Divider(
                color: const PdfColor.fromInt(0xFFE8EAED)),
              pw.SizedBox(height: 6),
              pw.Text(
                'Ce document est soumis aux Conditions Générales de Vente '
                "d'INWIN disponibles sur l'application. Toute commande "
                'implique l\'acceptation sans réserve des CGV. '
                'En cas de litige, les tribunaux de Tunis seront seuls compétents.',
                style: pw.TextStyle(
                  font: fontNormal, fontSize: 7,
                  color: grey),
                textAlign: pw.TextAlign.center),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  // ── Share/print via system sheet ──────────────────────────────────────────
  static Future<void> printOrShare(Uint8List bytes) async {
    await Printing.sharePdf(
        bytes: bytes, filename: 'bon_de_commande.pdf');
  }

  // ── Save to documents folder ──────────────────────────────────────────────
  static Future<String> saveToDevice(Uint8List bytes, String ref) async {
    final dir  = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$ref.pdf');
    await file.writeAsBytes(bytes);
    return file.path;
  }

  // ── Math helpers ──────────────────────────────────────────────────────────
  static String _ht(double ttc) =>
      '${(ttc / 1.19).toStringAsFixed(3)} TND';
  static String _tva(double ttc) =>
      '${(ttc - ttc / 1.19).toStringAsFixed(3)} TND';
  static String _half(double ttc) =>
      '${(ttc / 2).toStringAsFixed(3)} TND';
}

// ─── PDF helper functions (module-level, not inside the class) ────────────

pw.Widget _th(pw.Font bold, String text) => pw.Padding(
  padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 7),
  child: pw.Text(text,
    style: pw.TextStyle(font: bold, fontSize: 9,
        color: PdfColors.white)));

pw.TableRow _tr(
  pw.Font normal,
  pw.Font bold,
  String label,
  dynamic value,
  bool shaded,
) => pw.TableRow(
  decoration: pw.BoxDecoration(
    color: shaded
        ? const PdfColor.fromInt(0xFFF8F9FC)
        : PdfColors.white),
  children: [
    pw.Padding(
      padding: const pw.EdgeInsets.symmetric(
          horizontal: 10, vertical: 7),
      child: pw.Text(label,
        style: pw.TextStyle(font: bold, fontSize: 9,
            color: const PdfColor.fromInt(0xFF374151)))),
    pw.Padding(
      padding: const pw.EdgeInsets.symmetric(
          horizontal: 10, vertical: 7),
      child: pw.Text('$value',
        style: pw.TextStyle(font: normal, fontSize: 9))),
  ],
);

pw.Widget _infoRow(
  pw.Font bold,
  pw.Font normal,
  String label,
  String value,
) => pw.Padding(
  padding: const pw.EdgeInsets.only(bottom: 4),
  child: pw.Row(
    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
    children: [
      pw.Text('$label :',
        style: pw.TextStyle(
          font: bold, fontSize: 9,
          color: const PdfColor.fromInt(0xFF6B7280))),
      pw.Text(value,
        style: pw.TextStyle(font: normal, fontSize: 9)),
    ],
  ),
);

pw.Widget _fin(
  pw.Font normal,
  pw.Font bold,
  String label,
  String value, {
  bool isTotal = false,
  bool highlight = false,
}) => pw.Container(
  padding: const pw.EdgeInsets.symmetric(
      horizontal: 10, vertical: 6),
  color: isTotal
      ? const PdfColor.fromInt(0xFF1A237E)
      : highlight
          ? const PdfColor.fromInt(0xFFE8EAF6)
          : null,
  child: pw.Row(
    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
    children: [
      pw.Text(label,
        style: pw.TextStyle(
          font: isTotal || highlight ? bold : normal,
          fontSize: isTotal ? 10 : 9,
          color: isTotal
              ? PdfColors.white
              : const PdfColor.fromInt(0xFF374151))),
      pw.Text(value,
        style: pw.TextStyle(
          font: isTotal || highlight ? bold : normal,
          fontSize: isTotal ? 10 : 9,
          color: isTotal
              ? PdfColors.white
              : highlight
                  ? const PdfColor.fromInt(0xFF1A237E)
                  : const PdfColor.fromInt(0xFF374151))),
    ],
  ),
);
