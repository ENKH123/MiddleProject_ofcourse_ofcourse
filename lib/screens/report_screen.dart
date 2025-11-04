import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../models/report_models.dart';
///ID: FO_03_03_01

/// 신고 화면 위젯
/// 사용자가 신고를 작성하고 제출할 수 있는 화면입니다.
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
  /// 사유, 상세 내용, 이미지 개수가 모두 유효한지 확인합니다.
  bool get _isFormValid {
    return _selectedReason != null &&
        _detailsController.text.length <= 1000 &&
        _reportImages.length <= 3;
  }

  /// 이미지 업로드 처리 - 바로 갤러리 열기
  Future<void> _handleImageUpload() async {
    if (_reportImages.length >= 3) {
      return;
    }

    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
      );

      if (image != null) {
        setState(() {
          _reportImages.add(image);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('이미지를 선택하는 중 오류가 발생했습니다: $e')),
      );
    }
  }

  /// 신고 제출 처리
  /// 입력된 신고 데이터를 수집하고 처리합니다.
  void _submitReport() {
    if (!_isFormValid) return;

    // 신고 데이터 객체 생성
    final reportData = ReportData(
      reportTargetType: widget.reportTargetType,
      targetId: widget.targetId,
      reportTitle: '${widget.targetId}를 신고합니다',
      reportReason: _selectedReason,
      reportDetails: _detailsController.text,
      reportImages: _reportImages.map((file) => file.path).toList(),
    );

    // TODO: 실제 API 호출로 변경 필요
    // 로컬에서만 처리 (API 호출 없음)
    print('신고 데이터 준비 완료:');
    print('제목: ${reportData.reportTitle}');
    print('사유: ${reportData.reportReason?.label}');
    print('상세: ${reportData.reportDetails}');
    print('이미지 개수: ${reportData.reportImages.length}');

    // 성공 시 완료 팝업 표시
    _showCompletionDialog();
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
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
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
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
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
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
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
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
      appBar: AppBar(
        backgroundColor: const Color(0xFFFAFAFA),
        elevation: 0,
        // 뒤로가기 버튼
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => _showCancelDialog(),
        ),
        // 타이틀 제거
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
                  buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null,
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
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
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
              onPressed: _isFormValid ? _submitReport : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                '신고하기',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
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
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
