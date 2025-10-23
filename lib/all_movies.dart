import 'package:axcelle_code/components/movie_card1.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// Kelas Movie, tetap dipertahankan
class Movie {
  final String title;
  final String imageUrl;
  final String rating;

  Movie(this.title, this.imageUrl, this.rating);
}

class MovieTabsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          centerTitle: true,
          title: Text(
            'Movies',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          backgroundColor: Color(0xFF7B1113),
          elevation: 0,
          iconTheme: IconThemeData(color: Colors.white),
        ),
        body: Column(
          children: [
            Container(
              color: Colors.white,
              child: TabBar(
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
            Divider(height: 0, color: Colors.white),
            Expanded(
              child: TabBarView(
                // Menggunakan widget dinamis untuk kedua tab
                children: [NowShowingMovies(), ComingSoonMovies()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Tab: Now Showing (Film yang sedang tayang) ---

class NowShowingMovies extends StatefulWidget {
  const NowShowingMovies({super.key});

  @override
  State<NowShowingMovies> createState() => _NowShowingMoviesState();
}

class _NowShowingMoviesState extends State<NowShowingMovies> {
  // Mengubah struktur data untuk menampung klasifikasi usia (certification)
  List<Map<String, dynamic>> _movies = [];
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _fetchNowPlayingMovies();
  }

  // Fungsi baru untuk mengambil klasifikasi usia berdasarkan movie ID
  Future<String> _fetchAgeRating(int movieId, String apiKey) async {
    final url = 'https://api.themoviedb.org/3/movie/$movieId/release_dates?api_key=$apiKey';
    
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Cari klasifikasi usia di US (atau negara lain yang Anda prioritaskan)
        final results = data['results'] as List;
        final usResult = results.firstWhere(
          (result) => result['iso_3166_1'] == 'US', // Mencari klasifikasi US
          orElse: () => null,
        );

        if (usResult != null) {
          final releases = usResult['release_dates'] as List;
          // Cari sertifikasi yang paling relevan (biasanya yang pertama)
          if (releases.isNotEmpty && releases[0]['certification'] != null) {
            final certification = releases[0]['certification'] as String;
            return certification.isNotEmpty ? certification : 'N/A';
          }
        }
        return 'N/A';
      }
    } catch (e) {
      // DebugPrint('Error fetching age rating for $movieId: $e');
      return 'N/A';
    }
    return 'N/A';
  }


  Future<void> _fetchNowPlayingMovies() async {
    final apiKey = dotenv.env['TMDB_API_KEY'];

    if (apiKey == null || apiKey.isEmpty) {
      debugPrint('❌ ERROR: TMDB_API_KEY not found in .env');
      if (mounted) {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
      return;
    }

    final url =
        'https://api.themoviedb.org/3/movie/now_playing?api_key=$apiKey&language=en-US&page=1';

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

        // --- Langkah Baru: Ambil Klasifikasi Usia untuk Setiap Film ---
        List<Map<String, dynamic>> moviesWithRating = [];
        for (var movie in results) {
          final movieId = movie['id'] as int;
          final ageRating = await _fetchAgeRating(movieId, apiKey);
          
          // Tambahkan klasifikasi usia ke objek film
          movie['certification'] = ageRating; 
          moviesWithRating.add(movie);
        }
        // --- Akhir Langkah Baru ---

        if (mounted) {
          setState(() {
            _movies = moviesWithRating;
            _isLoading = false;
          });
        }
      } else {
        debugPrint('Failed to load now playing movies. Status: ${response.statusCode}');
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
      // Tampilkan indikator loading yang lebih menarik jika perlu, tetapi ini cukup
      return const Center(child: CircularProgressIndicator());
    }

    if (_hasError || _movies.isEmpty) {
      return Center(
        child: Text(_hasError ? 'Gagal memuat film yang sedang tayang.' : 'Tidak ada film yang sedang tayang.'),
      );
    }

    // Menggunakan GridView.builder untuk tampilan 2 kolom yang responsif
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, // 2 kolom
          childAspectRatio: 0.55, // Rasio agar MovieCard1 terlihat proporsional
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: _movies.length,
        itemBuilder: (context, index) {
          final movie = _movies[index];
          
          // Data yang benar dari TMDB
          final rating5Star = (movie['vote_average'] ?? 0.0) / 2.0;

          // Menggunakan data klasifikasi usia yang baru diambil (certification)
          final agerate = movie['certification'] ?? 'N/A';
          final posterPath = movie['poster_path'];

          return MovieCard1(
            // URL jaringan penuh yang akan ditangani oleh Image.network di MovieCard1
            image: posterPath != null
                ? 'https://image.tmdb.org/t/p/w500$posterPath'
                : '', // Berikan string kosong jika path tidak ada
            title: movie['title'] ?? 'No Title',
            agerate: agerate, // Kini berisi 'PG', 'R', 'PG-13', dll.
            showStars: true, // Film yang sedang tayang harus menunjukkan rating
            rating: rating5Star,
          );
        },
      ),
    );
  }
}

// --- Tab: Coming Soon (Film yang akan datang) ---
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
  
  // Fungsi baru untuk mengambil klasifikasi usia berdasarkan movie ID (Sama dengan NowShowing)
  Future<String> _fetchAgeRating(int movieId, String apiKey) async {
    final url = 'https://api.themoviedb.org/3/movie/$movieId/release_dates?api_key=$apiKey';
    
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
      // debugPrint('Error fetching age rating for $movieId: $e');
      return 'N/A';
    }
    return 'N/A';
  }


  Future<void> _fetchUpcomingMovies() async {
    final apiKey = dotenv.env['TMDB_API_KEY'];

    if (apiKey == null || apiKey.isEmpty) {
      debugPrint('❌ ERROR: TMDB_API_KEY not found in .env');
      if (mounted) {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
      return;
    }

    // Menggunakan endpoint /movie/upcoming
    final url =
        'https://api.themoviedb.org/3/movie/upcoming?api_key=$apiKey&language=en-US&page=1';

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

        // --- Langkah Baru: Ambil Klasifikasi Usia untuk Setiap Film ---
        List<Map<String, dynamic>> moviesWithRating = [];
        for (var movie in results) {
          final movieId = movie['id'] as int;
          final ageRating = await _fetchAgeRating(movieId, apiKey);
          
          // Tambahkan klasifikasi usia ke objek film
          movie['certification'] = ageRating; 
          moviesWithRating.add(movie);
        }
        // --- Akhir Langkah Baru ---

        if (mounted) {
          setState(() {
            _movies = moviesWithRating;
            _isLoading = false;
          });
        }
      } else {
        debugPrint('Failed to load upcoming movies. Status: ${response.statusCode}');
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
      return const Center(child: CircularProgressIndicator());
    }

    if (_hasError || _movies.isEmpty) {
      return Center(
        child: Text(_hasError ? 'Gagal memuat film yang akan datang.' : 'Tidak ada film yang akan datang.'),
      );
    }

    // Menggunakan GridView.builder untuk konsistensi tampilan 2 kolom
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, // 2 columns
          childAspectRatio: 0.55, // Rasio agar MovieCard1 terlihat proporsional
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: _movies.length,
        itemBuilder: (context, index) {
          final movie = _movies[index];
          
          // Menggunakan data klasifikasi usia yang baru diambil (certification)
          // Jika klasifikasi usia tidak ada, fallback ke tahun rilis untuk film yang akan datang
          final agerate = movie['certification'] ?? movie['release_date']?.toString().split('-')[0] ?? 'TBA'; 
          final posterPath = movie['poster_path'];

          return MovieCard1(
            image: posterPath != null
                ? 'https://image.tmdb.org/t/p/w500$posterPath'
                : '',
            title: movie['title'] ?? 'No Title',
            agerate: agerate, // Kini berisi 'PG', 'R', 'PG-13', dll.
            showStars: false, // Bintang disembunyikan untuk film yang belum rilis
            rating: 0.0,
          );
        },
      ),
    );
  }
}
