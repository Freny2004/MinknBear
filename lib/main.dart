import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:shopify_flutter/product/product_selected_variant_model.dart';
import 'package:shopify_flutter/wishlist/wishlist.dart';
import 'homepage.dart';
import 'cart/cart_model.dart';
import 'customer/customer_model.dart';

const seedColor = Color(0xffFAF9F6);
const primaryColor = Color(0xffFAF9F6);
const shadowColor = Colors.black;

void main() async {
  WidgetsFlutterBinding
      .ensureInitialized();
  await dotenv.load(); // This is important!

  final wishlistProvider = WishlistProvider();
  await wishlistProvider.loadWishlist();
  await initHiveForFlutter();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CartModel()),
        ChangeNotifierProvider(create: (_) => CustomerModel()),
       ChangeNotifierProvider(create: (_) => WishlistProvider()),
        ChangeNotifierProvider(create: (_) => SelectedVariantModel()),

      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GraphQLProvider(
      client: ValueNotifier<GraphQLClient>(
        GraphQLClient(
          link: HttpLink(
            "${dotenv.env['PERMANENT_DOMAIN']}/api/${dotenv.env['API_VERSION']}/graphql.json",
            defaultHeaders: {
              'X-Shopify-Storefront-Access-Token': dotenv.env['API_KEY']!,
            },
          ),
          cache: GraphQLCache(store: HiveStore()),
        ),
      ),
      child: MaterialApp(
        title: dotenv.env['STORE_NAME']!,
        theme: ThemeData(
          // colorScheme: ColorScheme.light(
          //   primary: primaryColor,
          //   surface: seedColor,
          // ),
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.white),
          primaryColor: primaryColor,
          shadowColor: primaryColor.withOpacity(.25),
          appBarTheme: AppBarTheme.of(context).copyWith(
            backgroundColor: primaryColor,
            foregroundColor: Colors.black,
            elevation: 5,
            shadowColor: shadowColor.withOpacity(.5),
          ),
          cardTheme: CardTheme.of(context).copyWith(
            surfaceTintColor: Colors.transparent,
            shadowColor: shadowColor.withOpacity(.5),
          ),
          expansionTileTheme: ExpansionTileTheme.of(context).copyWith(
            backgroundColor: primaryColor.withOpacity(.05),
            collapsedBackgroundColor: Colors.transparent,
          ),
        ),
        debugShowCheckedModeBanner: false,
        home: const MyHomePage(),
      ),
    );
  }
}
