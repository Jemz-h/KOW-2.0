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
    const { firstName, lastName, nickname, birthday, sex, area, teacherId, deviceUuid, tmpLocalId } = userData;
    const sexId = await this.resolveSexId(sex);
    const barangayId = await this.resolveBarangayId(area);

    if (db.isOracle()) {
      const driver = db.getDriver();
      const query = `
        INSERT INTO studentTb (
          first_name,
          last_name,
          nickname,
          birthday,
          sex_id,
          teacher_id,
          barangay_id,
          device_origin,
          tmp_local_id
        )
        VALUES (
          :firstName,
          :lastName,
          :nickname,
          TO_DATE(:birthday, 'YYYY-MM-DD'),
          :sexId,
          :teacherId,
          :barangayId,
          :deviceUuid,
          :tmpLocalId
        )
        RETURNING stud_id INTO :outId
      `;

      const binds = {
        firstName,
        lastName,
        nickname,
        birthday,
        sexId,
        teacherId: teacherId || null,
        barangayId,
        deviceUuid: deviceUuid || null,
        tmpLocalId: tmpLocalId || null,
        outId: { dir: driver.BIND_OUT, type: driver.NUMBER }
      };

      const result = await db.execute(query, binds, { autoCommit: true });
      return result.outBinds.outId[0];
    }

    const result = await db.execute(
      `INSERT INTO studentTb (
         first_name,
         last_name,
         nickname,
         birthday,
         sex_id,
         teacher_id,
         barangay_id,
         device_origin,
         tmp_local_id
       )
       VALUES (
         :firstName,
         :lastName,
         :nickname,
         :birthday,
         :sexId,
         :teacherId,
         :barangayId,
         :deviceUuid,
         :tmpLocalId
       )`,
      {
        firstName,
        lastName,
        nickname,
        birthday,
        sexId,
        teacherId: teacherId || null,
        barangayId,
        deviceUuid: deviceUuid || null,
        tmpLocalId: tmpLocalId || null
      },
      { autoCommit: true, returning: 'lastId' }
    );

    return result.outBinds.outId[0];
  }

  static async findUserByNicknameAndBirthday(nickname, birthday) {
    const dateFilter = db.isOracle()
      ? `TRUNC(s.birthday) = TO_DATE(:birthday, 'YYYY-MM-DD')`
      : `date(s.birthday) = date(:birthday)`;

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
        AND ${dateFilter}
    `;
    const result = await db.execute(query, { nickname, birthday });
    
    if (!result.rows[0]) {
      return null;
    }

    return result.rows[0];
  }

  static async updateUserBirthday(userID, newBirthday) {
    const query = db.isOracle()
      ? `UPDATE studentTb
         SET birthday = TO_DATE(:birthday, 'YYYY-MM-DD')
         WHERE stud_id = :userID`
      : `UPDATE studentTb
         SET birthday = :birthday
         WHERE stud_id = :userID`;
    
    const result = await db.execute(
      query, 
      { userID, birthday: newBirthday },
      { autoCommit: true }
    );
    
    return result.rowsAffected > 0;
  }

  static async updateUserProfile({
    userId,
    firstName,
    lastName,
    nickname,
    birthday,
    sex,
    area,
  }) {
    const sexId = await this.resolveSexId(sex);
    const barangayId = await this.resolveBarangayId(area);

    const query = db.isOracle()
      ? `UPDATE studentTb
         SET first_name = :firstName,
             last_name = :lastName,
             nickname = :nickname,
             birthday = TO_DATE(:birthday, 'YYYY-MM-DD'),
             sex_id = :sexId,
             barangay_id = :barangayId,
             updated_at = SYSTIMESTAMP
         WHERE stud_id = :userId`
      : `UPDATE studentTb
         SET first_name = :firstName,
             last_name = :lastName,
             nickname = :nickname,
             birthday = :birthday,
             sex_id = :sexId,
             barangay_id = :barangayId,
             updated_at = CURRENT_TIMESTAMP
         WHERE stud_id = :userId`;

    const result = await db.execute(
      query,
      {
        userId,
        firstName,
        lastName,
        nickname,
        birthday,
        sexId,
        barangayId,
      },
      { autoCommit: true }
    );

    return result.rowsAffected > 0;
  }
}

module.exports = UserModel;