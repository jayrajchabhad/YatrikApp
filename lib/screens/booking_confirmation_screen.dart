import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../data/hotel_repository.dart';
import '../resources/app_images.dart';
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
    final imagePath = value == null || value.hotelImageUrl.trim().isEmpty
        ? AppImages.assetAzureVista
        : value.hotelImageUrl.trim();

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(title: const Text('Yatrik')),
      body: value == null
          ? const Center(child: Text('Booking details are not available.'))
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              children: [
                Icon(
                  value.status == 'CONFIRMED'
                      ? Icons.check_circle
                      : Icons.check_circle_outline,
                  color: AppColors.badgeYellow,
                  size: 52,
                ),
                const SizedBox(height: 10),
                Text(
                  value.status == 'CONFIRMED'
                      ? 'Booking Confirmed'
                      : 'Booking Requested',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryDark,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  value.status == 'CONFIRMED'
                      ? 'Your stay at ${value.hotelTitle} is confirmed.'
                      : 'Your reservation request for ${value.hotelTitle} was created.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 20),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.borderLight),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      Stack(
                        children: [
                          AppImages.buildImage(
                            pathOrUrl: imagePath,
                            height: 180,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            fallbackUrl: AppImages.azureVistaResort,
                          ),
                          Container(
                            height: 180,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [
                                  Colors.black.withValues(alpha: 0.72),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 16,
                            left: 16,
                            right: 16,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  value.hotelTitle,
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  value.hotelLocation.toUpperCase(),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.white,
                                    letterSpacing: 0.8,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _detail('CHECK-IN', value.checkIn),
                            _detail('CHECK-OUT', value.checkOut),
                            _detail('ROOM', value.roomTitle),
                            _detail(
                              'GUESTS',
                              '${value.adults} Adults, ${value.children} Children',
                            ),
                            _detail('GUEST NAME', value.guestName),
                            _detail('BOOKING ID', '#${value.id}'),
                            _detail('STATUS', value.status),
                            _detail('PAYMENT SELECTION', value.paymentMethod),
                            const Divider(height: 24),
                            _detail(
                              'TOTAL (DEMO - NOT CHARGED)',
                              '₹${value.total.toStringAsFixed(2)}',
                              bold: true,
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Present your booking reference at reception. No payment was processed.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: () => _exportVoucher(context, value),
                    icon: const Icon(Icons.download_outlined),
                    label: const Text('Download PDF'),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 50,
                  child: OutlinedButton.icon(
                    onPressed: () => _shareVoucher(context, value),
                    icon: const Icon(Icons.share_outlined),
                    label: const Text('Share voucher'),
                  ),
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
            width: 140,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: bold ? FontWeight.bold : FontWeight.w600,
                color: AppColors.primaryDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
