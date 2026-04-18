const express = require('express');
<<<<<<< HEAD
const router = express.Router();
const authController = require('../controllers/authController');

// POST /api/auth/register
router.post('/register', authController.register);

// POST /api/auth/login
router.post('/login', authController.login);

// POST /api/auth/admin/login
router.post('/admin/login', authController.adminLogin);

// POST /api/auth/device/register
router.post('/device/register', authController.registerDevice);

module.exports = router;
=======
const { register, login } = require('../controllers/authController');

const router = express.Router();

router.post('/register', register);
router.post('/login', login);

module.exports = router;
>>>>>>> 50596e6deeea80c069a5998050186a37243c272b
