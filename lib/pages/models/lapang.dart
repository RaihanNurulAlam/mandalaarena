class Lapang {
  String? name;
  String? description;
  String? price;
  String? imagePath;
  String? rating;

  Lapang({
    this.name,
    this.description,
    this.price,
    this.imagePath,
    this.rating,
  });

  Lapang.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    description = json['description'];
    price = json['price'];
    imagePath = json['image_path'];
    rating = json['rating'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['name'] = name;
    data['description'] = description;
    data['price'] = price;
    data['image_path'] = imagePath;
    data['rating'] = rating;
    return data;
  }
}
