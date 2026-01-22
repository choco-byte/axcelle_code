import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import 'qr_ticket_screen.dart';

const String _mockPersistenceKey = 'mock_api_tickets_history';

final List<Map<String, dynamic>> _initialMockTickets = [
  {
    'id': 1,
    'title': 'Black Panther: Wakanda Forever',
    'date': '2025-11-15',
    'seats': 'A1, A2'
  },
  {
    'id': 2,
    'title': 'Avatar: The Way of Water',
    'date': '2025-10-20',
    'seats': 'H5, H6, H7'
  },
  {
    'id': 3,
    'title': 'The Marvels',
    'date': '2025-09-01',
    'seats': 'F1, F2'
  },
];

class TicketsPage extends StatefulWidget {
  const TicketsPage({super.key});

  @override
  State<TicketsPage> createState() => _TicketsPageState();
}

class _TicketsPageState extends State<TicketsPage> {
  List<Map<String, dynamic>> _ticketHistory = [];
  bool _isLoading = true;
  bool _hasError = false;

  int? _pressedIndex;

  @override
  void initState() {
    super.initState();
    _fetchTickets();
  }

  Future<void> _fetchTickets() async {
    try {
      await Future.delayed(const Duration(milliseconds: 600));
      final prefs = await SharedPreferences.getInstance();

      final saved = prefs.getString(_mockPersistenceKey);
      if (saved == null) {
        await prefs.setString(
          _mockPersistenceKey,
          json.encode(_initialMockTickets),
        );
      }

      final response = http.Response(
        prefs.getString(_mockPersistenceKey) ?? '[]',
        200,
      );

      final List decoded = json.decode(response.body);
      _ticketHistory = decoded.cast<Map<String, dynamic>>();
    } catch (_) {
      _hasError = true;
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_hasError) {
      return const Center(child: Text('Failed to load tickets'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _ticketHistory.length,
      itemBuilder: (context, index) {
        final ticket = _ticketHistory[index];
        final isPressed = _pressedIndex == index;

        return InkWell(
          borderRadius: BorderRadius.circular(16),
          onTapDown: (_) => setState(() => _pressedIndex = index),
          onTapCancel: () => setState(() => _pressedIndex = null),
          onTap: () async {
            setState(() => _pressedIndex = index);
            await Future.delayed(const Duration(milliseconds: 120));
            setState(() => _pressedIndex = null);

            if (!mounted) return;

            Navigator.push(
              context,
              PageRouteBuilder(
                transitionDuration: const Duration(milliseconds: 300),
                // PERBAIKAN DI SINI: Tambahkan 'context' di depan
                pageBuilder: (context, animation, secondaryAnimation) => QrTicketScreen(
                  movieTitle: ticket['title'],
                  selectedDate: ticket['date'],
                  selectedTime: '19:00',
                  selectedSeats: ticket['seats'].toString().split(', '),
                  paymentMethod: 'E-Wallet',
                  totalPrice: 50000,
                ),
                // PERBAIKAN DI SINI: Tambahkan 'context' di depan
                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                  final slide = Tween<Offset>(
                    begin: const Offset(0, 0.05),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOut,
                    ),
                  );

                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(position: slide, child: child),
                  );
                },
              ),
            );
          },
          child: AnimatedScale(
            scale: isPressed ? 0.97 : 1,
            duration: const Duration(milliseconds: 120),
            child: Card(
              elevation: isPressed ? 6 : 4,
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ticket['title'],
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color:
                            Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today,
                            size: 16, color: Colors.grey),
                        const SizedBox(width: 8),
                        Text(ticket['date']),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.event_seat,
                            size: 16, color: Colors.grey),
                        const SizedBox(width: 8),
                        Text(ticket['seats']),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tickets'),
        backgroundColor:
            Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: _buildBody(),
    );
  }
}