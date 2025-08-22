import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';
import '../constants/categories.dart';
import 'calendar_screen.dart';
import 'settings_screen.dart';
import 'date_detail_screen.dart';
import 'record_screen.dart';
import 'voice_test_screen.dart';
import 'recurring_tasks_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with TickerProviderStateMixin {
  bool _showTodayImportantOnly = false; // 오늘 중요 일정만 보기 상태
  bool _showTomorrowImportantOnly = false; // 내일 중요 일정만 보기 상태
  late AnimationController _slideController;
  late AnimationController _fadeController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _slideController.forward();
    _fadeController.forward();

    // iOS에서 검은 화면 문제 해결을 위한 초기화
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await context.read<TaskProvider>().initialize();
        print('✅ iOS MainScreen TaskProvider 초기화 완료');
      } catch (e) {
        print('❌ iOS MainScreen TaskProvider 초기화 실패: $e');
      }
    });
  }

  @override
  void dispose() {
    _slideController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  // 시간 포맷 (오전/오후 형식)
  String _formatTime(DateTime date) {
    final hour = date.hour;
    final minute = date.minute;
    final period = hour < 12 ? '오전' : '오후';
    final displayHour = hour < 12 ? hour : (hour == 12 ? 12 : hour - 12);
    final displayMinute = minute.toString().padLeft(2, '0');
    return '$period${displayHour.toString().padLeft(2, '0')}:$displayMinute';
  }

  // 날짜 포맷 (월/일) - 수정된 형식
  String _formatDate(DateTime date) {
    return '${date.month}월 ${date.day}일';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFfafafa), // 밝은 배경
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFfafafa), // 밝은 회색
              Color(0xFFf5f5f5), // 더 밝은 회색
            ],
          ),
        ),
        child: SafeArea(
          child: SlideTransition(
            position: _slideAnimation,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Consumer<TaskProvider>(
                builder: (context, taskProvider, child) {
                  if (taskProvider.isLoading) {
                    return const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color(0xFF6366f1),
                        ),
                      ),
                    );
                  }

                  final todayTasks = taskProvider.getTodayTasks();
                  final tomorrowTasks = taskProvider.getTomorrowTasks();
                  final fontSize = taskProvider.fontSize;

                  return Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        // 하단 기존 버튼 영역을 재사용하므로 상단 액션 제거
                        // 메인 콘텐츠 영역 (헤더 없이 바로 시작)
                        Expanded(
                          child: Column(
                            children: [
                              // 오늘/내일 패널
                              Expanded(
                                flex: 3,
                                child: Column(
                                  children: [
                                    // 오늘 패널
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  DateDetailScreen(
                                                    date: DateTime.now(),
                                                    title: '오늘',
                                                  ),
                                            ),
                                          );
                                        },
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(
                                              24,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(
                                                  0.08,
                                                ),
                                                blurRadius: 20,
                                                offset: const Offset(0, 8),
                                              ),
                                            ],
                                          ),
                                          padding: const EdgeInsets.all(12),
                                          child: LayoutBuilder(
                                            builder: (context, constraints) {
                                              final scaleFactor =
                                                  0.75 + (fontSize * 0.5);
                                              final titleFontSize =
                                                  (20 + 5) * scaleFactor;
                                              final taskFontSize =
                                                  (14 + 5) * scaleFactor;

                                              final panelHeight =
                                                  constraints.maxHeight;
                                              final topPadding = 4.0; // 여백 더 줄임
                                              final bottomPadding =
                                                  4.0; // 여백 더 줄임
                                              final headerHeight =
                                                  titleFontSize + 12;
                                              final buttonHeight = 40.0;
                                              final spaceBetweenTitleAndTasks =
                                                  8 * scaleFactor; // 여백 줄임

                                              final fixedHeight =
                                                  topPadding +
                                                  headerHeight +
                                                  buttonHeight +
                                                  spaceBetweenTitleAndTasks +
                                                  bottomPadding;
                                              final availableHeight =
                                                  panelHeight - fixedHeight;

                                              final itemVerticalPadding =
                                                  6 * scaleFactor;
                                              final itemMargin =
                                                  6 * scaleFactor;
                                              final textHeight = taskFontSize;
                                              // 실제 렌더링 높이 계산 (margin 포함)
                                              final actualItemMargin =
                                                  12 * scaleFactor;
                                              final taskItemHeight =
                                                  (itemVerticalPadding * 2) +
                                                  textHeight +
                                                  actualItemMargin;

                                              // 패널 높이의 90% 제한으로 이상적인 여백 확보
                                              final maxAllowedHeight =
                                                  panelHeight *
                                                  0.90; // 패널 높이의 90%
                                              final maxAvailableHeight =
                                                  maxAllowedHeight -
                                                  (topPadding +
                                                      headerHeight +
                                                      buttonHeight +
                                                      spaceBetweenTitleAndTasks); // 헤더 영역만 제외

                                              // 90% 제한 내에서 들어갈 수 있는 최대 일정 개수 계산
                                              int maxTasks =
                                                  (maxAvailableHeight /
                                                          taskItemHeight)
                                                      .floor();

                                              // 더 적극적인 최적화로 최대한 많은 일정 표시
                                              maxTasks = (maxTasks - 0.3)
                                                  .round()
                                                  .clamp(1, 10);

                                              // 디버깅: 실제 계산값들 출력
                                              print(
                                                '오늘 패널 - panelHeight: $panelHeight, maxTasks: $maxTasks, taskItemHeight: $taskItemHeight',
                                              );

                                              return Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Container(
                                                        padding:
                                                            const EdgeInsets.all(
                                                              10,
                                                            ),
                                                        decoration: BoxDecoration(
                                                          color: const Color(
                                                            0xFF6366f1,
                                                          ),
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                14,
                                                              ),
                                                          boxShadow: [
                                                            BoxShadow(
                                                              color:
                                                                  const Color(
                                                                    0xFF6366f1,
                                                                  ).withOpacity(
                                                                    0.3,
                                                                  ),
                                                              blurRadius: 12,
                                                              offset:
                                                                  const Offset(
                                                                    0,
                                                                    4,
                                                                  ),
                                                            ),
                                                          ],
                                                        ),
                                                        child: const Icon(
                                                          Icons.today,
                                                          color: Colors.white,
                                                          size: 22,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 16),
                                                      Expanded(
                                                        child: Row(
                                                          children: [
                                                            Text(
                                                              '오늘',
                                                              style: TextStyle(
                                                                color:
                                                                    const Color(
                                                                      0xFF1f2937,
                                                                    ),
                                                                fontSize:
                                                                    titleFontSize +
                                                                    5,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                              ),
                                                            ),
                                                            const SizedBox(
                                                              width: 8,
                                                            ),
                                                            Text(
                                                              '-',
                                                              style: TextStyle(
                                                                color:
                                                                    const Color(
                                                                      0xFF6b7280,
                                                                    ),
                                                                fontSize:
                                                                    titleFontSize -
                                                                    2,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .normal,
                                                              ),
                                                            ),
                                                            const SizedBox(
                                                              width: 8,
                                                            ),
                                                            Text(
                                                              _formatDate(
                                                                DateTime.now(),
                                                              ),
                                                              style: TextStyle(
                                                                color:
                                                                    const Color(
                                                                      0xFF6b7280,
                                                                    ),
                                                                fontSize:
                                                                    titleFontSize -
                                                                    6,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .normal,
                                                              ),
                                                            ),
                                                            const SizedBox(
                                                              width: 12,
                                                            ),
                                                            // 일정 개수 배지 (공간 부족시 숨김)
                                                            Builder(
                                                              builder: (context) {
                                                                final screenWidth =
                                                                    MediaQuery.of(
                                                                      context,
                                                                    ).size.width;
                                                                final availableWidth =
                                                                    screenWidth -
                                                                    40; // 패딩 제외

                                                                // 배지가 들어갈 수 있는 공간 계산
                                                                final titleWidth =
                                                                    (titleFontSize +
                                                                        5) *
                                                                    2; // "오늘" 텍스트
                                                                final dateWidth =
                                                                    (titleFontSize -
                                                                        6) *
                                                                    4; // 날짜 텍스트
                                                                final dashWidth =
                                                                    (titleFontSize -
                                                                        2) *
                                                                    1; // "-" 텍스트
                                                                final spacingWidth =
                                                                    8 +
                                                                    8 +
                                                                    12; // 간격들
                                                                final importantButtonWidth =
                                                                    60; // 중요 버튼
                                                                final iconWidth =
                                                                    44; // 아이콘 컨테이너
                                                                final iconSpacing =
                                                                    16; // 아이콘과 텍스트 간격

                                                                // 배지가 들어갈 수 있는 공간
                                                                final spaceForBadge =
                                                                    availableWidth -
                                                                    titleWidth -
                                                                    dateWidth -
                                                                    dashWidth -
                                                                    spacingWidth -
                                                                    importantButtonWidth -
                                                                    iconWidth -
                                                                    iconSpacing;

                                                                // 배지 대략적 너비
                                                                final estimatedBadgeWidth =
                                                                    8 +
                                                                    8 +
                                                                    12 +
                                                                    4 +
                                                                    ((14 + 2) *
                                                                        scaleFactor *
                                                                        3);

                                                                // 공간이 충분한지 확인
                                                                if (spaceForBadge >=
                                                                    estimatedBadgeWidth) {
                                                                  return Container(
                                                                    padding: const EdgeInsets.symmetric(
                                                                      horizontal:
                                                                          8,
                                                                      vertical:
                                                                          4,
                                                                    ),
                                                                    decoration: BoxDecoration(
                                                                      color: const Color(
                                                                        0xFFf3f4f6,
                                                                      ),
                                                                      borderRadius:
                                                                          BorderRadius.circular(
                                                                            12,
                                                                          ),
                                                                      border: Border.all(
                                                                        color: const Color(
                                                                          0xFFd1d5db,
                                                                        ),
                                                                        width:
                                                                            1,
                                                                      ),
                                                                    ),
                                                                    child: Row(
                                                                      mainAxisSize:
                                                                          MainAxisSize
                                                                              .min,
                                                                      children: [
                                                                        Icon(
                                                                          Icons
                                                                              .check_circle,
                                                                          size:
                                                                              12,
                                                                          color: const Color(
                                                                            0xFF10b981,
                                                                          ),
                                                                        ),
                                                                        const SizedBox(
                                                                          width:
                                                                              4,
                                                                        ),
                                                                        Text(
                                                                          '${todayTasks.where((task) => task.isCompleted).length}/${todayTasks.length}',
                                                                          style: TextStyle(
                                                                            fontSize:
                                                                                (14 +
                                                                                    2) *
                                                                                scaleFactor,
                                                                            fontWeight:
                                                                                FontWeight.w600,
                                                                            color: const Color(
                                                                              0xFF6b7280,
                                                                            ),
                                                                          ),
                                                                        ),
                                                                      ],
                                                                    ),
                                                                  );
                                                                } else {
                                                                  // 공간이 부족하면 완전히 숨김
                                                                  return const SizedBox.shrink();
                                                                }
                                                              },
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                      // 중요 버튼
                                                      GestureDetector(
                                                        onTap: () {
                                                          setState(() {
                                                            _showTodayImportantOnly =
                                                                !_showTodayImportantOnly;
                                                          });
                                                        },
                                                        child: AnimatedContainer(
                                                          duration:
                                                              const Duration(
                                                                milliseconds:
                                                                    300,
                                                              ),
                                                          padding:
                                                              const EdgeInsets.symmetric(
                                                                horizontal: 16,
                                                                vertical: 8,
                                                              ),
                                                          decoration: BoxDecoration(
                                                            color:
                                                                _showTodayImportantOnly
                                                                ? const Color(
                                                                    0xFFfbbf24,
                                                                  )
                                                                : const Color(
                                                                    0xFFf3f4f6,
                                                                  ),
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  20,
                                                                ),
                                                            border: Border.all(
                                                              color:
                                                                  _showTodayImportantOnly
                                                                  ? const Color(
                                                                      0xFFfbbf24,
                                                                    )
                                                                  : const Color(
                                                                      0xFFd1d5db,
                                                                    ),
                                                              width: 1,
                                                            ),
                                                          ),
                                                          child: Row(
                                                            mainAxisSize:
                                                                MainAxisSize
                                                                    .min,
                                                            children: [
                                                              Icon(
                                                                Icons.star,
                                                                color:
                                                                    _showTodayImportantOnly
                                                                    ? Colors
                                                                          .white
                                                                    : const Color(
                                                                        0xFF6b7280,
                                                                      ),
                                                                size: 18,
                                                              ),
                                                              const SizedBox(
                                                                width: 6,
                                                              ),
                                                              Text(
                                                                '${todayTasks.where((task) => task.isImportant).length}',
                                                                style: TextStyle(
                                                                  color:
                                                                      _showTodayImportantOnly
                                                                      ? Colors
                                                                            .white
                                                                      : const Color(
                                                                          0xFF6b7280,
                                                                        ),
                                                                  fontSize: 16,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  SizedBox(
                                                    height: 8 * scaleFactor,
                                                  ),
                                                  // 일정 목록 (스크롤 가능하게 수정)
                                                  Expanded(
                                                    child: todayTasks.isEmpty
                                                        ? LayoutBuilder(
                                                            builder:
                                                                (
                                                                  context,
                                                                  constraints,
                                                                ) {
                                                                  // 화면 높이에 따라 동적으로 조정
                                                                  final availableHeight =
                                                                      constraints
                                                                          .maxHeight;
                                                                  final isSmallScreen =
                                                                      availableHeight <
                                                                      100;

                                                                  return Center(
                                                                    child: Column(
                                                                      mainAxisAlignment:
                                                                          MainAxisAlignment
                                                                              .center,
                                                                      mainAxisSize:
                                                                          MainAxisSize
                                                                              .min,
                                                                      children: [
                                                                        if (!isSmallScreen) ...[
                                                                          Icon(
                                                                            Icons.event_note,
                                                                            color: const Color(
                                                                              0xFFd1d5db,
                                                                            ),
                                                                            size:
                                                                                isSmallScreen
                                                                                ? 24
                                                                                : 48,
                                                                          ),
                                                                          SizedBox(
                                                                            height:
                                                                                isSmallScreen
                                                                                ? 8
                                                                                : 16,
                                                                          ),
                                                                        ],
                                                                        Flexible(
                                                                          child: Text(
                                                                            isSmallScreen
                                                                                ? '일정 없음'
                                                                                : '오늘 일정이 없습니다',
                                                                            style: TextStyle(
                                                                              color: const Color(
                                                                                0xFF9ca3af,
                                                                              ),
                                                                              fontSize: isSmallScreen
                                                                                  ? taskFontSize *
                                                                                        0.8
                                                                                  : taskFontSize,
                                                                              fontStyle: FontStyle.italic,
                                                                            ),
                                                                            textAlign:
                                                                                TextAlign.center,
                                                                            overflow:
                                                                                TextOverflow.ellipsis,
                                                                            maxLines:
                                                                                2,
                                                                          ),
                                                                        ),
                                                                      ],
                                                                    ),
                                                                  );
                                                                },
                                                          )
                                                        : SingleChildScrollView(
                                                            child: Column(
                                                              children:
                                                                  (_showTodayImportantOnly
                                                                          ? todayTasks.where(
                                                                              (
                                                                                task,
                                                                              ) => task.isImportant,
                                                                            )
                                                                          : todayTasks)
                                                                      .take(
                                                                        maxTasks,
                                                                      )
                                                                      .map(
                                                                        (
                                                                          task,
                                                                        ) => Container(
                                                                          margin: EdgeInsets.only(
                                                                            bottom:
                                                                                12 *
                                                                                scaleFactor,
                                                                          ),
                                                                          child: Container(
                                                                            padding: EdgeInsets.symmetric(
                                                                              horizontal:
                                                                                  16 *
                                                                                  scaleFactor,
                                                                              vertical:
                                                                                  12 *
                                                                                  scaleFactor,
                                                                            ),
                                                                            decoration: BoxDecoration(
                                                                              color: task.isCompleted
                                                                                  ? const Color(
                                                                                      0xFFdcfce7,
                                                                                    )
                                                                                  : const Color(
                                                                                      0xFFfef2f2,
                                                                                    ),
                                                                              borderRadius: BorderRadius.circular(
                                                                                16,
                                                                              ),
                                                                              border: Border.all(
                                                                                color: task.isCompleted
                                                                                    ? const Color(
                                                                                        0xFF22c55e,
                                                                                      )
                                                                                    : const Color(
                                                                                        0xFFef4444,
                                                                                      ),
                                                                                width: 1,
                                                                              ),
                                                                            ),
                                                                            child: Row(
                                                                              children: [
                                                                                // 상태 아이콘
                                                                                Container(
                                                                                  padding: EdgeInsets.all(
                                                                                    6 *
                                                                                        scaleFactor,
                                                                                  ),
                                                                                  decoration: BoxDecoration(
                                                                                    color: Color(
                                                                                      TaskCategories.getCategoryColor(
                                                                                        task.category,
                                                                                      ),
                                                                                    ),
                                                                                    borderRadius: BorderRadius.circular(
                                                                                      8 *
                                                                                          scaleFactor,
                                                                                    ),
                                                                                  ),
                                                                                  child: Center(
                                                                                    child: Row(
                                                                                      mainAxisSize: MainAxisSize.min,
                                                                                      children: [
                                                                                        // 반복 일정 아이콘 (반복 일정인 경우)
                                                                                        if (task.isRecurring) ...[
                                                                                          Text(
                                                                                            '🔄',
                                                                                            style: TextStyle(
                                                                                              fontSize:
                                                                                                  16 *
                                                                                                  scaleFactor,
                                                                                            ),
                                                                                          ),
                                                                                          SizedBox(
                                                                                            width:
                                                                                                4 *
                                                                                                scaleFactor,
                                                                                          ),
                                                                                          Text(
                                                                                            '반복',
                                                                                            style: TextStyle(
                                                                                              fontSize:
                                                                                                  12 *
                                                                                                  scaleFactor,
                                                                                              color: Colors.white,
                                                                                              fontWeight: FontWeight.bold,
                                                                                            ),
                                                                                          ),
                                                                                        ] else ...[
                                                                                          Text(
                                                                                            TaskCategories.getCategoryIcon(
                                                                                              task.category,
                                                                                            ),
                                                                                            style: TextStyle(
                                                                                              fontSize:
                                                                                                  16 *
                                                                                                  scaleFactor,
                                                                                            ),
                                                                                          ),
                                                                                          SizedBox(
                                                                                            width:
                                                                                                4 *
                                                                                                scaleFactor,
                                                                                          ),
                                                                                          Text(
                                                                                            TaskCategories.getCategoryInfo(
                                                                                                  task.category,
                                                                                                )?['name'] ??
                                                                                                task.category,
                                                                                            style: TextStyle(
                                                                                              fontSize:
                                                                                                  12 *
                                                                                                  scaleFactor,
                                                                                              color: Colors.white,
                                                                                              fontWeight: FontWeight.bold,
                                                                                            ),
                                                                                          ),
                                                                                        ],
                                                                                      ],
                                                                                    ),
                                                                                  ),
                                                                                ),
                                                                                const SizedBox(
                                                                                  width: 12,
                                                                                ),
                                                                                // 일정 제목
                                                                                Expanded(
                                                                                  child: Row(
                                                                                    children: [
                                                                                      // 별 아이콘 또는 빈 공간 (일관된 레이아웃을 위해)
                                                                                      if (task.isImportant)
                                                                                        Icon(
                                                                                          Icons.star,
                                                                                          color: const Color(
                                                                                            0xFFfbbf24,
                                                                                          ),
                                                                                          size: 16,
                                                                                        )
                                                                                      else
                                                                                        const SizedBox(
                                                                                          width: 20, // 별 아이콘 + 간격과 동일한 공간
                                                                                        ),
                                                                                      const SizedBox(
                                                                                        width: 4,
                                                                                      ),
                                                                                      Expanded(
                                                                                        child: Text(
                                                                                          task.title,
                                                                                          style: TextStyle(
                                                                                            color: const Color(
                                                                                              0xFF1f2937,
                                                                                            ),
                                                                                            fontSize: taskFontSize,
                                                                                            fontWeight: FontWeight.w600,
                                                                                          ),
                                                                                          overflow: TextOverflow.ellipsis,
                                                                                        ),
                                                                                      ),
                                                                                    ],
                                                                                  ),
                                                                                ),
                                                                                const SizedBox(
                                                                                  width: 8,
                                                                                ),
                                                                                // 시간 표시 (오른쪽으로 이동)
                                                                                Text(
                                                                                  _formatTime(
                                                                                    task.date,
                                                                                  ),
                                                                                  style: TextStyle(
                                                                                    color: const Color(
                                                                                      0xFF6b7280,
                                                                                    ),
                                                                                    fontSize:
                                                                                        taskFontSize -
                                                                                        2,
                                                                                  ),
                                                                                ),
                                                                              ],
                                                                            ),
                                                                          ),
                                                                        ),
                                                                      )
                                                                      .toList(),
                                                            ),
                                                          ),
                                                  ),
                                                ],
                                              );
                                            },
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    // 내일 패널
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  DateDetailScreen(
                                                    date: DateTime.now().add(
                                                      const Duration(days: 1),
                                                    ),
                                                    title: '내일',
                                                  ),
                                            ),
                                          );
                                        },
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(
                                              24,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(
                                                  0.08,
                                                ),
                                                blurRadius: 20,
                                                offset: const Offset(0, 8),
                                              ),
                                            ],
                                          ),
                                          padding: const EdgeInsets.all(12),
                                          child: LayoutBuilder(
                                            builder: (context, constraints) {
                                              final scaleFactor =
                                                  0.75 + (fontSize * 0.5);
                                              final titleFontSize =
                                                  (20 + 5) * scaleFactor;
                                              final taskFontSize =
                                                  (14 + 5) * scaleFactor;

                                              final panelHeight =
                                                  constraints.maxHeight;
                                              final topPadding = 4.0; // 여백 더 줄임
                                              final bottomPadding =
                                                  4.0; // 여백 더 줄임
                                              final headerHeight =
                                                  titleFontSize + 12;
                                              final buttonHeight = 40.0;
                                              final spaceBetweenTitleAndTasks =
                                                  8 * scaleFactor; // 여백 줄임

                                              final fixedHeight =
                                                  topPadding +
                                                  headerHeight +
                                                  buttonHeight +
                                                  spaceBetweenTitleAndTasks +
                                                  bottomPadding;
                                              final availableHeight =
                                                  panelHeight - fixedHeight;

                                              final itemVerticalPadding =
                                                  6 * scaleFactor;
                                              final itemMargin =
                                                  6 * scaleFactor;
                                              final textHeight = taskFontSize;
                                              // 실제 렌더링 높이 계산 (margin 포함)
                                              final actualItemMargin =
                                                  12 * scaleFactor;
                                              final taskItemHeight =
                                                  (itemVerticalPadding * 2) +
                                                  textHeight +
                                                  actualItemMargin;

                                              // 패널 높이의 90% 제한으로 이상적인 여백 확보
                                              final maxAllowedHeight =
                                                  panelHeight *
                                                  0.90; // 패널 높이의 90%
                                              final maxAvailableHeight =
                                                  maxAllowedHeight -
                                                  (topPadding +
                                                      headerHeight +
                                                      buttonHeight +
                                                      spaceBetweenTitleAndTasks); // 헤더 영역만 제외

                                              // 90% 제한 내에서 들어갈 수 있는 최대 일정 개수 계산
                                              int maxTasks =
                                                  (maxAvailableHeight /
                                                          taskItemHeight)
                                                      .floor();

                                              // 오버플로우 방지와 일정 표시 균형 조정
                                              maxTasks = (maxTasks - 0.5)
                                                  .round()
                                                  .clamp(1, 10);

                                              // 디버깅: 실제 계산값들 출력
                                              print(
                                                '내일 패널 - panelHeight: $panelHeight, maxTasks: $maxTasks, taskItemHeight: $taskItemHeight',
                                              );

                                              return Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Container(
                                                        padding:
                                                            const EdgeInsets.all(
                                                              10,
                                                            ),
                                                        decoration: BoxDecoration(
                                                          color: const Color(
                                                            0xFF6366f1,
                                                          ),
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                14,
                                                              ),
                                                          boxShadow: [
                                                            BoxShadow(
                                                              color:
                                                                  const Color(
                                                                    0xFF6366f1,
                                                                  ).withOpacity(
                                                                    0.3,
                                                                  ),
                                                              blurRadius: 12,
                                                              offset:
                                                                  const Offset(
                                                                    0,
                                                                    4,
                                                                  ),
                                                            ),
                                                          ],
                                                        ),
                                                        child: const Icon(
                                                          Icons.event,
                                                          color: Colors.white,
                                                          size: 22,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 16),
                                                      Expanded(
                                                        child: Row(
                                                          children: [
                                                            Text(
                                                              '내일',
                                                              style: TextStyle(
                                                                color:
                                                                    const Color(
                                                                      0xFF1f2937,
                                                                    ),
                                                                fontSize:
                                                                    titleFontSize +
                                                                    5,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                              ),
                                                            ),
                                                            const SizedBox(
                                                              width: 8,
                                                            ),
                                                            Text(
                                                              '-',
                                                              style: TextStyle(
                                                                color:
                                                                    const Color(
                                                                      0xFF6b7280,
                                                                    ),
                                                                fontSize:
                                                                    titleFontSize -
                                                                    2,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .normal,
                                                              ),
                                                            ),
                                                            const SizedBox(
                                                              width: 8,
                                                            ),
                                                            Text(
                                                              _formatDate(
                                                                DateTime.now().add(
                                                                  const Duration(
                                                                    days: 1,
                                                                  ),
                                                                ),
                                                              ),
                                                              style: TextStyle(
                                                                color:
                                                                    const Color(
                                                                      0xFF6b7280,
                                                                    ),
                                                                fontSize:
                                                                    titleFontSize -
                                                                    6,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .normal,
                                                              ),
                                                            ),
                                                            const SizedBox(
                                                              width: 12,
                                                            ),
                                                            // 일정 개수 배지 (공간 부족시 숨김)
                                                            Builder(
                                                              builder: (context) {
                                                                final screenWidth =
                                                                    MediaQuery.of(
                                                                      context,
                                                                    ).size.width;
                                                                final availableWidth =
                                                                    screenWidth -
                                                                    40; // 패딩 제외

                                                                // 배지가 들어갈 수 있는 공간 계산
                                                                final titleWidth =
                                                                    (titleFontSize +
                                                                        5) *
                                                                    2; // "내일" 텍스트
                                                                final dateWidth =
                                                                    (titleFontSize -
                                                                        6) *
                                                                    4; // 날짜 텍스트
                                                                final dashWidth =
                                                                    (titleFontSize -
                                                                        2) *
                                                                    1; // "-" 텍스트
                                                                final spacingWidth =
                                                                    8 +
                                                                    8 +
                                                                    12; // 간격들
                                                                final importantButtonWidth =
                                                                    60; // 중요 버튼
                                                                final iconWidth =
                                                                    44; // 아이콘 컨테이너
                                                                final iconSpacing =
                                                                    16; // 아이콘과 텍스트 간격

                                                                // 배지가 들어갈 수 있는 공간
                                                                final spaceForBadge =
                                                                    availableWidth -
                                                                    titleWidth -
                                                                    dateWidth -
                                                                    dashWidth -
                                                                    spacingWidth -
                                                                    importantButtonWidth -
                                                                    iconWidth -
                                                                    iconSpacing;

                                                                // 배지 대략적 너비
                                                                final estimatedBadgeWidth =
                                                                    8 +
                                                                    8 +
                                                                    12 +
                                                                    4 +
                                                                    ((14 + 2) *
                                                                        scaleFactor *
                                                                        3);

                                                                // 공간이 충분한지 확인
                                                                if (spaceForBadge >=
                                                                    estimatedBadgeWidth) {
                                                                  return Container(
                                                                    padding: const EdgeInsets.symmetric(
                                                                      horizontal:
                                                                          8,
                                                                      vertical:
                                                                          4,
                                                                    ),
                                                                    decoration: BoxDecoration(
                                                                      color: const Color(
                                                                        0xFFf3f4f6,
                                                                      ),
                                                                      borderRadius:
                                                                          BorderRadius.circular(
                                                                            12,
                                                                          ),
                                                                      border: Border.all(
                                                                        color: const Color(
                                                                          0xFFd1d5db,
                                                                        ),
                                                                        width:
                                                                            1,
                                                                      ),
                                                                    ),
                                                                    child: Row(
                                                                      mainAxisSize:
                                                                          MainAxisSize
                                                                              .min,
                                                                      children: [
                                                                        Icon(
                                                                          Icons
                                                                              .check_circle,
                                                                          size:
                                                                              12,
                                                                          color: const Color(
                                                                            0xFF10b981,
                                                                          ),
                                                                        ),
                                                                        const SizedBox(
                                                                          width:
                                                                              4,
                                                                        ),
                                                                        Text(
                                                                          '${tomorrowTasks.where((task) => task.isCompleted).length}/${tomorrowTasks.length}',
                                                                          style: TextStyle(
                                                                            fontSize:
                                                                                (14 +
                                                                                    2) *
                                                                                scaleFactor,
                                                                            fontWeight:
                                                                                FontWeight.w600,
                                                                            color: const Color(
                                                                              0xFF6b7280,
                                                                            ),
                                                                          ),
                                                                        ),
                                                                      ],
                                                                    ),
                                                                  );
                                                                } else {
                                                                  // 공간이 부족하면 완전히 숨김
                                                                  return const SizedBox.shrink();
                                                                }
                                                              },
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                      // 중요 버튼
                                                      GestureDetector(
                                                        onTap: () {
                                                          setState(() {
                                                            _showTomorrowImportantOnly =
                                                                !_showTomorrowImportantOnly;
                                                          });
                                                        },
                                                        child: AnimatedContainer(
                                                          duration:
                                                              const Duration(
                                                                milliseconds:
                                                                    300,
                                                              ),
                                                          padding:
                                                              const EdgeInsets.symmetric(
                                                                horizontal: 16,
                                                                vertical: 8,
                                                              ),
                                                          decoration: BoxDecoration(
                                                            color:
                                                                _showTomorrowImportantOnly
                                                                ? const Color(
                                                                    0xFFfbbf24,
                                                                  )
                                                                : const Color(
                                                                    0xFFf3f4f6,
                                                                  ),
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  20,
                                                                ),
                                                            border: Border.all(
                                                              color:
                                                                  _showTomorrowImportantOnly
                                                                  ? const Color(
                                                                      0xFFfbbf24,
                                                                    )
                                                                  : const Color(
                                                                      0xFFd1d5db,
                                                                    ),
                                                              width: 1,
                                                            ),
                                                          ),
                                                          child: Row(
                                                            mainAxisSize:
                                                                MainAxisSize
                                                                    .min,
                                                            children: [
                                                              Icon(
                                                                Icons.star,
                                                                color:
                                                                    _showTomorrowImportantOnly
                                                                    ? Colors
                                                                          .white
                                                                    : const Color(
                                                                        0xFF6b7280,
                                                                      ),
                                                                size: 18,
                                                              ),
                                                              const SizedBox(
                                                                width: 6,
                                                              ),
                                                              Text(
                                                                '${tomorrowTasks.where((task) => task.isImportant).length}',
                                                                style: TextStyle(
                                                                  color:
                                                                      _showTomorrowImportantOnly
                                                                      ? Colors
                                                                            .white
                                                                      : const Color(
                                                                          0xFF6b7280,
                                                                        ),
                                                                  fontSize: 16,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  SizedBox(
                                                    height: 8 * scaleFactor,
                                                  ),
                                                  // 일정 목록 (스크롤 가능하게 수정)
                                                  Expanded(
                                                    child: tomorrowTasks.isEmpty
                                                        ? LayoutBuilder(
                                                            builder:
                                                                (
                                                                  context,
                                                                  constraints,
                                                                ) {
                                                                  // 화면 높이에 따라 동적으로 조정
                                                                  final availableHeight =
                                                                      constraints
                                                                          .maxHeight;
                                                                  final isSmallScreen =
                                                                      availableHeight <
                                                                      100;

                                                                  return Center(
                                                                    child: Column(
                                                                      mainAxisAlignment:
                                                                          MainAxisAlignment
                                                                              .center,
                                                                      mainAxisSize:
                                                                          MainAxisSize
                                                                              .min,
                                                                      children: [
                                                                        if (!isSmallScreen) ...[
                                                                          Icon(
                                                                            Icons.event_note,
                                                                            color: const Color(
                                                                              0xFFd1d5db,
                                                                            ),
                                                                            size:
                                                                                isSmallScreen
                                                                                ? 24
                                                                                : 48,
                                                                          ),
                                                                          SizedBox(
                                                                            height:
                                                                                isSmallScreen
                                                                                ? 8
                                                                                : 16,
                                                                          ),
                                                                        ],
                                                                        Flexible(
                                                                          child: Text(
                                                                            isSmallScreen
                                                                                ? '일정 없음'
                                                                                : '내일 일정이 없습니다',
                                                                            style: TextStyle(
                                                                              color: const Color(
                                                                                0xFF9ca3af,
                                                                              ),
                                                                              fontSize: isSmallScreen
                                                                                  ? taskFontSize *
                                                                                        0.8
                                                                                  : taskFontSize,
                                                                              fontStyle: FontStyle.italic,
                                                                            ),
                                                                            textAlign:
                                                                                TextAlign.center,
                                                                            overflow:
                                                                                TextOverflow.ellipsis,
                                                                            maxLines:
                                                                                2,
                                                                          ),
                                                                        ),
                                                                      ],
                                                                    ),
                                                                  );
                                                                },
                                                          )
                                                        : SingleChildScrollView(
                                                            child: Column(
                                                              children:
                                                                  (_showTomorrowImportantOnly
                                                                          ? tomorrowTasks.where(
                                                                              (
                                                                                task,
                                                                              ) => task.isImportant,
                                                                            )
                                                                          : tomorrowTasks)
                                                                      .take(
                                                                        maxTasks,
                                                                      )
                                                                      .map(
                                                                        (
                                                                          task,
                                                                        ) => Container(
                                                                          margin: EdgeInsets.only(
                                                                            bottom:
                                                                                12 *
                                                                                scaleFactor,
                                                                          ),
                                                                          child: Container(
                                                                            padding: EdgeInsets.symmetric(
                                                                              horizontal:
                                                                                  16 *
                                                                                  scaleFactor,
                                                                              vertical:
                                                                                  12 *
                                                                                  scaleFactor,
                                                                            ),
                                                                            decoration: BoxDecoration(
                                                                              color: task.isCompleted
                                                                                  ? const Color(
                                                                                      0xFFdcfce7,
                                                                                    )
                                                                                  : const Color(
                                                                                      0xFFfef2f2,
                                                                                    ),
                                                                              borderRadius: BorderRadius.circular(
                                                                                16,
                                                                              ),
                                                                              border: Border.all(
                                                                                color: task.isCompleted
                                                                                    ? const Color(
                                                                                        0xFF22c55e,
                                                                                      )
                                                                                    : const Color(
                                                                                        0xFFef4444,
                                                                                      ),
                                                                                width: 1,
                                                                              ),
                                                                            ),
                                                                            child: Row(
                                                                              children: [
                                                                                // 상태 아이콘
                                                                                Container(
                                                                                  padding: EdgeInsets.all(
                                                                                    6 *
                                                                                        scaleFactor,
                                                                                  ),
                                                                                  decoration: BoxDecoration(
                                                                                    color: Color(
                                                                                      TaskCategories.getCategoryColor(
                                                                                        task.category,
                                                                                      ),
                                                                                    ),
                                                                                    borderRadius: BorderRadius.circular(
                                                                                      8 *
                                                                                          scaleFactor,
                                                                                    ),
                                                                                  ),
                                                                                  child: Center(
                                                                                    child: Row(
                                                                                      mainAxisSize: MainAxisSize.min,
                                                                                      children: [
                                                                                        // 반복 일정 아이콘 (반복 일정인 경우)
                                                                                        if (task.isRecurring) ...[
                                                                                          Text(
                                                                                            '🔄',
                                                                                            style: TextStyle(
                                                                                              fontSize:
                                                                                                  16 *
                                                                                                  scaleFactor,
                                                                                            ),
                                                                                          ),
                                                                                          SizedBox(
                                                                                            width:
                                                                                                4 *
                                                                                                scaleFactor,
                                                                                          ),
                                                                                          Text(
                                                                                            '반복',
                                                                                            style: TextStyle(
                                                                                              fontSize:
                                                                                                  12 *
                                                                                                  scaleFactor,
                                                                                              color: Colors.white,
                                                                                              fontWeight: FontWeight.bold,
                                                                                            ),
                                                                                          ),
                                                                                        ] else ...[
                                                                                          Text(
                                                                                            TaskCategories.getCategoryIcon(
                                                                                              task.category,
                                                                                            ),
                                                                                            style: TextStyle(
                                                                                              fontSize:
                                                                                                  16 *
                                                                                                  scaleFactor,
                                                                                            ),
                                                                                          ),
                                                                                          SizedBox(
                                                                                            width:
                                                                                                4 *
                                                                                                scaleFactor,
                                                                                          ),
                                                                                          Text(
                                                                                            TaskCategories.getCategoryInfo(
                                                                                                  task.category,
                                                                                                )?['name'] ??
                                                                                                task.category,
                                                                                            style: TextStyle(
                                                                                              fontSize:
                                                                                                  12 *
                                                                                                  scaleFactor,
                                                                                              color: Colors.white,
                                                                                              fontWeight: FontWeight.bold,
                                                                                            ),
                                                                                          ),
                                                                                        ],
                                                                                      ],
                                                                                    ),
                                                                                  ),
                                                                                ),
                                                                                const SizedBox(
                                                                                  width: 12,
                                                                                ),
                                                                                // 일정 제목
                                                                                Expanded(
                                                                                  child: Row(
                                                                                    children: [
                                                                                      // 별 아이콘 또는 빈 공간 (일관된 레이아웃을 위해)
                                                                                      if (task.isImportant)
                                                                                        Icon(
                                                                                          Icons.star,
                                                                                          color: const Color(
                                                                                            0xFFfbbf24,
                                                                                          ),
                                                                                          size: 16,
                                                                                        )
                                                                                      else
                                                                                        const SizedBox(
                                                                                          width: 20, // 별 아이콘 + 간격과 동일한 공간
                                                                                        ),
                                                                                      const SizedBox(
                                                                                        width: 4,
                                                                                      ),
                                                                                      Expanded(
                                                                                        child: Text(
                                                                                          task.title,
                                                                                          style: TextStyle(
                                                                                            color: const Color(
                                                                                              0xFF1f2937,
                                                                                            ),
                                                                                            fontSize: taskFontSize,
                                                                                            fontWeight: FontWeight.w600,
                                                                                          ),
                                                                                          overflow: TextOverflow.ellipsis,
                                                                                        ),
                                                                                      ),
                                                                                    ],
                                                                                  ),
                                                                                ),
                                                                                const SizedBox(
                                                                                  width: 8,
                                                                                ),
                                                                                // 시간 표시 (오른쪽으로 이동)
                                                                                Text(
                                                                                  _formatTime(
                                                                                    task.date,
                                                                                  ),
                                                                                  style: TextStyle(
                                                                                    color: const Color(
                                                                                      0xFF6b7280,
                                                                                    ),
                                                                                    fontSize:
                                                                                        taskFontSize -
                                                                                        2,
                                                                                  ),
                                                                                ),
                                                                              ],
                                                                            ),
                                                                          ),
                                                                        ),
                                                                      )
                                                                      .toList(),
                                                            ),
                                                          ),
                                                  ),
                                                ],
                                              );
                                            },
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 20),
                              // 일정 더보기 섹션
                              SizedBox(
                                height: 80,
                                child: GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const CalendarScreen(),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          Color(0xFF6366f1),
                                          Color(0xFF8b5cf6),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(
                                            0xFF6366f1,
                                          ).withValues(alpha: 0.3),
                                          blurRadius: 12,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    padding: const EdgeInsets.all(20),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withValues(
                                              alpha: 0.2,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.calendar_today,
                                            color: Colors.white,
                                            size: 24,
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Text(
                                          '일정 더보기',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize:
                                                (20 + 5) *
                                                (0.75 + (fontSize * 0.5)),
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        // 하단 버튼들
                        SizedBox(
                          height: 70,
                          child: Row(
                            children: [
                              // 좌측: 반복일정 버튼 (원래 카드 스타일)
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const RecurringTasksScreen(),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    height: 70,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(
                                            alpha: 0.08,
                                          ),
                                          blurRadius: 20,
                                          offset: const Offset(0, 8),
                                        ),
                                      ],
                                    ),
                                    child: Center(
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          const Icon(
                                            Icons.repeat,
                                            color: Color(0xFF6366f1),
                                            size: 24,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            '반복일정',
                                            style: TextStyle(
                                              color: const Color(0xFF1f2937),
                                              fontSize:
                                                  22 *
                                                  (0.75 + (fontSize * 0.5)),
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              // 중앙: 녹음 버튼 (원형 빨간 버튼)
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const RecordScreen(),
                                    ),
                                  );
                                },
                                child: Container(
                                  width: 72,
                                  height: 72,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFD35445),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: const Color(0xFF263238),
                                      width: 6,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.12,
                                        ),
                                        blurRadius: 12,
                                        offset: const Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              // 우측: 설정 버튼 (원래 카드 스타일)
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const SettingsScreen(),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    height: 70,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(
                                            alpha: 0.08,
                                          ),
                                          blurRadius: 20,
                                          offset: const Offset(0, 8),
                                        ),
                                      ],
                                    ),
                                    child: Center(
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          const Icon(
                                            Icons.settings,
                                            color: Color(0xFF6366f1),
                                            size: 24,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            '설정',
                                            style: TextStyle(
                                              color: const Color(0xFF1f2937),
                                              fontSize:
                                                  22 *
                                                  (0.75 + (fontSize * 0.5)),
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  // (제거됨) 빠른 액션: 기존 하단 버튼 레이아웃을 사용하도록 복귀
}
