import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import 'home_screen.dart';
import 'tickets_all.dart';
import 'profile.dart';

class Nav extends StatefulWidget {
  @override
  _NavState createState() => _NavState();
}

class _NavState extends State<Nav> {
  int _selectedIndex = 0;

  final List<Widget> _widgetOptions = <Widget>[
    HomeScreen(),
    TicketsPage(),
    MyAccountPage(),
  ];

  void _onItemTap(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  bool _isConnected(List<ConnectivityResult>? results) {
    if (results == null || results.isEmpty) return true;
    return results.any((result) =>
        result == ConnectivityResult.mobile ||
        result == ConnectivityResult.wifi ||
        result == ConnectivityResult.ethernet);
  }

  String _getTitle() {
    switch (_selectedIndex) {
      case 0:
        return 'Home';
      case 1:
        return 'Tickets';
      case 2:
        return 'Profile';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ConnectivityResult>>(
      stream: Connectivity().onConnectivityChanged,
      builder: (context, snapshot) {
        final bool isOnline = _isConnected(snapshot.data);

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: const Color(0xFF7B1113),
            title: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                _getTitle(),
                style: const TextStyle(color: Colors.white, fontSize: 20),
              ),
            ),
            elevation: 0,
          ),
          body: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: isOnline
                ? _widgetOptions.elementAt(_selectedIndex)
                : const Center(
                    key: ValueKey('offline'),
                    child: Text(
                      'Opps, no internet connection',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
          ),
          bottomNavigationBar: BottomNavigationBar(
            items: const <BottomNavigationBarItem>[
              BottomNavigationBarItem(
                icon: Icon(Icons.home),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.movie_outlined),
                label: 'Tickets',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person),
                label: 'Profile',
              ),
            ],
            currentIndex: _selectedIndex,
            onTap: _onItemTap,
            selectedItemColor: const Color(0xFF7B1113),
            unselectedItemColor: Colors.grey,
          ),
        );
      },
    );
  }
}
