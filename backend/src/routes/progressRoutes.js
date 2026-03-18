const express = require('express');
const router = express.Router();
const progressController = require('../controllers/progressController');

// POST /api/progress
router.post('/', progressController.saveProgress);

// GET /api/progress/user/:userId
router.get('/user/:userId', progressController.getUserProgress);

module.exports = router;
