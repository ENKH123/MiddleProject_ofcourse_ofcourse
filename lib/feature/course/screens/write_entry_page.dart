import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:of_course/core/managers/supabase_manager.dart';

class WriteEntryPage extends StatefulWidget {
  final String? from; // 🔥 이전 화면 저장

  const WriteEntryPage({super.key, this.from});

  @override
  State<WriteEntryPage> createState() => _WriteEntryPageState();
}

class _WriteEntryPageState extends State<WriteEntryPage> {
  bool _checked = false;
  bool _isChecking = false;

  late String _prevRoute;

  @override
  void initState() {
    super.initState();
    // 🔥 이전 화면 경로 저장 → 없으면 홈
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

  Future<void> _checkDraft() async {
    if (_isChecking) return;
    _isChecking = true;

    final userId = await SupabaseManager.shared.getMyUserRowId();
    if (!mounted) return;

    if (userId == null) {
      context.go(_prevRoute);
      return;
    }

    final drafts = await SupabaseManager.shared.getDraftCourses(userId);
    if (!mounted) return;

    if (drafts.isEmpty) {
      context.go('/write/new');
      return;
    }

    final selected = await showDialog<int>(
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

                  // 📌 리스트 섹션
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

                  // 📌 하단 버튼 구역 (같은 영역)
                  Column(
                    children: [
                      // 새 코스 만들기
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

                      // 취소
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

    if (!mounted) return;

    if (selected == null) {
      context.go(_prevRoute);
      return;
    }

    if (selected == -1) {
      context.go('/write/new');
      return;
    }

    context.go('/write/continue', extra: selected);
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        context.go(_prevRoute); // 🔥 뒤로가기 → 이전 경로로 복귀
        return false;
      },
      child: const Scaffold(body: Center(child: CircularProgressIndicator())),
    );
  }
}
