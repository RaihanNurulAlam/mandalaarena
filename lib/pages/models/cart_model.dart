class CartModel {
  String? userId; // User ID dari Firebase
  String? docId; // Document ID dari Firebase
  String? id; // ID dari lapangan
  String? name;
  String? price;
  String? imagePath;
  String? quantity;
  String? bookingDate; // Tanggal booking
  String? time; // Waktu booking
  int? duration; // Durasi booking
  String? namaPengguna; // Nama pengguna
  String? noWhatsapp; // Nomor WhatsApp
  bool? usePhotographer; // Apakah menggunakan photographer
  bool? useReferee; // Apakah menggunakan wasit
  int? totalPrice; // Total harga termasuk biaya tambahan

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
    };
  }
}
