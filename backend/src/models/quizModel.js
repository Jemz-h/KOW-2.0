const db = require('../config/db');

class QuizModel {
  static async getQuestions(gradeName, subjectName, difficultyName) {
    const query = `
      SELECT q.questionID,
             q.questionText,
             q.questionImageURL,
             q.correctAnswer,
             q.points,
             ac.choiceID,
             ac.choiceText,
             ac.isCorrect
      FROM Question q
      JOIN Level_Table l ON q.levelID = l.levelID
      JOIN Grade g ON l.gradeID = g.gradeID
      JOIN Subject s ON g.subjectID = s.subjectID
      JOIN Difficulty d ON l.difficultyID = d.difficultyID
      LEFT JOIN Answer_Choice ac ON q.questionID = ac.questionID
      WHERE UPPER(g.gradeName) = UPPER(:gradeName)
        AND UPPER(s.subjectName) = UPPER(:subjectName)
        AND UPPER(d.difficultyName) = UPPER(:difficultyName)
      ORDER BY q.orderNumber, ac.orderNumber
    `;

    const result = await db.execute(query, {
      gradeName,
      subjectName,
      difficultyName
    });

    // Group answers by question
    const questionsMap = {};
    for (const row of result.rows) {
      if (!questionsMap[row.QUESTIONID]) {
        questionsMap[row.QUESTIONID] = {
          id: row.QUESTIONID,
          prompt: row.QUESTIONTEXT,
          imagePath: row.QUESTIONIMAGEURL,
          funFact: row.CORRECTANSWER, // assuming this maps
          points: row.POINTS,
          choices: [],
          correctIndex: 0
        };
      }
      
      if (row.CHOICETEXT) {
        questionsMap[row.QUESTIONID].choices.push(row.CHOICETEXT);
        if (row.ISCORRECT === 1) {
          questionsMap[row.QUESTIONID].correctIndex = questionsMap[row.QUESTIONID].choices.length - 1;
        }
      }
    }

    return Object.values(questionsMap);
  }

  static async submitScore(studentId, grade, subject, difficulty, score, total) {
    // Attempt to find the specific levelID
    const levelQuery = `
      SELECT l.levelID
      FROM Level_Table l
      JOIN Grade g ON l.gradeID = g.gradeID
      JOIN Subject s ON g.subjectID = s.subjectID
      JOIN Difficulty d ON l.difficultyID = d.difficultyID
      WHERE UPPER(g.gradeName) = UPPER(:grade)
        AND UPPER(s.subjectName) = UPPER(:subject)
        AND UPPER(d.difficultyName) = UPPER(:difficulty)
      FETCH FIRST 1 ROWS ONLY
    `;
    const levelRes = await db.execute(levelQuery, { grade, subject, difficulty });
    if (!levelRes.rows || levelRes.rows.length === 0) {
      throw new Error('Level not found for the given grade, subject, and difficulty');
    }
    
    const levelId = levelRes.rows[0].LEVELID;

    // Insert progress
    const insertQuery = `
      INSERT INTO User_Progress (userID, levelID, score, completionStatus, dateCompleted)
      VALUES (:userId, :levelId, :score, :status, SYSDATE)
    `;
    
    const status = score >= Math.floor(total / 2) ? 'PASSED' : 'FAILED';
    
    await db.execute(insertQuery, {
      userId: studentId,
      levelId: levelId,
      score: score,
      status: status
    }, { autoCommit: true });
  }

  static async getScores(studentId) {
    const query = `
      SELECT up.score,
             up.completionStatus,
             up.dateCompleted,
             g.gradeName,
             s.subjectName,
             d.difficultyName
      FROM User_Progress up
      JOIN Level_Table l ON up.levelID = l.levelID
      JOIN Grade g ON l.gradeID = g.gradeID
      JOIN Subject s ON g.subjectID = s.subjectID
      JOIN Difficulty d ON l.difficultyID = d.difficultyID
      WHERE up.userID = :studentId
      ORDER BY up.dateCompleted DESC
    `;
    const result = await db.execute(query, { studentId });
    return result.rows;
  }
}

module.exports = QuizModel;