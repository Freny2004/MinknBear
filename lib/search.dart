import 'dart:async';

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

import 'main.dart';
import 'product/product_card.dart';

class SearchPage extends StatefulWidget {
	const SearchPage({super.key});

	@override
	State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
	final _scaffoldKey = GlobalKey<ScaffoldState>();
	final ScrollController _listViewController = ScrollController();
	final TextEditingController _textController = TextEditingController();
	String? _query;
	List? _products;
	bool _paginationLoading = false;
	Map? _paginationInfo;
	Timer? _debounce;

	Future<void> _getProducts({int limit = 12, String? after}) async {
		final client = GraphQLProvider.of(context).value;

		try {
			final result = await client.query(QueryOptions(
				document: gql(r"""
          query products($limit: Int, $after: String, $query: String) {
            products(
              first: $limit
              after: $after
              query: $query
            ) {
              edges {
                node {
                  id
                  title
                  handle
                  featuredImage {
                    id
                    url(transform: { maxWidth: 480, maxHeight: 480 })
                    altText
                  }
                  images(first: 5) {
                    edges {
                      node {
                        transformedSrc(maxWidth: 480, maxHeight: 480)
                        altText
                      }
                    }
                  }
                  compareAtPriceRange {
                    minVariantPrice { amount currencyCode }
                    maxVariantPrice { amount currencyCode }
                  }
                  priceRange {
                    minVariantPrice { amount currencyCode }
                    maxVariantPrice { amount currencyCode }
                  }
                  metafields(identifiers: [
                    { namespace: "reviews", key: "rating" }
                    { namespace: "reviews", key: "rating_count" }
                  ]) {
                    type
                    namespace
                    key
                    value
                  }
                }
              }
              pageInfo {
                endCursor
                hasNextPage
              }
            }
          }
        """),
				variables: {'limit': limit, 'after': after, 'query': _query},
			));

			if (result.hasException) {
				if (kDebugMode) {
					print(result.exception.toString());
				}
				ScaffoldMessenger.of(context).showSnackBar(
					const SnackBar(content: Text('Failed to load products. Try again later.')),
				);
				return;
			}

			setState(() {
				if (after == null) {
					_products = result.data!['products']['edges'];
				} else {
					_products = [..._products!, ...result.data!['products']['edges']];
				}

				_paginationLoading = false;
				_paginationInfo = result.data!['products']['pageInfo'];
			});
		} catch (e) {
			if (kDebugMode) {
				print(e);
			}
			ScaffoldMessenger.of(context).showSnackBar(
				const SnackBar(content: Text('An error occurred. Please try again later.')),
			);
		}
	}

	void _onSearchChanged(String value) {
		if (_debounce?.isActive ?? false) _debounce!.cancel();
		_debounce = Timer(const Duration(milliseconds: 500), () {
			setState(() {
				_query = value;
				if (value.isEmpty) {
					_products = null;
				} else {
					_getProducts();
				}
			});
		});
	}

	@override
	void initState() {
		super.initState();
		_textController.addListener(() {
			_onSearchChanged(_textController.text);
		});
	}

	@override
	void dispose() {
		_textController.dispose();
		_listViewController.dispose();
		_debounce?.cancel();
		super.dispose();
	}

	@override
	Widget build(BuildContext context) {
		return Scaffold(
			key: _scaffoldKey,
			appBar: AppBar(
				backgroundColor: seedColor,
				elevation: 0,
				title: Container(
					width: double.infinity,
					height: 40,
					decoration: BoxDecoration(
						color: Colors.white,
						borderRadius: BorderRadius.circular(4),
					),
					child: Center(
						child: TextField(
							controller: _textController,
							autofocus: true,
							decoration: InputDecoration(
								prefixIcon: const Icon(
									Icons.search,
									size: 22,
									color: Colors.grey,
								),
								suffixIcon: IconButton(
									icon: const Icon(Icons.clear),
									color: _textController.text.isEmpty ? Colors.grey : null,
									iconSize: 22,
									onPressed: () {
										_textController.clear();
										setState(() {
											_query = null;
											_products = null;
										});
									},
								),
								hintText: 'Search for products...',
								border: InputBorder.none,
							),
						),
					),
				),
			),
			body: _products == null
					? const Center(child: Text('Start typing to search for products.'))
					: _products!.isEmpty
					? const Center(
					child: Column(
						mainAxisAlignment: MainAxisAlignment.center,
						children: [
							Icon(
								Icons.sentiment_dissatisfied,
								size: 28,
								color: Colors.grey,
							),
							SizedBox(height: 12),
							Text('No products found!'),
							SizedBox(height: 16),
						],
					))
					: NotificationListener<ScrollEndNotification>(
				onNotification: (scrollEnd) {
					if (scrollEnd.metrics.atEdge) {
						if (!scrollEnd.metrics.pixels.isNegative &&
								_paginationInfo != null &&
								_paginationInfo!['hasNextPage']) {
							setState(() {
								_paginationLoading = true;
							});
							_getProducts(after: _paginationInfo!['endCursor']);
						}
					}
					return false;
				},
				child: Column(
					children: [
						Expanded(
							child: GridView.count(
								controller: _listViewController,
								crossAxisCount:
								MediaQuery.of(context).size.width > 600 ? 3 : 2,
								childAspectRatio:
								MediaQuery.of(context).size.width > 600
										? 0.75
										: 0.5,
								padding: const EdgeInsets.symmetric(
										vertical: 8, horizontal: 6),
								mainAxisSpacing: 8,
								crossAxisSpacing: 6,
								children: [
									for (dynamic edge in _products!)
										ProductCard(product: edge['node']),
								],
							),
						),
						if (_paginationLoading)
							const Padding(
								padding: EdgeInsets.all(8.0),
								child: CircularProgressIndicator(),
							),
					],
				),
			),
		);
	}
}
