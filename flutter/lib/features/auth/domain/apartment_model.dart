class ApartmentModel {
  final String id;
  final String name;

  const ApartmentModel({
    required this.id,
    required this.name,
  });

  factory ApartmentModel.fromMap(String id, Map<String, dynamic> map) {
    return ApartmentModel(
      id: id,
      name: map['name'] as String? ?? '',
    );
  }
}
