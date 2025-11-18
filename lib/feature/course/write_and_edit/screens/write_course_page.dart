import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:of_course/feature/course/write_and_edit/viewmodels/write_course_view_model.dart';
import 'package:of_course/feature/course/write_and_edit/widgets/write_course/write_map.dart';
import 'package:of_course/feature/course/write_and_edit/widgets/write_course/write_sets.dart';
import 'package:of_course/feature/course/write_and_edit/widgets/write_course/write_sets_action.dart';
import 'package:of_course/feature/course/write_and_edit/widgets/write_course/write_title.dart';
import 'package:of_course/feature/course/write_and_edit/widgets/write_course/write_top_button.dart';
import 'package:of_course/feature/course/write_and_edit/widgets/write_course/write_upload_button.dart';
import 'package:provider/provider.dart';

class WriteCoursePage extends StatelessWidget {
  final int? continueCourseId;

  const WriteCoursePage({super.key, this.continueCourseId});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => WriteCourseViewModel()..init(continueCourseId),
      child: const _WriteCoursePageView(),
    );
  }
}

class _WriteCoursePageView extends StatefulWidget {
  const _WriteCoursePageView();

  @override
  State<_WriteCoursePageView> createState() => _WriteCoursePageViewState();
}

class _WriteCoursePageViewState extends State<_WriteCoursePageView> {
  final ScrollController _scrollController = ScrollController();

  Future<bool> _confirmExit() async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: true,
          builder: (_) => AlertDialog(
            title: const Text("코스 작성을 취소하시겠습니까?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("취소"),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text("확인"),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<WriteCourseViewModel>();

    if (vm.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return WillPopScope(
      onWillPop: () async {
        final ok = await _confirmExit();
        if (ok) context.pushReplacement('/home');
        return false;
      },
      child: Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: const [
                WriteTopButtons(),
                SizedBox(height: 16),
                WriteTitleField(),
                SizedBox(height: 16),
                WriteMapView(),
                SizedBox(height: 16),
                WriteSetsList(),
                SizedBox(height: 16),
                WriteSetActions(),
                SizedBox(height: 24),
                WriteUploadButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
