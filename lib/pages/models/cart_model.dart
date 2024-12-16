class CartModel {
  String? name;
  String? price;
  String? imagePath;
  String? quantity;

  CartModel({
    this.name,
    this.price,
    this.imagePath,
    this.quantity,
  });

  CartModel.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    price = json['price'];
    imagePath = json['image_path'];
    quantity = json['quantity'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['name'] = name;
    data['price'] = price;
    data['image_path'] = imagePath;
    data['quantity'] = quantity;
    return data;
  }
}
