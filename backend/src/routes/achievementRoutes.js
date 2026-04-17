const express = require('express');
const {
  createOrUpdateAchievement,
  getAchievements,
} = require('../controllers/achievementsController');

const router = express.Router();

router.post('/', createOrUpdateAchievement);
router.get('/:studentId', getAchievements);

module.exports = router;
