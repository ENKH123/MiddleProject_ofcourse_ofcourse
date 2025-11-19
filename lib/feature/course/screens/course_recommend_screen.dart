import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:of_course/core/data/core_data_source.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../utils/recommendation_parser.dart';

class CourseRecommendScreen extends StatefulWidget {
  const CourseRecommendScreen({super.key});

  @override
  State<CourseRecommendScreen> createState() => _CourseRecommendScreenState();
}

class _CourseRecommendScreenState extends State<CourseRecommendScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic>? _recommendationData;
  int? _recommendedCourseId;
  String? _recommendationReason;

  static const Color _backgroundColor = Color(0xFFFAFAFA);
  static const Color _mainColor = Color(0xFF003366);
  static const double _borderRadius = 8.0;
  static const double _spacingSmall = 8.0;
  static const double _spacingMedium = 16.0;
  static const double _spacingLarge = 32.0; // 간격 조금 더 크게

  @override
  void initState() {
    super.initState();
    _loadRecommendation();
  }

  Future<void> _loadRecommendation() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final userRowId = await CoreDataSource.instance.getMyUserRowId();
      if (userRowId == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = '로그인이 필요합니다.';
        });
        return;
      }

      final response = await Supabase.instance.client.functions.invoke(
        'smart-task',
        body: {'user_id': userRowId},
      );

      debugPrint('엣지 펑션 전체 응답: $response');
      debugPrint('응답 상태 코드: ${response.status}');
      debugPrint('응답 데이터 타입: ${response.data.runtimeType}');
      debugPrint('응답 데이터: ${response.data}');

      dynamic rawData = response.data;

      Map<String, dynamic>? responseData;
      if (rawData == null) {
        debugPrint('응답 데이터가 null입니다.');
        setState(() {
          _isLoading = false;
          _errorMessage = '추천 데이터를 받아올 수 없습니다. (응답이 null)';
        });
        return;
      } else if (rawData is Map<String, dynamic>) {
        responseData = rawData;
      } else if (rawData is Map) {
        responseData = Map<String, dynamic>.from(rawData);
      } else if (rawData is String) {
        try {
          responseData = Map<String, dynamic>.from(jsonDecode(rawData) as Map);
        } catch (e) {
          debugPrint('JSON 파싱 오류: $e');
          setState(() {
            _isLoading = false;
            _errorMessage = '응답 데이터 형식이 올바르지 않습니다.';
          });
          return;
        }
      } else {
        debugPrint('예상치 못한 응답 데이터 타입: ${rawData.runtimeType}');
        setState(() {
          _isLoading = false;
          _errorMessage = '응답 데이터 형식이 올바르지 않습니다.';
        });
        return;
      }

      debugPrint('파싱된 응답 데이터: $responseData');

      final parsedData = RecommendationParser.parseFirstRecommendation(
        responseData,
      );

      if (parsedData == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = '추천할 코스가 없습니다.';
        });
        return;
      }

      debugPrint('파싱된 추천 데이터: $parsedData');
      debugPrint('코스 ID: ${parsedData['courseId']}');

      setState(() {
        _recommendationData = parsedData;
        _recommendedCourseId = parsedData['courseId'] as int?;
        _recommendationReason = parsedData['reason'] as String?;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('추천 로드 오류: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = '추천을 불러오는 중 오류가 발생했습니다: $e';
      });
    }
  }

  void _navigateToDetail(int courseId) async {
    final userRowId = await CoreDataSource.instance.getMyUserRowId();
    if (context.mounted) {
      context.push(
        '/detail',
        extra: {
          'courseId': courseId,
          'userId': userRowId ?? '',
          'recommendationReason': _recommendationReason,
        },
      );
    }
  }

  void _goToHome() {
    if (context.mounted) {
      // 라우팅 히스토리를 완전히 교체하여 홈으로 이동
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (!didPop) {
          _goToHome();
        }
      },
      child: Scaffold(
        backgroundColor: _backgroundColor,
        appBar: AppBar(
          backgroundColor: _backgroundColor,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _goToHome,
          ),
          title: const Text(
            '코스 추천',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: _spacingMedium),
                    ElevatedButton(
                      onPressed: _loadRecommendation,
                      child: const Text('다시 시도'),
                    ),
                  ],
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(_spacingMedium),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(_spacingMedium),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(_borderRadius),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.lightbulb_outline,
                                color: _mainColor,
                                size: 24,
                              ),
                              const SizedBox(width: _spacingSmall),
                              const Text(
                                '코스 추천 사유',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: _spacingMedium),
                          if (_recommendationReason != null)
                            Text(
                              _recommendationReason!,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[700],
                                height: 1.5,
                              ),
                            )
                          else
                            const Text(
                              '추천 사유를 불러올 수 없습니다.',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: _spacingLarge), // 여기 간격 크게
                    if (_recommendedCourseId != null)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () =>
                              _navigateToDetail(_recommendedCourseId!),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _mainColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                _borderRadius,
                              ),
                            ),
                          ),
                          child: const Text(
                            '추천 코스 상세 보기',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      )
                    else
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(_spacingMedium),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(_borderRadius),
                        ),
                        child: const Text(
                          '추천할 코스가 없습니다.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                      ),
                  ],
                ),
              ),
      ),
    );
  }
}
