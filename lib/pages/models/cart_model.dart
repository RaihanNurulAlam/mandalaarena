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
  bool? useIceBath; // --- [MODIFIKASI] Tambahkan field useIceBath
  int? totalPrice;
  String? teamName;

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
    this.useIceBath, // --- [MODIFIKASI] Tambahkan di constructor
    this.totalPrice,
    this.teamName,
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
    useIceBath = json['useIceBath']; // --- [MODIFIKASI] Ambil dari JSON
    totalPrice = json['totalPrice'];
    teamName = json['teamName'];
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
      'useIceBath': useIceBath, // --- [MODIFIKASI] Sertakan dalam JSON
      'totalPrice': totalPrice,
      'teamName': teamName,
    };
  }
}
