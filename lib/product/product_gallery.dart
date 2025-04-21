import 'dart:core';

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:provider/provider.dart';

import '../wishlist/wishlist.dart';
import 'product_selected_variant_model.dart';

class ProductGallery extends StatefulWidget {
  final Map product;

  const ProductGallery({super.key, required this.product});

  @override
  State<ProductGallery> createState() => _ProductGalleryState();
}

class _ProductGalleryState extends State<ProductGallery> {
  int _currentSlide = 0;
  late CarouselSliderController _controller; // Correct controller type

  @override
  void initState() {
    super.initState();
    _controller = CarouselSliderController(); // Initialize the correct controller

    if (mounted) {
      final selectedVariant = context.read<SelectedVariantModel>().selectedVariant;

      if (selectedVariant != null) {
        for (MapEntry mapEntry in widget.product['images']['edges'].asMap().entries) {
          if (mapEntry.value['node']['id'] == selectedVariant['image']['id']) {
            _currentSlide = mapEntry.key;
          }
        }
      }
    }

    Provider.of<SelectedVariantModel>(context, listen: false).addListener(() {
      if (mounted) {
        final selectedVariant = context.read<SelectedVariantModel>().selectedVariant;

        if (selectedVariant != null) {
          for (MapEntry mapEntry in widget.product['images']['edges'].asMap().entries) {
            if (mapEntry.value['node']['id'] == selectedVariant['image']['id']) {
              _controller.animateToPage(mapEntry.key, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut); // Correct method usage
            }
          }
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product as Map<String,dynamic>;
    if(product['images']== null || product['images']['edges']== null){
      return const Center(child: Text('No Image Available'));
    }
    return Stack(
      children: [
        CarouselSlider(
          carouselController: _controller, // Correct controller usage
          options: CarouselOptions(
            initialPage: _currentSlide,
            aspectRatio: 1,
            viewportFraction: 1,

            pageSnapping: true,
            onPageChanged: (index, reason) {
              setState(() {
                _currentSlide = index;
              });
            },
            scrollPhysics: const BouncingScrollPhysics(),
          ),
          items: widget.product['images']['edges'].map<Widget>((item) => CachedNetworkImage(
            imageUrl: item['node']['transformedSrc'] ?? '',
            placeholder: (context, url) => const Center(child: CircularProgressIndicator(
              color: Colors.black,
            )),
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.width,
            fit: BoxFit.cover,
          )).toList(),
        ),
        Positioned(
          top: MediaQuery.of(context).size.height * 0.42,
          right: MediaQuery.of(context).size.width * 0.035,
          child: Consumer<WishlistProvider>(
            builder: (context, wishlistProvider, child) {
              final productId = product['id'] ?? ''; // Ensure productId is non-null
              final isWishlisted = wishlistProvider.isWishlisted(productId) == true; // Explicitly ensure a boolean value

              return Container(
                height: 35,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.6), // Background with slight opacity
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2), // Add shadow for better visibility
                      spreadRadius: 1,
                      blurRadius: 3,
                      offset: Offset(0, 2), // Shadow offset
                    ),
                  ],
                ),
                child: IconButton(
                  padding: EdgeInsets.all(6), // Smaller padding for compact size
                  iconSize: 24, // Slightly reduced icon size
                  icon: Icon(
                    isWishlisted ? Icons.favorite : Icons.favorite_border,
                    color: isWishlisted ? Colors.red : Colors.black,
                  ),
                  onPressed: () {
                    final wasWishlisted = wishlistProvider.isWishlisted(productId) == true; // Explicit check again
                    wishlistProvider.toggleWishlist(product); // Toggle wishlist state
                    final message = wasWishlisted
                        ? 'Removed from Wishlist!'
                        : 'Added to Wishlist!';
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(message)),
                    );
                  },
                ),
              );
            },
          ),
        ),
        Positioned(
          bottom: 12,
          child: SizedBox(
            width: MediaQuery.of(context).size.width,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: widget.product['images']['edges'].asMap().entries.map<Widget>((entry) =>
                  Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black.withOpacity(_currentSlide == entry.key ? 0.5 : 0.1),
                    ),
                  ),
              ).toList(),
            ),
          ),
        ),
      ],
    );
  }
}
