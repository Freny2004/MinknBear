import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:shopify_flutter/main.dart';

import 'drawer.dart';
import 'search.dart';
import 'collection/collection.dart';
import 'cart/cart_model.dart';
import 'cart/cart.dart';
import 'customer/customer_model.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      context.read<CartModel>().getCart(context);
      context.read<CustomerModel>().getCustomer(context);
      final customerModel = Provider.of<CustomerModel>(context, listen: false);
      customerModel.getCustomer(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: seedColor,
        elevation: 0,
        title: Text(dotenv.env['STORE_NAME']!),
        actions: [
          IconButton(
            onPressed: () {
              Future.delayed(const Duration(milliseconds: 200)).then((_) => {
                    Navigator.of(context).push(
                      PageRouteBuilder(
                        pageBuilder: (context, animation, secondaryAnimation) =>
                            const SearchPage(),
                        transitionsBuilder:
                            (context, animation, secondaryAnimation, child) {
                          const begin =
                              Offset(3.0, 0.0); // Slide in from the right
                          const end = Offset.zero;
                          const curve = Curves.easeInOut;

                          var tween = Tween(begin: begin, end: end)
                              .chain(CurveTween(curve: curve));
                          var offsetAnimation = animation.drive(tween);

                          return SlideTransition(
                            position: offsetAnimation,
                            child: child,
                          );
                        },
                      ),
                    )
                  });
            },
            icon: const Icon(Icons.search),
          ),
          IconButton(
            onPressed: () {
              Future.delayed(const Duration(milliseconds: 200)).then((_) => {
                Navigator.of(context).push(
                  PageRouteBuilder(
                    pageBuilder: (context, animation, secondaryAnimation) =>
                    const CartPage(),
                    transitionsBuilder:
                        (context, animation, secondaryAnimation, child) {
                      const begin =
                      Offset(1.0, 0.0); // Slide in from the right
                      const end = Offset.zero;
                      const curve = Curves.easeInOut;

                      var tween = Tween(begin: begin, end: end)
                          .chain(CurveTween(curve: curve));
                      var offsetAnimation = animation.drive(tween);

                      return SlideTransition(
                        position: offsetAnimation,
                        child: child,
                      );
                    },
                  ),
                )
                  });
            },
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(
                  Icons.shopping_cart_outlined,
                  semanticLabel: 'Cart',
                ),
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
                  )
              ],
            ),
          ),
          const SizedBox(
            width: 6,
          )
        ],
      ),
      drawer: const MyDrawer(),
      body: Query(
        options: QueryOptions(
          document: gql(r"""
            query collections() {
              collections (first: 50) {
                edges {
                  node {
                    id,
                    title,
                    handle,
                    description,
                    image {
                      transformedSrc(maxWidth: 900, maxHeight: 720, )
                      altText
                    }
                  }
                }
              }
            }
          """),
        ),
        builder: (result, {fetchMore, refetch}) {
          if (result.isLoading) {
            return const Center(
              child: CircularProgressIndicator(
                color: Colors.black,
                semanticsLabel: 'Loading, please wait',
              ),
            );
          }

          if (result.hasException) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error, size: 40, color: Colors.red),
                  SizedBox(height: 10),
                  Text(
                    'Error fetching data',
                    style: TextStyle(fontSize: 16, color: Colors.red),
                  ),
                ],
              ),
            );
          }

          return GridView.count(
            crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
            childAspectRatio:
                MediaQuery.of(context).size.width > 600 ? 1.1 : 0.6,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
            children: [
              for (dynamic edge in result.data!['collections']['edges'])
                buildCollectionCard(edge, context),
            ],
          );
        },
      ),
    );
  }

  Widget buildCollectionCard(dynamic edge, BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(4),
      child: Stack(
        children: <Widget>[
          Column(
            children: [
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(4.0)),
                child: AspectRatio(
                  aspectRatio:
                      4 / 5, // Adjust this based on the desired aspect ratio
                  child: CachedNetworkImage(
                    imageUrl: edge['node']['image'] != null
                        ? edge['node']['image']['transformedSrc'] ?? ''
                        : '',
                    placeholder: (context, url) => const SkeletonLoader(),
                    fit: BoxFit.cover, // Ensures the image fits within its box
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  edge['node']['title'] ?? '',
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center, // Center the text
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis, // Avoid overflowing text
                ),
              ),
            ],
          ),
          Positioned.fill(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () async {
                  await Future.delayed(const Duration(milliseconds: 200));
                  if (context.mounted) {
                    Navigator.of(context).push(
                      PageRouteBuilder(
                        pageBuilder: (context, animation, secondaryAnimation) =>
                            CollectionPage(
                              id: edge['node']['id'],
                              title: edge['node']['title'],
                            ),
                        transitionsBuilder:
                            (context, animation, secondaryAnimation, child) {
                          const begin =
                          Offset(1.0, 0.0); // Slide in from the right
                          const end = Offset.zero;
                          const curve = Curves.easeInOut;

                          var tween = Tween(begin: begin, end: end)
                              .chain(CurveTween(curve: curve));
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
              ),
            ),
          ),
        ],
      ),
    );
  }
}
class SkeletonLoader extends StatelessWidget {
  const SkeletonLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey.shade200,
      width: double.infinity,
      height: 200,
    );
  }
}