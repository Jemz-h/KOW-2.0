const path = require('path');
const dotenv = require('dotenv');

function loadEnv() {
  const cwd = process.cwd();
  const nodeEnv = process.env.NODE_ENV || 'development';
  const envSpecificPath = path.resolve(cwd, `.env.${nodeEnv}`);
  const envDefaultPath = path.resolve(cwd, '.env');
  const originalEnv = { ...process.env };

  // Let env files override each other, but keep any shell-provided values.
  dotenv.config({ path: envDefaultPath });
  dotenv.config({ path: envSpecificPath, override: true });

  for (const [key, value] of Object.entries(originalEnv)) {
    process.env[key] = value;
  }
}

module.exports = {
  loadEnv,
};
