const express = require('express');
const { register, login, registerDevice } = require('../controllers/authController');

const router = express.Router();

router.post('/register', register);
router.post('/login', login);
router.post('/device/register', registerDevice);

module.exports = router;
