import 'package:flutter/material.dart';

class _NetworkImageLoader extends StatelessWidget {
  final String imageUrl;
  final double width;
  final double height;
  final Widget placeholderWidget;

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

    return Image(
      key: ValueKey(imageUrl), 
      image: NetworkImage(imageUrl), 
      fit: BoxFit.cover,
      
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Center(
          child: CircularProgressIndicator(
            value: loadingProgress.expectedTotalBytes != null
                ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                : null,
            color: Theme.of(context).colorScheme.primary,
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) => placeholderWidget, 
    );
  }
}

class MovieCard1 extends StatelessWidget {
  final String image; 
  final String title;
  final String agerate;
  final bool showStars;
  final double rating;
  final VoidCallback onTap;

  MovieCard1({
    Key? key,
    required this.image,
    required this.title,
    required this.agerate,
    required this.showStars,
    required this.rating,
    required this.onTap,
  }) : super(key: key);

  Widget _buildImage(BuildContext context, double width, double height) {
    final placeholderWidget = Container(
      color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[800] : Colors.grey[300],
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text('No Poster Available', textAlign: TextAlign.center, style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[500] : Colors.grey, 
              fontSize: 14)),
        ),
      ),
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(7), 
      child: SizedBox(
        width: width,
        height: height,
        child: _NetworkImageLoader(
          imageUrl: image,
          width: width,
          height: height,
          placeholderWidget: placeholderWidget,
        ),
      ),
    );
  }

  Widget _buildStarRating(double rating, double starSize) {
    return Row(
      children: List.generate(5, (index) {
        double starValue = index + 1.0; 
        
        if (rating >= starValue) {
          return Icon(Icons.star, color: Colors.amber, size: starSize);
        } else if (rating > index) {
          return Icon(Icons.star_half, color: Colors.amber, size: starSize); 
        } else {
          return Icon(Icons.star_border, color: Colors.amber, size: starSize);
        }
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    double fontSizeBase = screenWidth * 0.05;
    
    final clampedRating5Star = (rating / 2.0).clamp(0.0, 5.0);

    final imageWidth = screenWidth * 9 / 28; 
    final imageHeight = screenWidth * 9 / 20;

    return GestureDetector( 
      onTap: onTap, 
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildImage(context, imageWidth, imageHeight),
          
          SizedBox(height: screenWidth * 0.025),

          Container(
            width: imageWidth,
            child: Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: fontSizeBase * 0.8,
                color: Theme.of(context).textTheme.bodyLarge!.color, 
              ),
            ),
          ),
          
          SizedBox(height: screenWidth * 0.015), 

          if (agerate.isNotEmpty && agerate != 'N/A')
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark 
                    ? Colors.grey[700] 
                    : const Color.fromARGB(255, 199, 199, 199),
                borderRadius: BorderRadius.circular(4), 
              ),
              child: Text(
                agerate, 
                style: TextStyle(
                  fontSize: fontSizeBase * 0.6, 
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).brightness == Brightness.dark 
                      ? Colors.white 
                      : Colors.black,
                ),
              ),
            ),
          
          SizedBox(height: screenWidth * 0.02),

          if (showStars) 
            _buildStarRating(clampedRating5Star, screenWidth * 0.04), 

          SizedBox(height: screenWidth * 0.02), 
        ],
      ),
    );
  }
}
