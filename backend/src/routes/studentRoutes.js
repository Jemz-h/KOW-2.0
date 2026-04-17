const express = require('express');
const { getStudents, getStudent } = require('../controllers/studentsController');
const { requireAuth } = require('../middleware/auth');

const router = express.Router();

router.get('/', requireAuth, getStudents);
router.get('/:studentId', requireAuth, getStudent);

module.exports = router;
