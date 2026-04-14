const path = require('path');
const dotenv = require('dotenv');

function loadEnv() {
  const cwd = process.cwd();
  const nodeEnv = process.env.NODE_ENV || 'development';
  const envSpecificPath = path.resolve(cwd, `.env.${nodeEnv}`);
  const envDefaultPath = path.resolve(cwd, '.env');

  // Load base first, then override with environment-specific file.
  dotenv.config({ path: envDefaultPath });
  dotenv.config({ path: envSpecificPath, override: true });
}

module.exports = {
  loadEnv,
};
