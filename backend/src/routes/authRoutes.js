const express = require('express');
const { register, login, adminLogin, registerDevice } = require('../controllers/authController');

const router = express.Router();

router.post('/register', register);
router.post('/login', login);
router.post('/admin/login', adminLogin);
router.post('/device/register', registerDevice);

module.exports = router;
