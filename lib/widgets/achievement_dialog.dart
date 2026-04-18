import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../api_service.dart';
import '../local_sync_store.dart';

class _AchievementStats {
  final String nickname;
  final String totalTimePlayed;
  final int bronzeTokens;
  final int silverTokens;
  final int goldTokens;
  final int mathLessonsCompleted;
  final int totalLevelsPassed;

  const _AchievementStats({
    required this.nickname,
    required this.totalTimePlayed,
    required this.bronzeTokens,
    required this.silverTokens,
    required this.goldTokens,
    required this.mathLessonsCompleted,
    required this.totalLevelsPassed,
  });

  static const empty = _AchievementStats(
    nickname: 'STUDENT',
    totalTimePlayed: '0h 0m',
    bronzeTokens: 0,
    silverTokens: 0,
    goldTokens: 0,
    mathLessonsCompleted: 0,
    totalLevelsPassed: 0,
  );
}

void showAchievementDialog(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (context) {
      final screenWidth = MediaQuery.of(context).size.width;
      final screenHeight = MediaQuery.of(context).size.height;
      final isTablet = screenWidth > 600;

      final dialogWidth = isTablet ? screenWidth * 0.70 : screenWidth * 0.88;
      final scale = isTablet ? 1.4 : 1.0;
      final hFactor = (screenHeight / 750).clamp(0.75, 1.2);

      final titleFontSize = 22.0 * scale * hFactor;
      final sectionTitleFontSize = 18.0 * scale * hFactor;
      final bodyFontSize = 13.0 * scale * hFactor;
      final nicknameFontSize = 22.0 * scale * hFactor;
      final sectionVertPad = 12.0 * scale * hFactor;
      final sectionMargin = 6.0 * scale * hFactor;

      TextStyle strokedText({
        required double fontSize,
        required Color color,
        FontWeight fontWeight = FontWeight.w900,
        double letterSpacing = 1.0,
      }) =>
          TextStyle(
            fontSize: fontSize,
            fontWeight: fontWeight,
            color: color,
            letterSpacing: letterSpacing,
            shadows: const [
              Shadow(offset: Offset(-1, -1), color: Colors.black, blurRadius: 1),
              Shadow(offset: Offset(1, -1), color: Colors.black, blurRadius: 1),
              Shadow(offset: Offset(-1, 1), color: Colors.black, blurRadius: 1),
              Shadow(offset: Offset(1, 1), color: Colors.black, blurRadius: 1),
            ],
          );

      const panelGradient = RadialGradient(
        center: Alignment.center,
        radius: 1.0,
        colors: [Color(0xFF48B5BB), Color(0xFF36888D)],
      );

      Widget sectionBox({required Widget child}) => Container(
            width: double.infinity,
            margin: EdgeInsets.only(bottom: sectionMargin),
            decoration: BoxDecoration(
              gradient: panelGradient,
              borderRadius: BorderRadius.circular(10 * scale),
              boxShadow: const [
                BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))
              ],
            ),
            padding: EdgeInsets.symmetric(
              horizontal: 12 * scale,
              vertical: sectionVertPad,
            ),
            child: child,
          );

      Future<_AchievementStats> loadStats() async {
        final profile = await ApiService.getCurrentProfile();
        final session = await LocalSyncStore.instance.getActiveSession();

        final nickname = _nonEmptyString(
              _readValue(profile, const ['nickname', 'NICKNAME']),
            ) ??
            _nonEmptyString(session?['nickname']) ??
            _AchievementStats.empty.nickname;

        final studentIdValue = _readValue(
          profile,
          const ['student_id', 'studentId', 'STUDENT_ID', 'STUDENTID'],
        );
        final studentId = _asInt(studentIdValue);
        if (studentId == null) {
          return _AchievementStats(
            nickname: nickname,
            totalTimePlayed: _AchievementStats.empty.totalTimePlayed,
            bronzeTokens: _AchievementStats.empty.bronzeTokens,
            silverTokens: _AchievementStats.empty.silverTokens,
            goldTokens: _AchievementStats.empty.goldTokens,
            mathLessonsCompleted: _AchievementStats.empty.mathLessonsCompleted,
            totalLevelsPassed: _AchievementStats.empty.totalLevelsPassed,
          );
        }

        List<Map<String, dynamic>> remoteProgress = const [];
        List<Map<String, dynamic>> remoteScores = const [];

        try {
          remoteProgress = await ApiService.getProgress(studentId);
        } catch (_) {
          remoteProgress = const [];
        }

        try {
          remoteScores = await ApiService.getScores(studentId);
        } catch (_) {
          remoteScores = const [];
        }

        final pendingProgress =
            await LocalSyncStore.instance.getPendingProgressForStudent(studentId);
        final pendingScores =
            await LocalSyncStore.instance.getPendingScoresForStudent(studentId);

        final progress = <Map<String, dynamic>>[
          ...remoteProgress,
          ...pendingProgress,
        ];
        final scores = <Map<String, dynamic>>[
          ...remoteScores,
          ...pendingScores,
        ];

        final totalTimeSeconds = progress.fold<int>(0, (sum, row) {
          final timePlayed = _asInt(_readValue(
            row,
            const [
              'total_time_played',
              'TOTAL_TIME_PLAYED',
              'totalTimePlayed',
              'TOTALTIMEPLAYED',
              'time_spent',
              'TIME_SPENT',
            ],
          ));
          return sum + (timePlayed ?? 0);
        });

        final totalTimePlayed = _formatDuration(totalTimeSeconds);

        var bronzeTokens = 0;
        var silverTokens = 0;
        var goldTokens = 0;
        for (final row in scores) {
          final score = (_asNum(_readValue(row, const ['score', 'SCORE'])) ?? 0).toDouble();
          final maxScore = (_asNum(_readValue(
            row,
            const ['max_score', 'MAX_SCORE', 'total', 'TOTAL'],
          )) ??
                  0)
              .toDouble();
          final passed = _asBool(_readValue(row, const ['passed', 'PASSED'])) ||
              (maxScore > 0 && (score / maxScore) >= 0.7);

          if (maxScore > 0 && score >= maxScore) {
            goldTokens++;
          } else if (passed) {
            silverTokens++;
          } else {
            bronzeTokens++;
          }
        }

        final mathLessonsCompleted = progress.where((row) {
          final subject = _nonEmptyString(
                    _readValue(row, const ['subject', 'SUBJECT']),
                  )
                  ?.toUpperCase() ??
              '';
          final diff = _asInt(_readValue(
            row,
            const ['highest_diff_passed', 'HIGHEST_DIFF_PASSED', 'diffId', 'DIFFID'],
          ));
          final completed = _asBool(_readValue(row, const ['completed', 'COMPLETED'])) ||
              ((diff ?? 0) > 0);
          return (subject == 'MATH' || subject == 'MATHEMATICS') && completed;
        }).length;

        final totalLevelsPassed = progress.where((row) {
          final diff = _asInt(_readValue(
            row,
            const ['highest_diff_passed', 'HIGHEST_DIFF_PASSED', 'diffId', 'DIFFID'],
          ));
          final completed = _asBool(_readValue(row, const ['completed', 'COMPLETED']));
          return completed || ((diff ?? 0) > 0);
        }).length;

        return _AchievementStats(
          nickname: nickname,
          totalTimePlayed: totalTimePlayed,
          bronzeTokens: bronzeTokens,
          silverTokens: silverTokens,
          goldTokens: goldTokens,
          mathLessonsCompleted: mathLessonsCompleted,
          totalLevelsPassed: totalLevelsPassed,
        );
      }

      return FutureBuilder<_AchievementStats>(
        future: loadStats(),
        builder: (context, snapshot) {
          final stats = snapshot.data ?? _AchievementStats.empty;
          final isLoading = snapshot.connectionState == ConnectionState.waiting;

          return Stack(
            children: [
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(color: Colors.transparent),
              ),

              Center(
                child: Material(
                  color: Colors.transparent,
                  child: Stack(
                    children: [
                      Container(
                        width: dialogWidth,
                        decoration: BoxDecoration(
                          color: const Color(0xFFD9D9D9),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFBBBBBB), width: 2),
                          boxShadow: const [
                            BoxShadow(color: Colors.black38, blurRadius: 16, offset: Offset(0, 8))
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [

                            // ── HEADER ──
                            Padding(
                              padding: EdgeInsets.symmetric(vertical: 14 * scale * hFactor),
                              child: Center(
                                child: Text(
                                  'STATISTICS',
                                  style: strokedText(
                                    fontSize: titleFontSize,
                                    color: Colors.white,
                                    letterSpacing: 2,
                                  ),
                                ),
                              ),
                            ),

                            // ── INNER PANEL ──
                            Container(
                              margin: EdgeInsets.fromLTRB(10 * scale, 0, 10 * scale, 12 * scale),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: const [
                                  BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4))
                                ],
                              ),
                              padding: EdgeInsets.symmetric(
                                horizontal: 10 * scale,
                                vertical: 10 * scale * hFactor,
                              ),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.topCenter,
                                child: SizedBox(
                                  width: dialogWidth - (10 * scale * 2) - (10 * scale * 2),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [

                                      // NICKNAME
                                      Container(
                                        width: double.infinity,
                                        margin: EdgeInsets.only(bottom: sectionMargin),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF3C467B),
                                          borderRadius: BorderRadius.circular(10 * scale),
                                        ),
                                        padding: EdgeInsets.symmetric(vertical: 12 * scale * hFactor),
                                        child: Center(
                                          child: Text(
                                            isLoading ? 'LOADING...' : stats.nickname.toUpperCase(),
                                            style: strokedText(
                                              fontSize: nicknameFontSize,
                                              color: const Color(0xFFFFA500),
                                            ),
                                          ),
                                        ),
                                      ),

                                      // TOTAL TIME
                                      sectionBox(
                                        child: Row(
                                          children: [
                                            Image.asset(
                                              'assets/icons/back.png',
                                              width: 52 * scale * hFactor,
                                              height: 52 * scale * hFactor,
                                              errorBuilder: (c, e, s) => Icon(
                                                Icons.hourglass_bottom,
                                                size: 52 * scale * hFactor,
                                                color: Colors.white,
                                              ),
                                            ),
                                            SizedBox(width: 14 * scale),
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text('Total Time',
                                                    style: strokedText(fontSize: bodyFontSize, color: Colors.white)),
                                                Text('Played:',
                                                    style: strokedText(fontSize: bodyFontSize, color: Colors.white)),
                                                Text(stats.totalTimePlayed,
                                                    style: strokedText(
                                                        fontSize: bodyFontSize, color: Colors.white70)),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),

                                      // TOKENS
                                      sectionBox(
                                        child: Column(
                                          children: [
                                            Text('TOKENS EARNED', style: strokedText(fontSize: sectionTitleFontSize, color: Colors.white)),
                                            SizedBox(height: 10),
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                              children: [
                                                _CoinBadge(assetPath: 'assets/icons/bronze.svg', count: stats.bronzeTokens),
                                                _CoinBadge(assetPath: 'assets/icons/silver.svg', count: stats.silverTokens),
                                                _CoinBadge(assetPath: 'assets/icons/gold.svg', count: stats.goldTokens),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),

                                      // COMPLETION
                                      sectionBox(
                                        child: Column(
                                          children: [
                                            Text('COMPLETION', style: strokedText(fontSize: sectionTitleFontSize, color: Colors.white)),
                                            Text('Math Lessons Completed: ${stats.mathLessonsCompleted}', style: strokedText(fontSize: bodyFontSize, color: Colors.white)),
                                            Text('Total Levels Passed: ${stats.totalLevelsPassed}', style: strokedText(fontSize: bodyFontSize, color: Colors.white)),
                                          ],
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

                      // ❌ X BUTTON (TOP RIGHT)
                      Positioned(
                        top: 10 * scale,
                        right: 10 * scale,
                        child: GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: SvgPicture.asset(
                            'assets/icons/x.svg',
                            width: 32 * scale,
                            height: 32 * scale,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      );
    },
  );
}

String _formatDuration(int totalMinutes) {
  if (totalMinutes <= 0) {
    return '0h 0m';
  }
  final hours = totalMinutes ~/ 3600;
  final minutes = (totalMinutes % 3600) ~/ 60;
  return '${hours}h ${minutes}m';
}

dynamic _readValue(Map<String, dynamic>? row, List<String> keys) {
  if (row == null) return null;
  for (final key in keys) {
    if (row.containsKey(key)) {
      return row[key];
    }
  }
  return null;
}

String? _nonEmptyString(dynamic value) {
  if (value is! String) return null;
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

num? _asNum(dynamic value) {
  if (value is num) return value;
  if (value is String) return num.tryParse(value.trim());
  return null;
}

int? _asInt(dynamic value) {
  final parsed = _asNum(value);
  return parsed?.toInt();
}

bool _asBool(dynamic value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    final normalized = value.trim().toLowerCase();
    return normalized == '1' || normalized == 'true' || normalized == 'yes';
  }
  return false;
}

class _CoinBadge extends StatelessWidget {
  final String assetPath;
  final int count;

  const _CoinBadge({
    required this.assetPath,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SvgPicture.asset(assetPath, width: 50, height: 50),
        const SizedBox(width: 6),
        Text('x$count', style: const TextStyle(color: Colors.white)),
      ],
    );
  }
}
