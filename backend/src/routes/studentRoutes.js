const express = require('express');
const router = express.Router();
const studentController = require('../controllers/studentController');
const { requireAuth, requireRole } = require('../middleware/authMiddleware');

router.post('/lookup', requireAuth, requireRole(['device', 'admin']), studentController.lookupStudent);
router.post('/register', requireAuth, requireRole(['device', 'admin']), studentController.registerStudent);

module.exports = router;
