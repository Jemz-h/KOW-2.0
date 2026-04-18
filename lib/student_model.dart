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

  static T? _readAny<T>(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      if (json.containsKey(key) && json[key] != null) {
        return json[key] as T?;
      }
    }
    return null;
  }

  factory Student.fromJson(Map<String, dynamic> json) {
    final studentId = _readAny<num>(json, ['STUDENT_ID', 'student_id', 'studentId'])?.toInt() ?? 0;
    final firstName = (_readAny<String>(json, ['FIRST_NAME', 'first_name', 'firstName']) ?? '').trim();
    final lastName = (_readAny<String>(json, ['LAST_NAME', 'last_name', 'lastName']) ?? '').trim();
    final nickname = (_readAny<String>(json, ['NICKNAME', 'nickname']) ?? '').trim();
    final birthday = _readAny<String>(json, ['BIRTHDAY', 'birthday'])?.trim();
    final sex = (_readAny<String>(json, ['SEX', 'sex']) ?? 'Unknown').trim();
    final area = _readAny<String>(json, ['AREA', 'area'])?.trim();
    final totalScore = _readAny<num>(json, ['TOTAL_SCORE', 'total_score', 'totalScore'])?.toInt() ?? 0;

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
