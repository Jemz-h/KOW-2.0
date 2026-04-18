const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const crypto = require('crypto');
const UserModel = require('../models/userModel');
const {
  createStudent,
  findStudentById,
} = require('../repositories/students.repository');
const { jwtSecret, dbMode } = require('../config/env');

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
  if (!input) return null;
  const raw = String(input).trim();

  // Already canonical.
  if (/^\d{4}-\d{2}-\d{2}$/.test(raw)) {
    return raw;
  }

  // Handle mm/dd/yyyy.
  const slash = raw.match(/^(\d{1,2})\/(\d{1,2})\/(\d{4})$/);
  if (slash) {
    const mm = slash[1].padStart(2, '0');
    const dd = slash[2].padStart(2, '0');
    return `${slash[3]}-${mm}-${dd}`;
  }

  // Handle textual dates like "MARCH 5, 2020".
  const parsed = new Date(raw);
  if (!Number.isNaN(parsed.getTime())) {
    const y = parsed.getUTCFullYear();
    const m = String(parsed.getUTCMonth() + 1).padStart(2, '0');
    const d = String(parsed.getUTCDate()).padStart(2, '0');
    return `${y}-${m}-${d}`;
  }

  return null;
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
  registerDevice,
};
