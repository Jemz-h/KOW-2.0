const UserModel = require('../models/userModel');

// @desc    Register a new user
// @route   POST /api/auth/register
// @access  Public
exports.register = async (req, res, next) => {
  try {
    const { firstName, lastName, nickname, birthday, sex, area, teacherId, deviceUuid } = req.body;
    
    if (!firstName || !lastName || !nickname || !birthday) {
      return res.status(400).json({ error: 'Missing required fields' });
    }

    const userId = await UserModel.createUser({
      firstName,
      lastName,
      nickname,
      birthday,
      sex: sex || null,
      area: area || null,
      teacherId: teacherId || null,
      deviceUuid: deviceUuid || null
    });

    res.status(201).json({ success: true, message: 'User registered successfully', userId });
  } catch (error) {
    if (error.message.includes('unique constraint')) {
      return res.status(409).json({ error: 'Nickname and birthday already exist' });
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

    // Set a default total score or calculate it if needed
    student.TOTAL_SCORE = 0; 

    res.json({ success: true, student });
  } catch (error) {
    next(error);
  }
};