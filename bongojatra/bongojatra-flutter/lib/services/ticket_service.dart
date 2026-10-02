import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/booking.dart';

class TicketService {
  Future<Uint8List> generateTicketPdf(
      Booking booking, String passengerName) async {
    final pdf = pw.Document();

    final PdfColor primaryColor = PdfColor.fromHex('#006A4E');
    final PdfColor accentColor = PdfColor.fromHex('#F42A41');
    final PdfColor surfaceColor = PdfColor.fromHex('#F7F9FC');

    PdfColor transportColor;
    if (booking.type == 'BUS') {
      transportColor = PdfColor.fromHex('#F4A22A'); // Amber
    } else if (booking.type == 'TRAIN') {
      transportColor = PdfColor.fromHex('#264653'); // Navy
    } else {
      transportColor = PdfColor.fromHex('#2A9D8F'); // Teal
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a5.landscape,
        margin: const pw.EdgeInsets.all(0),
        build: (pw.Context context) {
          return pw.Column(
            children: [
              // Header
              pw.Container(
                color: primaryColor,
                padding: const pw.EdgeInsets.all(20),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('BongoJatra',
                            style: pw.TextStyle(
                                color: PdfColors.white,
                                fontSize: 24,
                                fontWeight: pw.FontWeight.bold)),
                        pw.Text('বাংলাদেশের যোগাযোগ ব্যবস্থা',
                            style: const pw.TextStyle(
                                color: PdfColors.white, fontSize: 12)),
                      ],
                    ),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: pw.BoxDecoration(
                        color: transportColor,
                        borderRadius: pw.BorderRadius.circular(12),
                      ),
                      child: pw.Text(booking.type,
                          style: pw.TextStyle(
                              color: PdfColors.white,
                              fontWeight: pw.FontWeight.bold)),
                    ),
                  ],
                ),
              ),
              // Red Accent Stripe
              pw.Container(
                height: 3,
                color: accentColor,
                width: double.infinity,
              ),
              // Main Content
              pw.Expanded(
                child: pw.Container(
                  color: PdfColors.white,
                  padding: const pw.EdgeInsets.all(20),
                  child: pw.Row(
                    children: [
                      // Left 60%
                      pw.Expanded(
                        flex: 6,
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Row(
                              children: [
                                pw.Text('PASSENGER: ',
                                    style: const pw.TextStyle(
                                        color: PdfColors.grey)),
                                pw.Text(passengerName,
                                    style: pw.TextStyle(
                                        fontWeight: pw.FontWeight.bold,
                                        fontSize: 16)),
                              ],
                            ),
                            pw.SizedBox(height: 10),
                            pw.Row(
                              children: [
                                pw.Text(booking.origin,
                                    style: pw.TextStyle(
                                        fontSize: 20,
                                        fontWeight: pw.FontWeight.bold)),
                                pw.SizedBox(width: 10),
                                pw.Text('→',
                                    style: const pw.TextStyle(
                                        fontSize: 20, color: PdfColors.grey)),
                                pw.SizedBox(width: 10),
                                pw.Text(booking.destination,
                                    style: pw.TextStyle(
                                        fontSize: 20,
                                        fontWeight: pw.FontWeight.bold)),
                              ],
                            ),
                            pw.SizedBox(height: 10),
                            pw.Row(
                              mainAxisAlignment:
                                  pw.MainAxisAlignment.spaceBetween,
                              children: [
                                _buildInfoColumn(
                                    'Date', booking.bookedAt.split('T')[0]),
                                _buildInfoColumn(
                                    'Departure', booking.departureTime),
                                _buildInfoColumn(
                                    'Arrival', booking.arrivalTime),
                              ],
                            ),
                            pw.SizedBox(height: 10),
                            pw.Row(
                              mainAxisAlignment:
                                  pw.MainAxisAlignment.spaceBetween,
                              children: [
                                _buildInfoColumn('Operator', booking.operator),
                                _buildInfoColumn('Class', booking.seatClass),
                                pw.Column(
                                  crossAxisAlignment:
                                      pw.CrossAxisAlignment.start,
                                  children: [
                                    pw.Text('Seat',
                                        style: const pw.TextStyle(
                                            color: PdfColors.grey,
                                            fontSize: 10)),
                                    pw.Text(booking.seatId,
                                        style: pw.TextStyle(
                                            color: accentColor,
                                            fontSize: 16,
                                            fontWeight: pw.FontWeight.bold)),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Divider
                      pw.Container(
                        width: 1,
                        margin: const pw.EdgeInsets.symmetric(horizontal: 15),
                        decoration: const pw.BoxDecoration(
                          // A dashed line would require custom painting in pdf, just use a solid light grey line for now
                          border: pw.Border(
                              left: pw.BorderSide(
                                  color: PdfColors.grey300,
                                  width: 1,
                                  style: pw.BorderStyle.dashed)),
                        ),
                      ),
                      // Right 40%
                      pw.Expanded(
                        flex: 4,
                        child: pw.Column(
                          mainAxisAlignment: pw.MainAxisAlignment.center,
                          crossAxisAlignment: pw.CrossAxisAlignment.center,
                          children: [
                            pw.BarcodeWidget(
                              color: PdfColors.black,
                              barcode: pw.Barcode.qrCode(),
                              data: booking.bookingId,
                              width: 100,
                              height: 100,
                            ),
                            pw.SizedBox(height: 10),
                            pw.Text(booking.bookingId,
                                style: pw.TextStyle(
                                    fontWeight: pw.FontWeight.bold)),
                            pw.SizedBox(height: 10),
                            pw.Text('৳${booking.price}',
                                style: pw.TextStyle(
                                    color: primaryColor,
                                    fontSize: 20,
                                    fontWeight: pw.FontWeight.bold)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Footer
              pw.Container(
                color: surfaceColor,
                padding:
                    const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Valid for date of travel only',
                        style: const pw.TextStyle(
                            color: PdfColors.grey, fontSize: 10)),
                    pw.Container(
                      width: 6,
                      height: 6,
                      decoration: pw.BoxDecoration(
                        color: accentColor,
                        shape: pw.BoxShape.circle,
                      ),
                    ),
                    pw.Text('Payment: ${booking.paymentMethod}',
                        style: const pw.TextStyle(
                            color: PdfColors.grey, fontSize: 10)),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  pw.Widget _buildInfoColumn(String label, String value) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(label,
            style: const pw.TextStyle(color: PdfColors.grey, fontSize: 10)),
        pw.Text(value,
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
      ],
    );
  }
}
