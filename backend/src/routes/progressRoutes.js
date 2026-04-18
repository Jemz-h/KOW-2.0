const express = require('express');
<<<<<<< HEAD
const router = express.Router();
const progressController = require('../controllers/progressController');

// POST /api/progress
router.post('/', progressController.saveProgress);

// GET /api/progress/user/:userId
router.get('/user/:userId', progressController.getUserProgress);
=======
const {
  createOrUpdateProgress,
  getProgress,
} = require('../controllers/progressController');

const router = express.Router();

router.post('/', createOrUpdateProgress);
router.get('/:studentId', getProgress);
>>>>>>> 50596e6deeea80c069a5998050186a37243c272b

module.exports = router;
