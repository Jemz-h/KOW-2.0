/// Data model for a KOW student returned by the backend.
class Student {
  final int studentId;
  final String firstName;
  final String lastName;
  final String nickname;
  final String sex;
  final String? area;
  final int totalScore;

  const Student({
    required this.studentId,
    required this.firstName,
    required this.lastName,
    required this.nickname,
    required this.sex,
    this.area,
    required this.totalScore,
  });

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      studentId:  (json['STUDENT_ID']  as num).toInt(),
      firstName:  json['FIRST_NAME']   as String,
      lastName:   json['LAST_NAME']    as String,
      nickname:   json['NICKNAME']     as String,
      sex:        json['SEX']          as String,
      area:       json['AREA']         as String?,
      totalScore: (json['TOTAL_SCORE'] as num? ?? 0).toInt(),
    );
  }

  Map<String, dynamic> toJson() => {
    'STUDENT_ID':  studentId,
    'FIRST_NAME':  firstName,
    'LAST_NAME':   lastName,
    'NICKNAME':    nickname,
    'SEX':         sex,
    'AREA':        area,
    'TOTAL_SCORE': totalScore,
  };
}
