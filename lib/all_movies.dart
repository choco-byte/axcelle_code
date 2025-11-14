import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:axcelle_code/movie_detail_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

const String _tmdbApiKey = '6c53df6acacc8783afa96e6d4bfda42f';
const String _baseImageUrl = 'https://image.tmdb.org/t/p/w500';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  final FirebaseAnalytics analytics = FirebaseAnalytics.instance;
  runApp(
    MaterialApp(
      home: MovieTabsPage(analytics: analytics),
      debugShowCheckedModeBanner: false,
    ),
  );
}

class MovieCard1 extends StatelessWidget {
  final String image;
  final String title;
  final String agerate;
  final bool showStars;
  final double rating;
  final VoidCallback onTap;

  const MovieCard1({
    super.key,
    required this.image,
    required this.title,
    required this.agerate,
    required this.showStars,
    required this.rating,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isNetworkImage = image.startsWith('http');
    final clampedRating = (rating / 2.0).clamp(0.0, 5.0);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 160),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: isNetworkImage && image.isNotEmpty
                    ? Image.network(
                        image,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        errorBuilder: (context, error, stackTrace) =>
                            Container(
                          color: Colors.grey.shade300,
                          alignment: Alignment.center,
                          child:
                              const Icon(Icons.broken_image, color: Colors.grey),
                        ),
                      )
                    : Container(
                        color: const Color(0xFF7B1113).withOpacity(0.1),
                        alignment: Alignment.center,
                        child: Text(
                          'No Poster',
                          textAlign: TextAlign.center,
                          style:
                              TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                if (showStars && rating > 0)
                  Row(
                    children: List.generate(5, (index) {
                      return Icon(
                        index < clampedRating.floor()
                            ? Icons.star
                            : index < clampedRating
                                ? Icons.star_half
                                : Icons.star_border,
                        color: Colors.amber,
                        size: 14,
                      );
                    }),
                  ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7B1113),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    agerate,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
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

class MovieTabsPage extends StatelessWidget {
  final FirebaseAnalytics analytics;
  const MovieTabsPage({super.key, required this.analytics});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final primaryColor = colorScheme.primary;
    final surfaceColor = colorScheme.surface;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          centerTitle: true,
          title: const Text(
            'Movies',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: const Color(0xFF7B1113),
        ),
        body: Column(
          children: [
            Container(
              color: surfaceColor,
              child: const TabBar(
                labelColor: Color(0xFF7B1113),
                unselectedLabelColor: Colors.grey,
                indicatorColor: Color(0xFF7B1113),
                labelStyle: TextStyle(fontWeight: FontWeight.bold),
                tabs: [
                  Tab(text: 'Now Showing'),
                  Tab(text: 'Coming Soon'),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  NowShowingMovies(analytics: analytics),
                  ComingSoonMovies(analytics: analytics),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class NowShowingMovies extends StatefulWidget {
  final FirebaseAnalytics analytics;
  const NowShowingMovies({super.key, required this.analytics});

  @override
  State<NowShowingMovies> createState() => _NowShowingMoviesState();
}

class _NowShowingMoviesState extends State<NowShowingMovies> {
  List<Map<String, dynamic>> _movies = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchMovies();
    widget.analytics.logEvent(name: 'now_showing_opened');
  }

  Future<void> _fetchMovies() async {
    final url =
        'https://api.themoviedb.org/3/movie/now_playing?api_key=$_tmdbApiKey&language=en-US&page=1';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _movies = List<Map<String, dynamic>>.from(data['results']);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching now playing: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
          child: CircularProgressIndicator(color: Color(0xFF7B1113)));
    }
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: GridView.builder(
        itemCount: _movies.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.55,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemBuilder: (context, i) {
          final m = _movies[i];
          return MovieCard1(
            image: '$_baseImageUrl${m['poster_path'] ?? ''}',
            title: m['title'] ?? 'No Title',
            agerate: 'PG',
            showStars: true,
            rating: (m['vote_average'] as num?)?.toDouble() ?? 0,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => MovieDetailScreen(movie: m),
              ),
            ),
          );
        },
      ),
    );
  }
}

class ComingSoonMovies extends StatefulWidget {
  final FirebaseAnalytics analytics;
  const ComingSoonMovies({super.key, required this.analytics});

  @override
  State<ComingSoonMovies> createState() => _ComingSoonMoviesState();
}

class _ComingSoonMoviesState extends State<ComingSoonMovies> {
  List<Map<String, dynamic>> _movies = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchMovies();
    widget.analytics.logEvent(name: 'coming_soon_opened');
  }

  Future<void> _fetchMovies() async {
    final url =
        'https://api.themoviedb.org/3/movie/upcoming?api_key=$_tmdbApiKey&language=en-US&page=1';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _movies = List<Map<String, dynamic>>.from(data['results']);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching coming soon: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
          child: CircularProgressIndicator(color: Color(0xFF7B1113)));
    }
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: GridView.builder(
        itemCount: _movies.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.55,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemBuilder: (context, i) {
          final m = _movies[i];
          return MovieCard1(
            image: '$_baseImageUrl${m['poster_path'] ?? ''}',
            title: m['title'] ?? 'No Title',
            agerate:
                m['release_date']?.toString().split('-')[0] ?? 'Coming Soon',
            showStars: false,
            rating: 0.0,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => MovieDetailScreen(movie: m),
              ),
            ),
          );
        },
      ),
    );
  }
}
