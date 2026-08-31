import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import '../repositories/interfaces/cart_repository.dart';

class ReceiptData {
  ReceiptData({
    required this.shopName,
    required this.customerName,
    required this.customerId,
    required this.totalPrice,
    required this.formattedDate,
    required this.receiptNo,
    required this.items,
  });

  final String shopName;
  final String customerName;
  final String customerId;
  final double totalPrice;
  final String formattedDate;
  final String receiptNo;
  final List<CartItem> items;
}

class ReceiptService {
  ReceiptService();

  Future<Uint8List> generatePdf(ReceiptData data) async {
    final dmSansRegular = pw.Font.ttf(
      await rootBundle.load('assets/fonts/DMSans-Regular.ttf'),
    );
    final dmSansBold = pw.Font.ttf(
      await rootBundle.load('assets/fonts/DMSans-Bold.ttf'),
    );
    final notoSans = pw.Font.ttf(
      await rootBundle.load('assets/fonts/NotoSans.ttf'),
    );

    final doc = pw.Document(
      theme: pw.ThemeData.withFont(
        base: dmSansRegular,
        bold: dmSansBold,
        fontFallback: [notoSans],
      ),
    );

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Text(
            'Receipt',
            style: const pw.TextStyle(
              fontSize: 28,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            data.shopName.isNotEmpty ? data.shopName : '...',
            style: const pw.TextStyle(
              fontSize: 16,
              color: PdfColors.grey,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            'Receipt No. ${data.receiptNo}',
            style: const pw.TextStyle(
              fontSize: 13,
              color: PdfColors.grey600,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 24),

          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Customer Name',
                    style: const pw.TextStyle(
                      fontSize: 12,
                      color: PdfColors.grey600,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    data.customerName,
                    style: const pw.TextStyle(fontSize: 18),
                  ),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    'ID',
                    style: const pw.TextStyle(
                      fontSize: 12,
                      color: PdfColors.grey600,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    data.customerId,
                    style: const pw.TextStyle(fontSize: 18),
                  ),
                ],
              ),
            ],
          ),

          pw.SizedBox(height: 24),
          pw.Divider(),
          pw.SizedBox(height: 8),

          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'ITEMS',
                style: const pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                'Price',
                style: const pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ],
          ),
          pw.Divider(),

          ...data.items.map(
            (item) => pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 4),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Expanded(
                    child: pw.Text(
                      '${item.product.name} x${item.quantity}',
                      style: const pw.TextStyle(fontSize: 14),
                    ),
                  ),
                  pw.Text(
                    'GH₵ ${((item.product.price ?? 0.0) * item.quantity).toStringAsFixed(2)}',
                    style: const pw.TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          ),

          pw.SizedBox(height: 16),
          pw.Divider(),
          pw.SizedBox(height: 8),

          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Total Amount', style: const pw.TextStyle(fontSize: 18)),
              pw.Text(
                'GH₵ ${data.totalPrice.toStringAsFixed(2)}',
                style: const pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ],
          ),

          pw.SizedBox(height: 24),

          pw.Text(
            'DATE & TIME',
            style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey),
          ),
          pw.SizedBox(height: 4),
          pw.Text(data.formattedDate, style: const pw.TextStyle(fontSize: 13)),
        ],
      ),
    );

    return doc.save();
  }

  Future<File> savePdf(Uint8List bytes) async {
    final dir = await getTemporaryDirectory();
    final file = File(
      '${dir.path}/receipt_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
    await file.writeAsBytes(bytes);
    return file;
  }

  Future<void> shareReceipt(File file) async {
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: 'application/pdf')],
        text: 'Receipt',
      ),
    );
  }

  Future<void> generateAndShareReceipt({
    required String shopName,
    required String customerName,
    required String customerId,
    required double totalPrice,
    required String formattedDate,
    required String receiptNo,
    required List<CartItem> items,
  }) async {
    final data = ReceiptData(
      shopName: shopName,
      customerName: customerName,
      customerId: customerId,
      totalPrice: totalPrice,
      formattedDate: formattedDate,
      receiptNo: receiptNo,
      items: items,
    );

    final pdfBytes = await generatePdf(data);
    final file = await savePdf(pdfBytes);
    await shareReceipt(file);
  }
}
