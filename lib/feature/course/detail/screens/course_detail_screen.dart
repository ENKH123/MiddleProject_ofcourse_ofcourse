import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:of_course/feature/course/detail/viewmodels/course_detail_viewmodel.dart';
import 'package:of_course/feature/course/detail/widgets/course_detail_comments.dart';
import 'package:of_course/feature/course/detail/widgets/course_detail_header.dart';
import 'package:of_course/feature/course/detail/widgets/course_detail_map.dart';
import 'package:of_course/feature/course/detail/widgets/course_detail_recommendation_reason.dart';
import 'package:of_course/feature/course/detail/widgets/course_detail_sets.dart';
import 'package:of_course/feature/report/models/report_models.dart';
import 'package:of_course/feature/report/screens/report_screen.dart';
import 'package:provider/provider.dart';

class CourseDetailScreen extends StatefulWidget {
  final int courseId;
  final String userId;
  final String? recommendationReason;

  const CourseDetailScreen({
    super.key,
    required this.courseId,
    required this.userId,
    this.recommendationReason,
  });

  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen> {
  late final CourseDetailViewModel _viewModel;
  final ScrollController _scrollController = ScrollController();
  final Map<String, GlobalKey> _setCardKeys = {};
  final GlobalKey _mapSectionKey = GlobalKey();
  final CourseDetailMapController _mapController = CourseDetailMapController();

  static const double _spacingMedium = 16.0;
  static const double _spacingLarge = 24.0;

  @override
  void initState() {
    super.initState();
    _viewModel = CourseDetailViewModel(
      courseId: widget.courseId,
      userId: widget.userId,
      recommendationReason: widget.recommendationReason,
    );
    _viewModel.loadCourseDetail();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  void _handleBackNavigation() {
    Navigator.pop(context, true);
  }

  Future<void> _handleToggleLike() async {
    // context를 async 전에 사용해서 messenger를 만들어둠
    final messenger = ScaffoldMessenger.of(context);

    try {
      await _viewModel.toggleLike();
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            e.toString().contains('로그인')
                ? '로그인이 필요합니다.'
                : '좋아요 처리 중 오류가 발생했습니다: $e',
          ),
        ),
      );
    }
  }

  Future<void> _handleSubmitComment(String commentText) async {
    // 마찬가지로 messenger를 먼저 만들어둔다
    final messenger = ScaffoldMessenger.of(context);

    try {
      await _viewModel.submitComment(commentText);
      messenger.showSnackBar(
        const SnackBar(content: Text('댓글이 작성되었습니다.')),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            e.toString().contains('로그인')
                ? '로그인이 필요합니다.'
                : '댓글 작성 중 오류가 발생했습니다: ${e.toString()}',
          ),
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  void _handleDeleteComment(String commentId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('댓글 삭제'),
        content: const Text('댓글을 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _viewModel.deleteComment(commentId);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('댓글이 삭제되었습니다.')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content:
                      Text('댓글 삭제 중 오류가 발생했습니다: ${e.toString()}'),
                      duration: const Duration(seconds: 5),
                    ),
                  );
                }
              }
            },
            child: const Text('삭제', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _handleDeleteCourse() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('게시글 삭제'),
        content:
        const Text('정말 이 코스를 삭제하시겠습니까?\n연관된 댓글과 좋아요도 함께 삭제됩니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _viewModel.deleteCourse();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content:
                      Text('코스 및 관련 세트, 이미지, 댓글, 좋아요가 모두 삭제되었습니다.'),
                    ),
                  );
                  Navigator.pop(context, true);
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('코스 삭제 중 오류가 발생했습니다: $e'),
                      duration: const Duration(seconds: 5),
                    ),
                  );
                }
              }
            },
            child: const Text('삭제', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _handleEditCourse() async {
    final courseDetail = _viewModel.courseDetail;
    if (courseDetail == null) return;

    final result = await context.push(
      '/editcourse',
      extra: int.parse(courseDetail.courseId),
    );

    if (result == true) {
      await _viewModel.loadCourseDetail();
      if (!mounted) return;
      setState(() {});
    }
  }

  void _navigateToReport(
      String targetId,
      ReportTargetType targetType, {
        String? commentAuthor,
      }) {
    final courseDetail = _viewModel.courseDetail;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReportScreen(
          targetId: targetId,
          reportTargetType: targetType,
          reportingUser: targetType == ReportTargetType.course
              ? courseDetail?.authorName ?? ''
              : commentAuthor ?? '',
        ),
      ),
    );
  }

  void _showImageFullScreen(String imageUrl) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(backgroundColor: Colors.black),
          body: Center(
            child: InteractiveViewer(
              child: Image.network(imageUrl, fit: BoxFit.contain),
            ),
          ),
        ),
      ),
    );
  }

  void _scrollToSetCard(String setId) {
    final key = _setCardKeys[setId];
    if (key?.currentContext != null) {
      Scrollable.ensureVisible(
        key!.currentContext!,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
        alignment: 0.1,
      );
    }
  }

  void _moveToMarker(String setId) {
    if (_mapSectionKey.currentContext != null) {
      Scrollable.ensureVisible(
        _mapSectionKey.currentContext!,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
        alignment: 0.0,
      );
    }

    _mapController.moveToMarker(setId);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ChangeNotifierProvider.value(
      value: _viewModel,
      child: Consumer<CourseDetailViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.isLoading) {
            return Scaffold(
              backgroundColor: cs.surface,
              appBar: _buildAppBar(),
              body: const Center(child: CircularProgressIndicator()),
            );
          }

          if (viewModel.errorMessage != null) {
            return Scaffold(
              backgroundColor: cs.surface,
              appBar: _buildAppBar(),
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      viewModel.errorMessage!,
                      style: const TextStyle(color: Colors.red),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => viewModel.loadCourseDetail(),
                      child: const Text('다시 시도'),
                    ),
                  ],
                ),
              ),
            );
          }

          final courseDetail = viewModel.courseDetail;
          if (courseDetail == null) {
            return Scaffold(
              backgroundColor: cs.surface,
              appBar: _buildAppBar(),
              body: const Center(child: Text('코스 정보를 불러올 수 없습니다.')),
            );
          }

          // 세트 카드 키 초기화
          if (_setCardKeys.length != courseDetail.sets.length) {
            _setCardKeys.clear();
            for (final set in courseDetail.sets) {
              _setCardKeys[set.setId] = GlobalKey();
            }
          }

          return PopScope(
            canPop: false,
            onPopInvokedWithResult: (didPop, result) {
              if (!didPop) {
                _handleBackNavigation();
              }
            },
            child: Scaffold(
              backgroundColor: cs.surface,
              appBar: _buildAppBar(),
              body: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      child: Column(
                        children: [
                          CourseDetailHeader(
                            courseDetail: courseDetail,
                            onEdit: _handleEditCourse,
                            onDelete: _handleDeleteCourse,
                            onReport: courseDetail.isAuthor
                                ? null
                                : () => _navigateToReport(
                              courseDetail.courseId,
                              ReportTargetType.course,
                            ),
                          ),
                          if (widget.recommendationReason != null) ...[
                            CourseDetailRecommendationReason(
                              reason: widget.recommendationReason!,
                            ),
                            const SizedBox(height: 24),
                          ],
                          CourseDetailMap(
                            key: ValueKey(courseDetail.courseId),
                            courseDetail: courseDetail,
                            setCardKeys: _setCardKeys,
                            mapSectionKey: _mapSectionKey,
                            onMarkerTap: _scrollToSetCard,
                            controller: _mapController,
                          ),
                          const SizedBox(height: _spacingLarge),
                          CourseDetailSets(
                            sets: courseDetail.sets,
                            setCardKeys: _setCardKeys,
                            onImageTap: _showImageFullScreen,
                            onAddressTap: _moveToMarker,
                          ),
                          const SizedBox(height: _spacingLarge),
                          _buildEngagementSection(viewModel),
                          const SizedBox(height: _spacingMedium),
                          CourseDetailComments(
                            comments: viewModel.comments,
                            onDeleteComment: _handleDeleteComment,
                            onReportComment: (commentId, commentAuthor) {
                              _navigateToReport(
                                commentId,
                                ReportTargetType.comment,
                                commentAuthor: commentAuthor,
                              );
                            },
                          ),
                          const SizedBox(height: _spacingLarge),
                        ],
                      ),
                    ),
                  ),
                  CourseDetailCommentInput(onSubmit: _handleSubmitComment),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: _handleBackNavigation,
      ),
      title: const Text(
        '코스 세부정보',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildEngagementSection(CourseDetailViewModel viewModel) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: _spacingMedium),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              viewModel.isLiked ? Icons.favorite : Icons.favorite_border,
              color: viewModel.isLiked ? Colors.red : Colors.grey,
            ),
            onPressed: _handleToggleLike,
          ),
          Text('${viewModel.likeCount}'),
          const SizedBox(width: _spacingLarge),
          const Icon(Icons.comment),
          const SizedBox(width: 8),
          Text('${viewModel.comments.length}'),
        ],
      ),
    );
  }
}