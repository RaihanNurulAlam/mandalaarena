class TransactionDetails {
  final String orderId;
  final double grossAmount;

  TransactionDetails({
    required this.orderId,
    required this.grossAmount,
  });
}

class CustomerDetails {
  final String firstName;
  final String lastName;
  final String email;
  final String phone;

  CustomerDetails({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
  });
}

class ItemDetails {
  final String id;
  final double price;
  final int quantity;
  final String name;

  ItemDetails({
    required this.id,
    required this.price,
    required this.quantity,
    required this.name,
  });
}
