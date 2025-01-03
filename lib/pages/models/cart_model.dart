class CartModel {
  String? id; // ID dari Firebase
  String? name;
  String? price;
  String? imagePath;
  String? quantity;
  String? bookingDate; // Tanggal booking dari Firebase
  String? time; // Waktu booking dari Firebase
  int? duration; // Durasi booking dari Firebase

  CartModel({
    this.id,
    this.name,
    this.price,
    this.imagePath,
    this.quantity,
    this.bookingDate,
    this.time,
    this.duration,
  });

  // Konversi dari JSON Firebase ke CartModel
  CartModel.fromJson(Map<String, dynamic> json, {String? documentId}) {
    id = documentId; // Set ID dari dokumen Firebase
    name = json['name'];
    price = json['price'];
    imagePath = json['image_path'];
    quantity = json['quantity'];
    bookingDate = json['date']; // Ambil `date` dari Firebase
    time = json['time']; // Ambil `time` dari Firebase
    duration = json['duration']; // Ambil `duration` dari Firebase
  }

  // Konversi dari CartModel ke JSON Firebase
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['name'] = name;
    data['price'] = price;
    data['image_path'] = imagePath;
    data['quantity'] = quantity;
    data['date'] = bookingDate; // Tambahkan ke JSON
    data['time'] = time; // Tambahkan ke JSON
    data['duration'] = duration; // Tambahkan ke JSON
    return data;
  }
}