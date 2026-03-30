const db = require('../config/db');

class UserModel {
  static async resolveSexId(sex) {
    if (!sex) {
      return null;
    }

    const normalized = String(sex).trim().toLowerCase();
    const byName = await db.execute(
      `SELECT sex_id
       FROM sexTb
       WHERE LOWER(sex) = :sexName`,
      { sexName: normalized }
    );

    if (byName.rows.length > 0) {
      return byName.rows[0].SEX_ID;
    }

    if (normalized === 'm') return 1;
    if (normalized === 'f') return 2;

    return null;
  }

  static async resolveBarangayId(area) {
    if (!area) {
      return 1;
    }

    const result = await db.execute(
      `SELECT barangay_id
       FROM barangayTb
       WHERE LOWER(barangay_nm) = :areaName`,
      { areaName: String(area).trim().toLowerCase() }
    );

    return result.rows.length > 0 ? result.rows[0].BARANGAY_ID : 1;
  }

  static async createUser(userData) {
    const { firstName, lastName, nickname, birthday, sex, area, teacherId, deviceUuid } = userData;
    const sexId = await this.resolveSexId(sex);
    const barangayId = await this.resolveBarangayId(area);
    
    const query = `
      INSERT INTO studentTb (
        first_name,
        last_name,
        nickname,
        birthday,
        sex_id,
        teacher_id,
        barangay_id,
        device_origin
      )
      VALUES (
        :firstName,
        :lastName,
        :nickname,
        TO_DATE(:birthday, 'YYYY-MM-DD'),
        :sexId,
        :teacherId,
        :barangayId,
        :deviceUuid
      )
      RETURNING stud_id INTO :outId
    `;

    const binds = {
      firstName: firstName,
      lastName: lastName,
      nickname: nickname,
      birthday: birthday,
      sexId,
      teacherId: teacherId || null,
      barangayId,
      deviceUuid: deviceUuid || null,
      outId: { dir: require('oracledb').BIND_OUT, type: require('oracledb').NUMBER }
    };

    const result = await db.execute(query, binds, { autoCommit: true });
    return result.outBinds.outId[0];
  }

  static async findUserByNicknameAndBirthday(nickname, birthday) {
    const query = `
      SELECT s.stud_id AS "STUDENT_ID",
             s.first_name AS "FIRST_NAME",
             s.last_name AS "LAST_NAME",
             s.nickname AS "NICKNAME",
             x.sex AS "SEX",
             b.barangay_nm AS "AREA"
      FROM studentTb s
      LEFT JOIN sexTb x ON s.sex_id = x.sex_id
      LEFT JOIN barangayTb b ON s.barangay_id = b.barangay_id
      WHERE s.nickname = :nickname
        AND TRUNC(s.birthday) = TO_DATE(:birthday, 'YYYY-MM-DD')
    `;
    const result = await db.execute(query, { nickname, birthday });
    
    if (!result.rows[0]) {
      return null;
    }

    return result.rows[0];
  }

  static async updateUserBirthday(userID, newBirthday) {
    const query = `
      UPDATE studentTb
      SET birthday = TO_DATE(:birthday, 'YYYY-MM-DD')
      WHERE stud_id = :userID
    `;
    
    const result = await db.execute(
      query, 
      { userID, birthday: newBirthday },
      { autoCommit: true }
    );
    
    return result.rowsAffected > 0;
  }
}

module.exports = UserModel;