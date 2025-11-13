import 'package:flutter/material.dart';

class MovieDetailScreen extends StatelessWidget {
  final Map<String, dynamic> movie;

  const MovieDetailScreen({super.key, required this.movie});

  String _getMovieImageUrl() {
    if (movie.containsKey('poster_path') && movie['poster_path'] != null) {
      return 'https://image.tmdb.org/t/p/w500${movie['poster_path']}';
    } 
    else if (movie.containsKey('image') && movie['image'] != null) {
      return movie['image']; 
    }
    return 'https://via.placeholder.com/500x750?text=No+Image';
  }

  @override
  Widget build(BuildContext context) {
    final String imageUrl = _getMovieImageUrl();
    final bool isLocalAsset = imageUrl.startsWith('assets/');

    return Scaffold(
      appBar: AppBar(
        title: Text(movie['title'] ?? 'Detail Film'),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
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
                        errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 300),
                      )
                    : Image.network(
                        imageUrl,
                        height: 300,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return SizedBox(
                            height: 300,
                            child: Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                    : null,
                              ),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 300),
                      ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            Text(
              movie['title'] ?? 'N/A',
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            
            const SizedBox(height: 10),

            if (movie['vote_average'] != null)
              Row(
                children: [
                  const Icon(Icons.star, color: Colors.amber, size: 20),
                  const SizedBox(width: 5),
                  Text(
                    'Rating: ${movie['vote_average'].toString()}',
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            
            const SizedBox(height: 10),

            Text(
              'Overview:',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
            ),
            const SizedBox(height: 5),
            Text(
              movie['overview'] ?? 'Sinopsis tidak tersedia.',
              style: const TextStyle(fontSize: 16),
            ),

            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Booking tiket untuk ${movie['title']}!')),
                  );
                },
                icon: const Icon(Icons.confirmation_number_sharp),
                label: const Text('Book Now', style: TextStyle(fontSize: 18)),
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