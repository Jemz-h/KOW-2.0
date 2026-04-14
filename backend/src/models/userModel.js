const db = require('../config/db');

class UserModel {
  static normalizeBirthday(value) {
    if (value === undefined || value === null) {
      return null;
    }

    const raw = String(value).trim();
    if (!raw) {
      return null;
    }

    const match = raw.match(/^(\d{4})-(\d{1,2})-(\d{1,2})$/);
    if (!match) {
      return raw;
    }

    const year = Number(match[1]);
    const month = Number(match[2]);
    const day = Number(match[3]);

    if (month < 1 || month > 12 || day < 1 || day > 31) {
      return raw;
    }

    const mm = String(month).padStart(2, '0');
    const dd = String(day).padStart(2, '0');
    return `${year}-${mm}-${dd}`;
  }

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

  static async resolveAreaId(area) {
    if (!area) {
      return 1;
    }

    const result = await db.execute(
      `SELECT area_id
       FROM areaTb
       WHERE LOWER(area_nm) = :areaName`,
      { areaName: String(area).trim().toLowerCase() }
    );

    return result.rows.length > 0 ? result.rows[0].AREA_ID : 1;
  }

  static async createUser(userData) {
    const { firstName, lastName, nickname, birthday, sex, area, teacherId, deviceUuid, tmpLocalId } = userData;
    const sexId = await this.resolveSexId(sex);
    const areaId = await this.resolveAreaId(area);
    const normalizedBirthday = this.normalizeBirthday(birthday);

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
          area_id,
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
          :areaId,
          :deviceUuid,
          :tmpLocalId
        )
        RETURNING stud_id INTO :outId
      `;

      const binds = {
        firstName,
        lastName,
        nickname,
        birthday: normalizedBirthday,
        sexId,
        teacherId: teacherId || null,
        areaId,
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
         area_id,
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
         :areaId,
         :deviceUuid,
         :tmpLocalId
       )`,
      {
        firstName,
        lastName,
        nickname,
        birthday: normalizedBirthday,
        sexId,
        teacherId: teacherId || null,
        areaId,
        deviceUuid: deviceUuid || null,
        tmpLocalId: tmpLocalId || null
      },
      { autoCommit: true, returning: 'lastId' }
    );

    return result.outBinds.outId[0];
  }

  static async findUserByNicknameAndBirthday(nickname, birthday) {
    const normalizedBirthday = this.normalizeBirthday(birthday);
    const dateFilter = db.isOracle()
      ? `TRUNC(s.birthday) = TO_DATE(:birthday, 'YYYY-MM-DD')`
      : `date(s.birthday) = date(:birthday)`;
    const birthdaySelect = db.isOracle()
      ? `TO_CHAR(s.birthday, 'YYYY-MM-DD')`
      : `date(s.birthday)`;

    const query = `
      SELECT s.stud_id AS "STUDENT_ID",
             s.first_name AS "FIRST_NAME",
             s.last_name AS "LAST_NAME",
             s.nickname AS "NICKNAME",
             ${birthdaySelect} AS "BIRTHDAY",
             x.sex AS "SEX",
             COALESCE(a.area_nm, b.barangay_nm) AS "AREA"
      FROM studentTb s
      LEFT JOIN sexTb x ON s.sex_id = x.sex_id
      LEFT JOIN areaTb a ON s.area_id = a.area_id
      LEFT JOIN barangayTb b ON s.barangay_id = b.barangay_id
      WHERE s.nickname = :nickname
        AND ${dateFilter}
    `;
    const result = await db.execute(query, { nickname, birthday: normalizedBirthday });
    
    if (!result.rows[0]) {
      return null;
    }

    return result.rows[0];
  }

  static async updateUserBirthday(userID, newBirthday) {
    const normalizedBirthday = this.normalizeBirthday(newBirthday);
    const query = db.isOracle()
      ? `UPDATE studentTb
         SET birthday = TO_DATE(:birthday, 'YYYY-MM-DD')
         WHERE stud_id = :userID`
      : `UPDATE studentTb
         SET birthday = :birthday
         WHERE stud_id = :userID`;
    
    const result = await db.execute(
      query, 
      { userID, birthday: normalizedBirthday },
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
    const areaId = await this.resolveAreaId(area);
    const normalizedBirthday = this.normalizeBirthday(birthday);

    const query = db.isOracle()
      ? `UPDATE studentTb
         SET first_name = :firstName,
             last_name = :lastName,
             nickname = :nickname,
             birthday = TO_DATE(:birthday, 'YYYY-MM-DD'),
             sex_id = :sexId,
         area_id = :areaId,
             updated_at = SYSTIMESTAMP
         WHERE stud_id = :userId`
      : `UPDATE studentTb
         SET first_name = :firstName,
             last_name = :lastName,
             nickname = :nickname,
             birthday = :birthday,
             sex_id = :sexId,
         area_id = :areaId,
             updated_at = CURRENT_TIMESTAMP
         WHERE stud_id = :userId`;

    const result = await db.execute(
      query,
      {
        userId,
        firstName,
        lastName,
        nickname,
        birthday: normalizedBirthday,
        sexId,
        areaId,
      },
      { autoCommit: true }
    );

    return result.rowsAffected > 0;
  }

  static async reconcileIdentityById({
    userId,
    firstName,
    lastName,
    nickname,
    birthday,
  }) {
    const normalizedBirthday = this.normalizeBirthday(birthday);

    const query = db.isOracle()
      ? `UPDATE studentTb
         SET first_name = :firstName,
             last_name = :lastName,
             nickname = :nickname,
             birthday = TO_DATE(:birthday, 'YYYY-MM-DD'),
             updated_at = SYSTIMESTAMP
         WHERE stud_id = :userId`
      : `UPDATE studentTb
         SET first_name = :firstName,
             last_name = :lastName,
             nickname = :nickname,
             birthday = :birthday,
             updated_at = CURRENT_TIMESTAMP
         WHERE stud_id = :userId`;

    const result = await db.execute(
      query,
      {
        userId,
        firstName,
        lastName,
        nickname,
        birthday: normalizedBirthday,
      },
      { autoCommit: true }
    );

    return result.rowsAffected > 0;
  }
}

module.exports = UserModel;