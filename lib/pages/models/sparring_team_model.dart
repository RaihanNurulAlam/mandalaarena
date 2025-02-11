class SparringTeam {
  late final String id;
  final String name;
  final String imageUrl;
  final List<String> availableDays;
  final List<String> availableHours;
  final String contact;
  final String category; // Tambahkan properti category

  SparringTeam({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.availableDays,
    required this.availableHours,
    required this.contact,
    required this.category, // Tambahkan parameter category
  });

  // Convert SparringTeam to a Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'imageUrl': imageUrl,
      'availableDays': availableDays,
      'availableHours': availableHours,
      'contact': contact,
      'category': category, // Tambahkan category ke dalam map
    };
  }

  // Create SparringTeam from a Map
  factory SparringTeam.fromMap(Map<String, dynamic> map) {
    return SparringTeam(
      id: map['id'],
      name: map['name'],
      imageUrl: map['imageUrl'],
      availableDays: List<String>.from(map['availableDays']),
      availableHours: List<String>.from(map['availableHours']),
      contact: map['contact'],
      category: map['category'], // Ambil category dari map
    );
  }
}
