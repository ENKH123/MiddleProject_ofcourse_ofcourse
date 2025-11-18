import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:of_course/core/managers/supabase_manager.dart';

import '../models/report_models.dart';

class ReportViewModel extends ChangeNotifier {
  static const int defaultMaxImages = 3;
  static const int defaultMaxDetailsLength = 1000;

  final String targetId;
  final ReportTargetType reportTargetType;
  final ImagePicker _picker;

  final int maxImages;
  final int maxDetailsLength;

  ReportReason? _selectedReason;
  String _details = '';
  final List<XFile> _reportImages = [];
  bool _isSubmitting = false;

  ReportViewModel({
    required this.targetId,
    required this.reportTargetType,
    ImagePicker? picker,
    this.maxImages = defaultMaxImages,
    this.maxDetailsLength = defaultMaxDetailsLength,
  }) : _picker = picker ?? ImagePicker();

  ReportReason? get selectedReason => _selectedReason;
  String get details => _details;
  List<XFile> get reportImages => List.unmodifiable(_reportImages);
  bool get isSubmitting => _isSubmitting;

  bool get isFormValid {
    return _selectedReason != null &&
        _details.length <= maxDetailsLength &&
        _reportImages.length <= maxImages;
  }

  void setReason(ReportReason? reason) {
    _selectedReason = reason;
    notifyListeners();
  }

  void setDetails(String value) {
    if (value.length > maxDetailsLength) return;
    _details = value;
    notifyListeners();
  }

  void addImage(XFile image) {
    if (_reportImages.length >= maxImages) return;
    _reportImages.add(image);
    notifyListeners();
  }

  void removeImageAt(int index) {
    if (index < 0 || index >= _reportImages.length) return;
    _reportImages.removeAt(index);
    notifyListeners();
  }

  Future<void> pickImageFromGallery() async {
    if (_reportImages.length >= maxImages) return;

    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      _reportImages.add(image);
      notifyListeners();
    }
  }

  Future<void> submitReport() async {
    if (!isFormValid || _isSubmitting) return;
    if (_selectedReason == null) {
      throw Exception('신고 사유를 선택해주세요.');
    }

    _isSubmitting = true;
    notifyListeners();

    try {
      await SupabaseManager.shared.submitReport(
        targetId: targetId,
        targetType: reportTargetType,
        reportReason: _selectedReason!,
        reason: _details,
        imagePaths: _reportImages.map((file) => file.path).toList(),
      );
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }
}