import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shopify_flutter/main.dart';
import 'package:shopify_flutter/product/product.dart';
import '../cart/cart.dart';
import '../cart/cart_model.dart';
import 'WishlistDbHelper.dart';


class WishlistProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _wishlist = [];

  List<Map<String, dynamic>> get wishlist => _wishlist;

  Future<void> loadWishlist() async {
    final products = await WishlistDatabaseHelper.getAllProducts();
    _wishlist = products;
    notifyListeners();
  }

  bool isWishlisted(String productId) {
    return _wishlist.any((product) => product['id'] == productId);
  }

  Future<void> toggleWishlist(Map<String, dynamic> product) async {
    if (isWishlisted(product['id'])) {
      await WishlistDatabaseHelper.removeProduct(product['id']);
      _wishlist.removeWhere((item) => item['id'] == product['id']);
    } else {
      await WishlistDatabaseHelper.addProduct(product);
      _wishlist.add(product);
    }
    notifyListeners();
  }
}

class WishlistPage extends StatefulWidget {
  const WishlistPage({super.key});

  @override
  _WishlistPageState createState() => _WishlistPageState();
}

class _WishlistPageState extends State<WishlistPage> {
  int _currentSlide = 0;
  late CarouselSliderController _controller;
  int _qty = 1;

  @override
  void initState() {
    super.initState();
    _controller = CarouselSliderController();
    Provider.of<WishlistProvider>(context, listen: false).loadWishlist();
  }

  @override
  Widget build(BuildContext context) {
    final wishlistProvider = Provider.of<WishlistProvider>(context);
    final wishlist = wishlistProvider.wishlist;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Wishlist'),
        backgroundColor: seedColor,
        actions: [
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const CartPage()),
              );
            },
            icon: Stack(
              children: [
                const Icon(Icons.shopping_cart_outlined),
                if (context.watch<CartModel>().count > 0)
                  Positioned(
                    top: 0,
                    right: -6,
                    child: CircleAvatar(
                      radius: 8,
                      backgroundColor: Colors.yellow.shade900,
                      child: Text(
                        context.watch<CartModel>().count.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      body: wishlist.isEmpty
          ? const Center(child: Text('Your wishlist is empty!'))
          : Padding(
        padding: const EdgeInsets.all(8.0),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.6,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: wishlist.length,
          itemBuilder: (context, index) {
            final product = wishlist[index];

            final selectedVariant = product['variants']?['edges']?.isNotEmpty == true
                ? product['variants']['edges'][0]['node']
                : null;

            if (selectedVariant == null) {
              return Container(
                alignment: Alignment.center,
                child: const Text(
                  'No variants available',
                  style: TextStyle(color: Colors.red),
                ),
              );
            }

            final double compareAtPrice = selectedVariant['compareAtPrice']?['amount'] != null
                ? double.tryParse(selectedVariant['compareAtPrice']['amount']) ?? 0
                : 0;

            final double price = double.tryParse(selectedVariant['price']['amount']) ?? 0;

            return GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => ProductPage(
                      id: product['id'],
                      title: product['title'],
                    ),
                  ),
                );
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      flex: 3,
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(15),
                            ),
                            child: CarouselSlider(
                              carouselController: _controller,
                              options: CarouselOptions(
                                initialPage: _currentSlide,
                                viewportFraction: 1,
                                aspectRatio: 1,
                                onPageChanged: (index, reason) {
                                  setState(() {
                                    _currentSlide = index;
                                  });
                                },
                              ),
                              items: (product['images']?['edges'] ?? [])
                                  .map<Widget>((item) {
                                return CachedNetworkImage(
                                  imageUrl: item['node']?['transformedSrc'] ?? '',
                                  placeholder: (context, url) =>
                                      Container(color: Colors.grey.shade100),
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                );
                              }).toList(),
                            ),
                          ),
                          Positioned(
                            top: 2,
                            right: 0,
                            child: IconButton(
                              icon: const Icon(Icons.highlight_off),
                              onPressed: () {
                                wishlistProvider.toggleWishlist(product);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Removed from Wishlist')),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product['title'],
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (compareAtPrice > 0)
                                  Text(
                                    '₹${compareAtPrice.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                      decoration: TextDecoration.lineThrough,
                                    ),
                                  ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '₹${price.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    if (compareAtPrice > 0)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 4,
                                          vertical: 1,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.green.shade50,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          '${(((compareAtPrice - price) / compareAtPrice) * 100).round()}% OFF',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: Colors.green.shade700,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    IconButton(
                                      icon: const Icon(Icons.shopping_cart),
                                      onPressed: () {
                                        context.read<CartModel>().cartLinesAdd(context, [
                                          {
                                            'merchandiseId': selectedVariant['id'],
                                            'quantity': _qty,
                                          },
                                        ]);

                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                                '${product['title']} added to cart!'),
                                            action: SnackBarAction(
                                              label: 'View cart',
                                              onPressed: () {
                                                Navigator.of(context).push(
                                                  MaterialPageRoute(
                                                    builder: (context) => const CartPage(),
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
