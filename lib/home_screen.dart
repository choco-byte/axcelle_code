import 'dart:async';
import 'dart:convert';
<<<<<<< HEAD
=======
import 'package:firebase_analytics/firebase_analytics.dart';
>>>>>>> lio
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:axcelle_code/components/movie_card.dart';
import 'package:axcelle_code/components/skeleton_loading.dart';
import 'package:axcelle_code/all_movies.dart';
import 'package:axcelle_code/movie_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Stream<List<ConnectivityResult>> _connectivityStream;
  late final PageController _pageController;
  late Timer _timer;
  final TextEditingController _searchController = TextEditingController();
  final FirebaseAnalytics analytics = FirebaseAnalytics.instance;

<<<<<<< HEAD
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
=======
  List<Map<String, dynamic>> _nowPlayingMovies = [];

  final List<Map<String, dynamic>> _localMovies = [
    {
      'id': 1,
      'title': 'Ne Zha 2',
      'image': 'assets/nezha_poster.jpeg',
      'overview': 'A synopsis of Ne Zha 2.',
      'isLocal': true,
      'vote_average': 7.5,
    },
    {
      'id': 2,
      'title': 'Lilo & Stitch',
      'image': 'assets/lilo.jpg',
      'overview': 'A synopsis of Lilo & Stitch.',
      'isLocal': true,
      'vote_average': 7.8,
    },
    {
      'id': 3,
      'title': 'Superman',
      'image': 'assets/superman.jpg',
      'overview': 'A synopsis of Superman.',
      'isLocal': true,
      'vote_average': 8.0,
    },
    {
      'id': 4,
      'title': 'Scream VI',
      'image': 'assets/scream.jpg',
      'overview': 'A synopsis of Scream VI.',
      'isLocal': true,
      'vote_average': 6.8,
    },
    {
      'id': 5,
      'title': 'Elio',
      'image': 'assets/ELIO (2025).jpg',
      'overview': 'A synopsis of Elio.',
      'isLocal': true,
      'vote_average': 7.2,
    },
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


  _logHomeScreenOpened();

  _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
    if (_pageController.hasClients && _nowPlayingMovies.isNotEmpty) {
      if (_nowPlayingMovies.length > 1) {
        int nextPage =
            (_pageController.page!.toInt() + 1) % _nowPlayingMovies.length;
>>>>>>> lio
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
        );
      }
    }
  });
}

Future<void> _logHomeScreenOpened() async {
  try {
    await analytics.logEvent(
      name: 'home_screen_opened',
      parameters: {'timestamp': DateTime.now().toIso8601String()},
    );
    debugPrint('HomeScreen opened event logged!');
  } catch (e) {
    debugPrint('Error logging HomeScreen event: $e');
  }
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

<<<<<<< HEAD
    _loadSearchHistory();
    _fetchNowPlayingMovies();
=======
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final results = List<Map<String, dynamic>>.from(data['results']);

        setState(() {
          _nowPlayingMovies = results;
          _isLoading = false;
        });
      } else {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    } catch (e) {
      
    }
  }

  void _performSearch(String query) {
    final cleanQuery = query.trim();
    if (cleanQuery.isNotEmpty) {
      _addToHistory(cleanQuery);
    }

    final List<Map<String, dynamic>> searchSource = [];

    if (_nowPlayingMovies.isNotEmpty) {
      searchSource.addAll(_nowPlayingMovies);
    }
    searchSource.addAll(_localMovies);

    final Set<String> uniqueTitles = {};
    final List<Map<String, dynamic>> finalResults = [];

    final filtered = searchSource
        .where(
          (movie) => (movie['title'] ?? '').toLowerCase().contains(
            cleanQuery.toLowerCase(),
          ),
        )
        .toList();

    for (var movie in filtered) {
      final title = movie['title'] as String;
      if (!uniqueTitles.contains(title)) {
        uniqueTitles.add(title);

        final String imagePath = (movie['poster_path'] != null)
            ? 'https://image.tmdb.org/t/p/w500${movie['poster_path']}'
            : (movie['image'] ??
                  'https://via.placeholder.com/500x750?text=No+Image');

        finalResults.add(
          Map<String, dynamic>.from(movie)..['image'] = imagePath,
        );
      }
    }

    setState(() {
      if (cleanQuery.isEmpty) {
        _searchResults = [];
      } else {
        _searchResults = finalResults;
      }
    });
>>>>>>> lio
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
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) return;

    setState(() {
      _searchHistory.remove(cleanQuery);
      _searchHistory.insert(0, cleanQuery);
      if (_searchHistory.length > 10) {
        _searchHistory.removeLast();
      }
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

<<<<<<< HEAD
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
=======
  void _handleMovieTap(Map<String, dynamic> movieData) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MovieDetailScreen(movie: movieData),
      ),
    );
>>>>>>> lio
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
              MaterialPageRoute(
                builder: (context) => MovieTabsPage(analytics: analytics),
              ),
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

    return RefreshIndicator(
      onRefresh: _fetchNowPlayingMovies, 
      color: const Color(0xFF7B1113),
      child: SingleChildScrollView(
      key: const ValueKey('content'),
      physics: const AlwaysScrollableScrollPhysics(),
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
              onChanged: _performSearch,
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
                            color: Theme.of(context).textTheme.bodySmall?.color,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: _searchHistory
                        .map(
                          (query) => ActionChip(
                            label: Text(query),
                            onPressed: () {
                              _searchController.text = query;
                              _performSearch(query);
                            },
                          ),
                        )
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
                    const Text(
                      'No results found.',
                      style: TextStyle(fontSize: 16),
                    )
                  else
                    GridView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.6,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                          ),
                      itemCount: _searchResults.length,
                      itemBuilder: (context, index) {
                        final movie =
                            _searchResults[index]; 
                        // Di dalam GridView.builder
                        return MovieCard(
                          title: movie['title'] ?? 'No Title',
                          image: movie['image'] ?? '',
                          scale: 1.0,
                          opacity: 1.0,
                          // TAMBAHKAN INI:
                          heroTag: 'movie-poster-${movie['id']}', 
                          onTap: () => _handleMovieTap(movie),
                        );
                      },
                    ),
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

                if (_hasError &&
                    _nowPlayingMovies.isEmpty &&
                    _localMovies.isNotEmpty)
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: Row(
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          color: Colors.orange,
                          size: 18,
                        ),
                        SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'Menampilkan data lokal (gagal memuat dari API).',
                            style: TextStyle(
                              color: Colors.orange,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 10),
                if (movies.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'No movies available.',
                      style: TextStyle(fontSize: 16),
                    ),
                  )
                else
                  SizedBox(
                    height: size.height * 0.45,
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: movies.length,
                      itemBuilder: (context, index) {
                        final movie = movies[index] as Map<String, dynamic>;
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
                            // TAMBAHKAN INI:
                            heroTag: 'movie-poster-${movie['id']}', 
                            onTap: () => _handleMovieTap(movie),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
        ],
      ),
    )
    );
    
  }

  Widget _getAnimatedBodyContent(Size size, bool isOnline) {
    final List<dynamic> displayMovies =
        (_nowPlayingMovies.isNotEmpty || isOnline)
        ? _nowPlayingMovies
        : _localMovies;

    if (_isLoading) {
      return const MovieCarouselSkeleton(key: ValueKey('loading'));
    }

    if (!isOnline && _nowPlayingMovies.isEmpty && _localMovies.isNotEmpty) {
      return _buildSharedLayout(size, _localMovies);
    }

    if (displayMovies.isNotEmpty) {
      return _buildSharedLayout(size, displayMovies);
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
        bool isOnline =
            snapshot.hasData &&
            snapshot.data!.any((result) => result != ConnectivityResult.none);

        return Scaffold(
          appBar: AppBar(
            backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
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
<<<<<<< HEAD
                icon: const Icon(Icons.refresh),
                tooltip: 'Refresh',
                onPressed: _fetchNowPlayingMovies,
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: _clearHistory,
=======
                icon: const Icon(Icons.refresh, color: Colors.white),
                tooltip: 'Refresh',
                onPressed: isOnline ? _fetchNowPlayingMovies : null,
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.white),
>>>>>>> lio
                tooltip: 'Clear History',
                onPressed: _clearHistory,
              ),
            ],
          ),
          body: Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
<<<<<<< HEAD
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
=======
              child: _getAnimatedBodyContent(size, isOnline),
>>>>>>> lio
            ),
          ),
        );
      },
    );
  }
<<<<<<< HEAD

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
=======
>>>>>>> lio
}
