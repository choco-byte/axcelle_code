import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:axcelle_code/components/movie_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Stream<List<ConnectivityResult>> _connectivityStream;
  late final PageController _pageController;
  late Timer _timer;

  // 🔹 Data dari API TMDB
  List<Map<String, dynamic>> _nowPlayingMovies = [];

  // 🔹 State tambahan
  bool _isLoading = true;
  bool _hasError = false;

  // 🔹 Pencarian
  final TextEditingController _searchController = TextEditingController();
  List<String> _searchHistory = [];
  List<Map<String, dynamic>> _searchResults = [];

  @override
  void initState() {
    super.initState();
    _connectivityStream = Connectivity().onConnectivityChanged;

    _pageController = PageController(viewportFraction: 0.6);

    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_pageController.hasClients && _nowPlayingMovies.isNotEmpty) {
        int nextPage = _pageController.page!.toInt() + 1;
        if (nextPage >= _nowPlayingMovies.length) nextPage = 0;
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
        );
      }
    });

    _loadSearchHistory();
    _fetchNowPlayingMovies();
  }

  // 🧠 Ambil data dari API TMDB
  Future<void> _fetchNowPlayingMovies() async {
    const apiKey = '6c53df6acacc8783afa96e6d4bfda42f'; // 🔑 Ganti dengan API key TMDB kamu
    final url =
        'https://api.themoviedb.org/3/movie/now_playing?api_key=$apiKey&language=en-US&page=1';

    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final results = List<Map<String, dynamic>>.from(data['results']);

        setState(() {
          _nowPlayingMovies = results;
          _searchResults = [];
          _isLoading = false;
        });

        debugPrint('✅ Data berhasil diambil: ${results.length} film');
      } else {
        debugPrint('❌ Gagal fetch data. Status: ${response.statusCode}');
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Error fetching movies: $e');
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
    }
  }

  // 🧠 History pencarian
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

  // 🧠 Fungsi pencarian film dari data yang di-fetch
  void _performSearch(String query) {
    _addToHistory(query);
    setState(() {
      _searchResults = _nowPlayingMovies
          .where((movie) => (movie['title'] ?? '')
              .toLowerCase()
              .contains(query.toLowerCase()))
          .map((movie) => {
                'title': (movie['title'] ?? 'No Title').toString(),
                'image':
                    'https://image.tmdb.org/t/p/w500${movie['poster_path'] ?? ''}',
              })
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
                icon: const Icon(Icons.refresh),
                tooltip: 'Refresh',
                onPressed: _fetchNowPlayingMovies,
              ),
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
              child: !isOnline
                  ? Text(
                      'Oops, no internet connection',
                      key: const ValueKey('offline'),
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.redAccent[400],
                      ),
                      textAlign: TextAlign.center,
                    )
                  : _isLoading
                      ? const CircularProgressIndicator()
                      : _hasError
                          ? const Text(
                              'Failed to load movies 😢',
                              style: TextStyle(fontSize: 20),
                            )
                          : _buildContent(size),
            ),
          ),
        );
      },
    );
  }

  // 🎬 UI konten utama
  Widget _buildContent(Size size) {
    return Padding(
      key: const ValueKey('online'),
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🔍 Search Bar
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
                  onPressed: () => _performSearch(_searchController.text),
                ),
              ),
              onSubmitted: _performSearch,
            ),
            const SizedBox(height: 16),

            // 🕓 Search History
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

            // 🎬 Search Results / Now Playing
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
                            title: movie['title'] ?? 'No Title',
                            image: movie['image'] ?? '',
                            scale: 1.0,
                            opacity: 1.0,
                          ),
                        )
                        .toList(),
                  ),
                ],
              )
            else
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
                  if (_nowPlayingMovies.isEmpty)
                    const Text('No movies found 😢')
                  else
                    SizedBox(
                      height: size.height * 0.45,
                      child: PageView.builder(
                        controller: _pageController,
                        itemCount: _nowPlayingMovies.length,
                        itemBuilder: (context, index) {
                          final movie = _nowPlayingMovies[index];
                          final title = movie['title'] ?? 'No Title';
                          final imageUrl =
                              'https://image.tmdb.org/t/p/w500${movie['poster_path'] ?? ''}';
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: MovieCard(
                              title: title,
                              image: imageUrl,
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
    );
  }
}
