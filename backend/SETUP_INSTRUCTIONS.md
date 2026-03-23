# Setup Instructions for Birthday-Based Password System

## Overview
The system uses each user's **birthday as their password**. The birthday is stored in hashed format for security.

## Installation Steps

### 1. Install bcrypt dependency
Open Command Prompt or PowerShell in the backend folder:
```bash
cd "c:\Users\Administrator\Desktop\2E KOW\KOW-True.worktrees\copilot-worktree-2026-03-22T02-03-04\backend"
npm install bcrypt
```

### 2. Apply the SQL Schema
Choose one of these methods:

#### Method A: Using SQL*Plus (Command Line)
```bash
sqlplus kow_admin/admin123@localhost:1521/XEPDB1
@c:\Users\Administrator\Desktop\2E KOW\KOW-True.worktrees\copilot-worktree-2026-03-22T02-03-04\backend\src\config\setup.sql
EXIT;
```

#### Method B: Using SQL Developer (GUI)
1. Connect to: `kow_admin/admin123@localhost:1521/XEPDB1`
2. Open file: `backend\src\config\setup.sql`
3. Click "Run Script" button (F5)

### 3. Start the backend
```bash
npm run dev
```

## How It Works

### User Registration
- When a user registers with birthday `2010-05-15`
- The system automatically hashes `2010-05-15` and stores it as the password
- The birthday is also stored in the `birthday` field

### User Login
- User enters their nickname/username and birthday (format: YYYY-MM-DD)
- System hashes the entered birthday and compares it with stored password hash
- If match, user is authenticated

### Birthday Changes
- If a user's birthday is updated, their password is automatically updated too
- Use endpoint: `PUT /api/users/:id/birthday` with `{ "birthday": "YYYY-MM-DD" }`

## Security Notes

⚠️ **WARNING**: Using birthday as password is inherently insecure because:
- Birthdays are often public information
- They are easy to guess
- No password complexity

### Mitigations in place:
✅ Passwords are hashed using bcrypt (10 salt rounds)
✅ Plain text passwords are NEVER stored
✅ Password field has database comment warning about hashing requirement
✅ GET endpoints exclude password from responses

### Recommended additional security:
- Add account lockout after failed login attempts
- Implement rate limiting on login endpoint
- Add CAPTCHA for login
- Consider two-factor authentication
- Log all authentication attempts

## API Examples

### Create User
```bash
POST /api/users
Content-Type: application/json

{
  "username": "juan123",
  "firstName": "Juan",
  "lastName": "Dela Cruz",
  "birthday": "2010-05-15"
}
```
Password is automatically set to hashed version of `2010-05-15`

### Login (Using UserModel)
```javascript
const UserModel = require('./models/userModel');
const user = await UserModel.findUserByNicknameAndBirthday("juan123", "2010-05-15");
if (user) {
  // Login successful
} else {
  // Invalid credentials
}
```

### Update Birthday (and password)
```bash
PUT /api/users/1/birthday
Content-Type: application/json

{
  "birthday": "2010-05-16"
}
```
Both birthday and password are updated together.

## Birthday Format
**Always use: YYYY-MM-DD** (e.g., `2010-05-15`)

## Files Changed
- ✅ `backend/src/config/setup.sql` - Enhanced with foreign keys, indexes, constraints, comments, and triggers
- ✅ `backend/src/middleware/passwordHelper.js` - New file for password hashing
- ✅ `backend/src/models/userModel.js` - Updated to hash passwords
- ✅ `backend/src/controllers/userController.js` - Updated to hash passwords and exclude them from responses

