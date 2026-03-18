const oracledb = require('oracledb');
const db = require('../config/db');
const asyncHandler = require('express-async-handler');

// @desc    Get all users
// @route   GET /api/users
// @access  Public
const getUsers = asyncHandler(async (req, res) => {
  const result = await db.execute(`SELECT * FROM Users`);
  
  res.status(200).json({
    success: true,
    data: result.rows
  });
});

// @desc    Get user by ID
// @route   GET /api/users/:id
// @access  Public
const getUserById = asyncHandler(async (req, res) => {
  const { id } = req.params;
  const result = await db.execute(`SELECT * FROM Users WHERE userID = :id`, [id]);
  
  if (result.rows.length === 0) {
    res.status(404);
    throw new Error(`User not found with ID of ${id}`);
  }
  
  res.status(200).json({
    success: true,
    data: result.rows[0]
  });
});

// @desc    Create a new user
// @route   POST /api/users
// @access  Public
const createUser = asyncHandler(async (req, res) => {
  const { username, password, firstName, lastName } = req.body;

  // Basic validation
  if (!username || !password || !firstName || !lastName) {
    res.status(400);
    throw new Error('Please provide all required fields (username, password, firstName, lastName)');
  }

  const result = await db.execute(
    `INSERT INTO Users (username, password, firstName, lastName) 
     VALUES (:username, :password, :firstName, :lastName)
     RETURNING userID INTO :userID`,
    {
      username,
      password,
      firstName,
      lastName,
      userID: { type: oracledb.NUMBER, dir: oracledb.BIND_OUT }
    },
    { autoCommit: true }
  );

  res.status(201).json({ 
    success: true,
    message: 'User created successfully',
    data: { userID: result.outBinds.userID[0] }
  });
});

module.exports = { getUsers, getUserById, createUser };

