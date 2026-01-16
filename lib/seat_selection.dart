import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:axcelle_code/payment_screen.dart';

const String _mockPersistenceKey = 'mock_api_tickets_history';

class SeatData {
  final List<List<bool>> realtimeBooked;
  final List<List<bool>> userSelected;

  SeatData(this.realtimeBooked, this.userSelected);
}

class SeatSelectionScreen extends StatefulWidget {
  final String movieTitle;

  const SeatSelectionScreen({super.key, required this.movieTitle});

  @override
  State<SeatSelectionScreen> createState() => _SeatSelectionScreenState();
}

class _SeatSelectionScreenState extends State<SeatSelectionScreen> {
  final StreamController<SeatData> _seatStreamController =
      StreamController<SeatData>.broadcast();

  List<List<bool>> _realtimeBookedSeats =
      List.generate(5, (_) => List.generate(8, (_) => false));
  List<List<bool>> _userSelectedSeats =
      List.generate(5, (_) => List.generate(8, (_) => false));

  late List<String> availableDates;
  late List<String> availableTimes;

  String? selectedDate;
  String? selectedTime;

  Timer? _timer;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();

    availableDates = List.generate(
      3,
      (i) =>
          "${now.add(Duration(days: i)).day}-${now.add(Duration(days: i)).month}-${now.add(Duration(days: i)).year}",
    );

    availableTimes = ["10:00", "13:30", "16:00", "19:30", "22:00"];

    selectedDate = availableDates.first;
    selectedTime = availableTimes.first;

    _startSeatStream();
  }

  void _startSeatStream() {
    _realtimeBookedSeats =
        List.generate(5, (_) => List.generate(8, (_) => false));
    _userSelectedSeats =
        List.generate(5, (_) => List.generate(8, (_) => false));

    _seatStreamController.add(
        SeatData(_realtimeBookedSeats, _userSelectedSeats));

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      final updatedSeats = List<List<bool>>.from(
        _realtimeBookedSeats.map((row) => List<bool>.from(row)),
      );

      final randomRow = DateTime.now().second % 5;
      final randomCol = DateTime.now().second % 8;

      if (!_userSelectedSeats[randomRow][randomCol]) {
        updatedSeats[randomRow][randomCol] =
            !updatedSeats[randomRow][randomCol];
      } else {
        _userSelectedSeats[randomRow][randomCol] = false;
      }

      _realtimeBookedSeats = updatedSeats;
      _seatStreamController.add(
          SeatData(_realtimeBookedSeats, _userSelectedSeats));
    });
  }

  @override
  void dispose() {
    _seatStreamController.close();
    _timer?.cancel();
    super.dispose();
  }

  void toggleSeat(int row, int col) {
    if (!_realtimeBookedSeats[row][col]) {
      _userSelectedSeats[row][col] = !_userSelectedSeats[row][col];
      _seatStreamController.add(
          SeatData(_realtimeBookedSeats, _userSelectedSeats));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This seat is already booked in real-time.')),
      );
    }
  }

  Color _getSeatColor(bool isBooked, bool isSelected) {
    if (isBooked) return Colors.red;
    if (isSelected) return Colors.green;
    return Colors.grey[300]!;
  }

  Future<void> _saveTicket(
      String title, String date, String time, List<String> seats) async {
    final prefs = await SharedPreferences.getInstance();
    final ticketsJson = prefs.getString(_mockPersistenceKey);
    List<Map<String, dynamic>> currentTickets = [];

    if (ticketsJson != null && ticketsJson.isNotEmpty) {
      final List<dynamic> decodedList = json.decode(ticketsJson);
      currentTickets = decodedList.cast<Map<String, dynamic>>();
    }

    final newId = currentTickets.isEmpty
        ? 1
        : (currentTickets
                .map((t) => t['id'] as int)
                .reduce((a, b) => a > b ? a : b) +
            1);

    final newTicket = {
      'id': newId,
      'title': title,
      'date': date,
      'time': time,
      'seats': seats.join(', '),
    };

    currentTickets.add(newTicket);
    await prefs.setString(_mockPersistenceKey, json.encode(currentTickets));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
          AppBar(title: Text('Select Seats - ${widget.movieTitle}')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text('Choose Your Seat',
                style:
                    TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            _buildLegend(),
            const SizedBox(height: 10),

            Expanded(
              child: StreamBuilder<SeatData>(
                stream: _seatStreamController.stream,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final seatData = snapshot.data!;
                  const rowCount = 5;
                  const colCount = 8;

                  return GridView.builder(
                    itemCount: rowCount * colCount,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: colCount,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                    ),
                    itemBuilder: (context, index) {
                      final row = index ~/ colCount;
                      final col = index % colCount;
                      final isBooked = seatData.realtimeBooked[row][col];
                      final isSelected = seatData.userSelected[row][col];
                      final color =
                          _getSeatColor(isBooked, isSelected);

                      return GestureDetector(
                        onTap: () => toggleSeat(row, col),
                        child: Container(
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.black26),
                          ),
                          child: Center(
                            child: Text(
                              '${String.fromCharCode(65 + row)}${col + 1}',
                              style: TextStyle(
                                color: isBooked || isSelected
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

            const SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: selectedDate,
                    decoration: const InputDecoration(
                        labelText: 'Date',
                        border: OutlineInputBorder()),
                    items: availableDates
                        .map((d) =>
                            DropdownMenuItem(value: d, child: Text(d)))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedDate = value;
                        _startSeatStream();
                      });
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: selectedTime,
                    decoration: const InputDecoration(
                        labelText: 'Time',
                        border: OutlineInputBorder()),
                    items: availableTimes
                        .map((t) =>
                            DropdownMenuItem(value: t, child: Text(t)))
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

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('Confirm Selection'),
                style: ElevatedButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(vertical: 14)),
                onPressed: () async {
                  final selectedSeats = <String>[];

                  for (int i = 0; i < _userSelectedSeats.length; i++) {
                    for (int j = 0; j < _userSelectedSeats[i].length; j++) {
                      if (_userSelectedSeats[i][j]) {
                        selectedSeats
                            .add('${String.fromCharCode(65 + i)}${j + 1}');
                      }
                    }
                  }

                  if (selectedSeats.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Please select at least one seat.')),
                    );
                    return;
                  }

                  await _saveTicket(widget.movieTitle, selectedDate!,
                      selectedTime!, selectedSeats);

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PaymentScreen(
                        totalPrice: selectedSeats.length * 50000,
                        movieTitle: widget.movieTitle,
                        selectedDate: selectedDate!,
                        selectedTime: selectedTime!,
                        selectedSeats: selectedSeats,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Row(children: [
          Icon(Icons.square, color: Colors.green, size: 16),
          SizedBox(width: 4),
          Text('Selected')
        ]),
        Row(children: [
          Icon(Icons.square, color: Colors.red, size: 16),
          SizedBox(width: 4),
          Text('Unavailable')
        ]),
        Row(children: [
          Icon(Icons.square, color: Colors.grey, size: 16),
          SizedBox(width: 4),
          Text('Available')
        ]),
      ],
    );
  }
}
