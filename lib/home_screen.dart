import 'dart:async';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:axcelle_code/components/movie_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Stream untuk koneksi internet
  late Stream<List<ConnectivityResult>> _connectivityStream;

  // Carousel controller & timer
  static const int _fakeLoopCount = 10000;
  final int _initialPage = 5000;
  late final PageController _pageController;
  late Timer _timer;

  final List<Map<String, String>> _movies = [
    {'title': 'Ne Zha 2', 'image': 'assets/nezha_poster.jpeg'},
    {'title': 'Lilo & Stitch', 'image': 'assets/lilo.jpg'},
    {'title': 'Superman', 'image': 'assets/superman.jpg'},
    {'title': 'Scream VI', 'image': 'assets/scream.jpg'},
    {'title': 'Elio', 'image': 'assets/ELIO (2025).jpg'},
  ];

  @override
  void initState() {
    super.initState();
    // Stream koneksi
    _connectivityStream = Connectivity().onConnectivityChanged;

    // PageController untuk carousel
    _pageController = PageController(
      initialPage: _initialPage,
      viewportFraction: 0.6,
    );

    // Timer otomatis untuk geser slide
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_pageController.hasClients) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

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
            backgroundColor: const Color(0xFF7B1113),
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
              child: isOnline
                  ? Padding(
                      key: const ValueKey('online'),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Now Showing',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                          SizedBox(height: size.height * 0.01),
                          SizedBox(
                            height: size.height * 0.45,
                            child: PageView.builder(
                              controller: _pageController,
                              itemBuilder: (context, index) {
                                final movie =
                                    _movies[index % _movies.length];
                                return Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  child: MovieCard(
                                    title: movie['title']!,
                                    image: movie['image']!,
                                    scale: 1.0,
                                    opacity: 1.0,
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    )
                  : Text(
                      'Oops, no internet connection',
                      key: const ValueKey('offline'),
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.redAccent[400],
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