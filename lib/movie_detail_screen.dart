import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Penting untuk Haptic Feedback
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
  List<Map<String, dynamic>> _reviews = [];
  bool _alreadyRated = false;
  late Future<bool> _isWatchlistedFuture;
  BannerAd? _bannerAd;
  bool _isBannerAdLoaded = false;

  @override
  void initState() {
    super.initState();
    _isWatchlistedFuture = dbHelper.isMovieInWatchlist(_getSafeId());
    _refreshData();
    _initBannerAd();
  }

  int _getSafeId() => int.tryParse(widget.movie['id'].toString()) ?? 0;

  Future<void> _refreshData() async {
    final reviews = await dbHelper.getReviewsByMovie(_getSafeId());
    final hasRated = await dbHelper.hasUserRated(_getSafeId(), 'You');
    if (mounted) {
      setState(() {
        _reviews = reviews;
        _alreadyRated = hasRated;
      });
    }
  }

  void _initBannerAd() {
    _bannerAd = BannerAd(
      adUnitId: 'ca-app-pub-3940256099942544/6300978111', // Test ID
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) => setState(() => _isBannerAdLoaded = true),
        onAdFailedToLoad: (ad, error) => ad.dispose(),
      ),
    )..load();
  }

  void _showReviewSheet() {
    double selectedRating = 0;
    final commentController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom + 20, left: 20, right: 20, top: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_alreadyRated ? "Add a Comment" : "Rate & Review", 
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              
              if (!_alreadyRated)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (i) => IconButton(
                    icon: AnimatedScale(
                      scale: selectedRating == i + 1 ? 1.3 : 1.0, // Efek Animasi
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        i < selectedRating ? Icons.star : Icons.star_border, 
                        color: Colors.amber, size: 40
                      ),
                    ),
                    onPressed: () {
                      HapticFeedback.lightImpact(); // Getar Halus
                      setModalState(() => selectedRating = i + 1.0);
                    },
                  )),
                )
              else
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: Text("You've already rated this movie ⭐", style: TextStyle(color: Colors.grey)),
                ),

              const SizedBox(height: 10),
              TextField(
                controller: commentController,
                decoration: const InputDecoration(
                  hintText: "Review (Optional)", 
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.edit_note)
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 15)),
                  onPressed: () async {
                    if (!_alreadyRated && selectedRating == 0) {
                      HapticFeedback.heavyImpact(); // Getar Error
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please select a star rating!")));
                      return;
                    }

                    HapticFeedback.mediumImpact(); // Getar Sukses
                    await dbHelper.insertReview({
                      'movie_id': _getSafeId(),
                      'user_name': 'You',
                      'rating': _alreadyRated ? 0 : selectedRating,
                      'comment': commentController.text,
                    });

                    await _refreshData();
                    if (mounted) Navigator.pop(ctx);
                  },
                  child: const Text("SUBMIT REVIEW"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final posterPath = widget.movie['poster_path'];
    final imageUrl = posterPath != null ? 'https://image.tmdb.org/t/p/w500$posterPath' : 'https://via.placeholder.com/500';

    return Scaffold(
      appBar: AppBar(
        title: const Text("Detail"),
        actions: [
          FutureBuilder<bool>(
            future: _isWatchlistedFuture,
            builder: (context, snapshot) {
              bool isIn = snapshot.data ?? false;
              return IconButton(
                icon: Icon(isIn ? Icons.bookmark : Icons.bookmark_border, color: isIn ? Colors.yellow : null),
                onPressed: () async {
                  HapticFeedback.selectionClick();
                  if (isIn) {
                    await dbHelper.removeFromWatchlist(_getSafeId());
                  } else {
                    await dbHelper.addToWatchlist({'id': _getSafeId(), 'title': widget.movie['title'], 'poster_path': posterPath});
                  }
                  setState(() { _isWatchlistedFuture = dbHelper.isMovieInWatchlist(_getSafeId()); });
                },
              );
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: ClipRRect(borderRadius: BorderRadius.circular(15), child: Image.network(imageUrl, height: 300))),
            const SizedBox(height: 20),
            Text(widget.movie['title'] ?? '', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text(widget.movie['overview'] ?? '', style: const TextStyle(color: Colors.grey)),
            const Divider(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Reviews (${_reviews.length})", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                TextButton(onPressed: _showReviewSheet, child: const Text("Write Review")),
              ],
            ),
            const SizedBox(height: 10),
            _reviews.isEmpty 
              ? const Text("No reviews yet.")
              : SizedBox(
                  height: 110,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _reviews.length,
                    itemBuilder: (ctx, i) {
                      final rev = _reviews[i];
                      return Container(
                        width: 240,
                        margin: const EdgeInsets.only(right: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: Colors.blueGrey.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                if (rev['rating'] > 0) ...[const Icon(Icons.star, color: Colors.amber, size: 16), Text(" ${rev['rating']}")],
                                const Spacer(),
                                Text(rev['user_name'], style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blue)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(rev['comment'].toString().isEmpty ? "(Rating Only)" : rev['comment'], 
                                 maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontStyle: rev['comment'].toString().isEmpty ? FontStyle.italic : FontStyle.normal)),
                          ],
                        ),
                      );
                    },
                  ),
                ),
            const SizedBox(height: 20),
            if (_isBannerAdLoaded) Container(alignment: Alignment.center, height: 50, child: AdWidget(ad: _bannerAd!)),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.confirmation_num),
                label: const Text("Book Now"),
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SeatSelectionScreen(movieTitle: widget.movie['title'] ?? ''))),
              ),
            ),
          ],
        ),
      ),
    );
  }
}