import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/hr_letter.dart';

class LetterPdfService {
  static Future<Uint8List> buildPdf(HrLetter letter) async {
    final doc = pw.Document();
    final body = letter.body.trim().isNotEmpty
        ? letter.body
        : letter.renderBody();

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(56, 52, 56, 52),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                letter.companyName.isNotEmpty
                    ? letter.companyName
                    : 'Dentassure 360',
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              if (letter.companyAddress.trim().isNotEmpty) ...[
                pw.SizedBox(height: 4),
                pw.Text(
                  letter.companyAddress,
                  style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                ),
              ],
              pw.SizedBox(height: 12),
              pw.Container(height: 1.2, color: PdfColors.blue800),
              pw.SizedBox(height: 22),
              pw.Text(
                letter.title.toUpperCase(),
                style: pw.TextStyle(
                  fontSize: 13,
                  fontWeight: pw.FontWeight.bold,
                  letterSpacing: 0.8,
                ),
              ),
              pw.SizedBox(height: 18),
              pw.Text(
                body,
                style: const pw.TextStyle(fontSize: 11, lineSpacing: 5),
              ),
            ],
          );
        },
      ),
    );

    return doc.save();
  }

  static Future<void> download(HrLetter letter) async {
    final bytes = await buildPdf(letter);
    await Printing.sharePdf(bytes: bytes, filename: letter.pdfFilename);
  }
}
