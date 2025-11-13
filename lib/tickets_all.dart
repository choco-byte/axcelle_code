import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

// ****************
// MOCK API CONFIGURATION
// ****************
const String _apiBaseUrl = 'https://api.mockcinema.com';
const String _ticketHistoryEndpoint = '/tickets/history';
const String _mockPersistenceKey = 'mock_api_tickets_history';

// Data tiket awal untuk simulasi jika belum ada data di 'server'
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

  // Fungsi untuk memuat data tiket
  Future<void> _fetchTickets() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      await Future.delayed(const Duration(milliseconds: 800)); // simulasi delay
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
        throw Exception('Gagal memuat tiket.');
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

  // Fungsi hapus riwayat tiket
  Future<void> _clearHistory() async {
    // Jika kosong, langsung beri pesan
    if (_ticketHistory.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak ada riwayat untuk dihapus.')),
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
          const SnackBar(content: Text('Riwayat tiket berhasil dihapus!')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menghapus riwayat: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Fungsi pulihkan riwayat
  Future<void> _restoreHistory() async {
    setState(() => _isLoading = true);

    try {
      await Future.delayed(const Duration(milliseconds: 1000)); // simulasi delay
      final prefs = await SharedPreferences.getInstance();

      // Simulasi HTTP POST ke server untuk restore data
      await prefs.setString(_mockPersistenceKey, json.encode(_initialMockTickets));

      final response = http.Response(json.encode(_initialMockTickets), 200);
      if (response.statusCode == 200) {
        setState(() {
          _ticketHistory = List<Map<String, dynamic>>.from(_initialMockTickets);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Riwayat tiket berhasil dipulihkan!')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memulihkan riwayat: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _confirmClearHistory() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Riwayat Tiket?'),
        content: const Text('Apakah Anda yakin ingin menghapus semua riwayat tiket?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _clearHistory();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Hapus'),
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
            const Text('Gagal memuat riwayat tiket.'),
            ElevatedButton(onPressed: _fetchTickets, child: const Text('Coba Lagi')),
          ],
        ),
      );
    }

    if (_ticketHistory.isEmpty) {
      // Jika kosong, tampilkan tombol "Pulihkan Riwayat"
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.movie_outlined, size: 80, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'Tidak ada riwayat tiket.',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _restoreHistory,
              icon: const Icon(Icons.restore),
              label: const Text('Pulihkan Riwayat'),
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
                    Text('Tanggal: ${ticket['date']}'),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.event_seat, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text('Kursi: ${ticket['seats']}'),
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
        title: const Text('Riwayat Tiket'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          if (!_isLoading)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Hapus Semua Riwayat',
              onPressed: _confirmClearHistory,
            ),
        ],
      ),
      body: _buildBodyContent(),
    );
  }
}