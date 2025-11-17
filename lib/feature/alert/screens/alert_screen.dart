import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:of_course/core/extensions/extension.dart';
import 'package:of_course/feature/alert/viewmodels/alert_viewmodel.dart';
import 'package:provider/provider.dart';

class AlertScreen extends StatelessWidget {
  const AlertScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AlertViewModel(),
      child: _AlertScreen(),
    );
  }
}

class _AlertScreen extends StatelessWidget {
  const _AlertScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        title: AppBar(
          scrolledUnderElevation: 0,
          title: const Text("알림"),
          centerTitle: true,
        ),
      ),
      body: SafeArea(
        child: Consumer<AlertViewModel>(
          builder: (context, viewmodel, child) {
            if (viewmodel.alerts != null) {
              return Padding(
                padding: const EdgeInsets.all(28.0),
                child: Column(
                  spacing: 20,
                  children: [
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: () async {
                          await Future<void>.delayed(
                            const Duration(seconds: 1),
                          );
                          await viewmodel.fetchAlerts();
                        },
                        edgeOffset: 20,
                        displacement: 20,
                        strokeWidth: 4,
                        color: Color(0xFF003366),
                        child: ListView.separated(
                          itemCount: viewmodel.alerts?.length ?? 0,
                          itemBuilder: (context, index) {
                            return viewmodel.alerts!.isEmpty
                                ? _emptyScreen(viewmodel)
                                : AlertBox(
                                    fromUser: viewmodel
                                        .alerts![index]
                                        .fromUserNickname,
                                    type: viewmodel.alerts![index].type,
                                    userId: viewmodel.alerts![index].to_user_id,
                                    courseId: viewmodel.alerts![index].course_id
                                        .toString(),
                                    viewModel: viewmodel,
                                    alertId: viewmodel.alerts![index].id,
                                    relativeTime: viewmodel
                                        .alerts![index]
                                        .created_at
                                        .getRelativeTime(),
                                  );
                          },
                          separatorBuilder: (BuildContext context, int index) {
                            return const SizedBox(height: 20.0);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              );
            } else {
              return Container();
            }
          },
        ),
      ),
    );
  }
}

Widget _emptyScreen(AlertViewModel viewModel) {
  return Center(child: const Text("새로운 알림이 없습니다."));
}

void _showAlertErrorPopup(BuildContext context) {
  showDialog(
    context: context,
    // 다이얼로그 외부를 탭해도 닫히지 않게 설정 (배경 클릭 방지)
    barrierDismissible: false,

    builder: (BuildContext context) {
      return Dialog(
        backgroundColor: Colors.transparent, // Dialog 배경을 투명하게 (선택 사항)
        child: Center(
          child: Container(
            width: 240,
            height: 160,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                spacing: 12,
                children: [
                  Text(
                    "코스를 찾을 수 없습니다.",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  SizedBox(
                    width: double.maxFinite,
                    child: ElevatedButton(
                      onPressed: () {
                        print("닫기 버튼 눌림");
                        Navigator.of(context).pop(); // 팝업 닫기
                      },
                      child: Text("닫기", style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}

class AlertAppBar extends StatelessWidget {
  const AlertAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              onPressed: () {
                context.push('/home'); // ✅ 홈으로 이동
              },
              icon: const Icon(Icons.arrow_back_ios_new),
            ),
          ),
        ),
        const Expanded(
          child: Center(
            child: Text("알림", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
        const Expanded(child: SizedBox()),
      ],
    );
  }
}

class AlertBox extends StatelessWidget {
  final String fromUser;
  final String type;
  final String courseId;
  final String userId;
  final String relativeTime;
  final int alertId;
  final AlertViewModel viewModel;
  const AlertBox({
    super.key,
    required this.fromUser,
    required this.type,
    required this.courseId,
    required this.userId,
    required this.relativeTime,
    required this.alertId,
    required this.viewModel,
  });

  @override
  Widget build(BuildContext context) {
    // 리플 효과 없는 버튼
    // 알림창 전체 영역이 버튼
    return GestureDetector(
      onTap: () async {
        // print('AlertBox가 클릭되었습니다!');
        // _showAlertErrorPopup(context);
        await context.push(
          '/detail',
          extra: {'courseId': courseId, 'userId': userId},
        );
        await viewModel.deleteAlert(alertId);
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: double.maxFinite,
          // height: 100,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              // spacing: 8,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 알림 메세지
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      relativeTime,
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
                Text.rich(
                  TextSpan(
                    children: <TextSpan>[
                      TextSpan(
                        text: fromUser,
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(text: " 님이 내 코스에 "),
                      TextSpan(
                        text: type,
                        style: TextStyle(
                          color: type == "좋아요" ? Colors.red : Colors.blue,
                        ),
                      ),
                      TextSpan(text: " 을(를) 남겼습니다."),
                    ],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                // 보러 가기 메세지
                Text(
                  'Go to View',
                  style: TextStyle(
                    // fontSize: 18,
                    color: Colors.blue,
                    decoration:
                        TextDecoration.underline, // 클릭 가능하다는 시각적 힌트 추가 (선택 사항)
                    decorationColor: Colors.blue,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
