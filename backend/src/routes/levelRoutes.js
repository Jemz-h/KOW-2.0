const express = require('express');
const router = express.Router();
const levelController = require('../controllers/levelController');

// GET /api/levels
router.get('/', levelController.getLevels);

// GET /api/levels/grade/:gradeId
router.get('/grade/:gradeId', levelController.getLevelsByGrade);

module.exports = router;
