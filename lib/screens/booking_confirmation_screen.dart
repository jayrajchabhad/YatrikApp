import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../data/hotel_repository.dart';
import '../theme/app_theme.dart';

class BookingConfirmationScreen extends StatelessWidget {
  const BookingConfirmationScreen({super.key, this.booking});

  final Booking? booking;

  Future<pw.Document> _buildVoucherPdf(Booking booking) async {
    final document = pw.Document();
    document.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) => pw.Padding(
          padding: const pw.EdgeInsets.all(36),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'YATRIK - BOOKING VOUCHER',
                style: pw.TextStyle(
                  fontSize: 22,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 24),
              pw.Text('Status: ${booking.status}'),
              pw.Text('Booking reference: ${booking.id}'),
              pw.SizedBox(height: 16),
              pw.Text('Property: ${booking.hotelTitle}'),
              pw.Text('Location: ${booking.hotelLocation}'),
              pw.Text('Room: ${booking.roomTitle}'),
              pw.Text('Guest: ${booking.guestName}'),
              pw.Text('Stay: ${booking.checkIn} to ${booking.checkOut}'),
              pw.Text(
                'Guests: ${booking.adults} adults, ${booking.children} children',
              ),
              pw.SizedBox(height: 20),
              pw.Divider(),
              pw.Text(
                'Booking total: INR ${booking.total.toStringAsFixed(2)}',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
              pw.Text(
                'Payment selection: ${booking.paymentMethod} (demo only)',
              ),
              pw.Spacer(),
              pw.Text('No payment has been processed by this demo app.'),
            ],
          ),
        ),
      ),
    );
    return document;
  }

  Future<void> _exportVoucher(BuildContext context, Booking booking) async {
    final document = await _buildVoucherPdf(booking);
    try {
      await Printing.layoutPdf(onLayout: (_) => document.save());
    } on PlatformException catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not export voucher: ${error.message}')),
      );
    }
  }

  Future<void> _shareVoucher(BuildContext context, Booking booking) async {
    final document = await _buildVoucherPdf(booking);
    try {
      await Printing.sharePdf(
        bytes: await document.save(),
        filename: 'yatrik-${booking.id}.pdf',
      );
    } on PlatformException catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not share voucher: ${error.message}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final value = booking;
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(title: const Text('Booking voucher')),
      body: value == null
          ? const Center(child: Text('Booking details are not available.'))
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 52),
                const SizedBox(height: 12),
                const Text(
                  'Booking created',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryDark,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'This is a demo reservation. No payment was processed.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 20),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          value.hotelTitle,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryDark,
                          ),
                        ),
                        Text(value.hotelLocation),
                        const Divider(height: 28),
                        _detail('Booking ID', value.id),
                        _detail('Status', value.status),
                        _detail('Room', value.roomTitle),
                        _detail('Check-in', value.checkIn),
                        _detail('Check-out', value.checkOut),
                        _detail(
                          'Guests',
                          '${value.adults} adults, ${value.children} children',
                        ),
                        _detail('Guest', value.guestName),
                        _detail('Payment selection', value.paymentMethod),
                        const Divider(height: 28),
                        _detail(
                          'Total (demo)',
                          '₹${value.total.toStringAsFixed(2)}',
                          bold: true,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                ElevatedButton.icon(
                  onPressed: () => _exportVoucher(context, value),
                  icon: const Icon(Icons.download_outlined),
                  label: const Text('Download PDF'),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () => _shareVoucher(context, value),
                  icon: const Icon(Icons.share_outlined),
                  label: const Text('Share voucher'),
                ),
              ],
            ),
    );
  }

  Widget _detail(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: bold ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
