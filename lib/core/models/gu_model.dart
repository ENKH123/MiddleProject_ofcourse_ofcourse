class GuModel {
  final int id;
  final String name;

  GuModel({required this.id, required this.name});

  factory GuModel.fromJson(Map<String, dynamic> json) {
    return GuModel(id: json['id'] as int, name: json['gu_name'] as String);
  }
}
