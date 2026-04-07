const UserModel = require('../models/userModel');
const crypto = require('crypto');
const bcrypt = require('bcryptjs');

const TOKEN_SECRET = process.env.TOKEN_SECRET || 'kow-dev-secret-change-me';

function base64UrlEncode(value) {
  return Buffer.from(value)
    .toString('base64')
    .replace(/=/g, '')
    .replace(/\+/g, '-')
    .replace(/\//g, '_');
}

function signToken(payload, expiresInSeconds) {
  const header = { alg: 'HS256', typ: 'JWT' };
  const now = Math.floor(Date.now() / 1000);
  const fullPayload = { ...payload, iat: now, exp: now + expiresInSeconds };

  const encodedHeader = base64UrlEncode(JSON.stringify(header));
  const encodedPayload = base64UrlEncode(JSON.stringify(fullPayload));
  const data = `${encodedHeader}.${encodedPayload}`;

  const signature = crypto
    .createHmac('sha256', TOKEN_SECRET)
    .update(data)
    .digest('base64')
    .replace(/=/g, '')
    .replace(/\+/g, '-')
    .replace(/\//g, '_');

  return `${data}.${signature}`;
}

function sha256(value) {
  return crypto.createHash('sha256').update(String(value)).digest('hex');
}

function verifyTokenLikePassword(password, storedHash) {
  const plainMatch = storedHash === password;
  const shaMatch = storedHash === `sha256$${sha256(password)}`;
  return plainMatch || shaMatch;
}

// @desc    Register a new user
// @route   POST /api/auth/register
// @access  Public
exports.register = async (req, res, next) => {
  try {
    const { firstName, lastName, nickname, birthday, sex, area, teacherId, deviceUuid } = req.body;
    
    if (!firstName || !lastName || !nickname || !birthday) {
      return res.status(400).json({ error: 'Missing required fields' });
    }

    const userId = await UserModel.createUser({
      firstName,
      lastName,
      nickname,
      birthday,
      sex: sex || null,
      area: area || null,
      teacherId: teacherId || null,
      deviceUuid: deviceUuid || null
    });

    res.status(201).json({ success: true, message: 'User registered successfully', userId });
  } catch (error) {
    if (error.message.includes('unique constraint')) {
      return res.status(409).json({ error: 'Nickname and birthday already exist' });
    }
    next(error);
  }
};

// @desc    Login user with nickname and birthday
// @route   POST /api/auth/login
// @access  Public
exports.login = async (req, res, next) => {
  try {
    const { nickname, birthday } = req.body;

    if (!nickname || !birthday) {
      return res.status(400).json({ error: 'Nickname and birthday are required' });
    }

    const student = await UserModel.findUserByNicknameAndBirthday(nickname, birthday);

    if (!student) {
      return res.status(401).json({ error: 'Invalid nickname or birthday' });
    }

    // Set a default total score or calculate it if needed
    student.TOTAL_SCORE = 0; 

    res.json({ success: true, student });
  } catch (error) {
    next(error);
  }
};

// @desc    Admin login
// @route   POST /api/auth/admin/login
// @access  Public
exports.adminLogin = async (req, res, next) => {
  try {
    const { username, password } = req.body;

    if (!username || !password) {
      return res.status(400).json({ success: false, error: 'Username and password are required' });
    }

    const db = require('../config/db');
    const result = await db.execute(
      `SELECT admin_id,
              username,
              password_hash,
              role
       FROM adminTb
       WHERE LOWER(username) = LOWER(:username)`,
      { username }
    );

    const admin = result.rows[0];
    if (!admin) {
      return res.status(401).json({ success: false, error: 'Invalid credentials' });
    }

    const storedHash = String(admin.PASSWORD_HASH || '');
    let isValid = false;

    if (storedHash.startsWith('$2')) {
      isValid = await bcrypt.compare(password, storedHash);
    } else {
      isValid = verifyTokenLikePassword(password, storedHash);
    }

    if (!isValid) {
      return res.status(401).json({ success: false, error: 'Invalid credentials' });
    }

    if (db.isOracle()) {
      await db.execute(
        `UPDATE adminTb
         SET last_login_at = SYSDATE
         WHERE admin_id = :adminId`,
        { adminId: admin.ADMIN_ID },
        { autoCommit: true }
      );
    } else {
      await db.execute(
        `UPDATE adminTb
         SET last_login_at = CURRENT_TIMESTAMP
         WHERE admin_id = :adminId`,
        { adminId: admin.ADMIN_ID },
        { autoCommit: true }
      );
    }

    const token = signToken(
      { role: admin.ROLE || 'admin', adminId: admin.ADMIN_ID, username: admin.USERNAME },
      8 * 60 * 60
    );

    return res.status(200).json({
      success: true,
      token,
      admin_id: admin.ADMIN_ID,
      username: admin.USERNAME,
      role: admin.ROLE || 'admin',
      expires_in: '8h',
      admin: {
        adminId: admin.ADMIN_ID,
        username: admin.USERNAME,
        role: admin.ROLE || 'admin',
      },
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Register or refresh a device identity
// @route   POST /api/auth/device/register
// @access  Public
exports.registerDevice = async (req, res, next) => {
  try {
    const { deviceUuid, deviceName, device_uuid, device_name } = req.body;
    const resolvedDeviceUuid = deviceUuid || device_uuid;
    const resolvedDeviceName = deviceName || device_name || null;
    if (!resolvedDeviceUuid) {
      return res.status(400).json({ success: false, error: 'deviceUuid is required' });
    }

    const db = require('../config/db');

    if (db.isOracle()) {
      await db.execute(
        `MERGE INTO deviceTb d
         USING (
           SELECT :deviceUuid AS device_uuid,
                  :deviceName AS device_name
           FROM DUAL
         ) src
         ON (d.device_uuid = src.device_uuid)
         WHEN MATCHED THEN
           UPDATE SET
             d.device_name = NVL(src.device_name, d.device_name),
             d.last_synced_at = SYSDATE
         WHEN NOT MATCHED THEN
           INSERT (
             device_uuid,
             device_name,
             registered_at,
             last_synced_at
           )
           VALUES (
             src.device_uuid,
             src.device_name,
             SYSDATE,
             SYSDATE
           )`,
        {
          deviceUuid: resolvedDeviceUuid,
          deviceName: resolvedDeviceName,
        },
        { autoCommit: true }
      );
    } else {
      await db.execute(
        `UPDATE deviceTb
         SET device_name = COALESCE(:deviceName, device_name),
             last_synced_at = CURRENT_TIMESTAMP
         WHERE device_uuid = :deviceUuid`,
        {
          deviceUuid: resolvedDeviceUuid,
          deviceName: resolvedDeviceName,
        },
        { autoCommit: true }
      );

      await db.execute(
        `INSERT INTO deviceTb (
           device_uuid,
           device_name,
           registered_at,
           last_synced_at
         )
         SELECT :deviceUuid, :deviceName, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
         WHERE NOT EXISTS (
           SELECT 1 FROM deviceTb WHERE device_uuid = :deviceUuid
         )`,
        {
          deviceUuid: resolvedDeviceUuid,
          deviceName: resolvedDeviceName,
        },
        { autoCommit: true }
      );
    }

    const row = await db.execute(
      `SELECT device_id FROM deviceTb WHERE device_uuid = :deviceUuid`,
      { deviceUuid: resolvedDeviceUuid }
    );
    const deviceId = row.rows[0]?.DEVICE_ID || null;

    const token = signToken(
      { role: 'device', deviceUuid: resolvedDeviceUuid, deviceId },
      90 * 24 * 60 * 60
    );

    return res.status(200).json({
      success: true,
      token,
      device_id: deviceId,
      expires_in: '90d',
      device: {
        deviceUuid: resolvedDeviceUuid,
        deviceName: resolvedDeviceName,
      },
    });
  } catch (error) {
    next(error);
  }
};