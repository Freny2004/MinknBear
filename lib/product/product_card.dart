import 'package:carousel_slider/carousel_controller.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../wishlist/wishlist.dart';
import 'product.dart';
import 'product_rating_stars.dart';

class ProductCard extends StatefulWidget {
  final Map product;

  const ProductCard({super.key, required this.product});

  @override
  _ProductCardState createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Helper function to format price with decimal handling
    String formatPrice(double price) {
      return '\₹${price % 1 == 0 ? price.toStringAsFixed(0) : price.toStringAsFixed(2)}';
    }

    // Calculate discount percentage
    double calculateDiscountPercentage(double originalPrice, double discountedPrice) {
      return ((originalPrice - discountedPrice) / originalPrice) * 100;
    }
    final product = widget.product as Map<String,dynamic>;
    if(product['images']== null || product['images']['edges']== null){
      return const Center(child: Text('No Image Available'));
    }
    // Extract price details
    double originalPrice = double.parse(product['compareAtPriceRange']['minVariantPrice']['amount'] ?? '0');
    double discountedPrice = double.parse(product['priceRange']['minVariantPrice']['amount'] ?? '0');

    return GestureDetector(
      onTap: () async {
        await Future.delayed(const Duration(milliseconds: 200));
        if (context.mounted) {
          Navigator.of(context).push(
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) => ProductPage(
                id: product['id'],
                title: product['title'],
              ),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                const begin = Offset(1.0, 0.0);
                const end = Offset.zero;
                const curve = Curves.easeInOut;

                var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                var offsetAnimation = animation.drive(tween);

                return SlideTransition(
                  position: offsetAnimation,
                  child: child,
                );
              },
            ),
          );
        }
      },
      child: Card(
        color: Colors.grey[200],
        margin: EdgeInsets.symmetric(
          vertical: screenHeight * 0.01,
          horizontal: screenWidth * 0.02,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Stack(
          children: <Widget>[
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(12.0)),
                  child: AspectRatio(
                    aspectRatio: 4 / 5,
                    child: CachedNetworkImage(
                      imageUrl: product['featuredImage']['url'] ?? '',
                      placeholder: (context, url) => Container(
                        color: Colors.grey.shade100,
                      ),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(
                    vertical: screenHeight * 0.02,
                    horizontal: screenWidth * 0.02,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product['title'],
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                        style: TextStyle(
                          fontSize: screenWidth * 0.045, // Adjusted for better readability
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.005),
                      ProductRatingStars(
                        metafields: product['metafields'],
                        compact: true,
                      ),
                      SizedBox(height: screenHeight * 0.007),
                      Row(
                        children: [
                          if (originalPrice > discountedPrice)
                            Padding(
                              padding: EdgeInsets.only(right: screenWidth * 0.01),
                              child: Opacity(
                                opacity: 0.5,
                                child: Text(
                                  formatPrice(originalPrice),
                                  style: TextStyle(
                                    color: Colors.blueGrey,
                                    fontSize: screenWidth * 0.035,
                                    fontWeight: FontWeight.w500,
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                ),
                              ),
                            ),
                          Text(
                            formatPrice(discountedPrice),
                            style: TextStyle(
                              color: Colors.blueGrey,
                              fontSize: screenWidth * 0.035,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (originalPrice > discountedPrice)
                            Container(
                              margin: EdgeInsets.only(left: screenWidth * 0.012),
                              padding: EdgeInsets.symmetric(
                                horizontal: screenWidth * 0.008,
                                vertical: screenHeight * 0.005,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '${calculateDiscountPercentage(originalPrice, discountedPrice).round()}% OFF',
                                style: TextStyle(
                                  fontSize: screenWidth * 0.03,
                                  color: Colors.green.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Positioned(
              top: screenHeight * 0.01,
              right: screenWidth * 0.02,
              child: Consumer<WishlistProvider>(
                builder: (context, wishlistProvider, child) {
                  final productId = product['id'] ?? ''; // Ensure productId is non-null
                  final isWishlisted = wishlistProvider.isWishlisted(productId)==true;

                  return IconButton(
                    icon: Icon(
                      isWishlisted ? Icons.favorite : Icons.favorite_border,
                      color: isWishlisted ? Colors.red : Colors.black,
                    ),
                    onPressed: () {
                      wishlistProvider.toggleWishlist(product); // Toggle wishlist state
                      final message = isWishlisted
                          ? 'Removed from Wishlist!'
                          : 'Added to Wishlist!';
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(message)),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

