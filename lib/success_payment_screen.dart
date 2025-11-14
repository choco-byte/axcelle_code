import 'package:flutter/material.dart';
import 'package:axcelle_code/payment_screen.dart';

class SuccessPaymentScreen extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle,
                  color: Colors.green, size: 100),
              const SizedBox(height: 20),

              const Text(
                "Payment Successful!",
                style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.black),
              ),

              const SizedBox(height: 20),

              Text(
                "Movie: $movieTitle\n"
                "Date: $selectedDate\n"
                "Time: $selectedTime\n"
                "Seats: ${selectedSeats.join(', ')}\n"
                "Method: $paymentMethod\n"
                "Total: Rp${totalPrice.toStringAsFixed(0)}",
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
                      horizontal: 40, vertical: 14),
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
