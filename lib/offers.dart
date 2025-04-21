import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:provider/provider.dart';
import 'package:shopify_flutter/search.dart';
import 'cart/cart.dart';
import 'cart/cart_model.dart';

class OfferScreen extends StatefulWidget {
  const OfferScreen({super.key});

  @override
  State<OfferScreen> createState() => _OfferScreenState();
}

class _OfferScreenState extends State<OfferScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          elevation: 0,
          title: Text('Get Offers'),
          actions: [
            IconButton(
              onPressed: () {
                Future.delayed(const Duration(milliseconds: 200)).then((_) => {
                      Navigator.of(context).push(MaterialPageRoute(
                          builder: (context) => const SearchPage()))
                    });
              },
              icon: const Icon(Icons.search),
            ),
            IconButton(
              onPressed: () {
                Future.delayed(const Duration(milliseconds: 200)).then((_) => {
                      Navigator.of(context).push(MaterialPageRoute(
                          builder: (context) => const CartPage()))
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
        body: Column(
          children: [
            Card(
              color: Colors.grey[200],
              child: Html(data: """<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Discount Offers</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            line-height: 1.2;
            background-color: #f9f9f9;
            color: #333;
        }
        .container {
            padding: 10px;
            background: #fff;
            border-radius: 8px;
            box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
        }
        .heading {
            font-weight: bold;
            font-size: 16px;
            margin-bottom: 10px;
            color: #ea431f
        }
        ul {
            padding-left: 20px;
        }
    
        .footer {
            margin-top: 10px;
            font-size: 14px;
            color: #555;
        }
    </style>
</head>
<body>
    <div class="container">
       
            <p><span class="heading">Double Delight:</span> Buy 2 products and enjoy Rs. 120 OFF your purchase.</p>
          
           <p><span class="heading">Triple Treat:</span> Buy 3 products and receive Rs. 200 OFF your total.</p>
   
    </div>
</body>
</html>"""),
            ),
//             Card(
//               color: Colors.grey[200],
//               child: Html(data: """<!DOCTYPE html>
// <html lang="en">
// <head>
//     <meta charset="UTF-8">
//     <meta name="viewport" content="width=device-width, initial-scale=1.0">
//     <title>Discount Offers</title>
//     <style>
//         body {
//             font-family: Arial, sans-serif;
//             line-height: 1.2;
//             background-color: #f9f9f9;
//             color: #333;
//         }
//         .container {
//             padding: 10px;
//             background: #fff;
//             border-radius: 8px;
//             box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
//         }
//         .heading {
//             font-weight: bold;
//             font-size: 16px;
//             margin-bottom: 10px;
//             color: #ea431f
//         }
//         ul {
//             padding-left: 20px;
//         }
//
//         .footer {
//             margin-top: 10px;
//             font-size: 14px;
//             color: #555;
//         }
//     </style>
// </head>
// <body>
//     <div class="container">
//
//             <p><span class="heading">Triple Treat:</span> Buy 3 products and receive Rs. 200 OFF your total.</p>
//
//     </div>
// </body>
// </html>"""),
//             ),
            Html(data: """<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Discount Offers</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            line-height: 1.2;
            background-color: #f9f9f9;
            color: #333;
        }
        .container {
            padding: 10px;
            background: #fff;
            border-radius: 8px;
            box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
        }
        .heading {
            font-weight: bold;
            font-size: 16px;
            margin-bottom: 10px;
            color: #ea431f
        }
        ul {
            padding-left: 20px;
        }
    
        .footer {
            margin-top: 10px;
            font-size: 14px;
            color: #555;
        }
    </style>
</head>
<body>
    <div class="container">
       
            <p class="footer"><span class="heading"> Note:</span> 
            All discounts are automatically applied at checkout. Elevate your style and make the most of these fantastic deals with Mink & Bear's all collections!
        </p>

    </div>
</body>
</html>"""),
          ],
        ));
  }
}
