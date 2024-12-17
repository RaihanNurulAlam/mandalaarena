import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mandalaarenaapp/pages/checkout_page.dart';
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

          taxAndService = double.parse((totalPrice * 0.11).toStringAsFixed(2));
          totalPayment =
              double.parse((totalPrice + taxAndService).toStringAsFixed(2));
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
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          subtitle: Row(
                            children: [
                              Text('IDR ${lapang.price} x ${lapang.quantity}'),
                            ],
                          ),
                          trailing: IconButton(
                            onPressed: () {
                              setState(() {
                                // Hapus item dari keranjang
                                value.deleteItemCart(lapang);

                                //Hitung ulang total harga
                                totalPrice = 0;
                                for (var cartModel in value.cart) {
                                  double itemPrice =
                                      int.parse(cartModel.quantity.toString()) *
                                          int.parse(cartModel.price.toString())
                                              .toDouble();
                                  totalPrice += itemPrice;
                                }

                                // Hitung ulang pajak dan total pembayaran
                                taxAndService = double.parse(
                                    (totalPrice * 0.11).toStringAsFixed(2));
                                totalPayment = double.parse(
                                    (totalPrice + taxAndService)
                                        .toStringAsFixed(2));
                              });

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
                      child: Text(
                        'Tambah Booking Lapang',
                        style: TextStyle(
                          color: Colors.redAccent,
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
                                Text(
                                  'Price',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 20,
                                  ),
                                ),
                                Text(
                                  'IDR $totalPrice',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Tax and Service',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 20,
                                  ),
                                ),
                                Text(
                                  'IDR $taxAndService',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            Divider(),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Total Price',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 20,
                                  ),
                                ),
                                Text(
                                  'IDR $totalPayment',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Container(
                        margin: EdgeInsets.fromLTRB(16, 0, 16, 16),
                        width: MediaQuery.of(context).size.width,
                        child: CupertinoButton(
                          color: Colors.redAccent,
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
                              Icon(CupertinoIcons.arrow_right),
                            ],
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CheckoutPage(
                                  totalPayment: totalPayment.toString(),
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
