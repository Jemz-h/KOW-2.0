const express = require('express');
const { lookupStudent, registerStudent } = require('../controllers/studentController');
const { getStudents, getStudent } = require('../controllers/studentsController');
const { requireAuth } = require('../middleware/auth');

const router = express.Router();

router.post('/lookup', lookupStudent);
router.post('/register', registerStudent);

router.get('/', requireAuth, getStudents);
router.get('/:studentId', requireAuth, getStudent);

module.exports = router;
