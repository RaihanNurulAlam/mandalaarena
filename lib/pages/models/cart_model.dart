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
  bool? useIceBath;
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
    this.useIceBath,
    this.totalPrice,
    this.teamName,
  });

  // Konversi dari Map Firestore ke CartModel
  // Nama diubah menjadi fromMap untuk konsistensi
  factory CartModel.fromMap(Map<String, dynamic> map, {String? documentId}) {
    return CartModel(
      docId: documentId,
      userId: map['userId'],
      id: map['lapangId'], // Menggunakan 'lapangId' sesuai kode Anda
      name: map['name'],
      price: map['price'],
      imagePath: map['imagePath'],
      quantity: map['quantity'],
      bookingDate: map['bookingDate'],
      time: map['time'],
      duration: map['duration'],
      namaPengguna: map['namaPengguna'],
      noWhatsapp: map['noWhatsapp'],
      usePhotographer: map['usePhotographer'],
      useReferee: map['useReferee'],
      useIceBath: map['useIceBath'],
      totalPrice: map['totalPrice'],
      teamName: map['teamName'],
    );
  }

  // Konversi dari CartModel ke Map untuk Firestore
  // Nama diubah menjadi toMap untuk memperbaiki error
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'lapangId': id, // Menggunakan 'lapangId' sesuai kode Anda
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
      'useIceBath': useIceBath,
      'totalPrice': totalPrice,
      'teamName': teamName,
    };
  }
}
