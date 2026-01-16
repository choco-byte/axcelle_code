import 'package:flutter/material.dart';
import 'notification_service.dart';

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
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
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

              const SizedBox(height: 20),

              Text(
                "Movie: ${widget.movieTitle}\n"
                "Date: ${widget.selectedDate}\n"
                "Time: ${widget.selectedTime}\n"
                "Seats: ${widget.selectedSeats.join(', ')}\n"
                "Method: ${widget.paymentMethod}\n"
                "Total: Rp${widget.totalPrice.toStringAsFixed(0)}",
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18),
              ),

              const SizedBox(height: 30),

              ElevatedButton(
                onPressed: () {
                  Navigator.popUntil(context, (route) => route.isFirst);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 14,
                  ),
                ),
                child: const Text(
                  "Back to Home",
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}