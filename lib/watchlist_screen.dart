import 'package:axcelle_code/movie_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:axcelle_code/services/database_helper.dart';

class WatchlistScreen extends StatefulWidget {
  const WatchlistScreen({super.key});

  @override
  State<WatchlistScreen> createState() => _WatchlistScreenState();
}

class _WatchlistScreenState extends State<WatchlistScreen> {
  late Future<List<Map<String, dynamic>>> _watchlistFuture;

  @override
  void initState() {
    super.initState();
    _watchlistFuture = dbHelper.getWatchlist();
  }

  void _deleteMovie(int movieId, String movieTitle) async {
    await dbHelper.removeFromWatchlist(movieId);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$movieTitle successfully removed!')),
    );

    setState(() {
      _watchlistFuture = dbHelper.getWatchlist(); 
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Watchlist'),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _watchlistFuture, 
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error memuat data: ${snapshot.error}'));
          }

          final watchlist = snapshot.data ?? [];
          if (watchlist.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.movie_filter,
                    size: 80,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Your watchlist is empty.',
                    style: TextStyle(fontSize: 18),
                  ),
                  const Text(
                    'Add movies to watch later.',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, 
                childAspectRatio:
                    0.7, 
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: watchlist.length,
              itemBuilder: (context, index) {
                final movie = watchlist[index];
                final String imageUrl =
                    movie.containsKey('poster_path') &&
                        movie['poster_path'] != null
                    ? 'https://image.tmdb.org/t/p/w500${movie['poster_path']}' 
                    : 'https://via.placeholder.com/500x750?text=No+Poster';

                final int movieId = movie['id'] as int? ?? 0;
                final String movieTitle = movie['title'] ?? 'N/A';

                return InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MovieDetailScreen(movie: movie),
                      ),
                    );
                  },
                  child: Card(
                    clipBehavior: Clip
                        .antiAlias, 
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 5,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Center(
                            child: Icon(
                              Icons.broken_image,
                              size: 50,
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ),

                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.black.withOpacity(0.8),
                                  Colors.transparent,
                                ],
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                              ),
                            ),
                            child: Text(
                              movieTitle,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),

                        Positioned(
                          top: 5,
                          right: 5,
                          child: IconButton(
                            icon: const Icon(
                              Icons.delete_forever,
                              color: Colors.red,
                              size: 30,
                            ),
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.white.withOpacity(0.9),
                              minimumSize: Size.zero,
                              padding: const EdgeInsets.all(4),
                            ),
                            onPressed: () {
                              if (movieId != 0) {
                                _deleteMovie(movieId, movieTitle);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
