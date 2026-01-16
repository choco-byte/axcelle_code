import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:axcelle_code/services/database_helper.dart';
import 'seat_selection.dart';

class MovieDetailScreen extends StatefulWidget {
  final Map<String, dynamic> movie;

  const MovieDetailScreen({super.key, required this.movie});

  @override
  State<MovieDetailScreen> createState() => _MovieDetailScreenState();
}

class _MovieDetailScreenState extends State<MovieDetailScreen> {
  late Future<bool> _isWatchlistedFuture;

  // ===== ADMOB BANNER =====
  BannerAd? _bannerAd;
  bool _isBannerAdLoaded = false;

  @override
  void initState() {
    super.initState();
    _isWatchlistedFuture = _checkWatchlistStatus();

    _bannerAd = BannerAd(
      adUnitId: 'ca-app-pub-3940256099942544/6300978111',
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          setState(() {
            _isBannerAdLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          debugPrint('BannerAd failed to load: $error');
        },
      ),
    );

    _bannerAd!.load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  Future<bool> _checkWatchlistStatus() async {
    final movieId = widget.movie['id'] as int? ?? -1;
    if (movieId == -1) return false;
    return await dbHelper.isMovieInWatchlist(movieId);
  }

  void _toggleWatchlist() async {
    final movieId = widget.movie['id'] as int? ?? -1;
    final movieTitle = widget.movie['title'] ?? 'Film Tanpa Judul';
    final moviePosterPath = widget.movie['poster_path'];

    if (movieId == -1) return;

    final isCurrentlyWatchlisted = await _isWatchlistedFuture;
    String message;

    if (isCurrentlyWatchlisted) {
      await dbHelper.removeFromWatchlist(movieId);
      message = '$movieTitle dihapus dari Watchlist.';
    } else {
      await dbHelper.addToWatchlist({
        'id': movieId,
        'title': movieTitle,
        'poster_path': moviePosterPath,
      });
      message = '$movieTitle ditambahkan ke Watchlist!';
    }

    setState(() {
      _isWatchlistedFuture = Future.value(!isCurrentlyWatchlisted);
    });

    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  String _getMovieImageUrl() {
    if (widget.movie.containsKey('poster_path') &&
        widget.movie['poster_path'] != null) {
      return 'https://image.tmdb.org/t/p/w500${widget.movie['poster_path']}';
    } else if (widget.movie.containsKey('image') &&
        widget.movie['image'] != null) {
      return widget.movie['image'];
    }
    return 'https://via.placeholder.com/500x750?text=No+Image';
  }

  @override
  Widget build(BuildContext context) {
    final String imageUrl = _getMovieImageUrl();
    final bool isLocalAsset = imageUrl.startsWith('assets/');

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.movie['title'] ?? 'Detail Film'),
        actions: [
          FutureBuilder<bool>(
            future: _isWatchlistedFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.only(right: 15),
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                );
              }

              final isInWatchlist = snapshot.data ?? false;

              return IconButton(
                icon: Icon(
                  isInWatchlist
                      ? Icons.bookmark
                      : Icons.bookmark_border,
                  color: isInWatchlist ? Colors.yellow : Colors.white,
                ),
                onPressed: _toggleWatchlist,
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: isLocalAsset
                    ? Image.asset(
                        imageUrl,
                        height: 300,
                        fit: BoxFit.cover,
                      )
                    : Image.network(
                        imageUrl,
                        height: 300,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return const SizedBox(
                            height: 300,
                            child: Center(
                              child: CircularProgressIndicator(),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.broken_image, size: 300),
                      ),
              ),
            ),

            const SizedBox(height: 20),

            Text(
              widget.movie['title'] ?? 'N/A',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            if (widget.movie['vote_average'] != null)
              Row(
                children: [
                  const Icon(Icons.star, color: Colors.amber, size: 20),
                  const SizedBox(width: 5),
                  Text(
                    'Rating: ${widget.movie['vote_average']}',
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),

            const SizedBox(height: 15),

            Text(
              'Overview:',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),

            const SizedBox(height: 5),

            Text(
              widget.movie['overview'] ?? 'Sinopsis tidak tersedia.',
              style: const TextStyle(fontSize: 16),
            ),

            const SizedBox(height: 25),

            // ===== ADMOB BANNER =====
            if (_isBannerAdLoaded)
              Center(
                child: SizedBox(
                  width: _bannerAd!.size.width.toDouble(),
                  height: _bannerAd!.size.height.toDouble(),
                  child: AdWidget(ad: _bannerAd!),
                ),
              ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SeatSelectionScreen(
                        movieTitle:
                            widget.movie['title'] ?? 'Film Tanpa Judul',
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.confirmation_number),
                label: const Text(
                  'Book Now',
                  style: TextStyle(fontSize: 18),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}