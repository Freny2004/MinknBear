import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../main.dart';

class CartCheckout extends StatefulWidget {
  final String checkoutUrl;

  const CartCheckout({Key? key, required this.checkoutUrl}) : super(key: key);

  @override
  State<CartCheckout> createState() => _CartCheckoutState();
}

class _CartCheckoutState extends State<CartCheckout> {
  late final WebViewController _controller;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    // Initialize the WebViewController
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted) // Enable JavaScript
      ..setBackgroundColor(const Color(0x00000000)) // Transparent background
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            setState(() {
              isLoading = true; // Show loading indicator when page starts loading
            });
          },
          onPageFinished: (url) {
            setState(() {
              isLoading = false; // Hide loading indicator when page finishes loading
            });
          },
          onNavigationRequest: (request) {
            if (!Uri.parse(request.url).isAbsolute) {
              return NavigationDecision.prevent; // Prevent non-absolute URLs
            }
            return NavigationDecision.navigate; // Allow navigation to absolute URLs
          },
          onWebResourceError: (error) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to load page: ${error.description}')),
            ); // Show error message if page loading fails
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.checkoutUrl)); // Load the checkout URL
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: seedColor,

        elevation: 0,
        title: const Text('Checkout'),
        actions: [
          // Refresh button to reload the page
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _controller.reload(),
          ),
        ],
      ),
      body: Stack(
        children: [
          WebViewWidget(
            controller: _controller, // Display WebView
          ),
          // Show loading indicator while the page is loading
          if (isLoading)
            const Center(
              child: CircularProgressIndicator(color: Colors.black),
            ),
        ],
      ),
    );
  }
}
