import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../core/models/app_user.dart';
import '../../../core/models/quote_request.dart';

class BonCommandeService {
  static Future<Uint8List> generate({
    required QuoteRequest request,
    required AppUser customer,
  }) async {
    final pdf = pw.Document();
    final fmt = DateFormat('dd/MM/yyyy');
    final now = DateTime.now();
    final ref =
        'BC-${DateFormat('yyyyMMdd').format(now)}-${request.id.substring(0, 6).toUpperCase()}';

    // Load logo
    final logoData =
        await rootBundle.load('assets/images/logo inwin final.png');
    final logoImage = pw.MemoryImage(logoData.buffer.asUint8List());

    final fontNormal = pw.Font.helvetica();
    final fontBold = pw.Font.helveticaBold();

    const navy = PdfColor.fromInt(0xFF1A237E);
    const gold = PdfColor.fromInt(0xFFD4A853);
    const grey50 = PdfColor.fromInt(0xFFF8F9FC);
    const grey = PdfColor.fromInt(0xFF6B7280);

    final details = request.details;
    final isGift = request.type == RequestType.gift;

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Container(
                padding:
                    const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: const pw.BoxDecoration(
                  color: PdfColors.white,
                  border: pw.Border(
                    bottom: pw.BorderSide(color: navy, width: 1.5),
                  ),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Image(logoImage, height: 45),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(
                          'BON DE COMMANDE',
                          style: pw.TextStyle(
                            font: fontBold,
                            fontSize: 16,
                            color: navy,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          ref,
                          style: pw.TextStyle(
                            font: fontNormal,
                            fontSize: 10,
                            color: grey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(14),
                      decoration: const pw.BoxDecoration(
                        color: grey50,
                        borderRadius:
                            pw.BorderRadius.all(pw.Radius.circular(4)),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'CLIENT',
                            style: pw.TextStyle(
                              font: fontBold,
                              fontSize: 9,
                              color: navy,
                              letterSpacing: 1,
                            ),
                          ),
                          pw.SizedBox(height: 8),
                          pw.Text(
                            customer.fullName,
                            style: pw.TextStyle(font: fontBold, fontSize: 12),
                          ),
                          pw.Text(
                            customer.companyName ?? 'Particulier',
                            style: pw.TextStyle(font: fontNormal, fontSize: 11),
                          ),
                          pw.SizedBox(height: 4),
                          pw.Text(
                            customer.email,
                            style: pw.TextStyle(
                              font: fontNormal,
                              fontSize: 9,
                              color: grey,
                            ),
                          ),
                          pw.Text(
                            customer.phone,
                            style: pw.TextStyle(
                              font: fontNormal,
                              fontSize: 9,
                              color: grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  pw.SizedBox(width: 12),
                  pw.Expanded(
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(14),
                      decoration: const pw.BoxDecoration(
                        color: grey50,
                        borderRadius:
                            pw.BorderRadius.all(pw.Radius.circular(4)),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'COMMANDE',
                            style: pw.TextStyle(
                              font: fontBold,
                              fontSize: 9,
                              color: navy,
                              letterSpacing: 1,
                            ),
                          ),
                          pw.SizedBox(height: 8),
                          _infoRow(fontBold, fontNormal, 'Référence', ref),
                          _infoRow(
                            fontBold,
                            fontNormal,
                            'Date',
                            fmt.format(now),
                          ),
                          _infoRow(
                            fontBold,
                            fontNormal,
                            'Type',
                            isGift ? "Cadeau d'entreprise" : 'Événement',
                          ),
                          _infoRow(
                            fontBold,
                            fontNormal,
                            'Statut',
                            'Devis accepté',
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 20),
              pw.Text(
                'DÉTAIL DE LA COMMANDE',
                style: pw.TextStyle(
                  font: fontBold,
                  fontSize: 9,
                  color: navy,
                  letterSpacing: 1,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Table(
                border: pw.TableBorder.all(
                  color: const PdfColor.fromInt(0xFFE8EAED),
                  width: 0.5,
                ),
                columnWidths: {
                  0: const pw.FlexColumnWidth(1),
                  1: const pw.FlexColumnWidth(2),
                },
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: navy),
                    children: [
                      _tableHeader(fontBold, 'Désignation'),
                      _tableHeader(fontBold, 'Détail'),
                    ],
                  ),
                  if (details['category'] != null)
                    _tableRow(
                      fontNormal,
                      fontBold,
                      'Catégorie',
                      details['category'],
                      true,
                    ),
                  if (details['model'] != null)
                    _tableRow(
                      fontNormal,
                      fontBold,
                      'Modèle',
                      details['model'],
                      false,
                    ),
                  if (details['material'] != null)
                    _tableRow(
                      fontNormal,
                      fontBold,
                      'Matière',
                      details['material'],
                      true,
                    ),
                  if (details['quantity'] != null)
                    _tableRow(
                      fontNormal,
                      fontBold,
                      'Quantité',
                      '${details['quantity']} unités',
                      false,
                    ),
                  if (details['eventType'] != null)
                    _tableRow(
                      fontNormal,
                      fontBold,
                      "Type d'événement",
                      details['eventType'],
                      true,
                    ),
                  if (details['eventDate'] != null)
                    _tableRow(
                      fontNormal,
                      fontBold,
                      "Date de l'événement",
                      fmt.format(DateTime.parse(details['eventDate'])),
                      false,
                    ),
                  if (details['venueType'] != null)
                    _tableRow(
                      fontNormal,
                      fontBold,
                      'Type de lieu',
                      details['venueType'],
                      true,
                    ),
                  if (details['venueOther'] != null)
                    _tableRow(
                      fontNormal,
                      fontBold,
                      'Autre lieu',
                      details['venueOther'],
                      false,
                    ),
                  if (details['location'] != null)
                    _tableRow(
                      fontNormal,
                      fontBold,
                      'Lieu',
                      details['location'],
                      true,
                    ),
                  if (details['participants'] != null)
                    _tableRow(
                      fontNormal,
                      fontBold,
                      'Participants',
                      '${details['participants']}',
                      false,
                    ),
                  if (details['budget'] != null)
                    _tableRow(
                      fontNormal,
                      fontBold,
                      'Budget',
                      '${details['budget']}',
                      true,
                    ),
                  if (details['services'] != null)
                    _tableRow(
                      fontNormal,
                      fontBold,
                      'Services',
                      details['services'] is List
                          ? (details['services'] as List).join(', ')
                          : '${details['services']}',
                      false,
                    ),
                  if (details['ambiance'] != null)
                    _tableRow(
                      fontNormal,
                      fontBold,
                      'Ambiance',
                      details['ambiance'],
                      true,
                    ),
                  if (details['colors'] != null)
                    _tableRow(
                      fontNormal,
                      fontBold,
                      'Couleurs Thème',
                      details['colors'] is List
                          ? (details['colors'] as List).map((c) {
                              final s = c.toString();
                              final val = int.tryParse(s);
                              if (val == null) return s;
                              return '#${(val & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';
                            }).join(', ')
                          : details['colors'],
                      false,
                    ),
                  if (details['note'] != null &&
                      details['note'].toString().isNotEmpty)
                    _tableRow(
                      fontNormal,
                      fontBold,
                      'Note client',
                      details['note'],
                      false,
                    ),
                  if (details['logoPosition'] != null ||
                      details['logoPositions'] != null)
                    _tableRow(
                      fontNormal,
                      fontBold,
                      'Position logo',
                      'Définie via l\'app INWIN',
                      true,
                    ),
                  if (details['productColors'] != null)
                    _tableRow(
                      fontNormal,
                      fontBold,
                      'Couleurs produits',
                      (details['productColors'] as Map)
                          .entries
                          .map((e) => '${e.key}: ${e.value}')
                          .join(', '),
                      false,
                    ),
                ],
              ),
              pw.SizedBox(height: 20),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.SizedBox(
                    width: 260,
                    child: pw.Column(
                      children: [
                        _financialRow(
                          fontNormal,
                          fontBold,
                          'Montant HT',
                          _ht(request.quotedPrice!),
                        ),
                        _financialRow(
                          fontNormal,
                          fontBold,
                          'TVA (19%)',
                          _tva(request.quotedPrice!),
                        ),
                        pw.Container(
                          height: 0.5,
                          color: const PdfColor.fromInt(0xFFE8EAED),
                        ),
                        _financialRow(
                          fontNormal,
                          fontBold,
                          'TOTAL TTC',
                          '${request.quotedPrice!.toStringAsFixed(3)} TND',
                          isTotal: true,
                        ),
                        pw.SizedBox(height: 4),
                        _financialRow(
                          fontNormal,
                          fontBold,
                          'Acompte dû (50%)',
                          _half(request.quotedPrice!),
                          highlight: true,
                        ),
                        _financialRow(
                          fontNormal,
                          fontBold,
                          'Solde à la livraison (50%)',
                          _half(request.quotedPrice!),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 20),
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: const PdfColor.fromInt(0xFFFFF8E6),
                  border: pw.Border.all(color: gold, width: 0.8),
                  borderRadius:
                      const pw.BorderRadius.all(pw.Radius.circular(4)),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'MODALITÉS DE PAIEMENT',
                      style: pw.TextStyle(
                        font: fontBold,
                        fontSize: 9,
                        color: const PdfColor.fromInt(0xFF8B6400),
                        letterSpacing: 1,
                      ),
                    ),
                    pw.SizedBox(height: 6),
                    pw.Text(
                      'Paiement en espèces (remise en main propre)\n\nL\'acompte de 50% est exigé avant tout démarrage de production. Aucune commande ne sera traitée sans réception du présent bon de commande signé, cacheté et scanné, accompagné de l\'acompte.',
                      style: pw.TextStyle(
                        font: fontNormal,
                        fontSize: 9,
                        color: const PdfColor.fromInt(0xFF5C4000),
                        lineSpacing: 3,
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Row(
                children: [
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'Signature et cachet du client',
                          style: pw.TextStyle(
                            font: fontBold,
                            fontSize: 9,
                            color: navy,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          'À signer, cacheter et scanner.\nMention : "Lu et approuvé - Bon pour accord"',
                          style: pw.TextStyle(
                            font: fontNormal,
                            fontSize: 8,
                            color: grey,
                          ),
                        ),
                        pw.SizedBox(height: 50),
                        pw.Container(
                          height: 0.5,
                          color: const PdfColor.fromInt(0xFFD1D5DB),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          '${customer.fullName} - ${customer.companyName}',
                          style: pw.TextStyle(
                            font: fontNormal,
                            fontSize: 8,
                            color: grey,
                          ),
                        ),
                        pw.Text(
                          fmt.format(now),
                          style: pw.TextStyle(
                            font: fontNormal,
                            fontSize: 8,
                            color: grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  pw.SizedBox(width: 30),
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'Pour INWIN',
                          style: pw.TextStyle(
                            font: fontBold,
                            fontSize: 9,
                            color: navy,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          'Responsable commercial',
                          style: pw.TextStyle(
                            font: fontNormal,
                            fontSize: 8,
                            color: grey,
                          ),
                        ),
                        pw.SizedBox(height: 50),
                        pw.Container(
                          height: 0.5,
                          color: const PdfColor.fromInt(0xFFD1D5DB),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          'INWIN - Tunis, Tunisie',
                          style: pw.TextStyle(
                            font: fontNormal,
                            fontSize: 8,
                            color: grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 14),
              pw.Divider(color: const PdfColor.fromInt(0xFFE8EAED)),
              pw.SizedBox(height: 6),
              pw.Text(
                'Ce document est soumis aux Conditions Générales de Vente d\'INWIN disponibles sur l\'application. Toute commande implique l\'acceptation sans réserve des CGV. En cas de litige, les tribunaux de Tunis seront seuls compétents.',
                style: pw.TextStyle(
                  font: fontNormal,
                  fontSize: 7,
                  color: grey,
                ),
                textAlign: pw.TextAlign.center,
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  static Future<void> printOrShare(Uint8List bytes) async {
    await Printing.sharePdf(bytes: bytes, filename: 'bon_de_commande.pdf');
  }

  static String _ht(double ttc) => '${(ttc / 1.19).toStringAsFixed(3)} TND';

  static String _tva(double ttc) =>
      '${(ttc - ttc / 1.19).toStringAsFixed(3)} TND';

  static String _half(double ttc) => '${(ttc / 2).toStringAsFixed(3)} TND';
}

pw.Widget _tableHeader(pw.Font bold, String text) => pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      child: pw.Text(
        text,
        style: pw.TextStyle(font: bold, fontSize: 9, color: PdfColors.white),
      ),
    );

pw.TableRow _tableRow(
  pw.Font normal,
  pw.Font bold,
  String label,
  dynamic value,
  bool shaded,
) =>
    pw.TableRow(
      decoration: pw.BoxDecoration(
        color: shaded ? const PdfColor.fromInt(0xFFF8F9FC) : PdfColors.white,
      ),
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          child: pw.Text(
            label,
            style: pw.TextStyle(
              font: bold,
              fontSize: 9,
              color: const PdfColor.fromInt(0xFF374151),
            ),
          ),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          child: pw.Text(
            '$value',
            style: pw.TextStyle(font: normal, fontSize: 9),
          ),
        ),
      ],
    );

pw.Widget _infoRow(
  pw.Font bold,
  pw.Font normal,
  String label,
  String value,
) =>
    pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            '$label :',
            style: pw.TextStyle(
              font: bold,
              fontSize: 9,
              color: const PdfColor.fromInt(0xFF6B7280),
            ),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(font: normal, fontSize: 9),
          ),
        ],
      ),
    );

pw.Widget _financialRow(
  pw.Font normal,
  pw.Font bold,
  String label,
  String value, {
  bool isTotal = false,
  bool highlight = false,
}) =>
    pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      color: isTotal
          ? const PdfColor.fromInt(0xFF1A237E)
          : highlight
              ? const PdfColor.fromInt(0xFFE8EAF6)
              : null,
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              font: isTotal || highlight ? bold : normal,
              fontSize: isTotal ? 10 : 9,
              color: isTotal
                  ? PdfColors.white
                  : const PdfColor.fromInt(0xFF374151),
            ),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              font: isTotal || highlight ? bold : normal,
              fontSize: isTotal ? 10 : 9,
              color: isTotal
                  ? PdfColors.white
                  : highlight
                      ? const PdfColor.fromInt(0xFF1A237E)
                      : const PdfColor.fromInt(0xFF374151),
            ),
          ),
        ],
      ),
    );
