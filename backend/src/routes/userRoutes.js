const express = require('express');
const router = express.Router();
const userController = require('../controllers/userController');

// GET /api/users
router.get('/', userController.getUsers);

// POST /api/users
router.post('/', userController.createUser);

// GET /api/users/:id
router.get('/:id', userController.getUserById);

// PUT /api/users/:id/birthday
router.put('/:id/birthday', userController.updateUserBirthday);

// DELETE /api/users/:id
router.delete('/:id', userController.deleteUser);

module.exports = router;
