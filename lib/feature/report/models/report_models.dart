enum ReportTargetType {
  course,
  comment,
}

enum ReportReason {
  harassment('괴롭힘'),
  inappropriateContent('부적절한 내용'),
  spam('스팸'),
  copyright('저작권 침해'),
  other('기타');

  const ReportReason(this.label);
  final String label;
}

class ReportData {
  final ReportTargetType reportTargetType;
  final String targetId;
  final String reportTitle;
  final ReportReason? reportReason;
  final String reportDetails;
  final List<String> reportImages;

  ReportData({
    required this.reportTargetType,
    required this.targetId,
    required this.reportTitle,
    this.reportReason,
    this.reportDetails = '',
    this.reportImages = const [],
  });

  bool get isValid {
    return reportTitle.isNotEmpty &&
        reportTitle.length <= 30 &&
        reportReason != null &&
        reportDetails.length <= 1000 &&
        reportImages.length <= 3;
  }
}



