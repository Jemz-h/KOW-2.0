const bcrypt = require('bcrypt');

/**
 * Helper module for birthday-based password management
 * Security Note: Using birthday as password is inherently insecure
 * The password is always the user's birthday in YYYY-MM-DD format
 */

const SALT_ROUNDS = 10;

/**
 * Hash a birthday string to store as password
 * @param {string} birthday - Birthday in YYYY-MM-DD format
 * @returns {Promise<string>} Hashed password
 */
async function hashBirthday(birthday) {
  if (!birthday) {
    throw new Error('Birthday is required');
  }
  return await bcrypt.hash(birthday, SALT_ROUNDS);
}

/**
 * Verify if a birthday matches the stored password hash
 * @param {string} birthday - Birthday in YYYY-MM-DD format
 * @param {string} hashedPassword - Stored password hash
 * @returns {Promise<boolean>} True if birthday matches
 */
async function verifyBirthday(birthday, hashedPassword) {
  if (!birthday || !hashedPassword) {
    return false;
  }
  return await bcrypt.compare(birthday, hashedPassword);
}

module.exports = {
  hashBirthday,
  verifyBirthday
};
