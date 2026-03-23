const UserModel = require('../models/userModel');
const db = require('../config/db');
const { hashBirthday } = require('../middleware/passwordHelper');

// @desc    Register a new user
// @route   POST /api/auth/register
// @access  Public
exports.register = async (req, res, next) => {
  try {
    const { firstName, lastName, nickname, birthday, gender, barangay } = req.body;
    
    if (!firstName || !lastName || !nickname || !birthday) {
      return res.status(400).json({ error: 'Missing required fields' });
    }

    // Validate gender if provided (M/F/O format)
    if (gender && !['M', 'F', 'O'].includes(gender)) {
      return res.status(400).json({ error: 'Gender must be M (Male), F (Female), or O (Other)' });
    }

    // Hash password from birthday
    const hashedPassword = await hashBirthday(birthday);

    const userId = await UserModel.createUser({
      firstName,
      lastName,
      nickname,
      birthday,
      gender: gender || null,
      barangay: barangay || null,
      password: hashedPassword
    });

    // Create Achievement record for new user
    await db.execute(
      `INSERT INTO Achievement (userID) VALUES (:userID)`,
      { userID: userId },
      { autoCommit: true }
    );

    res.status(201).json({ success: true, message: 'User registered successfully', userId });
  } catch (error) {
    // Check for unique constraint violation (e.g., username/nickname already taken)
    if (error.message.includes('unique constraint')) {
      return res.status(409).json({ error: 'Nickname already exists' });
    }
    next(error);
  }
};

// @desc    Login user with nickname and birthday
// @route   POST /api/auth/login
// @access  Public
exports.login = async (req, res, next) => {
  try {
    const { nickname, birthday } = req.body;

    if (!nickname || !birthday) {
      return res.status(400).json({ error: 'Nickname and birthday are required' });
    }

    const student = await UserModel.findUserByNicknameAndBirthday(nickname, birthday);

    if (!student) {
      return res.status(401).json({ error: 'Invalid nickname or birthday' });
    }

    // Check if user is soft deleted
    if (student.IS_DELETED === 1) {
      return res.status(401).json({ error: 'User account has been deleted' });
    }

    // Set a default total score or calculate it if needed
    student.TOTAL_SCORE = 0; 

    res.json({ success: true, student });
  } catch (error) {
    next(error);
  }
};