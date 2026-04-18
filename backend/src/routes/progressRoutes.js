const express = require('express');
const {
  createOrUpdateProgress,
  getProgress,
} = require('../controllers/progressController');

const router = express.Router();

router.post('/', createOrUpdateProgress);
router.get('/user/:studentId', getProgress);
router.get('/:studentId', getProgress);

module.exports = router;
