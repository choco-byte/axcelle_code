import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

const String _apiBaseUrl = 'https://api.mockcinema.com';
const String _ticketHistoryEndpoint = '/tickets/history';
const String _mockPersistenceKey = 'mock_api_tickets_history';

final List<Map<String, dynamic>> _initialMockTickets = [
  {'id': 1, 'title': 'Black Panther: Wakanda Forever', 'date': '2025-11-15', 'seats': 'A1, A2'},
  {'id': 2, 'title': 'Avatar: The Way of Water', 'date': '2025-10-20', 'seats': 'H5, H6, H7'},
  {'id': 3, 'title': 'The Marvels', 'date': '2025-09-01', 'seats': 'F1, F2'},
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

  @override
  void initState() {
    super.initState();
    _fetchTickets();
  }

  Future<void> _fetchTickets() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      await Future.delayed(const Duration(milliseconds: 800)); 
      final prefs = await SharedPreferences.getInstance();
      final ticketsJson = prefs.getString(_mockPersistenceKey);

      if (ticketsJson == null) {
        await prefs.setString(_mockPersistenceKey, json.encode(_initialMockTickets));
      }

      final mockResponseString = prefs.getString(_mockPersistenceKey) ?? '[]';
      final response = http.Response(mockResponseString, 200);

      if (response.statusCode == 200) {
        final List<dynamic> decodedList = json.decode(response.body);
        _ticketHistory = decodedList.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Failed to load the ticket.');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _hasError = true);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _clearHistory() async {
    if (_ticketHistory.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('There is no history to delete.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await Future.delayed(const Duration(milliseconds: 1000));
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_mockPersistenceKey, json.encode([]));
      final response = http.Response('', 204);

      if (response.statusCode == 204) {
        setState(() => _ticketHistory = []);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ticket history successfully deleted!')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete history: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _restoreHistory() async {
    setState(() => _isLoading = true);

    try {
      await Future.delayed(const Duration(milliseconds: 1000));
      final prefs = await SharedPreferences.getInstance();

      await prefs.setString(_mockPersistenceKey, json.encode(_initialMockTickets));

      final response = http.Response(json.encode(_initialMockTickets), 200);
      if (response.statusCode == 200) {
        setState(() {
          _ticketHistory = List<Map<String, dynamic>>.from(_initialMockTickets);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ticket history successfully restored!')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to restore history: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _confirmClearHistory() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Ticket History?'),
        content: const Text('Are you sure you want to delete all ticket history?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _clearHistory();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Widget _buildBodyContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 80, color: Colors.redAccent),
            const SizedBox(height: 16),
            const Text('Failed to load ticket history.'),
            ElevatedButton(onPressed: _fetchTickets, child: const Text('Try Again')),
          ],
        ),
      );
    }

    if (_ticketHistory.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.movie_outlined, size: 80, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'No ticket history available.',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _restoreHistory,
              icon: const Icon(Icons.restore),
              label: const Text('Restore History'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _ticketHistory.length,
      itemBuilder: (context, index) {
        final ticket = _ticketHistory[index];
        return Card(
          elevation: 4,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ticket['title']!,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text('Date: ${ticket['date']}'),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.event_seat, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text('Seats: ${ticket['seats']}'),
                  ],
                ),
              ],
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
        title: const Text(
              'Tickets',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          if (!_isLoading)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Delete All History',
              onPressed: _confirmClearHistory,
            ),
        ],
      ),
      body: _buildBodyContent(),
    );
  }
}
