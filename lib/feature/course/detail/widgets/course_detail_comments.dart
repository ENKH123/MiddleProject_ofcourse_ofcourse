import 'package:flutter/material.dart';
import 'package:of_course/feature/course/models/course_detail_models.dart';
import 'package:of_course/feature/report/models/report_models.dart';
import 'package:of_course/feature/report/screens/report_screen.dart';

class CourseDetailComments extends StatelessWidget {
  final List<Comment> comments;
  final Function(String) onDeleteComment;
  final Function(String, String) onReportComment;

  const CourseDetailComments({
    super.key,
    required this.comments,
    required this.onDeleteComment,
    required this.onReportComment,
  });

  @override
  Widget build(BuildContext context) {
    if (comments.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text('댓글이 없습니다.', textAlign: TextAlign.center),
      );
    }

    return Column(
      children: comments.map((c) => _CommentItem(
            comment: c,
            onDelete: () => onDeleteComment(c.commentId),
            onReport: () => onReportComment(c.commentId, c.commentAuthor),
          )).toList(),
    );
  }
}

class _CommentItem extends StatelessWidget {
  final Comment comment;
  final VoidCallback onDelete;
  final VoidCallback onReport;

  const _CommentItem({
    required this.comment,
    required this.onDelete,
    required this.onReport,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 8,
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundImage: comment.commentAvatar.isNotEmpty
                ? NetworkImage(comment.commentAvatar)
                : null,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      comment.commentAuthor,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      comment.getRelativeTime(),
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(comment.commentBody),
              ],
            ),
          ),
          if (comment.isCommentAuthor)
            TextButton(
              onPressed: onDelete,
              child: const Text(
                '삭제',
                style: TextStyle(color: Colors.red, fontSize: 12),
              ),
            )
          else
            TextButton(
              onPressed: onReport,
              child: const Text('신고', style: TextStyle(fontSize: 12)),
            ),
        ],
      ),
    );
  }
}

class CourseDetailCommentInput extends StatefulWidget {
  final Function(String) onSubmit;
  final int maxLength;

  const CourseDetailCommentInput({
    super.key,
    required this.onSubmit,
    this.maxLength = 100,
  });

  @override
  State<CourseDetailCommentInput> createState() =>
      _CourseDetailCommentInputState();
}

class _CourseDetailCommentInputState
    extends State<CourseDetailCommentInput> {
  final TextEditingController _controller = TextEditingController();
  bool _isEmpty = true;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    setState(() {
      _isEmpty = _controller.text.trim().isEmpty;
    });
  }

  void _submit() {
    final text = _controller.text.trim();
    if (text.isEmpty || text.length > widget.maxLength) return;

    widget.onSubmit(text);
    _controller.clear();
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey[300]!,
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 40,
                child: TextField(
                  controller: _controller,
                  maxLength: widget.maxLength,
                  maxLines: 1,
                  decoration: InputDecoration(
                    hintText: '댓글 작성',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    counterText: '',
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    isDense: true,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              height: 40,
              child: ElevatedButton(
                onPressed: !_isEmpty ? _submit : null,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  minimumSize: const Size(0, 40),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('댓글', style: TextStyle(fontSize: 12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

