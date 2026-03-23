const db = require('../config/db');
const { hashBirthday, verifyBirthday } = require('../middleware/passwordHelper');

class UserModel {
  static async createUser(userData) {
    const { firstName, lastName, nickname, birthday, sex, area } = userData;
    // Password is always the birthday (hashed for security)
    // We use nickname as username and birthday as password
    
    const hashedPassword = await hashBirthday(birthday);
    
    const query = `
      INSERT INTO Users (username, password, firstName, lastName, nickName, birthday, gender, barangay)
      VALUES (:username, :password, :firstName, :lastName, :nickName, TO_DATE(:birthday, 'YYYY-MM-DD'), :gender, :barangay)
      RETURNING userID INTO :outId
    `;

    const binds = {
      username: nickname,
      password: hashedPassword,
      firstName: firstName,
      lastName: lastName,
      nickName: nickname,
      birthday: birthday,
      gender: sex,
      barangay: area,
      outId: { dir: require('oracledb').BIND_OUT, type: require('oracledb').NUMBER }
    };

    const result = await db.execute(query, binds, { autoCommit: true });
    return result.outBinds.outId[0];
  }

  static async findUserByNicknameAndBirthday(nickname, birthday) {
    // First get user by nickname
    const query = `
      SELECT userID AS "STUDENT_ID",
             firstName AS "FIRST_NAME",
             lastName AS "LAST_NAME",
             nickName AS "NICKNAME",
             gender AS "SEX",
             barangay AS "AREA",
             password AS "PASSWORD"
      FROM Users
      WHERE nickName = :nickname
    `;
    const result = await db.execute(query, [nickname]);
    
    if (!result.rows[0]) {
      return null;
    }
    
    const user = result.rows[0];
    
    // Verify birthday against hashed password
    const isValid = await verifyBirthday(birthday, user.PASSWORD);
    
    if (!isValid) {
      return null;
    }
    
    // Remove password from returned user object
    delete user.PASSWORD;
    return user;
  }

  static async updateUserBirthday(userID, newBirthday) {
    // When birthday changes, password must change too
    const hashedPassword = await hashBirthday(newBirthday);
    
    const query = `
      UPDATE Users 
      SET birthday = TO_DATE(:birthday, 'YYYY-MM-DD'),
          password = :password
      WHERE userID = :userID
    `;
    
    const result = await db.execute(
      query, 
      { userID, birthday: newBirthday, password: hashedPassword },
      { autoCommit: true }
    );
    
    return result.rowsAffected > 0;
  }
}

module.exports = UserModel;