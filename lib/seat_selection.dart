import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

// Konstanta untuk key SharedPreferences
const String _mockPersistenceKey = 'mock_api_tickets_history';

// ---------------------------
// 1️⃣ Model data kursi
// ---------------------------
class SeatData {
  final List<List<bool>> realtimeBooked; // Kursi merah (sudah dipesan)
  final List<List<bool>> userSelected; // Kursi hijau (dipilih user)

  SeatData(this.realtimeBooked, this.userSelected);
}

class SeatSelectionScreen extends StatefulWidget {
  final String movieTitle;

  const SeatSelectionScreen({super.key, required this.movieTitle});

  @override
  State<SeatSelectionScreen> createState() => _SeatSelectionScreenState();
}

class _SeatSelectionScreenState extends State<SeatSelectionScreen> {
  // ---------------------------
  // 2️⃣ Variabel utama
  // ---------------------------
  final StreamController<SeatData> _seatStreamController =
      StreamController<SeatData>.broadcast();

  List<List<bool>> _realtimeBookedSeats =
      List.generate(5, (_) => List.generate(8, (_) => false));
  List<List<bool>> _userSelectedSeats =
      List.generate(5, (_) => List.generate(8, (_) => false));

  // ---------------------------
  // 3️⃣ Variabel untuk jadwal
  // ---------------------------
  late List<String> availableDates;
  late List<String> availableTimes;

  String? selectedDate;
  String? selectedTime;

  Timer? _timer;

  @override
  void initState() {
    super.initState();

    // Generate daftar tanggal (3 hari ke depan)
    final now = DateTime.now();
    availableDates = List.generate(
        3,
        (i) =>
            "${now.add(Duration(days: i)).day}-${now.add(Duration(days: i)).month}-${now.add(Duration(days: i)).year}");

    // Daftar waktu tayang contoh
    availableTimes = ["10:00", "13:30", "16:00", "19:30", "22:00"];

    // Pilihan default
    selectedDate = availableDates.first;
    selectedTime = availableTimes.first;

    // Mulai stream awal
    _startSeatStream();
  }

  void _startSeatStream() {
    // Reset data kursi saat jadwal berubah
    _realtimeBookedSeats =
        List.generate(5, (_) => List.generate(8, (_) => false));
    _userSelectedSeats =
        List.generate(5, (_) => List.generate(8, (_) => false));

    // Emit data awal
    _seatStreamController.add(SeatData(_realtimeBookedSeats, _userSelectedSeats));

    // Hentikan timer lama (jika ada)
    _timer?.cancel();

    // Simulasi realtime update kursi setiap 5 detik
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      final updatedRealtimeSeats = List<List<bool>>.from(
        _realtimeBookedSeats.map((row) => List<bool>.from(row)),
      );

      final randomRow = DateTime.now().second % 5;
      final randomCol = DateTime.now().second % 8;

      // Pastikan tidak menimpa kursi yang dipilih user
      if (!_userSelectedSeats[randomRow][randomCol]) {
        updatedRealtimeSeats[randomRow][randomCol] =
            !updatedRealtimeSeats[randomRow][randomCol];
      } else {
        // Jika kursi user tiba-tiba dibooking real-time, batalkan pilihan user
        _userSelectedSeats[randomRow][randomCol] = false;
      }

      _realtimeBookedSeats = updatedRealtimeSeats;
      _seatStreamController.add(SeatData(_realtimeBookedSeats, _userSelectedSeats));
    });
  }

  @override
  void dispose() {
    _seatStreamController.close();
    _timer?.cancel();
    super.dispose();
  }

  // ---------------------------
  // 4️⃣ Fungsi toggle kursi
  // ---------------------------
  void toggleSeat(int row, int col) {
    if (!_realtimeBookedSeats[row][col]) {
      _userSelectedSeats[row][col] = !_userSelectedSeats[row][col];
      _seatStreamController.add(SeatData(_realtimeBookedSeats, _userSelectedSeats));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kursi ini sudah terisi secara real-time.')),
      );
    }
  }

  Color _getSeatColor(bool isRealtimeBooked, bool isUserSelected) {
    if (isRealtimeBooked) {
      return Colors.red;
    } else if (isUserSelected) {
      return Colors.green;
    } else {
      return Colors.grey[300]!;
    }
  }

  // 💡 FUNGSI BARU: Menyimpan tiket ke SharedPreferences
  Future<void> _saveTicket(
      String title, String date, String time, List<String> seats) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final ticketsJson = prefs.getString(_mockPersistenceKey);
      List<Map<String, dynamic>> currentTickets = [];

      if (ticketsJson != null && ticketsJson.isNotEmpty) {
        final List<dynamic> decodedList = json.decode(ticketsJson);
        currentTickets = decodedList.cast<Map<String, dynamic>>();
      }
      
      // Tentukan ID baru
      final newId = currentTickets.isEmpty ? 1 : (currentTickets.map((t) => t['id'] as int).reduce((a, b) => a > b ? a : b) + 1);

      // Buat data tiket baru (dengan 'time')
      final newTicket = {
        'id': newId,
        'title': title,
        'date': date,
        'time': time,
        'seats': seats.join(', '),
      };

      // Tambahkan tiket baru ke daftar
      currentTickets.add(newTicket);

      // Simpan kembali ke SharedPreferences
      await prefs.setString(_mockPersistenceKey, json.encode(currentTickets));

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan tiket: $e')),
        );
      }
    }
  }


  // ---------------------------
  // 5️⃣ UI
  // ---------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Pilih Kursi - ${widget.movieTitle}'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'Pilih Kursi Anda',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            _buildLegend(),
            const SizedBox(height: 10),

            // 🔹 Grid kursi (pakai StreamBuilder)
            Expanded(
              child: StreamBuilder<SeatData>(
                stream: _seatStreamController.stream,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final seatData = snapshot.data!;
                  final currentRealtimeSeats = seatData.realtimeBooked;
                  final currentUserSeats = seatData.userSelected;

                  const rowCount = 5;
                  const colCount = 8;

                  return GridView.builder(
                    itemCount: rowCount * colCount,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: colCount,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                    ),
                    itemBuilder: (context, index) {
                      final row = index ~/ colCount;
                      final col = index % colCount;

                      final isRealtimeBooked = currentRealtimeSeats[row][col];
                      final isUserSelected = currentUserSeats[row][col];
                      final seatColor =
                          _getSeatColor(isRealtimeBooked, isUserSelected);

                      return GestureDetector(
                        onTap: () => toggleSeat(row, col),
                        child: Container(
                          decoration: BoxDecoration(
                            color: seatColor,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.black26),
                          ),
                          child: Center(
                            child: Text(
                              '${String.fromCharCode(65 + row)}${col + 1}',
                              style: TextStyle(
                                color: isRealtimeBooked || isUserSelected
                                    ? Colors.white
                                    : Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),

            // 🔸 Dropdown tanggal & waktu di bawah kursi
            const SizedBox(height: 20),
            const Text(
              'Pilih Jadwal Tayang',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: selectedDate,
                    decoration: const InputDecoration(
                      labelText: 'Tanggal',
                      border: OutlineInputBorder(),
                    ),
                    items: availableDates
                        .map((date) =>
                            DropdownMenuItem(value: date, child: Text(date)))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedDate = value;
                        _startSeatStream();
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: selectedTime,
                    decoration: const InputDecoration(
                      labelText: 'Waktu',
                      border: OutlineInputBorder(),
                    ),
                    items: availableTimes
                        .map((time) =>
                            DropdownMenuItem(value: time, child: Text(time)))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedTime = value;
                        _startSeatStream();
                      });
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // 🔘 Tombol konfirmasi
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  final selectedSeats = <String>[];
                  for (int i = 0; i < _userSelectedSeats.length; i++) {
                    for (int j = 0; j < _userSelectedSeats[i].length; j++) {
                      if (_userSelectedSeats[i][j]) {
                        selectedSeats.add('${String.fromCharCode(65 + i)}${j + 1}');
                      }
                    }
                  }

                  if (selectedSeats.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Silakan pilih kursi terlebih dahulu.')),
                    );
                  } else {
                    // ✅ 1. Simpan Tiket
                    _saveTicket(
                      widget.movieTitle,
                      selectedDate!,
                      selectedTime!,
                      selectedSeats,
                    );
                    
                    // ✅ 2. Tampilkan SnackBar
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Kursi: ${selectedSeats.join(', ')}\nTanggal: $selectedDate • Jam: $selectedTime',
                        ),
                        duration: const Duration(seconds: 2),
                      ),
                    );

                    // ✅ 3. Setelah delay 2 detik, kembali ke halaman sebelumnya
                    Future.delayed(const Duration(seconds: 2), () {
                      // pop(true) untuk memberi tahu halaman detail film bahwa ada pemesanan
                      Navigator.pop(context, true); 
                    });
                  }
                },
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('Konfirmasi Pilihan'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🔹 Keterangan warna kursi
  Widget _buildLegend() {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Row(
          children: [
            Icon(Icons.square, color: Colors.green, size: 16),
            SizedBox(width: 4),
            Text('Selected'),
          ],
        ),
        Row(
          children: [
            Icon(Icons.square, color: Colors.red, size: 16),
            SizedBox(width: 4),
            Text('Unavailable'),
          ],
        ),
        Row(
          children: [
            Icon(Icons.square, color: Colors.grey, size: 16),
            SizedBox(width: 4),
            Text('Available'),
          ],
        ),
      ],
    );
  }
}