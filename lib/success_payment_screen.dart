import 'package:flutter/material.dart';
import 'notification_service.dart';
import 'qr_ticket_screen.dart';

class SuccessPaymentScreen extends StatefulWidget {
  final String movieTitle;
  final String selectedDate;
  final String selectedTime;
  final List<String> selectedSeats;
  final String paymentMethod;
  final double totalPrice;

  const SuccessPaymentScreen({
    super.key,
    required this.movieTitle,
    required this.selectedDate,
    required this.selectedTime,
    required this.selectedSeats,
    required this.paymentMethod,
    required this.totalPrice,
  });

  @override
  State<SuccessPaymentScreen> createState() => _SuccessPaymentScreenState();
}

class _SuccessPaymentScreenState extends State<SuccessPaymentScreen> {
  bool _notificationSent = false;

  @override
  void initState() {
    super.initState();

    /// 🔔 Tampilkan notifikasi SETELAH halaman sukses muncul
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_notificationSent) {
        NotificationService.showTicketSuccess(
          eventName: widget.movieTitle,
          ticketCode: widget.selectedSeats.join(', '),
        );
        _notificationSent = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Payment Success'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.popUntil(context, (route) => route.isFirst);
          },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 20),
              const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 100,
              ),
              const SizedBox(height: 20),

              const Text(
                "Payment Successful!",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),

              const SizedBox(height: 24),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      spreadRadius: 1,
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow(Icons.movie, 'Movie', widget.movieTitle),
                    const SizedBox(height: 12),
                    _buildInfoRow(Icons.calendar_today, 'Date', widget.selectedDate),
                    const SizedBox(height: 12),
                    _buildInfoRow(Icons.access_time, 'Time', widget.selectedTime),
                    const SizedBox(height: 12),
                    _buildInfoRow(Icons.event_seat, 'Seats', widget.selectedSeats.join(', ')),
                    const SizedBox(height: 12),
                    _buildInfoRow(Icons.payment, 'Method', widget.paymentMethod),
                    const SizedBox(height: 14),
                    const Divider(thickness: 1.5),
                    const SizedBox(height: 10),
                    _buildInfoRow(Icons.attach_money, 'Total', 'Rp${widget.totalPrice.toStringAsFixed(0)}', isTotal: true),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => QrTicketScreen(
                          movieTitle: widget.movieTitle,
                          selectedDate: widget.selectedDate,
                          selectedTime: widget.selectedTime,
                          selectedSeats: widget.selectedSeats,
                          paymentMethod: widget.paymentMethod,
                          totalPrice: widget.totalPrice,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.qr_code_2),
                  label: const Text(
                    'View QR Ticket',
                    style: TextStyle(fontSize: 18),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, {bool isTotal = false}) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: isTotal ? Colors.green : Colors.grey[700],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: isTotal ? 18 : 16,
                  fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
              Flexible(
                child: Text(
                  value,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: isTotal ? 18 : 16,
                    fontWeight: FontWeight.bold,
                    color: isTotal ? Colors.green : Colors.black,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}