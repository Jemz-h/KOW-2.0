const db = require('../config/db');
const asyncHandler = require('express-async-handler');
const UserModel = require('../models/userModel');

// @desc    Get all students
// @route   GET /api/users
// @access  Public
const getUsers = asyncHandler(async (req, res) => {
  const query = db.isOracle()
    ? `SELECT s.stud_id,
              s.first_name,
              s.last_name,
              s.nickname,
              TO_CHAR(s.birthday, 'YYYY-MM-DD') AS birthday,
              x.sex,
      COALESCE(a.area_nm, b.barangay_nm) AS area,
              TO_CHAR(s.created_at, 'YYYY-MM-DD HH24:MI:SS') AS created_at,
              TO_CHAR(s.updated_at, 'YYYY-MM-DD HH24:MI:SS') AS updated_at
       FROM studentTb s
       LEFT JOIN sexTb x ON s.sex_id = x.sex_id
    LEFT JOIN areaTb a ON s.area_id = a.area_id
       LEFT JOIN barangayTb b ON s.barangay_id = b.barangay_id
       ORDER BY s.stud_id`
    : `SELECT s.stud_id,
              s.first_name,
              s.last_name,
              s.nickname,
              date(s.birthday) AS birthday,
              x.sex,
      COALESCE(a.area_nm, b.barangay_nm) AS area,
              s.created_at,
              s.updated_at
       FROM studentTb s
       LEFT JOIN sexTb x ON s.sex_id = x.sex_id
    LEFT JOIN areaTb a ON s.area_id = a.area_id
       LEFT JOIN barangayTb b ON s.barangay_id = b.barangay_id
       ORDER BY s.stud_id`;

  const result = await db.execute(query);
  
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
  const query = db.isOracle()
    ? `SELECT s.stud_id,
              s.first_name,
              s.last_name,
              s.nickname,
              TO_CHAR(s.birthday, 'YYYY-MM-DD') AS birthday,
              x.sex,
      COALESCE(a.area_nm, b.barangay_nm) AS area,
              TO_CHAR(s.created_at, 'YYYY-MM-DD HH24:MI:SS') AS created_at,
              TO_CHAR(s.updated_at, 'YYYY-MM-DD HH24:MI:SS') AS updated_at,
              s.device_origin,
              s.tmp_local_id
       FROM studentTb s
       LEFT JOIN sexTb x ON s.sex_id = x.sex_id
    LEFT JOIN areaTb a ON s.area_id = a.area_id
       LEFT JOIN barangayTb b ON s.barangay_id = b.barangay_id
       WHERE s.stud_id = :id`
    : `SELECT s.stud_id,
              s.first_name,
              s.last_name,
              s.nickname,
              date(s.birthday) AS birthday,
              x.sex,
      COALESCE(a.area_nm, b.barangay_nm) AS area,
              s.created_at,
              s.updated_at,
              s.device_origin,
              s.tmp_local_id
       FROM studentTb s
       LEFT JOIN sexTb x ON s.sex_id = x.sex_id
    LEFT JOIN areaTb a ON s.area_id = a.area_id
       LEFT JOIN barangayTb b ON s.barangay_id = b.barangay_id
       WHERE s.stud_id = :id`;

  const result = await db.execute(query, { id });
  
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
    area: area || barangay || null,
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

  const query = db.isOracle()
    ? `UPDATE studentTb
       SET birthday = TO_DATE(:birthday, 'YYYY-MM-DD')
       WHERE stud_id = :id`
    : `UPDATE studentTb
       SET birthday = :birthday
       WHERE stud_id = :id`;

  const result = await db.execute(query, { id, birthday }, { autoCommit: true });

  if (result.rowsAffected === 0) {
    res.status(404);
    throw new Error(`Student not found with ID of ${id}`);
  }

  res.status(200).json({
    success: true,
    message: 'Birthday updated successfully'
  });
});

// @desc    Update student profile
// @route   PUT /api/users/:id/profile
// @access  Public
const updateUserProfile = asyncHandler(async (req, res) => {
  const { id } = req.params;
  const {
    firstName,
    lastName,
    nickname,
    birthday,
    sex,
    area,
  } = req.body;

  if (!firstName || !lastName || !nickname || !birthday || !sex) {
    res.status(400);
    throw new Error('Missing required profile fields');
  }

  const updated = await UserModel.updateUserProfile({
    userId: id,
    firstName,
    lastName,
    nickname,
    birthday,
    sex,
    area: area || null,
  });

  if (!updated) {
    res.status(404);
    throw new Error(`Student not found with ID of ${id}`);
  }

  res.status(200).json({
    success: true,
    message: 'Profile updated successfully',
  });
});

// @desc    Hard delete a student
// @route   DELETE /api/users/:id
// @access  Public
const deleteUser = asyncHandler(async (req, res) => {
  const { id } = req.params;

  const dependencyQuery = db.isOracle()
    ? `SELECT 'customTb' AS dep_name, COUNT(*) AS ref_count FROM customTb WHERE stud_id = :id
       UNION ALL
       SELECT 'scoreTb' AS dep_name, COUNT(*) AS ref_count FROM scoreTb WHERE stud_id = :id
       UNION ALL
       SELECT 'timeplTb' AS dep_name, COUNT(*) AS ref_count FROM timeplTb WHERE stud_id = :id
       UNION ALL
       SELECT 'progressTb' AS dep_name, COUNT(*) AS ref_count FROM progressTb WHERE stud_id = :id
       UNION ALL
       SELECT 'analyticsTb' AS dep_name, COUNT(*) AS ref_count FROM analyticsTb WHERE stud_id = :id
       UNION ALL
       SELECT 'syncLogTb' AS dep_name, COUNT(*) AS ref_count FROM syncLogTb WHERE stud_id = :id`
    : `SELECT 'scoreTb' AS dep_name, COUNT(*) AS ref_count FROM scoreTb WHERE stud_id = :id
       UNION ALL
       SELECT 'progressTb' AS dep_name, COUNT(*) AS ref_count FROM progressTb WHERE stud_id = :id`;

  const dependencyCheck = await db.execute(dependencyQuery, { id });
  const blockers = dependencyCheck.rows
    .filter((row) => Number(row.REF_COUNT || 0) > 0)
    .map((row) => ({ table: row.DEP_NAME, count: Number(row.REF_COUNT) }));

  if (blockers.length > 0) {
    return res.status(409).json({
      success: false,
      message: 'Cannot delete student with related records',
      dependencies: blockers
    });
  }

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

module.exports = {
  getUsers,
  getUserById,
  createUser,
  updateUserBirthday,
  updateUserProfile,
  deleteUser,
};

