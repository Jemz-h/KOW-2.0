const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const crypto = require('crypto');
const UserModel = require('../models/userModel');
const {
  createStudent,
  findStudentById,
} = require('../repositories/students.repository');
const db = require('../config/db');
const { jwtSecret, dbMode } = require('../config/env');
const { normalizeDateOnly } = require('../utils/dateTime');

const tokenSecret = process.env.TOKEN_SECRET || process.env.JWT_SECRET || 'kow-dev-secret-change-me';

function base64UrlEncode(value) {
  return Buffer.from(value)
    .toString('base64')
    .replace(/=/g, '')
    .replace(/\+/g, '-')
    .replace(/\//g, '_');
}

function signCustomToken(payload) {
  const header = { alg: 'HS256', typ: 'JWT' };
  const encodedHeader = base64UrlEncode(JSON.stringify(header));
  const encodedPayload = base64UrlEncode(JSON.stringify(payload));
  const data = `${encodedHeader}.${encodedPayload}`;
  const signature = crypto
    .createHmac('sha256', tokenSecret)
    .update(data)
    .digest('base64')
    .replace(/=/g, '')
    .replace(/\+/g, '-')
    .replace(/\//g, '_');

  return `${data}.${signature}`;
}

function normalizeDateKey(input) {
  return normalizeDateOnly(input);
}

function sha256(value) {
  return crypto.createHash('sha256').update(String(value)).digest('hex');
}

async function verifyAdminPassword(password, passwordHash) {
  const normalizedHash = String(passwordHash || '').trim();
  if (!normalizedHash) {
    return false;
  }

  if (normalizedHash.startsWith('sha256$')) {
    return normalizedHash === `sha256$${sha256(password)}`;
  }

  if (normalizedHash.startsWith('$2')) {
    return bcrypt.compare(String(password), normalizedHash);
  }

  return normalizedHash === String(password);
}

async function adminLogin(req, res, next) {
  try {
    const username = String(req.body?.username || '').trim();
    const password = String(req.body?.password || '');

    if (!username || !password) {
      return res.status(400).json({ error: 'username and password are required.' });
    }

    const result = await db.execute(
      `SELECT admin_id,
              username,
              password_hash,
              role
       FROM adminTb
       WHERE LOWER(username) = LOWER(:username)`,
      { username }
    );

    const row = result.rows[0];
    if (!row) {
      return res.status(401).json({ error: 'Invalid credentials.' });
    }

    const adminId = Number(row.ADMIN_ID ?? row.admin_id);
    const resolvedUsername = row.USERNAME ?? row.username ?? username;
    const role = row.ROLE ?? row.role ?? 'admin';
    const passwordHash = row.PASSWORD_HASH ?? row.password_hash;
    const isValid = await verifyAdminPassword(password, passwordHash);

    if (!isValid || !Number.isFinite(adminId)) {
      return res.status(401).json({ error: 'Invalid credentials.' });
    }

    const now = Math.floor(Date.now() / 1000);
    const payload = {
      sub: String(adminId),
      adminId,
      username: resolvedUsername,
      role,
      iat: now,
      exp: now + (60 * 60 * 8),
    };

    const token = signCustomToken(payload);
    const lastLoginExpression = db.isOracle() ? 'SYSDATE' : 'CURRENT_TIMESTAMP';
    await db.execute(
      `UPDATE adminTb
       SET last_login_at = ${lastLoginExpression}
       WHERE admin_id = :adminId`,
      { adminId },
      { autoCommit: true }
    );

    return res.status(200).json({
      token,
      admin_id: adminId,
      username: resolvedUsername,
      role,
    });
  } catch (error) {
    return next(error);
  }
}

// @desc    Register a new student account
// @route   POST /api/auth/register
// @access  Public
async function register(req, res, next) {
  try {
    const {
      studentId,
      firstName,
      lastName,
      nickname,
      area,
      birthday,
      sex,
      password,
    } = req.body;

    if (dbMode === 'online') {
      if (!firstName || !lastName || !birthday) {
        return res.status(400).json({
          message: 'firstName, lastName, and birthday are required in online mode.',
        });
      }

      const birthdayKey = normalizeDateKey(birthday);
      if (!birthdayKey) {
        return res.status(400).json({
          message: 'birthday must be a valid date.',
        });
      }

      if (studentId) {
        const existingById = await findStudentById(String(studentId));
        if (existingById) {
          return res.status(409).json({
            message: 'Student already exists.',
          });
        }
      }

      const student = await createStudent({
        studentId: studentId ? String(studentId) : null,
        firstName: String(firstName),
        lastName: String(lastName),
        nickname: nickname ? String(nickname) : String(firstName),
        area: area ? String(area) : null,
        birthday: birthdayKey,
        sex: sex ? String(sex) : null,
        passwordHash: null,
        deviceOrigin: 'API',
      });

      return res.status(201).json({
        message: 'Student registered successfully.',
        data: {
          studentId: student.studentId,
          firstName: student.firstName,
          lastName: student.lastName,
        },
      });
    }

    if (!studentId || !firstName || !lastName || !password) {
      return res.status(400).json({
        message: 'studentId, firstName, lastName, and password are required.',
      });
    }

    const existing = await findStudentById(String(studentId));
    if (existing) {
      return res.status(409).json({
        message: 'Student already exists.',
      });
    }

    const passwordHash = await bcrypt.hash(String(password), 10);

    const student = await createStudent({
      studentId: String(studentId),
      firstName: String(firstName),
      lastName: String(lastName),
      nickname: nickname ? String(nickname) : null,
      area: area ? String(area) : null,
      birthday: birthday ? String(birthday) : null,
      sex: sex ? String(sex) : null,
      passwordHash,
    });

    return res.status(201).json({
      message: 'Student registered successfully.',
      data: {
        studentId: student.studentId,
        firstName: student.firstName,
        lastName: student.lastName,
      },
    });
  } catch (error) {
    return next(error);
  }
}

// @desc    Login student account
// @route   POST /api/auth/login
// @access  Public
async function login(req, res, next) {
  try {
    const { studentId, password, nickname, birthday } = req.body;

    let resolvedStudentId = null;
    let resolvedFirstName = null;
    let resolvedLastName = null;
    let resolvedNickname = null;
    let resolvedBirthday = null;
    let resolvedSex = null;
    let resolvedArea = null;

    if (nickname && birthday) {
      const student = await UserModel.findUserByNicknameAndBirthday(
        String(nickname),
        String(birthday)
      );

      if (!student) {
        return res.status(401).json({ message: 'Invalid credentials.' });
      }

      resolvedStudentId = Number(student.STUDENT_ID);
      resolvedFirstName = student.FIRST_NAME || '';
      resolvedLastName = student.LAST_NAME || '';
      resolvedNickname = student.NICKNAME || String(nickname);
      resolvedBirthday = normalizeDateKey(student.BIRTHDAY || String(birthday));
      resolvedSex = student.SEX || null;
      resolvedArea = student.AREA || null;
    } else {
      if (!studentId || !password) {
        return res.status(400).json({
          message: 'Provide either nickname+birthday or studentId+password.',
        });
      }

      const student = await findStudentById(String(studentId));
      if (!student) {
        return res.status(401).json({ message: 'Invalid credentials.' });
      }

      if (dbMode === 'online') {
        const providedKey = normalizeDateKey(password);
        const storedKey = normalizeDateKey(student.birthdayKey || student.birthday);
        if (!providedKey || !storedKey || providedKey !== storedKey) {
          return res.status(401).json({ message: 'Invalid credentials.' });
        }
      } else {
        const ok = await bcrypt.compare(String(password), student.passwordHash);
        if (!ok) {
          return res.status(401).json({ message: 'Invalid credentials.' });
        }
      }

      resolvedStudentId = Number(student.studentId);
      resolvedFirstName = student.firstName || '';
      resolvedLastName = student.lastName || '';
      resolvedNickname = student.nickname || null;
      resolvedBirthday = normalizeDateKey(student.birthdayKey || student.birthday || null);
      resolvedSex = student.sex || null;
      resolvedArea = student.area || null;
    }

    if (!Number.isFinite(resolvedStudentId)) {
      return res.status(500).json({ message: 'Unable to resolve student ID.' });
    }

    const token = jwt.sign(
      {
        sub: String(resolvedStudentId),
        name: `${resolvedFirstName} ${resolvedLastName}`.trim(),
      },
      jwtSecret,
      { expiresIn: '7d' }
    );

    return res.status(200).json({
      token,
      student: {
        studentId: resolvedStudentId,
        firstName: resolvedFirstName,
        lastName: resolvedLastName,
        nickname: resolvedNickname,
        birthday: resolvedBirthday,
        sex: resolvedSex,
        area: resolvedArea,
      },
    });
  } catch (error) {
    return next(error);
  }
}

// @desc    Register device and issue device-role token
// @route   POST /api/auth/device/register
// @access  Public
async function registerDevice(req, res, next) {
  try {
    const deviceUuid = String(req.body?.device_uuid || req.body?.deviceUuid || '').trim();
    const deviceName = String(req.body?.device_name || req.body?.deviceName || 'KOW Device').trim();

    if (!deviceUuid) {
      return res.status(400).json({ message: 'device_uuid is required.' });
    }

    const now = Math.floor(Date.now() / 1000);
    const payload = {
      sub: deviceUuid,
      role: 'device',
      deviceUuid,
      deviceName,
      iat: now,
      exp: now + 60 * 60 * 24 * 30,
    };

    const token = signCustomToken(payload);
    return res.status(200).json({ token, device_uuid: deviceUuid, device_name: deviceName });
  } catch (error) {
    return next(error);
  }
}

module.exports = {
  register,
  login,
  adminLogin,
  registerDevice,
};
