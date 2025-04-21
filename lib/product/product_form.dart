import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';

import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../cart/cart.dart';
import '../cart/cart_model.dart';
import 'product_selected_variant_model.dart';
import 'product_buy_it_now.dart';

class ProductForm extends StatefulWidget {
  final Map product;

  const ProductForm({super.key, required this.product});

  @override
  State<ProductForm> createState() => _ProductFormState();
}

class _ProductFormState extends State<ProductForm> {
  int _qty = 1;
  bool _loading = false;

  Map get _selectedVariant =>
      context.read<SelectedVariantModel>().selectedVariant ??
      widget.product['variants']['edges'][0]['node'];

  double? get _compareAtPrice {
    if (_selectedVariant['compareAtPrice'] == null) {
      return null;
    }

    return double.parse(_selectedVariant['compareAtPrice']['amount']);
  }

  double get _price {
    return double.parse(_selectedVariant['price']['amount']);
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (_compareAtPrice != null)
            Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Text('\₹$_compareAtPrice',
                    style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black,
                        decoration: TextDecoration.lineThrough))),
          Text('\₹$_price',
              style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w500,
                  color: Colors.black)),
          Container(
            margin: const EdgeInsets.only(left: 8),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '${(((_compareAtPrice! - _price) / _compareAtPrice!) * 100).round()}% OFF',
              style: TextStyle(
                fontSize: 12,
                color: Colors.green.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

        ],
      ),
      const SizedBox(height: 12),
      for (MapEntry optionEntry in widget.product['options'].asMap().entries)
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Size:",
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            Wrap(
              spacing: 6,
              runSpacing: 0,
              children: [
                for (String optionValue in optionEntry.value['values'])
                  OutlinedButton(
                      onPressed: () {
                        List<String> selectedOptions =
                            List.from(_selectedVariant['selectedOptions'])
                                .map<String>((element) => element['value'])
                                .toList();

                        selectedOptions[optionEntry.key] = optionValue;

                        Map? newVariant;

                        for (Map edge in widget.product['variants']['edges']) {
                          List<String> optionsFound =
                              List.from(edge['node']['selectedOptions'])
                                  .map<String>((element) => element['value'])
                                  .toList();

                          if (listEquals(selectedOptions, optionsFound)) {
                            newVariant = edge['node'];
                          }
                        }

                        if (newVariant == null) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text(
                                  'Sorry! The variant with options ${selectedOptions.toString()} is not available')));
                          return;
                        }

                        context
                            .read<SelectedVariantModel>()
                            .setSelectedVariant(newVariant);
                      },
                      style: ButtonStyle(
                          side: WidgetStateProperty.all(BorderSide(
                            color: optionValue ==
                                    _selectedVariant['selectedOptions']
                                        [optionEntry.key]['value']
                                ? Colors.black.withOpacity(1)
                                : Colors.black.withOpacity(.2),
                          )),
                          overlayColor:
                              WidgetStateProperty.resolveWith<Color>(
                                  (states) {
                            if (states.contains(MaterialState.pressed)) {
                              return Colors.black.withOpacity(.1);
                            }
                            return Colors.transparent;
                          }),
                          foregroundColor:
                              WidgetStateProperty.all(Colors.black),
                          backgroundColor: optionValue ==
                                  _selectedVariant['selectedOptions']
                                      [optionEntry.key]['value']
                              ? WidgetStateProperty.all(Colors.black
                                 )
                              : WidgetStateProperty.all(Colors.white)),
                      child: Text(optionValue,
                          style: TextStyle(fontSize: 13,color: optionValue ==
                              _selectedVariant['selectedOptions']
                              [optionEntry.key]['value']
                              ? Colors.white
                              : Colors.black,),)),
              ],
            ),
            const SizedBox(height: 10),
          ],
        ),
      const SizedBox(height: 8),
      Row(
        children: [
          Container(
            decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.black),
                borderRadius: BorderRadius.circular(24)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 38,
                  height: 38,
                  child: RawMaterialButton(
                    onPressed: () {
                      if (_qty > 1) {
                        setState(() {
                          _qty -= 1;
                        });
                      }
                    },
                    shape: const CircleBorder(),
                    child: const Icon(
                      Icons.remove,
                      size: 16,
                      color: Colors.black,
                    ),
                  ),
                ),
                SizedBox(
                  width: 32,
                  child: TextField(
                    controller: TextEditingController(text: _qty.toString()),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: 'QTY',
                      isDense: true,
                      contentPadding: EdgeInsets.fromLTRB(0, 4, 0, 4),
                    ),
                    style: const TextStyle(fontSize: 14, color: Colors.black),
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    onChanged: (value) {
                      if (value.isNotEmpty && int.parse(value) > 1) {
                        setState(() {
                          _qty = int.parse(value);
                        });
                      }
                    },
                  ),
                ),
                SizedBox(
                  width: 38,
                  height: 38,
                  child: RawMaterialButton(
                    onPressed: () {
                      setState(() {
                        _qty += 1;
                      });
                    },
                    shape: const CircleBorder(),
                    child: const Icon(
                      Icons.add,
                      size: 16,
                      color: Colors.black,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
              child: OutlinedButton(
            onPressed: _selectedVariant['availableForSale']
                ? () async {
                    setState(() {
                      _loading = true;
                    });

                    await context.read<CartModel>().cartLinesAdd(context, [
                      {
                        'merchandiseId': _selectedVariant['id'],
                        'quantity': _qty
                      }
                    ]);

                    setState(() {
                      _loading = false;
                    });

                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(
                            '${widget.product['title']} was successfully added to your cart!'),
                        action: SnackBarAction(
                          label: 'View cart',
                          onPressed: () async {
                            await Future.delayed(
                                const Duration(milliseconds: 200));
                            if (context.mounted) {
                              Navigator.of(context).push(MaterialPageRoute(
                                  builder: (context) => const CartPage()));
                            }
                          },
                        ),
                      ));
                    }
                  }
                : null,
            style: ButtonStyle(
              backgroundColor:
                  WidgetStateProperty.all(Theme.of(context).primaryColor),
              foregroundColor: WidgetStateProperty.all(Colors.black),
              overlayColor:
                  WidgetStateProperty.all(Colors.black.withOpacity(.25)),
							side: WidgetStateProperty.all(const BorderSide(color: Colors.black))
            ),
            child: _loading
                ? const SizedBox(
                    height: 19,
                    width: 19,
                    child: CircularProgressIndicator(
                      color: Colors.black,
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    _selectedVariant['availableForSale']
                        ? 'Add to cart'
                        : 'Sold out',
                    style: const TextStyle(fontSize: 15),
                  ),
          ))
        ],
      ),
      const SizedBox(height: 4),
      SizedBox(
        width: double.infinity,
        child: OutlinedButton(

          onPressed: _selectedVariant['availableForSale']
              ? () async {
                  await Future.delayed(const Duration(milliseconds: 200));
                  if (context.mounted) {
                    final id = _selectedVariant['id'].split('Variant/')[1];
                    Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) => ProductBuyItNow(
                            checkoutUrl:
                                '${dotenv.env['PRIMARY_DOMAIN']}/cart/$id:$_qty')));
                  }
                }
              : null,
          style: ButtonStyle(
              backgroundColor: WidgetStateProperty.all(Colors.black),
              foregroundColor: WidgetStateProperty.all(Colors.black),
              overlayColor:
                  WidgetStateProperty.all(Colors.black.withOpacity(.25)),
              side: WidgetStateProperty.all(BorderSide(
                  color: _selectedVariant['availableForSale']
                      ? Colors.black
                      : Colors.black.withOpacity(.2)))),
          child: const Text('Buy it now',
              style: TextStyle(fontSize: 15, color: Colors.white)),
        ),
      )
    ]);
  }
}
