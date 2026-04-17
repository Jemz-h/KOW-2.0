const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const {
  createStudent,
  findStudentById,
} = require('../repositories/students.repository');
const { jwtSecret, dbMode } = require('../config/env');

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
    const { studentId, password } = req.body;

    if (!studentId || !password) {
      return res.status(400).json({
        message: 'studentId and password are required.',
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

    const token = jwt.sign(
      {
        sub: student.studentId,
        name: `${student.firstName} ${student.lastName}`,
      },
      jwtSecret,
      { expiresIn: '7d' }
    );

    return res.status(200).json({
      token,
      student: {
        studentId: student.studentId,
        firstName: student.firstName,
        lastName: student.lastName,
      },
    });
  } catch (error) {
    return next(error);
  }
}

module.exports = {
  register,
  login,
};
