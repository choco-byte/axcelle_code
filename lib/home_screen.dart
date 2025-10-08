import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Stream<List<ConnectivityResult>> _connectivityStream;

  @override
  void initState() {
    super.initState();
    _connectivityStream = Connectivity().onConnectivityChanged;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ConnectivityResult>>(
      stream: _connectivityStream,
      builder: (context, snapshot) {
        bool isOnline = false;

        if (snapshot.hasData && snapshot.data!.isNotEmpty) {
          isOnline = snapshot.data!
              .any((result) => result != ConnectivityResult.none);
        }

        return Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.red[900],
            elevation: 0,
            centerTitle: false,
            title: const Text(
              'Home',
              style: TextStyle(
                color: Colors.black,
                fontSize: 24,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          body: Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Text(
                isOnline
                    ? 'Home Page'
                    : 'Opps, no internet connection',
                key: ValueKey<bool>(isOnline),
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: isOnline ? Colors.black : Colors.redAccent[400],
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        );
      },
    );
  }
}
