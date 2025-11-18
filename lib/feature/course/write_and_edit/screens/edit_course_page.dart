import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:of_course/feature/course/write_and_edit/widgets/edit_course/comfim_exit_dialog.dart';
import 'package:of_course/feature/course/write_and_edit/widgets/edit_course/edit_map.dart';
import 'package:of_course/feature/course/write_and_edit/widgets/edit_course/edit_set_actions.dart';
import 'package:of_course/feature/course/write_and_edit/widgets/edit_course/edit_sets.dart';
import 'package:of_course/feature/course/write_and_edit/widgets/edit_course/edit_title.dart';
import 'package:provider/provider.dart';

import '../viewmodels/edit_course_view_model.dart';

class EditCoursePage extends StatelessWidget {
  final int courseId;
  const EditCoursePage({super.key, required this.courseId});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => EditCourseViewModel()..init(courseId),
      child: const _EditCoursePageView(),
    );
  }
}

class _EditCoursePageView extends StatefulWidget {
  const _EditCoursePageView();

  @override
  State<_EditCoursePageView> createState() => _EditCoursePageViewState();
}

class _EditCoursePageViewState extends State<_EditCoursePageView> {
  final ScrollController _scrollController = ScrollController();

  Future<bool> _confirmExit() async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: true,
          builder: (_) => const ConfirmExitDialog(),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<EditCourseViewModel>();

    if (vm.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return WillPopScope(
      onWillPop: () async {
        final ok = await _confirmExit();
        if (ok) context.pop(false);
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text("코스 수정"),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              final ok = await _confirmExit();
              if (ok) context.pop(false);
            },
          ),
          actions: [
            TextButton(
              onPressed: () async {
                final ok = await vm.saveEdit();

                if (ok && mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text("코스 수정 완료")));
                  context.pop(true);
                }
              },
              child: const Text("수정완료", style: TextStyle(color: Colors.orange)),
            ),
          ],
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: const [
                EditTitleField(),
                SizedBox(height: 16),
                EditMapView(),
                SizedBox(height: 16),
                EditSetsList(),
                SizedBox(height: 16),
                EditSetActions(),
                SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
