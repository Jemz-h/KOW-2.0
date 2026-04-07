const asyncHandler = require('express-async-handler');
const UserModel = require('../models/userModel');

// @desc    Lookup student by nickname + birthday
// @route   POST /api/students/lookup
// @access  Public
const lookupStudent = asyncHandler(async (req, res) => {
  const { nickname, birthday } = req.body;

  if (!nickname || !birthday) {
    return res.status(400).json({
      success: false,
      error: 'Nickname and birthday are required',
    });
  }

  const student = await UserModel.findUserByNicknameAndBirthday(nickname, birthday);

  if (!student) {
    return res.status(200).json({ found: false });
  }

  return res.status(200).json({
    success: true,
    found: true,
    stud_id: student.STUDENT_ID,
    nickname: student.NICKNAME,
    first_name: student.FIRST_NAME,
    last_name: student.LAST_NAME,
    sex_id: null,
    gradelvl_id: null,
    barangay_id: 1,
    student,
  });
});

// @desc    Register a student profile
// @route   POST /api/students/register
// @access  Public
const registerStudent = asyncHandler(async (req, res) => {
  const {
    firstName,
    lastName,
    nickname,
    birthday,
    sex,
    sex_id,
    area,
    teacherId,
    deviceUuid,
    device_uuid,
    tmpLocalId,
    tmp_local_id,
  } = req.body;

  if (!firstName || !lastName || !nickname || !birthday) {
    return res.status(400).json({
      success: false,
      error: 'Missing required fields',
    });
  }

  const userId = await UserModel.createUser({
    firstName,
    lastName,
    nickname,
    birthday,
    sex: sex || sex_id || null,
    area: area || null,
    teacherId: teacherId || null,
    deviceUuid: deviceUuid || device_uuid || null,
    tmpLocalId: tmpLocalId || tmp_local_id || null,
  });

  return res.status(201).json({
    success: true,
    message: 'Student registered successfully',
    student: {
      studentId: userId,
      nickname,
    },
  });
});

module.exports = {
  lookupStudent,
  registerStudent,
};
