import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:of_course/core/components/custom_app_bar.dart';
import 'package:of_course/core/managers/supabase_manager.dart';

import '../models/report_models.dart';

///ID: FO_03_03_01

/// 신고 화면 위젯
class ReportScreen extends StatefulWidget {
  final String targetId;
  final ReportTargetType reportTargetType;
  final String reportingUser;

  const ReportScreen({
    super.key,
    required this.targetId,
    required this.reportTargetType,
    this.reportingUser = '신고 대상',
  });

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  /// 신고 상세 내용 입력 컨트롤러
  late TextEditingController _detailsController;

  /// 선택된 신고 사유
  ReportReason? _selectedReason;

  /// 첨부된 신고 이미지 목록 (최대 3개)
  List<XFile> _reportImages = [];

  /// 이미지 피커 인스턴스
  final ImagePicker _picker = ImagePicker();

  /// 신고 제출 중 로딩 상태
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _detailsController = TextEditingController();
  }

  @override
  void dispose() {
    // 컨트롤러 메모리 해제
    _detailsController.dispose();
    super.dispose();
  }

  /// 폼 유효성 검사
  bool get _isFormValid {
    return _selectedReason != null &&
        _detailsController.text.length <= 1000 &&
        _reportImages.length <= 3;
  }

  Future<void> _handleImageUpload() async {
    if (_reportImages.length >= 3) {
      return;
    }

    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

      if (image != null) {
        setState(() {
          _reportImages.add(image);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('이미지를 선택하는 중 오류가 발생했습니다: $e')));
    }
  }

  /// 신고 제출 처리
  Future<void> _submitReport() async {
    if (!_isFormValid || _isSubmitting) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      if (_selectedReason == null) {
        throw Exception('신고 사유를 선택해주세요.');
      }

      // Supabase에 신고 제출
      await SupabaseManager.shared.submitReport(
        targetId: widget.targetId,
        targetType: widget.reportTargetType,
        reportReason: _selectedReason!,
        reason: _detailsController.text,
        imagePaths: _reportImages.map((file) => file.path).toList(),
      );

      // 성공 시 완료 팝업 표시
      if (mounted) {
        _showCompletionDialog();
      }
    } catch (e) {
      // 에러 발생 시 스낵바 표시
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('신고 제출 중 오류가 발생했습니다: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  /// 취소 확인 다이얼로그 표시
  void _showCancelDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return _buildCancelDialog();
      },
    );
  }

  /// 완료 확인 다이얼로그 표시
  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return _buildCompletionDialog();
      },
    );
  }

  /// 취소 확인 다이얼로그 위젯
  Widget _buildCancelDialog() {
    return Dialog(
      backgroundColor: const Color(0xFFFAFAFA),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            const Text(
              '신고하기를 취소 하시겠습니까?',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            // OK 버튼 (빨간색)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // 다이얼로그 닫기
                  Navigator.pop(context);
                  // 신고 화면 닫기
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'OK',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // 다이얼로그만 닫기
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF5F5F5),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Cancel',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 완료 확인 다이얼로그 위젯
  Widget _buildCompletionDialog() {
    return Dialog(
      backgroundColor: const Color(0xFFFAFAFA),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            const Text(
              '신고가 완료되었습니다!',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // 다이얼로그 닫기
                  Navigator.pop(context); // 신고 화면 닫기
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'OK',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: CustomAppBar(
        title: '신고하기',
        showBackButton: true,
        onBackPressed: () => _showCancelDialog(),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 신고 사용자 입력 필드
            _buildLabel('신고 사용자'),
            const SizedBox(height: 8),
            TextFormField(
              initialValue: widget.reportingUser,
              readOnly: true,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.grey[200],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 신고 사유 선택 드롭다운
            _buildLabel('신고 사유'),
            const SizedBox(height: 8),
            DropdownButtonFormField<ReportReason>(
              value: _selectedReason,
              decoration: InputDecoration(
                hintText: '신고 사유를 선택하세요',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              items: ReportReason.values.map((reason) {
                return DropdownMenuItem(
                  value: reason,
                  child: Text(reason.label),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedReason = value;
                });
              },
            ),
            const SizedBox(height: 24),

            // 신고 상세 내용 입력 필드
            _buildLabel('상세 내용 (최대 1000자)'),
            const SizedBox(height: 8),
            Stack(
              children: [
                TextFormField(
                  controller: _detailsController,
                  maxLines: 5,
                  maxLength: 1000,
                  buildCounter:
                      (
                      context, {
                    required currentLength,
                    required isFocused,
                    maxLength,
                  }) => null,
                  decoration: InputDecoration(
                    hintText: '신고 사유를 작성해주세요',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.only(
                      left: 12,
                      right: 12,
                      top: 12,
                      bottom: 32,
                    ),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                Positioned(
                  bottom: 8,
                  right: 12,
                  child: Text(
                    '${_detailsController.text.length}/1000',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // 이미지 업로드 섹션
            _buildLabel('이미지 (최대 3개)'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                // 기존에 업로드된 이미지들 표시
                ..._reportImages.asMap().entries.map((entry) {
                  return Stack(
                    children: [
                      // 이미지 컨테이너
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[400]!),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            File(entry.value.path),
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(Icons.image, size: 50);
                            },
                          ),
                        ),
                      ),
                      // 이미지 삭제 버튼
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _reportImages.removeAt(entry.key);
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                }),
                // 이미지 추가 버튼 (최대 3개까지)
                if (_reportImages.length < 3)
                  GestureDetector(
                    onTap: _handleImageUpload,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.grey[400]!,
                          style: BorderStyle.solid,
                        ),
                      ),
                      child: const Icon(
                        Icons.add,
                        size: 48,
                        color: Colors.black87,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 32),

            // 신고 제출 버튼
            ElevatedButton(
              onPressed: (_isFormValid && !_isSubmitting) ? _submitReport : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
                  : const Text(
                '신고하기',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 라벨 텍스트 위젯 생성
  Widget _buildLabel(String label) {
    return Text(
      label,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
    );
  }
}
