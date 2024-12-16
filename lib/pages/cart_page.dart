import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mandalaarenaapp/pages/home_page.dart';
import 'package:mandalaarenaapp/provider/cart.dart';
import 'package:provider/provider.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  @override
  Widget build(BuildContext context) {
    double price = 0;
    double totalPrice = 0;
    double taxAndService = 0;
    double totalPayment = 0;

    return Consumer<Cart>(
      builder: (context, value, child) {
        for (var cartModel in value.cart) {
          price = int.parse(cartModel.quantity.toString()) *
              int.parse(cartModel.price.toString()).toDouble();
          totalPrice += price;

          taxAndService = (totalPrice * 0.11).toDouble();
          totalPayment = (totalPrice + taxAndService).toDouble();
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Cart'),
            actions: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: IconButton(
                  onPressed: () {
                    value.clearCart();
                    setState(() {
                      price = 0;
                      totalPrice = 0;
                      taxAndService = 0;
                      totalPayment = 0;
                    });
                  },
                  icon: Row(
                    children: const [
                      Text('Clear cart'),
                    ],
                  ),
                ),
              ),
            ],
          ),
          body: value.cart.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Cart is empty',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 10),
                      CupertinoButton(
                        color: Theme.of(context).primaryColor,
                        child: Text('Tambah Booking Lapang'),
                        onPressed: () {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                                builder: (context) => HomePage()),
                            (route) => false,
                          );
                        },
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    ListView.builder(
                      shrinkWrap: true,
                      itemCount: value.cart.length,
                      itemBuilder: (context, index) {
                        final lapang = value.cart[index];
                        return ListTile(
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: SizedBox(
                              height: 50,
                              width: 50,
                              child: Image.asset(
                                lapang.imagePath.toString(),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          title: Text(lapang.name.toString()),
                          subtitle: Row(
                            children: [
                              Text('IDR ${lapang.price} x ${lapang.quantity}'),
                            ],
                          ),
                          trailing: IconButton(
                            onPressed: () {
                              value.deleteItemCart(lapang);
                              if (value.cart.isEmpty) {
                                price = 0;
                                totalPrice = 0;
                                taxAndService = 0;
                                totalPayment = 0;
                                setState(() {});
                              } else {
                                context.read<Cart>();
                              }
                            },
                            icon: Icon(CupertinoIcons.trash_circle),
                          ),
                        );
                      },
                    ),
                    SizedBox(height: 80),
                    CupertinoButton(
                      child: Text('Tambah Booking Lapang'),
                      onPressed: () {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (context) => HomePage()),
                          (route) => false,
                        );
                      },
                    ),
                  ],
                ),
          bottomNavigationBar: price == 0
              ? null
              : Container(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.black,
                            width: 1,
                          ),
                        ),
                        padding: EdgeInsets.all(16),
                        margin: EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Price'),
                                Text('IDR $totalPrice'),
                              ],
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Tax and Service'),
                                Text('IDR $taxAndService'),
                              ],
                            ),
                            Divider(),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Total Price'),
                                Text('IDR $totalPayment'),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Container(
                        margin: EdgeInsets.fromLTRB(16, 0, 16, 16),
                        width: MediaQuery.of(context).size.width,
                        child: CupertinoButton(
                          color: Theme.of(context).primaryColor,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Text('Pay Now'),
                              SizedBox(width: 10),
                              Icon(CupertinoIcons.arrow_right),
                            ],
                          ),
                          onPressed: () {},
                        ),
                      ),
                    ],
                  ),
                ),
        );
      },
    );
  }
}
