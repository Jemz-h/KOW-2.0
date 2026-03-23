const oracledb = require('oracledb');
const db = require('../config/db');
const asyncHandler = require('express-async-handler');
const { hashBirthday } = require('../middleware/passwordHelper');

// @desc    Get all active users (excluding passwords)
// @route   GET /api/users
// @access  Public
const getUsers = asyncHandler(async (req, res) => {
  const result = await db.execute(`
    SELECT userID, username, firstName, lastName, nickName, 
           TO_CHAR(birthday, 'YYYY-MM-DD') AS birthday, 
           barangay, gender, 
           TO_CHAR(dateCreated, 'YYYY-MM-DD HH24:MI:SS') AS dateCreated
    FROM Users
    WHERE isDeleted = 0
    ORDER BY userID
  `);
  
  res.status(200).json({
    success: true,
    data: result.rows
  });
});

// @desc    Get user by ID (excluding password)
// @route   GET /api/users/:id
// @access  Public
const getUserById = asyncHandler(async (req, res) => {
  const { id } = req.params;
  const result = await db.execute(`
    SELECT userID, username, firstName, lastName, nickName, 
           TO_CHAR(birthday, 'YYYY-MM-DD') AS birthday, 
           barangay, gender,
           TO_CHAR(dateCreated, 'YYYY-MM-DD HH24:MI:SS') AS dateCreated
    FROM Users 
    WHERE userID = :id AND isDeleted = 0
  `, [id]);
  
  if (result.rows.length === 0) {
    res.status(404);
    throw new Error(`User not found with ID of ${id}`);
  }
  
  res.status(200).json({
    success: true,
    data: result.rows[0]
  });
});

// @desc    Create a new user (password will be birthday)
// @route   POST /api/users
// @access  Public
const createUser = asyncHandler(async (req, res) => {
  const { username, firstName, lastName, birthday, gender, nickName, barangay } = req.body;

  // Basic validation
  if (!username || !firstName || !lastName || !birthday) {
    res.status(400);
    throw new Error('Please provide all required fields (username, firstName, lastName, birthday)');
  }

  // Validate gender if provided (M/F/O format)
  if (gender && !['M', 'F', 'O'].includes(gender)) {
    res.status(400);
    throw new Error('Gender must be M (Male), F (Female), or O (Other)');
  }

  // Password is always the birthday (hashed)
  const hashedPassword = await hashBirthday(birthday);

  const result = await db.execute(
    `INSERT INTO Users (username, password, firstName, lastName, birthday, gender, nickName, barangay, isDeleted) 
     VALUES (:username, :password, :firstName, :lastName, TO_DATE(:birthday, 'YYYY-MM-DD'), :gender, :nickName, :barangay, 0)
     RETURNING userID INTO :userID`,
    {
      username,
      password: hashedPassword,
      firstName,
      lastName,
      birthday,
      gender: gender || null,
      nickName: nickName || null,
      barangay: barangay || null,
      userID: { type: oracledb.NUMBER, dir: oracledb.BIND_OUT }
    },
    { autoCommit: true }
  );

  const userId = result.outBinds.userID[0];

  // Create Achievement record for new user
  await db.execute(
    `INSERT INTO Achievement (userID) VALUES (:userID)`,
    { userID: userId },
    { autoCommit: true }
  );

  res.status(201).json({ 
    success: true,
    message: 'User created successfully (password set to birthday)',
    data: { userID: userId }
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

  // Hash the new birthday as the new password
  const hashedPassword = await hashBirthday(birthday);

  const result = await db.execute(
    `UPDATE Users 
     SET birthday = TO_DATE(:birthday, 'YYYY-MM-DD'),
         password = :password
     WHERE userID = :id AND isDeleted = 0`,
    { id, birthday, password: hashedPassword },
    { autoCommit: true }
  );

  if (result.rowsAffected === 0) {
    res.status(404);
    throw new Error(`User not found with ID of ${id}`);
  }

  res.status(200).json({
    success: true,
    message: 'Birthday and password updated successfully'
  });
});

// @desc    Soft delete a user
// @route   DELETE /api/users/:id
// @access  Public
const deleteUser = asyncHandler(async (req, res) => {
  const { id } = req.params;

  const result = await db.execute(
    `UPDATE Users 
     SET isDeleted = 1,
         deletedAt = SYSDATE,
         deletedBy = :deletedBy
     WHERE userID = :id AND isDeleted = 0`,
    { id, deletedBy: id },
    { autoCommit: true }
  );

  if (result.rowsAffected === 0) {
    res.status(404);
    throw new Error(`User not found with ID of ${id}`);
  }

  res.status(200).json({
    success: true,
    message: 'User deleted successfully'
  });
});

module.exports = { getUsers, getUserById, createUser, updateUserBirthday, deleteUser };

