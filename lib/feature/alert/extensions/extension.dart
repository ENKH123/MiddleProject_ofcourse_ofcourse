extension DateTimeToRelativeStringTime on DateTime {
  String getRelativeTime() {
    final now = DateTime.now();
    final difference = now.difference(this);

    if (difference.inMinutes < 1) {
      return '방금 전';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}분 전';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}시간 전';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}일 전';
    } else {
      return '${this.year}/${this.month.toString().padLeft(2, '0')}/${this.day.toString().padLeft(2, '0')}';
    }
  }
}
