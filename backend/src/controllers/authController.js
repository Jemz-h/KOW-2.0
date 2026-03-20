const UserModel = require('../models/userModel');

exports.register = async (req, res, next) => {
  try {
    const { firstName, lastName, nickname, birthday, sex, area } = req.body;
    
    if (!firstName || !lastName || !nickname || !birthday || !sex) {
      return res.status(400).json({ error: 'Missing required fields' });
    }

    const userId = await UserModel.createUser({
      firstName,
      lastName,
      nickname,
      birthday,
      sex,
      area
    });

    res.status(201).json({ success: true, message: 'User registered successfully', userId });
  } catch (error) {
    // Check for unique constraint violation (e.g., username/nickname already taken)
    if (error.message.includes('unique constraint')) {
      return res.status(409).json({ error: 'Nickname already exists' });
    }
    next(error);
  }
};

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