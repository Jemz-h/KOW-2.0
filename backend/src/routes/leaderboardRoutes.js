const express = require('express');
const { listLeaderboard } = require('../controllers/leaderboardController');

const router = express.Router();

router.get('/', listLeaderboard);

module.exports = router;
