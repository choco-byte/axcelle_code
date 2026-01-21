import 'package:flutter/material.dart';

class TicketVerificationScreen extends StatelessWidget {
  final Map<String, dynamic> ticketData;

  const TicketVerificationScreen({
    super.key,
    required this.ticketData,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ticket Verified'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            Navigator.popUntil(context, (route) => route.isFirst);
          },
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
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
                "Ticket Verified!",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),

              const SizedBox(height: 10),

              Text(
                "Entry Approved",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),

              const SizedBox(height: 30),

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
                    _buildInfoRow(Icons.movie, 'Movie', ticketData['movie'] ?? 'N/A'),
                    const SizedBox(height: 12),
                    _buildInfoRow(Icons.calendar_today, 'Date', ticketData['date'] ?? 'N/A'),
                    const SizedBox(height: 12),
                    _buildInfoRow(Icons.access_time, 'Time', ticketData['time'] ?? 'N/A'),
                    const SizedBox(height: 12),
                    _buildInfoRow(Icons.event_seat, 'Seats', ticketData['seats'] ?? 'N/A'),
                    const SizedBox(height: 12),
                    _buildInfoRow(Icons.payment, 'Payment', ticketData['payment'] ?? 'N/A'),
                    const SizedBox(height: 14),
                    const Divider(thickness: 1.5),
                    const SizedBox(height: 10),
                    _buildInfoRow(Icons.attach_money, 'Total', 'Rp${ticketData['total'] ?? 'N/A'}', isTotal: true),
                    const SizedBox(height: 16),
                    Center(
                      child: Text(
                        'Ticket ID: ${ticketData['ticketId'] ?? 'N/A'}',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.qr_code_scanner),
                  label: const Text(
                    'Scan Another Ticket',
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
