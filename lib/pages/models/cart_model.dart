class CartModel {
  String? userId;
  String? docId;
  String? id;
  String? name;
  String? price;
  String? imagePath;
  String? quantity;
  String? bookingDate;
  String? time;
  int? duration;
  String? namaPengguna;
  String? noWhatsapp;
  bool? usePhotographer;
  bool? useReferee;
  int? totalPrice;
  String? teamName; // Tambahkan field teamName

  CartModel({
    this.userId,
    this.docId,
    this.id,
    this.name,
    this.price,
    this.imagePath,
    this.quantity,
    this.bookingDate,
    this.time,
    this.duration,
    this.namaPengguna,
    this.noWhatsapp,
    this.usePhotographer,
    this.useReferee,
    this.totalPrice,
    this.teamName, // Tambahkan field teamName
  });

  // Konversi dari JSON Firebase ke CartModel
  CartModel.fromJson(Map<String, dynamic> json, {String? documentId}) {
    docId = documentId;
    userId = json['userId'];
    id = json['lapangId'];
    name = json['name'];
    price = json['price'];
    imagePath = json['imagePath'];
    quantity = json['quantity'];
    bookingDate = json['bookingDate'];
    time = json['time'];
    duration = json['duration'];
    namaPengguna = json['namaPengguna'];
    noWhatsapp = json['noWhatsapp'];
    usePhotographer = json['usePhotographer'];
    useReferee = json['useReferee'];
    totalPrice = json['totalPrice'];
    teamName = json['teamName']; // Ambil teamName dari JSON
  }

  // Konversi dari CartModel ke JSON Firebase
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'lapangId': id,
      'name': name,
      'price': price,
      'imagePath': imagePath,
      'quantity': quantity,
      'bookingDate': bookingDate,
      'time': time,
      'duration': duration,
      'namaPengguna': namaPengguna,
      'noWhatsapp': noWhatsapp,
      'usePhotographer': usePhotographer,
      'useReferee': useReferee,
      'totalPrice': totalPrice,
      'teamName': teamName, // Sertakan teamName dalam JSON
    };
  }
}
