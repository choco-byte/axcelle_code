import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// 1. API Key Placeholder
// IMPORTANT: Replace 'YOUR_TMDB_API_KEY_HERE' with your actual TMDB API key for data to load.
const String _tmdbApiKey = '6c53df6acacc8783afa96e6d4bfda42f';
const String _baseImageUrl = 'https://image.tmdb.org/t/p/w500';

// 2. Placeholder for the MovieCard1 component (assuming it was a standalone component)
class MovieCard1 extends StatelessWidget {
  final String image;
  final String title;
  final String agerate;
  final bool showStars;
  final double rating;

  const MovieCard1({
    super.key,
    required this.image,
    required this.title,
    required this.agerate,
    required this.showStars,
    required this.rating,
  });

  @override
  Widget build(BuildContext context) {
    // Determine if the image is a network URL or a placeholder asset
    final isNetworkImage = image.startsWith('http');
    // Calculate 5-star rating (TMDB is 10-star, converted to 5)
    final clampedRating = (rating / 5.0 * 5.0).clamp(0.0, 5.0);
    
    return Container(
      constraints: const BoxConstraints(maxWidth: 160),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Movie Poster/Image
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
                        child: const Icon(Icons.broken_image, color: Colors.grey),
                      ),
                    )
                  : Container(
                      // Placeholder for missing image
                      color: Color(0xFF7B1113).withOpacity(0.1),
                      alignment: Alignment.center,
                      child: Text(
                        'No Poster',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 8),

          // Title
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

          // Rating & Age Rate
          Row(
            children: [
              if (showStars && rating > 0) ...[
                // Displaying star rating
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
              ],
              
              // Age Rating/Certification
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: Color(0xFF7B1113),
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
    );
  }
}

// 3. Main and Movie Model (from Code 1)
void main() {
  runApp(const MaterialApp(
    home: MovieTabsPage(),
    debugShowCheckedModeBanner: false,
  ));
}

class Movie {
  final String title;
  final String imageUrl;
  final String rating;

  Movie(this.title, this.imageUrl, this.rating);
}

// 4. Main Tabs Page
class MovieTabsPage extends StatelessWidget {
  const MovieTabsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          centerTitle: true,
          title: const Text(
            'Movies',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          backgroundColor: const Color(0xFF7B1113),
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: Column(
          children: [
            Container(
              color: Colors.white,
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
            const Divider(height: 0, color: Colors.white),
            Expanded(
              child: TabBarView(
                children: [
                  NowShowingMovies(),
                  ComingSoonMovies(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 5. Now Showing Movies (using dynamic API fetching from Code 2)
class NowShowingMovies extends StatefulWidget {
  const NowShowingMovies({super.key});

  @override
  State<NowShowingMovies> createState() => _NowShowingMoviesState();
}

class _NowShowingMoviesState extends State<NowShowingMovies> {
  List<Map<String, dynamic>> _movies = [];
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _fetchNowPlayingMovies();
  }

  // Utility function to fetch age rating
  Future<String> _fetchAgeRating(int movieId, String apiKey) async {
    final url =
        'https://api.themoviedb.org/3/movie/$movieId/release_dates?api_key=$apiKey';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        final results = data['results'] as List;
        final usResult = results.firstWhere(
          (result) => result['iso_3166_1'] == 'US',
          orElse: () => null,
        );

        if (usResult != null) {
          final releases = usResult['release_dates'] as List;
          if (releases.isNotEmpty && releases[0]['certification'] != null) {
            final certification = releases[0]['certification'] as String;
            return certification.isNotEmpty ? certification : 'N/A';
          }
        }
        return 'N/A';
      }
    } catch (e) {
      debugPrint('Error fetching age rating: $e');
      return 'N/A';
    }
    return 'N/A';
  }

  Future<void> _fetchNowPlayingMovies() async {
    if (_tmdbApiKey == 'YOUR_TMDB_API_KEY_HERE' || _tmdbApiKey.isEmpty) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
      return;
    }
    
    final url =
        'https://api.themoviedb.org/3/movie/now_playing?api_key=$_tmdbApiKey&language=en-US&page=1';

    if (mounted) {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });
    }

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final results = List<Map<String, dynamic>>.from(data['results']);

        List<Map<String, dynamic>> moviesWithRating = [];
        // Only fetch ratings for the first 10 movies to avoid excessive API calls
        for (var movie in results.take(10)) { 
          final movieId = movie['id'] as int;
          final ageRating = await _fetchAgeRating(movieId, _tmdbApiKey);

          movie['certification'] = ageRating;
          moviesWithRating.add(movie);
        }
        if (mounted) {
          setState(() {
            _movies = moviesWithRating;
            _isLoading = false;
          });
        }
      } else {
        debugPrint(
            'Failed to load now playing movies. Status: ${response.statusCode}');
        if (mounted) {
          setState(() {
            _hasError = true;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching now playing movies: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF7B1113)));
    }

    if (_hasError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Color(0xFF7B1113)),
              const SizedBox(height: 16),
              const Text(
                'Gagal memuat film yang sedang tayang.', 
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              if (_tmdbApiKey == 'YOUR_TMDB_API_KEY_HERE')
                const Text(
                  '\nPastikan Anda telah mengganti placeholder API key dengan kunci TMDB yang valid.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.red),
                ),
            ],
          ),
        ),
      );
    }

    if (_movies.isEmpty) {
      return const Center(
        child: Text('Tidak ada film yang sedang tayang.'),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.55,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: _movies.length,
        itemBuilder: (context, index) {
          final movie = _movies[index];
          final agerate = movie['certification'] ?? 'N/A';
          final posterPath = movie['poster_path'];
          
          // TMDB rating is out of 10. We use it directly in MovieCard1 logic.
          final double tmdbRating = (movie['vote_average'] as num?)?.toDouble() ?? 0.0; 

          return MovieCard1(
            image: posterPath != null ? '$_baseImageUrl$posterPath' : '',
            title: movie['title'] ?? 'No Title',
            agerate: agerate,
            showStars: true,
            rating: tmdbRating,
          );
        },
      ),
    );
  }
}

// 6. Coming Soon Movies (using dynamic API fetching from Code 2)
class ComingSoonMovies extends StatefulWidget {
  const ComingSoonMovies({super.key});

  @override
  State<ComingSoonMovies> createState() => _ComingSoonMoviesState();
}

class _ComingSoonMoviesState extends State<ComingSoonMovies> {
  List<Map<String, dynamic>> _movies = [];
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _fetchUpcomingMovies();
  }

  // Utility function to fetch age rating
  Future<String> _fetchAgeRating(int movieId, String apiKey) async {
    final url =
        'https://api.themoviedb.org/3/movie/$movieId/release_dates?api_key=$apiKey';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        final results = data['results'] as List;
        final usResult = results.firstWhere(
          (result) => result['iso_3166_1'] == 'US',
          orElse: () => null,
        );

        if (usResult != null) {
          final releases = usResult['release_dates'] as List;
          if (releases.isNotEmpty && releases[0]['certification'] != null) {
            final certification = releases[0]['certification'] as String;
            return certification.isNotEmpty ? certification : 'N/A';
          }
        }
        return 'N/A';
      }
    } catch (e) {
      debugPrint('Error fetching age rating: $e');
      return 'N/A';
    }
    return 'N/A';
  }


  Future<void> _fetchUpcomingMovies() async {
    if (_tmdbApiKey == 'YOUR_TMDB_API_KEY_HERE' || _tmdbApiKey.isEmpty) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
      return;
    }

    final url =
        'https://api.themoviedb.org/3/movie/upcoming?api_key=$_tmdbApiKey&language=en-US&page=1';

    if (mounted) {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });
    }

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final results = List<Map<String, dynamic>>.from(data['results']);

        List<Map<String, dynamic>> moviesWithRating = [];
        // Only fetch ratings for the first 10 movies to avoid excessive API calls
        for (var movie in results.take(10)) {
          final movieId = movie['id'] as int;
          final ageRating = await _fetchAgeRating(movieId, _tmdbApiKey);

          movie['certification'] = ageRating;
          moviesWithRating.add(movie);
        }
        if (mounted) {
          setState(() {
            _movies = moviesWithRating;
            _isLoading = false;
          });
        }
      } else {
        debugPrint(
            'Failed to load upcoming movies. Status: ${response.statusCode}');
        if (mounted) {
          setState(() {
            _hasError = true;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching upcoming movies: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF7B1113)));
    }

    if (_hasError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Color(0xFF7B1113)),
              const SizedBox(height: 16),
              const Text(
                'Gagal memuat film yang akan datang.', 
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              if (_tmdbApiKey == 'YOUR_TMDB_API_KEY_HERE')
                const Text(
                  '\nPastikan Anda telah mengganti placeholder API key dengan kunci TMDB yang valid.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.red),
                ),
            ],
          ),
        ),
      );
    }

    if (_movies.isEmpty) {
      return const Center(
        child: Text('Tidak ada film yang akan datang.'),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.55,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: _movies.length,
        itemBuilder: (context, index) {
          final movie = _movies[index];
          // For upcoming movies, use release year as a fallback for the age rate display
          final agerate = movie['certification'] ?? movie['release_date']?.toString().split('-')[0] ?? 'TBA'; 
          final posterPath = movie['poster_path'];

          return MovieCard1(
            image: posterPath != null ? '$_baseImageUrl$posterPath' : '',
            title: movie['title'] ?? 'No Title',
            agerate: agerate,
            showStars: false, // Don't show stars for coming soon movies
            rating: 0.0,
          );
        },
      ),
    );
  }
}
