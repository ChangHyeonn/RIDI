import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';
import 'calendar_screen.dart';
import 'settings_screen.dart';
import 'date_detail_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  bool _showTodayImportantOnly = false; // 오늘 중요 일정만 보기 상태
  bool _showTomorrowImportantOnly = false; // 내일 중요 일정만 보기 상태

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TaskProvider>().initialize();
    });
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
    return ' - ${date.month}월 ${date.day}일';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Consumer<TaskProvider>(
          builder: (context, taskProvider, child) {
            if (taskProvider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            final todayTasks = taskProvider.getTodayTasks();
            final tomorrowTasks = taskProvider.getTomorrowTasks();
            final fontSize = taskProvider.fontSize;

            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // 상단 영역 (Expanded로 남은 공간 모두 차지)
                  Expanded(
                    child: Column(
                      children: [
                        // 오늘/내일 패널 (Column으로 변경하여 상/하 배치)
                        Expanded(
                          flex: 3, // 3/4 비율
                          child: Column(
                            children: [
                              // 오늘 패널 (위쪽)
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => DateDetailScreen(
                                          date: DateTime.now(),
                                          title: '오늘',
                                        ),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.grey[400], // 패널 색상을 회색으로 고정
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    padding: const EdgeInsets.all(16),
                                    child: LayoutBuilder(
                                      builder: (context, constraints) {
                                        // 글씨 크기를 고려한 동적 계산 (범위 조정)
                                        final scaleFactor =
                                            0.75 +
                                            (fontSize * 0.5); // 75%~125% 범위
                                        final titleFontSize =
                                            (20 + 5) *
                                            scaleFactor; // 기본값 5px 증가 (25px)
                                        final taskFontSize =
                                            (14 + 5) *
                                            scaleFactor; // 기본값 5px 증가 (19px)

                                        // 패널 높이와 글씨 크기에 따라 보여줄 일정 개수 결정
                                        final panelHeight =
                                            constraints.maxHeight;
                                        final topPadding = 16.0; // 위쪽 패딩
                                        final bottomPadding = 16.0; // 아래쪽 패딩
                                        final headerHeight =
                                            titleFontSize + 8; // 제목 높이 + 작은 여백
                                        final buttonHeight = 32.0; // 중요 버튼 높이
                                        final spaceBetweenTitleAndTasks =
                                            8 * scaleFactor; // 제목과 일정 사이 여백

                                        final fixedHeight =
                                            topPadding +
                                            headerHeight +
                                            buttonHeight +
                                            spaceBetweenTitleAndTasks +
                                            bottomPadding;
                                        final availableHeight =
                                            panelHeight - fixedHeight;

                                        // 각 일정 아이템의 실제 높이 (더 정확하게 계산)
                                        final itemVerticalPadding =
                                            4 * scaleFactor; // 세로 패딩
                                        final itemMargin =
                                            4 * scaleFactor; // 아이템 간 여백
                                        final textHeight =
                                            taskFontSize; // 텍스트 한 줄 높이
                                        final taskItemHeight =
                                            (itemVerticalPadding * 2) +
                                            textHeight +
                                            itemMargin;

                                        // 사용 가능한 높이에 따라 일정 개수 계산 (여유분 고려)
                                        int maxTasks =
                                            (availableHeight / taskItemHeight)
                                                .floor();
                                        // 안전성을 위해 1개 적게 표시 (잘림 방지)
                                        maxTasks = (maxTasks - 1).clamp(1, 15);

                                        return Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                // "오늘"과 날짜를 분리하여 다른 스타일 적용
                                                RichText(
                                                  text: TextSpan(
                                                    children: [
                                                      TextSpan(
                                                        text: '오늘',
                                                        style: TextStyle(
                                                          color: Colors.white,
                                                          fontSize:
                                                              titleFontSize +
                                                              5, // 5px 추가 증가
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                      TextSpan(
                                                        text: _formatDate(
                                                          DateTime.now(),
                                                        ),
                                                        style: TextStyle(
                                                          color: Colors.white,
                                                          fontSize:
                                                              titleFontSize,
                                                          fontWeight: FontWeight
                                                              .w400, // bold에서 normal로 1단계 감소
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                const Spacer(),
                                                // 중요 버튼
                                                GestureDetector(
                                                  onTap: () {
                                                    setState(() {
                                                      _showTodayImportantOnly =
                                                          !_showTodayImportantOnly;
                                                    });
                                                  },
                                                  child: Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal:
                                                              12, // 8에서 12로 증가
                                                          vertical:
                                                              8, // 4에서 8로 증가
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color:
                                                          _showTodayImportantOnly
                                                          ? const Color(
                                                              0xFFFFD700,
                                                            )
                                                          : Colors.white
                                                                .withOpacity(
                                                                  0.3,
                                                                ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            16, // 12에서 16으로 증가
                                                          ),
                                                    ),
                                                    child: Row(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        Icon(
                                                          Icons.star,
                                                          color:
                                                              _showTodayImportantOnly
                                                              ? Colors.black
                                                              : Colors.white,
                                                          size:
                                                              20, // 16에서 20으로 증가
                                                        ),
                                                        const SizedBox(
                                                          width:
                                                              6, // 4에서 6으로 증가
                                                        ),
                                                        Text(
                                                          '${todayTasks.where((task) => task.isImportant).length}',
                                                          style: TextStyle(
                                                            color:
                                                                _showTodayImportantOnly
                                                                ? Colors.black
                                                                : Colors.white,
                                                            fontSize:
                                                                16, // 12에서 16으로 증가
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            SizedBox(height: 8 * scaleFactor),
                                            // 일정 목록 부분을 Expanded로 감싸서 남은 공간 활용
                                            Expanded(
                                              child: todayTasks.isEmpty
                                                  ? Text(
                                                      '일정이 없습니다',
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                        fontSize: taskFontSize,
                                                      ),
                                                    )
                                                  : SingleChildScrollView(
                                                      child: Column(
                                                        children:
                                                            (_showTodayImportantOnly
                                                                    ? todayTasks.where(
                                                                        (
                                                                          task,
                                                                        ) => task
                                                                            .isImportant,
                                                                      )
                                                                    : todayTasks)
                                                                .take(maxTasks)
                                                                .map(
                                                                  (
                                                                    task,
                                                                  ) => Container(
                                                                    margin: EdgeInsets.only(
                                                                      bottom:
                                                                          6 *
                                                                          scaleFactor,
                                                                    ),
                                                                    child: Container(
                                                                      padding: EdgeInsets.symmetric(
                                                                        horizontal:
                                                                            6 *
                                                                            scaleFactor,
                                                                        vertical:
                                                                            4 *
                                                                            scaleFactor,
                                                                      ),
                                                                      decoration: BoxDecoration(
                                                                        // 완료 상태에 따라 색상 변경
                                                                        color:
                                                                            task.isCompleted
                                                                            ? const Color(
                                                                                0xFF4CAF50,
                                                                              ).withOpacity(
                                                                                0.8,
                                                                              ) // 초록색 (완료)
                                                                            : const Color(
                                                                                0xFFF44336,
                                                                              ).withOpacity(
                                                                                0.8,
                                                                              ), // 빨간색 (미완료)
                                                                        borderRadius:
                                                                            BorderRadius.circular(
                                                                              8,
                                                                            ),
                                                                      ),
                                                                      child: Row(
                                                                        children: [
                                                                          // 중요도 표시
                                                                          if (task
                                                                              .isImportant) ...[
                                                                            Icon(
                                                                              Icons.star,
                                                                              color: const Color(
                                                                                0xFFFFD700,
                                                                              ),
                                                                              size:
                                                                                  16 *
                                                                                  scaleFactor,
                                                                            ),
                                                                            SizedBox(
                                                                              width:
                                                                                  4 *
                                                                                  scaleFactor,
                                                                            ),
                                                                          ],
                                                                          // 일정 제목
                                                                          Expanded(
                                                                            child: Text(
                                                                              task.title,
                                                                              style: TextStyle(
                                                                                color: Colors.white,
                                                                                fontSize: taskFontSize,
                                                                                fontWeight: FontWeight.w900,
                                                                              ),
                                                                              overflow: TextOverflow.ellipsis,
                                                                            ),
                                                                          ),
                                                                          SizedBox(
                                                                            width:
                                                                                4 *
                                                                                scaleFactor,
                                                                          ),
                                                                          // 시간 표시
                                                                          Text(
                                                                            _formatTime(
                                                                              task.date,
                                                                            ),
                                                                            style: TextStyle(
                                                                              color: Colors.white,
                                                                              fontSize:
                                                                                  taskFontSize *
                                                                                  0.9,
                                                                              fontWeight: FontWeight.w600,
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
                              const SizedBox(height: 12), // 패널 간 간격
                              // 내일 패널 (아래쪽)
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => DateDetailScreen(
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
                                      color: Colors.grey[400], // 패널 색상을 회색으로 고정
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    padding: const EdgeInsets.all(16),
                                    child: LayoutBuilder(
                                      builder: (context, constraints) {
                                        // 글씨 크기를 고려한 동적 계산 (범위 조정)
                                        final scaleFactor =
                                            0.75 +
                                            (fontSize * 0.5); // 75%~125% 범위
                                        final titleFontSize =
                                            (20 + 5) *
                                            scaleFactor; // 기본값 5px 증가 (25px)
                                        final taskFontSize =
                                            (14 + 5) *
                                            scaleFactor; // 기본값 5px 증가 (19px)

                                        // 패널 높이와 글씨 크기에 따라 보여줄 일정 개수 결정
                                        final panelHeight =
                                            constraints.maxHeight;
                                        final topPadding = 16.0; // 위쪽 패딩
                                        final bottomPadding = 16.0; // 아래쪽 패딩
                                        final headerHeight =
                                            titleFontSize + 8; // 제목 높이 + 작은 여백
                                        final buttonHeight = 32.0; // 중요 버튼 높이
                                        final spaceBetweenTitleAndTasks =
                                            8 * scaleFactor; // 제목과 일정 사이 여백

                                        final fixedHeight =
                                            topPadding +
                                            headerHeight +
                                            buttonHeight +
                                            spaceBetweenTitleAndTasks +
                                            bottomPadding;
                                        final availableHeight =
                                            panelHeight - fixedHeight;

                                        // 각 일정 아이템의 실제 높이 (더 정확하게 계산)
                                        final itemVerticalPadding =
                                            4 * scaleFactor; // 세로 패딩
                                        final itemMargin =
                                            4 * scaleFactor; // 아이템 간 여백
                                        final textHeight =
                                            taskFontSize; // 텍스트 한 줄 높이
                                        final taskItemHeight =
                                            (itemVerticalPadding * 2) +
                                            textHeight +
                                            itemMargin;

                                        // 사용 가능한 높이에 따라 일정 개수 계산 (여유분 고려)
                                        int maxTasks =
                                            (availableHeight / taskItemHeight)
                                                .floor();
                                        // 안전성을 위해 1개 적게 표시 (잘림 방지)
                                        maxTasks = (maxTasks - 1).clamp(1, 15);

                                        return Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                // "내일"과 날짜를 분리하여 다른 스타일 적용
                                                RichText(
                                                  text: TextSpan(
                                                    children: [
                                                      TextSpan(
                                                        text: '내일',
                                                        style: TextStyle(
                                                          color: Colors.white,
                                                          fontSize:
                                                              titleFontSize +
                                                              5, // 5px 추가 증가
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                      TextSpan(
                                                        text: _formatDate(
                                                          DateTime.now().add(
                                                            const Duration(
                                                              days: 1,
                                                            ),
                                                          ),
                                                        ),
                                                        style: TextStyle(
                                                          color: Colors.white,
                                                          fontSize:
                                                              titleFontSize,
                                                          fontWeight: FontWeight
                                                              .w400, // bold에서 normal로 1단계 감소
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                const Spacer(),
                                                // 중요 버튼 (내일 패널용)
                                                GestureDetector(
                                                  onTap: () {
                                                    setState(() {
                                                      _showTomorrowImportantOnly =
                                                          !_showTomorrowImportantOnly;
                                                    });
                                                  },
                                                  child: Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal:
                                                              12, // 8에서 12로 증가
                                                          vertical:
                                                              8, // 4에서 8로 증가
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color:
                                                          _showTomorrowImportantOnly
                                                          ? const Color(
                                                              0xFFFFD700,
                                                            )
                                                          : Colors.white
                                                                .withOpacity(
                                                                  0.3,
                                                                ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            16, // 12에서 16으로 증가
                                                          ),
                                                    ),
                                                    child: Row(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        Icon(
                                                          Icons.star,
                                                          color:
                                                              _showTomorrowImportantOnly
                                                              ? Colors.black
                                                              : Colors.white,
                                                          size:
                                                              20, // 16에서 20으로 증가
                                                        ),
                                                        const SizedBox(
                                                          width:
                                                              6, // 4에서 6으로 증가
                                                        ),
                                                        Text(
                                                          '${tomorrowTasks.where((task) => task.isImportant).length}',
                                                          style: TextStyle(
                                                            color:
                                                                _showTomorrowImportantOnly
                                                                ? Colors.black
                                                                : Colors.white,
                                                            fontSize:
                                                                16, // 12에서 16으로 증가
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            SizedBox(height: 8 * scaleFactor),
                                            // 일정 목록 부분을 Expanded로 감싸서 남은 공간 활용
                                            Expanded(
                                              child: tomorrowTasks.isEmpty
                                                  ? Text(
                                                      '일정이 없습니다',
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                        fontSize: taskFontSize,
                                                      ),
                                                    )
                                                  : SingleChildScrollView(
                                                      child: Column(
                                                        children:
                                                            (_showTomorrowImportantOnly
                                                                    ? tomorrowTasks.where(
                                                                        (
                                                                          task,
                                                                        ) => task
                                                                            .isImportant,
                                                                      )
                                                                    : tomorrowTasks)
                                                                .take(maxTasks)
                                                                .map(
                                                                  (
                                                                    task,
                                                                  ) => Container(
                                                                    margin: EdgeInsets.only(
                                                                      bottom:
                                                                          6 *
                                                                          scaleFactor,
                                                                    ),
                                                                    child: Container(
                                                                      padding: EdgeInsets.symmetric(
                                                                        horizontal:
                                                                            6 *
                                                                            scaleFactor,
                                                                        vertical:
                                                                            4 *
                                                                            scaleFactor,
                                                                      ),
                                                                      decoration: BoxDecoration(
                                                                        // 완료 상태에 따라 색상 변경
                                                                        color:
                                                                            task.isCompleted
                                                                            ? const Color(
                                                                                0xFF4CAF50,
                                                                              ).withOpacity(
                                                                                0.8,
                                                                              ) // 초록색 (완료)
                                                                            : const Color(
                                                                                0xFFF44336,
                                                                              ).withOpacity(
                                                                                0.8,
                                                                              ), // 빨간색 (미완료)
                                                                        borderRadius:
                                                                            BorderRadius.circular(
                                                                              8,
                                                                            ),
                                                                      ),
                                                                      child: Row(
                                                                        children: [
                                                                          // 중요도 표시
                                                                          if (task
                                                                              .isImportant) ...[
                                                                            Icon(
                                                                              Icons.star,
                                                                              color: const Color(
                                                                                0xFFFFD700,
                                                                              ),
                                                                              size:
                                                                                  16 *
                                                                                  scaleFactor,
                                                                            ),
                                                                            SizedBox(
                                                                              width:
                                                                                  4 *
                                                                                  scaleFactor,
                                                                            ),
                                                                          ],
                                                                          // 일정 제목
                                                                          Expanded(
                                                                            child: Text(
                                                                              task.title,
                                                                              style: TextStyle(
                                                                                color: Colors.white,
                                                                                fontSize: taskFontSize,
                                                                                fontWeight: FontWeight.w900,
                                                                              ),
                                                                              overflow: TextOverflow.ellipsis,
                                                                            ),
                                                                          ),
                                                                          SizedBox(
                                                                            width:
                                                                                4 *
                                                                                scaleFactor,
                                                                          ),
                                                                          // 시간 표시
                                                                          Text(
                                                                            _formatTime(
                                                                              task.date,
                                                                            ),
                                                                            style: TextStyle(
                                                                              color: Colors.white,
                                                                              fontSize:
                                                                                  taskFontSize *
                                                                                  0.9,
                                                                              fontWeight: FontWeight.w600,
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
                        SizedBox(height: 16 * (0.75 + (fontSize * 0.5))),
                        // 일정 더보기 영역 (고정 높이)
                        Container(
                          height: 80,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: const Color(0xFF2196F3),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
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
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.calendar_today,
                                      color: Colors.white,
                                      size:
                                          (24 + 5) * (0.75 + (fontSize * 0.5)),
                                    ),
                                    const SizedBox(width: 12),
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
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16 * (0.75 + (fontSize * 0.5))),
                  // 하단 버튼들 (고정 크기, 맨 밑에 배치)
                  SizedBox(
                    height: 60,
                    child: Row(
                      children: [
                        // 녹음 버튼
                        Expanded(
                          child: Container(
                            height: 60,
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(color: Colors.black, width: 2),
                            ),
                            child: const Center(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.mic,
                                    color: Colors.white,
                                    size: 28,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    '녹음',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 24),
                        // 설정 버튼
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const SettingsScreen(),
                                ),
                              );
                            },
                            child: Container(
                              height: 60,
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: const Center(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.settings,
                                      size: 28,
                                      color: Colors.black,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      '설정',
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
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
    );
  }
}
