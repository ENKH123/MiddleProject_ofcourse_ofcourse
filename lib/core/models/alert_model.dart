class AlertModel {
  final int id;
  final String from_user_id;
  final String to_user_id;
  final String type;
  final int course_id;
  final DateTime created_at;

  AlertModel({
    required this.id,
    required this.from_user_id,
    required this.to_user_id,
    required this.type,
    required this.course_id,
    required this.created_at,
  });

  factory AlertModel.fromJson(Map<String, dynamic> json) {
    return AlertModel(
      id: json["id"] as int,
      from_user_id: json["from_user_id"] as String,
      to_user_id: json["to_user_id"] as String,
      type: json["type"] as String,
      course_id: json["course_id"] as int,
      created_at: DateTime.parse(json['created_at'] as String),
    );
  }
}
