import 'package:axcelle_code/home_screen.dart';
import 'package:axcelle_code/profile.dart';
import 'package:axcelle_code/tickets_all.dart';
import 'package:flutter/material.dart';

class Nav extends StatefulWidget {
  @override
  _NavState createState() => _NavState();
}

class _NavState extends State<Nav> {
  int _selectedIndex = 0;
  List<Widget> _widgetOptions = <Widget>[
    HomeScreen(),
    TicketsPage(),
    MyAccountPage(),
  ];

  void _onItemTap(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(
              Icons.home,
            ),
            label: 'Home',  
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.movie_outlined,
            ),
            label: 'Tickets',  
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.person,
            ),
            label: 'Profile',  
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTap,
        selectedItemColor: Color(0xFF7B1113), // Warna merah ketika dipilih
        unselectedItemColor: Colors.grey,
        selectedFontSize: 13.0,
        unselectedFontSize: 13.0,
      ),
    );
  }
}
