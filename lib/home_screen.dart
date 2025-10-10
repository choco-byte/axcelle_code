import 'dart:async';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:axcelle_code/components/movie_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Stream<List<ConnectivityResult>> _connectivityStream;

  static const int _fakeLoopCount = 10000;
  final int _initialPage = 5000;
  late final PageController _pageController;
  late Timer _timer;

  final List<Map<String, String?>> _movies = [
    {'title': 'Ne Zha 2', 'image': 'assets/nezha_poster.jpeg'},
    {'title': '', 'image': 'assets/lilo.jpg'},
    {'title': null, 'image': 'assets/superman.jpg'},
    {'title': 'Scream VI', 'image': 'assets/scream.jpg'},
    {'title': 'Elio', 'image': 'assets/ELIO (2025).jpg'},
  ];

  final TextEditingController _searchController = TextEditingController();
  List<String> _searchHistory = [];
  List<Map<String, String?>> _searchResults = [];

  @override
  void initState() {
    super.initState();
    _connectivityStream = Connectivity().onConnectivityChanged;
    _pageController = PageController(
      initialPage: _initialPage,
      viewportFraction: 0.6,
    );

    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_pageController.hasClients) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
        );
      }
    });

    _loadSearchHistory();
  }

  Future<void> _loadSearchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _searchHistory = prefs.getStringList('searchHistory') ?? [];
    });
  }

  Future<void> _saveSearchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('searchHistory', _searchHistory);
  }

  void _addToHistory(String query) {
    if (query.isEmpty) return;
    if (!_searchHistory.contains(query)) {
      setState(() {
        _searchHistory.insert(0, query);
      });
      _saveSearchHistory();
    }
  }

  Future<void> _clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('searchHistory');
    setState(() {
      _searchHistory.clear();
    });
  }

  void _performSearch(String query) {
    _addToHistory(query);
    setState(() {
      _searchResults = _movies
          .where((movie) =>
              (movie['title'] ?? '')
                  .toLowerCase()
                  .contains(query.toLowerCase()))
          .toList();
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _pageController.dispose();
    _searchController.dispose();
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
          isOnline =
              snapshot.data!.any((result) => result != ConnectivityResult.none);
        }

        return Scaffold(
          appBar: AppBar(
            backgroundColor: const Color(0xFF7B1113),
            elevation: 0,
            title: const Text(
              'Home',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: _clearHistory,
                tooltip: 'Clear History',
              ),
            ],
          ),
          body: Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: isOnline
                  ? Padding(
                      key: const ValueKey('online'),
                      padding: const EdgeInsets.all(16),
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 🔍 Search Bar (English)
                            TextField(
                              controller: _searchController,
                              decoration: InputDecoration(
                                hintText: 'Search movies...',
                                prefixIcon: const Icon(Icons.search),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                suffixIcon: IconButton(
                                  icon: const Icon(Icons.arrow_forward),
                                  onPressed: () {
                                    _performSearch(_searchController.text);
                                  },
                                ),
                              ),
                              onSubmitted: _performSearch,
                            ),
                            const SizedBox(height: 16),

                            // 🔹 Search History
                            if (_searchHistory.isNotEmpty)
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Search History:',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                  Wrap(
                                    spacing: 8,
                                    children: _searchHistory
                                        .map((query) => ActionChip(
                                              label: Text(query),
                                              onPressed: () {
                                                _searchController.text = query;
                                                _performSearch(query);
                                              },
                                            ))
                                        .toList(),
                                  ),
                                  const SizedBox(height: 16),
                                ],
                              ),

                            // 🔹 Search Results
                            if (_searchResults.isNotEmpty)
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Search Results:',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Column(
                                    children: _searchResults
                                        .map(
                                          (movie) => MovieCard(
                                            title: (movie['title'] != null &&
                                                    movie['title']!
                                                        .trim()
                                                        .isNotEmpty)
                                                ? movie['title']!
                                                : 'Title not found',
                                            image: movie['image']!,
                                            scale: 1.0,
                                            opacity: 1.0,
                                          ),
                                        )
                                        .toList(),
                                  ),
                                ],
                              )
                            else
                              // 🔹 Movie Carousel
                              Column(
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
                                        final movie = _movies[
                                            index % _movies.length];
                                        final title =
                                            (movie['title'] != null &&
                                                    movie['title']!
                                                        .trim()
                                                        .isNotEmpty)
                                                ? movie['title']!
                                                : 'Title not found';
                                        return Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8),
                                          child: MovieCard(
                                            title: title,
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
                          ],
                        ),
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

