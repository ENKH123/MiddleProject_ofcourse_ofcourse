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
      builder: (ctx) => AlertDialog(
        title: const Text("임시 저장된 코스가 있어요"),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("이어 작성할 코스를 선택하세요.\n"),
              ...drafts.map((d) {
                return ListTile(
                  title: Text(d['title'] ?? '제목 없음'),
                  subtitle: Text("ID: ${d['id']}"),
                  onTap: () => Navigator.pop(ctx, d['id']),
                );
              }),
              const Divider(),
              TextButton(
                onPressed: () => Navigator.pop(ctx, -1),
                child: const Text("새 코스 만들기"),
              ),
            ],
          ),
        ),
      ),
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
