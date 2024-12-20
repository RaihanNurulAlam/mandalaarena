import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mandalaarenaapp/pages/payment_page.dart';
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
    double totalPrice = 0;
    return Consumer<Cart>(
      builder: (context, value, child) {
        for (var cartModel in value.cart) {
          double price = int.parse(cartModel.quantity.toString()) *
              int.parse(cartModel.price.toString()).toDouble();
          totalPrice += price;
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Cart'),
            actions: [
              Visibility(
                visible: value.cart.isNotEmpty ? true : false,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: IconButton(
                    onPressed: () {
                      value.clearCart();
                      setState(() {
                        totalPrice = 0;
                      });
                    },
                    icon: Row(
                      children: const [
                        Text('Clear cart'),
                      ],
                    ),
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
                      const Text(
                        'Cart is empty',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      CupertinoButton(
                        color: Colors.black,
                        child: const Text(
                          'Tambah Booking Lapang',
                          style: TextStyle(
                            color: Colors.white,
                          ),
                        ),
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
                          title: Text(
                            lapang.name.toString(),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          subtitle: Row(
                            children: [
                              Text('IDR ${lapang.price} x ${lapang.quantity} Jam'),
                            ],
                          ),
                          trailing: IconButton(
                            onPressed: () {
                              setState(() {
                                value.deleteItemCart(lapang);
                                totalPrice = 0;
                                for (var cartModel in value.cart) {
                                  totalPrice += int.parse(cartModel.quantity.toString()) *
                                      int.parse(cartModel.price.toString()).toDouble();
                                }
                              });
                            },
                            icon: const Icon(CupertinoIcons.trash_circle),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 80),
                    CupertinoButton(
                      child: const Text(
                        'Tambah Booking Lapang',
                        style: TextStyle(
                          color: Colors.black,
                        ),
                      ),
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
          bottomNavigationBar: totalPrice == 0
              ? null
              : Container(
                  color: Colors.black,
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
                        padding: const EdgeInsets.all(16),
                        margin: const EdgeInsets.all(16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total Price',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 20,
                              ),
                            ),
                            Text(
                              'IDR $totalPrice',
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        width: MediaQuery.of(context).size.width,
                        child: CupertinoButton(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(50),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Text(
                                'Pay Now',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Urbanist',
                                ),
                              ),
                              SizedBox(width: 10),
                              Icon(CupertinoIcons.arrow_right, color: Colors.white),
                            ],
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PaymentPage(
                                  totalPrice: totalPrice,
                                ),
                              ),
                            );
                          },
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