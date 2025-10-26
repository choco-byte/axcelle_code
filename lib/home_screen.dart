import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:axcelle_code/components/movie_card.dart';
import 'package:axcelle_code/all_movies.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Stream<List<ConnectivityResult>> _connectivityStream;
  late final PageController _pageController;
  late Timer _timer;
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _nowPlayingMovies = [];

  final List<Map<String, String?>> _localMovies = [
    {'title': 'Ne Zha 2', 'image': 'assets/nezha_poster.jpeg'},
    {'title': 'Lilo & Stitch', 'image': 'assets/lilo.jpg'},
    {'title': 'Superman', 'image': 'assets/superman.jpg'},
    {'title': 'Scream VI', 'image': 'assets/scream.jpg'},
    {'title': 'Elio', 'image': 'assets/ELIO (2025).jpg'},
  ];

  bool _isLoading = true;
  bool _hasError = false; 
  List<String> _searchHistory = [];
  List<Map<String, dynamic>> _searchResults = [];

  @override
  void initState() {
    super.initState();
    _connectivityStream = Connectivity().onConnectivityChanged;
    _pageController = PageController(viewportFraction: 0.6); 
    _loadSearchHistory();
    _fetchNowPlayingMovies();

    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_pageController.hasClients && _nowPlayingMovies.isNotEmpty) {
        if (_nowPlayingMovies.length > 1) {
          int nextPage =
              (_pageController.page!.toInt() + 1) % _nowPlayingMovies.length;
          _pageController.animateToPage(
            nextPage,
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeInOut,
          );
        }
      }
    });
  }

  Future<void> _fetchNowPlayingMovies() async {
    const apiKey = '6c53df6acacc8783afa96e6d4bfda42f'; 
    final url =
        'https://api.themoviedb.org/3/movie/now_playing?api_key=$apiKey&language=en-US&page=1';

    setState(() {
      _isLoading = true;
      _hasError = false;
      _searchResults = []; 
    });

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final results = List<Map<String, dynamic>>.from(data['results']);

        setState(() {
          _nowPlayingMovies = results;
          _isLoading = false;
        });

        debugPrint('✅ Data successfully fetched: ${results.length} movies');
      } else {
        debugPrint('❌ Failed to fetch data. Status: ${response.statusCode}');
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
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
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
    setState(() {
      _searchHistory.remove(query);
      _searchHistory.insert(0, query);
    });
    _saveSearchHistory();
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

    final List<Map<String, dynamic>> searchSource;
    if (_nowPlayingMovies.isNotEmpty) {
      searchSource = _nowPlayingMovies
          .map((movie) => {
                'title': movie['title'] ?? 'No Title',
                'image': (movie['poster_path'] != null)
                    ? 'https://image.tmdb.org/t/p/w500${movie['poster_path']}'
                    : 'https://via.placeholder.com/500x750?text=No+Image',
                'isLocal': false,
              })
          .toList();
    } else {
      searchSource = _localMovies
          .map((movie) => {
                'title': movie['title'] ?? 'No Title',
                'image': movie['image']!,
                'isLocal': true,
              })
          .toList();
    }

    setState(() {
      if (query.isEmpty) {
        _searchResults = [];
      } else {
        _searchResults = searchSource
            .where((movie) =>
                (movie['title'] ?? '').toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _pageController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => MovieTabsPage()),
            );
          },
          child: const Text(
            "See All",
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF7B1113),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSharedLayout(Size size, List<dynamic> movies) {
    final isSearching = _searchController.text.isNotEmpty;
    final displayMovies = isSearching ? _searchResults : movies;

    return SingleChildScrollView(
      key: const ValueKey('content'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
            child: TextField(
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
              onChanged: (value) {
                _performSearch(value);
              },
            ),
          ),
          const SizedBox(height: 16),

          if (_searchController.text.isEmpty && _searchHistory.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Search History:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      GestureDetector(
                        onTap: _clearHistory,
                        child: Text(
                          "Clear",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 8),
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
            ),

          if (isSearching)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Search Results (${_searchResults.length}):',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_searchResults.isEmpty)
                    const Text('No results found.', style: TextStyle(fontSize: 16))
                  else
                    ..._searchResults
                        .map(
                          (movie) => MovieCard(
                            title: movie['title'] ?? 'No Title',
                            image: movie['image'] ?? '',
                            scale: 1.0,
                            opacity: 1.0,
                          ),
                        )
                        .toList(),
                  const SizedBox(height: 16),
                ],
              ),
            )
          else 
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _buildSectionHeader('Now Showing'),
                ),
                
                if (_hasError && _nowPlayingMovies.isEmpty && _localMovies.isNotEmpty)
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: Row(
                      children: [
                        Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 18),
                        SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'Menampilkan data lokal (gagal memuat dari API).',
                            style: TextStyle(color: Colors.orange, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 10),
                if (movies.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text('No movies available.', style: TextStyle(fontSize: 16)),
                  )
                else
                  SizedBox(
                    height: size.height * 0.45,
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: movies.length,
                      itemBuilder: (context, index) {
                        final movie = movies[index];
                        final title = movie['title'] ?? 'No Title';

                        final image = (movie['poster_path'] != null)
                            ? 'https://image.tmdb.org/t/p/w500${movie['poster_path']}' 
                            : (movie['image'] ?? ''); 

                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: MovieCard(
                            title: title,
                            image: image,
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
    );
  }

  Widget _getAnimatedBodyContent(Size size, bool isOnline) {
    if (!isOnline) {
      return Text(
        'Oops, no internet connection',
        key: const ValueKey('offline'),
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: Colors.redAccent[400],
        ),
        textAlign: TextAlign.center,
      );
    }

    if (_nowPlayingMovies.isNotEmpty) {
      return _buildSharedLayout(size, _nowPlayingMovies);
    }

    if (_localMovies.isNotEmpty) {
      return _buildSharedLayout(size, _localMovies);
    }

    if (_isLoading) {
      return const CircularProgressIndicator(key: ValueKey('loading'));
    }

    return const Text(
      'No content available.',
      key: ValueKey('no_content'),
      style: TextStyle(fontSize: 16),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return StreamBuilder<List<ConnectivityResult>>(
      stream: _connectivityStream,
      builder: (context, snapshot) {
        bool isOnline = snapshot.hasData &&
            snapshot.data!.any((result) => result != ConnectivityResult.none);

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
                icon: const Icon(Icons.refresh, color: Colors.white),
                tooltip: 'Refresh',
                onPressed: isOnline ? _fetchNowPlayingMovies : null, 
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.white),
                tooltip: 'Clear History',
                onPressed: _clearHistory,
              ),
            ],
          ),
          body: Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _getAnimatedBodyContent(size, isOnline), 
            ),
          ),
        );
      },
    );
  }
}
