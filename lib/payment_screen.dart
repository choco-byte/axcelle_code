import 'package:flutter/material.dart';
import 'success_payment_screen.dart';

class PaymentScreen extends StatefulWidget {
  final double totalPrice;
  final String movieTitle;
  final String selectedDate;
  final String selectedTime;
  final List<String> selectedSeats;

  const PaymentScreen({
    super.key,
    required this.totalPrice,
    required this.movieTitle,
    required this.selectedDate,
    required this.selectedTime,
    required this.selectedSeats,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String? _selectedMethod;

  final List<String> paymentMethods = [
    'Credit Card',
    'Debit Card',
    'GoPay',
    'OVO',
    'Bank Transfer'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Method'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              'Total: Rp${widget.totalPrice.toStringAsFixed(0)}',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 20),

            Expanded(
              child: ListView.builder(
                itemCount: paymentMethods.length,
                itemBuilder: (context, index) {
                  final method = paymentMethods[index];

                  return Card(
                    child: ListTile(
                      title: Text(method),
                      trailing: Radio<String>(
                        value: method,
                        groupValue: _selectedMethod,
                        onChanged: (value) {
                          setState(() {
                            _selectedMethod = value;
                          });
                        },
                        activeColor: Colors.deepPurple,
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 10),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _selectedMethod == null
                    ? null
                    : () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SuccessPaymentScreen(
                              movieTitle: widget.movieTitle,
                              selectedDate: widget.selectedDate,
                              selectedTime: widget.selectedTime,
                              selectedSeats: widget.selectedSeats,
                              paymentMethod: _selectedMethod!,
                              totalPrice: widget.totalPrice,
                            ),
                          ),
                        );
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text(
                  'Pay Now',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
