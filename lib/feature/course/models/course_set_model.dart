import 'dart:io';

class CourseSetData {
  String? query; // 주소/매장명
  double? lat;
  double? lng;
  int? tagId;
  int? gu;
  List<String> existingImages = [];
  List<File> images = [];
  String? description;

  CourseSetData({this.query, this.lat, this.lng, this.tagId, this.description});

  Map<String, dynamic> toJson() => {
    'query': query,
    'lat': lat,
    'lng': lng,
    'tag': tagId,
    'description': description,
  };
}
