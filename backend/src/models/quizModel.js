const db = require('../config/db');

class QuizModel {
  static async getQuestions(gradeName, subjectName, difficultyName) {
    const query = `
      SELECT q.question_id,
             q.question_txt,
             q.option_a,
             q.option_b,
             q.option_c,
             q.option_d,
             q.correct_opt
      FROM questionTb q
      JOIN gradelvlTb g ON q.gradelvl_id = g.gradelvl_id
      JOIN subjectTb s ON q.subject_id = s.subject_id
      JOIN diffTb d ON q.diff_id = d.diff_id
      WHERE UPPER(g.gradelvl) = UPPER(:gradeName)
        AND UPPER(s.subject) = UPPER(:subjectName)
        AND UPPER(d.difficulty) = UPPER(:difficultyName)
        AND NVL(q.is_active, 1) = 1
      ORDER BY q.question_id
    `;

    const result = await db.execute(query, {
      gradeName,
      subjectName,
      difficultyName
    });

    const letterToIndex = { A: 0, B: 1, C: 2, D: 3 };

    return result.rows.map((row) => ({
      id: row.QUESTION_ID,
      prompt: row.QUESTION_TXT,
      imagePath: null,
      funFact: null,
      points: 1,
      choices: [row.OPTION_A, row.OPTION_B, row.OPTION_C, row.OPTION_D],
      correctIndex: letterToIndex[String(row.CORRECT_OPT || '').toUpperCase()] ?? 0
    }));
  }

  static async submitScore(studentId, grade, subject, difficulty, score, total) {
    const idQuery = `
      SELECT g.gradelvl_id,
             s.subject_id,
             d.diff_id
      FROM gradelvlTb g
      CROSS JOIN subjectTb s
      CROSS JOIN diffTb d
      WHERE UPPER(g.gradelvl) = UPPER(:grade)
        AND UPPER(s.subject) = UPPER(:subject)
        AND UPPER(d.difficulty) = UPPER(:difficulty)
    `;
    const idRes = await db.execute(idQuery, { grade, subject, difficulty });
    if (!idRes.rows || idRes.rows.length === 0) {
      throw new Error('Grade/subject/difficulty mapping not found');
    }

    const ids = idRes.rows[0];
    const maxScore = Number(total) > 0 ? Number(total) : 10;
    const passed = Number(score) / maxScore >= 0.7 ? 1 : 0;

    await db.execute(
      `BEGIN
         sp_upload_score(
           p_stud_id      => :studentId,
           p_subject_id   => :subjectId,
           p_gradelvl_id  => :gradeLevelId,
           p_diff_id      => :diffId,
           p_score        => :score,
           p_max_score    => :maxScore,
           p_passed       => :passed,
           p_played_at    => SYSDATE,
           p_device_uuid  => NULL
         );
         sp_refresh_analytics(
           p_stud_id      => :studentId,
           p_subject_id   => :subjectId,
           p_gradelvl_id  => :gradeLevelId
         );
       END;`,
      {
        studentId,
        subjectId: ids.SUBJECT_ID,
        gradeLevelId: ids.GRADELVL_ID,
        diffId: ids.DIFF_ID,
        score,
        maxScore,
        passed
      },
      { autoCommit: true }
    );
  }

  static async getScores(studentId) {
    const query = `
      SELECT sc.score,
             sc.max_score,
             sc.passed,
             sc.played_at,
             g.gradelvl,
             s.subject,
             d.difficulty
      FROM scoreTb sc
      JOIN gradelvlTb g ON sc.gradelvl_id = g.gradelvl_id
      JOIN subjectTb s ON sc.subject_id = s.subject_id
      JOIN diffTb d ON sc.diff_id = d.diff_id
      WHERE sc.stud_id = :studentId
      ORDER BY sc.played_at DESC
    `;
    const result = await db.execute(query, { studentId });
    return result.rows;
  }
}

module.exports = QuizModel;