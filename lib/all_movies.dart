import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:axcelle_code/movie_detail_screen.dart'; 

const String _tmdbApiKey = '6c53df6acacc8783afa96e6d4bfda42f';
const String _baseImageUrl = 'https://image.tmdb.org/t/p/w500';

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
                          child: const Icon(Icons.broken_image, color: Colors.grey),
                        ),
                      )
                    : Container(
                        color: const Color(0xFF7B1113).withOpacity(0.1),
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
                if (showStars && rating > 0) ...[
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
                
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
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

class Movie {
  final String title;
  final String imageUrl;
  final String rating;

  Movie(this.title, this.imageUrl, this.rating);
}

class MovieTabsPage extends StatelessWidget {
  const MovieTabsPage({super.key});

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
          title: Text(
            'Movies',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Column(
          children: [
            Container(
              color: surfaceColor,
              child: TabBar(
                labelColor: primaryColor,
                unselectedLabelColor: Colors.grey,
                indicatorColor: primaryColor,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                tabs: const [
                  Tab(text: 'Now Showing'),
                  Tab(text: 'Coming Soon'),
                ],
              ),
            ),
            Divider(height: 0, color: Theme.of(context).scaffoldBackgroundColor),
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

  void _handleMovieTap(Map<String, dynamic> movieData) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MovieDetailScreen(movie: movieData),
      ),
    );
  }

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
    final primaryColor = Theme.of(context).colorScheme.primary;

    if (_isLoading) {
      return Center(child: CircularProgressIndicator(color: primaryColor));
    }

    if (_hasError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: primaryColor),
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
          
          final double tmdbRating = (movie['vote_average'] as num?)?.toDouble() ?? 0.0; 

          return MovieCard1(
            image: posterPath != null ? '$_baseImageUrl$posterPath' : '',
            title: movie['title'] ?? 'No Title',
            agerate: agerate,
            showStars: true,
            rating: tmdbRating,
            onTap: () => _handleMovieTap(movie), 
          );
        },
      ),
    );
  }
}

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

  void _handleMovieTap(Map<String, dynamic> movieData) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MovieDetailScreen(movie: movieData),
      ),
    );
  }

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
    final primaryColor = Theme.of(context).colorScheme.primary;
    if (_isLoading) {
      return Center(child: CircularProgressIndicator(color: primaryColor));
    }

    if (_hasError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: primaryColor),
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
          final agerate = movie['certification'] ?? 'N/A';
          final posterPath = movie['poster_path'];
          
          final double tmdbRating = (movie['vote_average'] as num?)?.toDouble() ?? 0.0; 

          return MovieCard1(
            image: posterPath != null ? '$_baseImageUrl$posterPath' : '',
            title: movie['title'] ?? 'No Title',
            agerate: agerate,
            showStars: true,
            rating: tmdbRating,
            onTap: () => _handleMovieTap(movie), 
          );
        },
      ),
    );
  }
}