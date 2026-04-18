const express = require('express');
<<<<<<< HEAD
const router = express.Router();
const studentController = require('../controllers/studentController');
const { requireAuth, requireRole } = require('../middleware/authMiddleware');

router.post('/lookup', requireAuth, requireRole(['device', 'admin']), studentController.lookupStudent);
router.post('/register', requireAuth, requireRole(['device', 'admin']), studentController.registerStudent);
=======
const { getStudents, getStudent } = require('../controllers/studentsController');
const { requireAuth } = require('../middleware/auth');

const router = express.Router();

router.get('/', requireAuth, getStudents);
router.get('/:studentId', requireAuth, getStudent);
>>>>>>> 50596e6deeea80c069a5998050186a37243c272b

module.exports = router;
