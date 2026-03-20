const db = require('../config/db');

class UserModel {
  static async createUser(userData) {
    const { firstName, lastName, nickname, birthday, sex, area } = userData;
    // Map birthday to a proper date format if needed, or store it as string.
    // The Users table requires username and password, which the frontend doesn't provide.
    // We will use nickname as username and birthday as password.
    
    const query = `
      INSERT INTO Users (username, password, firstName, lastName, nickName, gender, barangay)
      VALUES (:username, :password, :firstName, :lastName, :nickName, :gender, :barangay)
      RETURNING userID INTO :outId
    `;

    const binds = {
      username: nickname,
      password: birthday, 
      firstName: firstName,
      lastName: lastName,
      nickName: nickname,
      gender: sex,
      barangay: area,
      outId: { dir: require('oracledb').BIND_OUT, type: require('oracledb').NUMBER }
    };

    const result = await db.execute(query, binds, { autoCommit: true });
    return result.outBinds.outId[0];
  }

  static async findUserByNicknameAndBirthday(nickname, birthday) {
    const query = `
      SELECT userID AS "STUDENT_ID",
             firstName AS "FIRST_NAME",
             lastName AS "LAST_NAME",
             nickName AS "NICKNAME",
             gender AS "SEX",
             barangay AS "AREA"
      FROM Users
      WHERE nickName = :nickname AND password = :birthday
    `;
    const result = await db.execute(query, [nickname, birthday]);
    return result.rows[0];
  }
}

module.exports = UserModel;