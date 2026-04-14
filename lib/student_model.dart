/// Data model for a KOW student returned by the backend.
class Student {
  final int studentId;
  final String firstName;
  final String lastName;
  final String nickname;
  final String? birthday;
  final String sex;
  final String? area;
  final int totalScore;

  const Student({
    required this.studentId,
    required this.firstName,
    required this.lastName,
    required this.nickname,
    this.birthday,
    required this.sex,
    this.area,
    required this.totalScore,
  });

  static T? _read<T>(Map<String, dynamic> json, String upper, String lower) {
    final value = json.containsKey(upper) ? json[upper] : json[lower];
    return value as T?;
  }

  factory Student.fromJson(Map<String, dynamic> json) {
    final studentId = _read<num>(json, 'STUDENT_ID', 'student_id')?.toInt() ?? 0;
    final firstName = (_read<String>(json, 'FIRST_NAME', 'first_name') ?? '').trim();
    final lastName = (_read<String>(json, 'LAST_NAME', 'last_name') ?? '').trim();
    final nickname = (_read<String>(json, 'NICKNAME', 'nickname') ?? '').trim();
    final birthday = _read<String>(json, 'BIRTHDAY', 'birthday')?.trim();
    final sex = (_read<String>(json, 'SEX', 'sex') ?? 'Unknown').trim();
    final area = _read<String>(json, 'AREA', 'area')?.trim();
    final totalScore = _read<num>(json, 'TOTAL_SCORE', 'total_score')?.toInt() ?? 0;

    return Student(
      studentId: studentId,
      firstName: firstName,
      lastName: lastName,
      nickname: nickname,
      birthday: birthday,
      sex: sex,
      area: area,
      totalScore: totalScore,
    );
  }

  Map<String, dynamic> toJson() => {
    'STUDENT_ID':  studentId,
    'FIRST_NAME':  firstName,
    'LAST_NAME':   lastName,
    'NICKNAME':    nickname,
    'BIRTHDAY':    birthday,
    'SEX':         sex,
    'AREA':        area,
    'TOTAL_SCORE': totalScore,
  };
}
