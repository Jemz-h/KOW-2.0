const db = require('../config/db');
const asyncHandler = require('express-async-handler');
const UserModel = require('../models/userModel');

// @desc    Get all students
// @route   GET /api/users
// @access  Public
const getUsers = asyncHandler(async (req, res) => {
  const result = await db.execute(`
    SELECT s.stud_id,
      s.first_name,
      s.last_name,
      s.nickname,
      TO_CHAR(s.birthday, 'YYYY-MM-DD') AS birthday,
      x.sex,
      b.barangay_nm,
      TO_CHAR(s.created_at, 'YYYY-MM-DD HH24:MI:SS') AS created_at,
      TO_CHAR(s.updated_at, 'YYYY-MM-DD HH24:MI:SS') AS updated_at
    FROM studentTb s
    LEFT JOIN sexTb x ON s.sex_id = x.sex_id
    LEFT JOIN barangayTb b ON s.barangay_id = b.barangay_id
    ORDER BY s.stud_id
  `);
  
  res.status(200).json({
    success: true,
    data: result.rows
  });
});

// @desc    Get student by ID
// @route   GET /api/users/:id
// @access  Public
const getUserById = asyncHandler(async (req, res) => {
  const { id } = req.params;
  const result = await db.execute(`
    SELECT s.stud_id,
           s.first_name,
           s.last_name,
           s.nickname,
           TO_CHAR(s.birthday, 'YYYY-MM-DD') AS birthday,
           x.sex,
           b.barangay_nm,
           TO_CHAR(s.created_at, 'YYYY-MM-DD HH24:MI:SS') AS created_at,
           TO_CHAR(s.updated_at, 'YYYY-MM-DD HH24:MI:SS') AS updated_at,
           s.device_origin,
           s.tmp_local_id
    FROM studentTb s
    LEFT JOIN sexTb x ON s.sex_id = x.sex_id
    LEFT JOIN barangayTb b ON s.barangay_id = b.barangay_id
    WHERE s.stud_id = :id
  `, { id });
  
  if (result.rows.length === 0) {
    res.status(404);
    throw new Error(`Student not found with ID of ${id}`);
  }
  
  res.status(200).json({
    success: true,
    data: result.rows[0]
  });
});

// @desc    Create a new student
// @route   POST /api/users
// @access  Public
const createUser = asyncHandler(async (req, res) => {
  const { firstName, lastName, birthday, gender, nickName, nickname, barangay, area, teacherId, deviceUuid } = req.body;
  const resolvedNickname = nickname || nickName;

  // Basic validation
  if (!firstName || !lastName || !resolvedNickname || !birthday) {
    res.status(400);
    throw new Error('Please provide all required fields (firstName, lastName, nickname, birthday)');
  }

  const userId = await UserModel.createUser({
    firstName,
    lastName,
    nickname: resolvedNickname,
    birthday,
    sex: gender || null,
    area: barangay || area || null,
    teacherId: teacherId || null,
    deviceUuid: deviceUuid || null
  });

  res.status(201).json({ 
    success: true,
    message: 'Student created successfully',
    data: { stud_id: userId }
  });
});

// @desc    Update user birthday (this also updates password)
// @route   PUT /api/users/:id/birthday
// @access  Public
const updateUserBirthday = asyncHandler(async (req, res) => {
  const { id } = req.params;
  const { birthday } = req.body;

  if (!birthday) {
    res.status(400);
    throw new Error('Birthday is required');
  }

  const result = await db.execute(
    `UPDATE studentTb
     SET birthday = TO_DATE(:birthday, 'YYYY-MM-DD')
     WHERE stud_id = :id`,
    { id, birthday },
    { autoCommit: true }
  );

  if (result.rowsAffected === 0) {
    res.status(404);
    throw new Error(`Student not found with ID of ${id}`);
  }

  res.status(200).json({
    success: true,
    message: 'Birthday updated successfully'
  });
});

// @desc    Hard delete a student
// @route   DELETE /api/users/:id
// @access  Public
const deleteUser = asyncHandler(async (req, res) => {
  const { id } = req.params;

  const result = await db.execute(
    `DELETE FROM studentTb
     WHERE stud_id = :id`,
    { id },
    { autoCommit: true }
  );

  if (result.rowsAffected === 0) {
    res.status(404);
    throw new Error(`Student not found with ID of ${id}`);
  }

  res.status(200).json({
    success: true,
    message: 'Student deleted successfully'
  });
});

module.exports = { getUsers, getUserById, createUser, updateUserBirthday, deleteUser };

