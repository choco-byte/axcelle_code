import 'package:flutter/material.dart';

// --- Widget Bantuan untuk Pemuatan Gambar Jaringan (Non-const untuk Stabilitas Hot Reload) ---
class _NetworkImageLoader extends StatelessWidget {
  final String imageUrl;
  final double width;
  final double height;
  final Widget placeholderWidget;

  // Menghapus 'const' untuk mengatasi masalah hot reload
  _NetworkImageLoader({
    required this.imageUrl,
    required this.width,
    required this.height,
    required this.placeholderWidget,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl.isEmpty) {
      return placeholderWidget;
    }

    // PENTING: Menggunakan konstruktor Image eksplisit dengan NetworkImage.
    // Ini adalah cara paling eksplisit untuk memberi tahu Flutter bahwa ini adalah gambar jaringan,
    // yang diharapkan dapat mengatasi bug hot reload yang terus menerus.
    return Image(
      // ValueKey dipertahankan
      key: ValueKey(imageUrl), 
      image: NetworkImage(imageUrl), // Menggunakan provider NetworkImage secara langsung
      fit: BoxFit.cover,
      
      // Properti loadingBuilder dan errorBuilder dipindahkan ke Image widget
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Center(
          child: CircularProgressIndicator(
            value: loadingProgress.expectedTotalBytes != null
                ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                : null,
            color: const Color(0xFF7B1113),
          ),
        );
      },
      // Menggunakan placeholder yang sama untuk error
      errorBuilder: (context, error, stackTrace) => placeholderWidget, 
    );
  }
}
// -----------------------------------------------------------------

class MovieCard1 extends StatelessWidget {
  final String image; 
  final String title;
  final String agerate;
  final bool showStars;
  final double rating;

  // Menghapus 'const' untuk mengatasi masalah hot reload
  MovieCard1({
    Key? key,
    required this.image,
    required this.title,
    required this.agerate,
    required this.showStars,
    required this.rating,
  }) : super(key: key);

  // Widget untuk membangun gambar
  Widget _buildImage(BuildContext context, double width, double height) {
    // Placeholder default jika gambar tidak tersedia atau kosong
    final placeholderWidget = Container(
      color: Colors.grey[300],
      child: const Center(
        child: Padding(
          padding: EdgeInsets.all(8.0),
          child: Text('No Poster Available', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 14)),
        ),
      ),
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(7), // Image border
      child: SizedBox(
        width: width,
        height: height,
        // Menggunakan widget baru yang terisolasi
        child: _NetworkImageLoader(
          imageUrl: image,
          width: width,
          height: height,
          placeholderWidget: placeholderWidget,
        ),
      ),
    );
  }

  // Widget untuk membuat baris rating bintang
  Widget _buildStarRating(double rating, double starSize) {
    return Row(
      children: List.generate(5, (index) {
        double starValue = index + 1.0; 
        
        if (rating >= starValue) {
          // Bintang penuh
          return Icon(Icons.star, color: Colors.amber, size: starSize);
        } else if (rating > index) {
          // Setengah bintang
          return Icon(Icons.star_half, color: Colors.amber, size: starSize); 
        } else {
          // Bintang kosong
          return Icon(Icons.star_border, color: Colors.amber, size: starSize);
        }
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    double fontSizeBase = screenWidth * 0.05;
    
    // Dimensi relatif
    final imageWidth = screenWidth * 9 / 28; 
    final imageHeight = screenWidth * 9 / 20;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Gambar Poster
        _buildImage(context, imageWidth, imageHeight),
        
        SizedBox(height: screenWidth * 0.025),

        // 2. Judul Film
        Container(
          width: imageWidth, // Batasi lebar teks sesuai lebar gambar
          child: Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: fontSizeBase * 0.8, // Ukuran disesuaikan agar pas dengan lebar kartu
              color: Colors.black,
            ),
          ),
        ),
        
        SizedBox(height: screenWidth * 0.015), 

        // 3. Kategori Usia/PG (Kotak Abu-abu)
        if (agerate.isNotEmpty && agerate != 'N/A')
          Container(
            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2), // Padding dikurangi
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 199, 199, 199),
              borderRadius: BorderRadius.circular(4), 
            ),
            child: Text(
              agerate, 
              style: TextStyle(
                fontSize: fontSizeBase * 0.6, 
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
        
        SizedBox(height: screenWidth * 0.02),

        // 4. Rating Bintang
        if (showStars) 
          _buildStarRating(rating, screenWidth * 0.04), // Ukuran bintang responsif

        // Tambahkan ruang di bagian bawah
        SizedBox(height: screenWidth * 0.02), 
      ],
    );
  }
}
