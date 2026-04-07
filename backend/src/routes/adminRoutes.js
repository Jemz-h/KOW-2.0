const express = require('express');
const router = express.Router();
const adminController = require('../controllers/adminController');
const { requireAuth, requireRole } = require('../middleware/authMiddleware');

router.use(requireAuth);

router.get('/dashboard', requireRole(['admin', 'readonly']), adminController.getDashboard);
router.get('/students', requireRole(['admin', 'readonly']), adminController.listStudents);
router.get('/students/:studId', requireRole(['admin', 'readonly']), adminController.getStudentDetail);
router.get('/devices', requireRole(['admin', 'readonly']), adminController.listDevices);
router.get('/questions', requireRole(['admin', 'readonly']), adminController.listQuestions);

router.post('/questions', requireRole('admin'), adminController.createQuestion);
router.put('/questions/:questionId', requireRole('admin'), adminController.updateQuestion);
router.delete('/questions/:questionId', requireRole('admin'), adminController.deleteQuestion);

module.exports = router;
