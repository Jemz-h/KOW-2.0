const { dbMode } = require('../config/env');

function isOnline() {
  return dbMode === 'online';
}

module.exports = {
  isOnline,
};
