import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:of_course/core/managers/supabase_manager.dart';
import 'package:of_course/feature/course/utils/recommendation_parser.dart';

class RecommendOnboardingScreen extends StatefulWidget {
  const RecommendOnboardingScreen({super.key});

  @override
  State<RecommendOnboardingScreen> createState() => _RecommendOnboardingScreenState();
}

class _RecommendOnboardingScreenState extends State<RecommendOnboardingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeIn,
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
    );

    _animationController.forward();
    _loadRecommendation();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadRecommendation() async {
    int? courseId;
    String? recommendationReason;
    String? userId;

    try {
      userId = await SupabaseManager.shared.getMyUserRowId();

      if (userId != null) {
        try {
          final response = await SupabaseManager.shared.supabase.functions.invoke(
            'smart-task',
            body: {
              'user_id': userId,
            },
          );

          debugPrint('맞춤형 추천 응답: $response');
          dynamic rawData = response.data;
          Map<String, dynamic>? responseData;

          if (rawData != null) {
            if (rawData is Map<String, dynamic>) {
              responseData = rawData;
            } else if (rawData is Map) {
              responseData = Map<String, dynamic>.from(rawData);
            } else if (rawData is String) {
              try {
                responseData = Map<String, dynamic>.from(
                  jsonDecode(rawData) as Map,
                );
              } catch (e) {
                debugPrint('JSON 파싱 오류: $e');
              }
            }

            if (responseData != null) {
              final parsedData =
              RecommendationParser.parseFirstRecommendation(responseData);
              debugPrint('맞춤형 추천 로딩 완료: $parsedData');

              if (parsedData != null) {
                courseId = parsedData['courseId'] as int?;
                recommendationReason = parsedData['reason'] as String?;
              }
            }
          }
        } catch (e) {
          debugPrint('맞춤형 추천 로딩 오류 (무시): $e');
        }
      }

      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        if (courseId != null && userId != null) {
          context.pushReplacement(
            '/detail',
            extra: {
              'courseId': courseId,
              'userId': userId,
              'recommendationReason': recommendationReason,
            },
          );
        } else {
          context.go('/recommend');
        }
      }
    } catch (e) {
      debugPrint('온보딩 오류: $e');
      if (mounted) {
        context.go('/recommend');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor =
    isDark ? const Color(0xFF002245) : const Color(0xFFFAFAFA);
    final textColor =
    isDark ? const Color(0xFFFAFAFA) : const Color(0xFF030303);
    final primaryColor =
    isDark ? const Color(0xFFC5D5E4) : const Color(0xFF003366);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/appLogo.png',
                    width: 200,
                    height: 200,
                  ),
                  const SizedBox(height: 48),

                  SizedBox(
                    width: 40,
                    height: 40,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                    ),
                  ),
                  const SizedBox(height: 32),

                  Text(
                    '맞춤형 추천을 준비하고 있어요',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '잠시만 기다려주세요',
                    style: TextStyle(
                      fontSize: 14,
                      color: textColor.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}