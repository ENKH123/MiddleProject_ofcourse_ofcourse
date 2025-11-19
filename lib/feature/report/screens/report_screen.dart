import 'dart:io';

import 'package:flutter/material.dart';
import 'package:of_course/core/components/custom_app_bar.dart';
import 'package:provider/provider.dart';

import '../models/report_models.dart';
import '../viewmodels/report_view_model.dart';

class ReportScreen extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ReportViewModel(
        targetId: targetId,
        reportTargetType: reportTargetType,
      ),
      child: _ReportScreenBody(reportingUser: reportingUser),
    );
  }
}

class _ReportScreenBody extends StatefulWidget {
  final String reportingUser;

  const _ReportScreenBody({
    required this.reportingUser,
  });

  @override
  State<_ReportScreenBody> createState() => _ReportScreenBodyState();
}

class _ReportScreenBodyState extends State<_ReportScreenBody> {
  late final TextEditingController _detailsController;

  @override
  void initState() {
    super.initState();
    final vm = context.read<ReportViewModel>();
    _detailsController = TextEditingController(text: vm.details);

    _detailsController.addListener(() {
      vm.setDetails(_detailsController.text);
    });
  }

  @override
  void dispose() {
    _detailsController.dispose();
    super.dispose();
  }

  Future<void> _submitReport() async {
    final vm = context.read<ReportViewModel>();

    try {
      await vm.submitReport();
      _showCompletionDialog();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('신고 제출 중 오류가 발생했습니다: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showCancelDialog() {
    showDialog(
      context: context,
      builder: (context) => _buildCancelDialog(context),
    );
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _buildCompletionDialog(context),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ReportViewModel>();
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: CustomAppBar(
        title: '신고하기',
        showBackButton: true,
        onBackPressed: _showCancelDialog,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildLabel('신고 사용자'),
            const SizedBox(height: 8),
            TextFormField(
              initialValue: widget.reportingUser,
              readOnly: true,
              decoration: InputDecoration(
                filled: true,
                fillColor: cs.surfaceContainerHighest,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 24),

            _buildLabel('신고 사유'),
            const SizedBox(height: 8),
            DropdownButtonFormField<ReportReason>(
              initialValue: vm.selectedReason,
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
              onChanged: vm.setReason,
            ),
            const SizedBox(height: 24),

            _buildLabel('상세 내용 (최대 ${vm.maxDetailsLength}자)'),
            const SizedBox(height: 8),
            _buildDetailsField(vm),
            const SizedBox(height: 24),

            _buildLabel('이미지 (최대 ${vm.maxImages}개)'),
            const SizedBox(height: 8),
            _buildImageSection(vm),
            const SizedBox(height: 32),

            _buildSubmitButton(vm),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String label) {
    return Text(
      label,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
    );
  }

  Widget _buildDetailsField(ReportViewModel vm) {
    return Stack(
      children: [
        TextFormField(
          controller: _detailsController,
          maxLines: 5,
          maxLength: vm.maxDetailsLength,
          buildCounter: (
              context, {
                required int currentLength,
                required bool isFocused,
                int? maxLength,
              }) {
            return null;
          },
          decoration: const InputDecoration(
            hintText: '신고 사유를 작성해주세요',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(8)),
            ),
            contentPadding: EdgeInsets.only(
              left: 12,
              right: 12,
              top: 12,
              bottom: 32,
            ),
          ),
        ),
        Positioned(
          bottom: 8,
          right: 12,
          child: Text(
            '${_detailsController.text.length}/${vm.maxDetailsLength}',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ),
      ],
    );
  }

  Widget _buildImageSection(ReportViewModel vm) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ...vm.reportImages.asMap().entries.map((entry) {
          final index = entry.key;
          final file = entry.value;

          return Stack(
            children: [
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
                    File(file.path),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(Icons.image, size: 50);
                    },
                  ),
                ),
              ),
              Positioned(
                top: 4,
                right: 4,
                child: GestureDetector(
                  onTap: () => vm.removeImageAt(index),
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
        if (vm.reportImages.length < vm.maxImages)
          GestureDetector(
            onTap: () async {
              try {
                await vm.pickImageFromGallery();
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('이미지를 선택하는 중 오류가 발생했습니다: $e')),
                );
              }
            },
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
              child: const Icon(Icons.add, size: 48, color: Colors.black87),
            ),
          ),
      ],
    );
  }

  Widget _buildSubmitButton(ReportViewModel vm) {
    return ElevatedButton(
      onPressed: (vm.isFormValid && !vm.isSubmitting) ? _submitReport : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: vm.isSubmitting
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
    );
  }

  Widget _buildCancelDialog(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            const Text(
              '신고하기를 취소 하시겠습니까?',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // dialog 닫기
                  Navigator.pop(context); // 화면 닫기
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
                onPressed: () => Navigator.pop(context),
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

  Widget _buildCompletionDialog(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            const Text(
              '신고가 완료되었습니다!',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
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
          ],
        ),
      ),
    );
  }
}