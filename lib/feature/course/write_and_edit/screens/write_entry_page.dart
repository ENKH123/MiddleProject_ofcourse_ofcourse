import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:of_course/core/data/core_data_source.dart';
import 'package:of_course/feature/course/data/course_data_source.dart';

class WriteEntryPage extends StatefulWidget {
  final String? from;

  const WriteEntryPage({super.key, this.from});

  @override
  State<WriteEntryPage> createState() => _WriteEntryPageState();
}

class _WriteEntryPageState extends State<WriteEntryPage> {
  late final String _prevRoute;
  bool _checked = false;

  @override
  void initState() {
    super.initState();
    _prevRoute = widget.from ?? '/home';
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_checked) {
      _checked = true;
      _checkDraft();
    }
  }

  void _navigateTo(String route, {Object? extra}) {
    if (!mounted) return;
    context.go(route, extra: extra);
  }

  void _navigateBack() => _navigateTo(_prevRoute);

  void _navigateToNew() => _navigateTo('/write/new');

  void _navigateToContinue(int id) => _navigateTo('/write/continue', extra: id);

  Future<void> _checkDraft() async {
    try {
      final userId = await CoreDataSource.instance.getMyUserRowId();
      if (!mounted) return;

      if (userId == null) return _navigateBack();

      final drafts = await CourseDataSource.instance.getDraftCourses(userId);
      if (!mounted) return;

      if (drafts.isEmpty) return _navigateToNew();

      final selected = await _showDraftDialog(drafts);

      if (selected == null) return _navigateBack();
      if (selected == -1) return _navigateToNew();

      return _navigateToContinue(selected);
    } catch (e) {
      debugPrint("❌ Draft check error: $e");
      if (mounted) _navigateBack();
    }
  }

  Future<int?> _showDraftDialog(List<dynamic> drafts) {
    return showDialog<int>(
      context: context,
      barrierDismissible: true,
      useRootNavigator: false,
      builder: (ctx) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: 300,
              padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.edit_note, size: 42, color: Colors.orange),
                  const SizedBox(height: 12),
                  const Text(
                    "임시 저장된 코스가 있어요",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 16),

                  SizedBox(
                    height: 180,
                    child: SingleChildScrollView(
                      child: Column(
                        children: drafts.map((d) {
                          return GestureDetector(
                            onTap: () => Navigator.pop(ctx, d['id']),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: 12,
                                horizontal: 10,
                              ),
                              margin: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8F8F8),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.description_outlined,
                                    color: Colors.orange,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          d['title'] ?? '제목 없음',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          "ID: ${d['id']}",
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  Column(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(ctx, -1),
                        child: Container(
                          height: 44,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.orange,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: const Text(
                            "새 코스 만들기",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      GestureDetector(
                        onTap: () => Navigator.pop(ctx, null),
                        child: Container(
                          height: 40,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF2F2F2),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Text("취소"),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        _navigateBack();
        return false;
      },
      child: const Scaffold(body: Center(child: CircularProgressIndicator())),
    );
  }
}
