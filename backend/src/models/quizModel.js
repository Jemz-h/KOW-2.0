const db = require('../config/db');
const { serializeQuestionImage } = require('../utils/questionImage');

class QuizModel {
  static async getQuestions(gradeName, subjectName, difficultyName) {
    const activeFilter = db.isOracle() ? 'NVL(q.is_active, 1) = 1' : 'COALESCE(q.is_active, 1) = 1';
    const query = `
      SELECT q.question_id,
             q.question_txt,
             q.question_image,
             q.option_a,
             q.option_b,
             q.option_c,
             q.option_d,
              q.option_a_image,
              q.option_b_image,
              q.option_c_image,
              q.option_d_image,
             q.correct_opt
      FROM questionTb q
      JOIN gradelvlTb g ON q.gradelvl_id = g.gradelvl_id
      JOIN subjectTb s ON q.subject_id = s.subject_id
      JOIN diffTb d ON q.diff_id = d.diff_id
      WHERE UPPER(g.gradelvl) = UPPER(:gradeName)
        AND UPPER(s.subject) = UPPER(:subjectName)
        AND UPPER(d.difficulty) = UPPER(:difficultyName)
        AND ${activeFilter}
      ORDER BY q.question_id
    `;

    const result = await db.execute(query, {
      gradeName,
      subjectName,
      difficultyName
    });

    const letterToIndex = { A: 0, B: 1, C: 2, D: 3 };

    return result.rows.map((row) => {
      const normalizedRow = Object.entries(row).reduce((accumulator, [key, value]) => {
        accumulator[key.toUpperCase()] = value;
        return accumulator;
      }, {});

      const imageBlob = serializeQuestionImage(normalizedRow.QUESTION_IMAGE);
      const choiceImageBlobs = [
        serializeQuestionImage(normalizedRow.OPTION_A_IMAGE),
        serializeQuestionImage(normalizedRow.OPTION_B_IMAGE),
        serializeQuestionImage(normalizedRow.OPTION_C_IMAGE),
        serializeQuestionImage(normalizedRow.OPTION_D_IMAGE),
      ];
      return {
        id: normalizedRow.QUESTION_ID,
        prompt: normalizedRow.QUESTION_TXT,
        imageBlob,
        imagePath: imageBlob,
        funFact: null,
        points: 1,
        choices: [normalizedRow.OPTION_A, normalizedRow.OPTION_B, normalizedRow.OPTION_C, normalizedRow.OPTION_D],
        choiceImageBlobs,
        choiceImages: choiceImageBlobs,
        correctIndex: letterToIndex[String(normalizedRow.CORRECT_OPT || '').toUpperCase()] ?? 0
      };
    });
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

    if (db.isOracle()) {
      await db.execute(
        `INSERT INTO scoreTb (
           stud_id,
           subject_id,
           gradelvl_id,
           diff_id,
           score,
           max_score,
           passed,
           played_at,
           synced_at
         )
         VALUES (
           :studentId,
           :subjectId,
           :gradeLevelId,
           :diffId,
           :score,
           :maxScore,
           :passed,
           SYSDATE,
           SYSDATE
         )`,
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
      return;
    }

    await db.execute(
      `INSERT INTO scoreTb (
         stud_id,
         subject_id,
         gradelvl_id,
         diff_id,
         score,
         max_score,
         passed,
         played_at,
         synced_at
       )
       VALUES (
         :studentId,
         :subjectId,
         :gradeLevelId,
         :diffId,
         :score,
         :maxScore,
         :passed,
         CURRENT_TIMESTAMP,
         CURRENT_TIMESTAMP
       )`,
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