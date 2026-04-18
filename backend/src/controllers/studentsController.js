const {
  listStudents,
  findStudentById,
} = require('../repositories/students.repository');

// @desc    List all students
// @route   GET /api/students
// @access  Private
async function getStudents(req, res, next) {
  try {
    const rows = await listStudents();
    return res.status(200).json({ count: rows.length, data: rows });
  } catch (error) {
    return next(error);
  }
}

// @desc    Get a single student by ID
// @route   GET /api/students/:studentId
// @access  Private
async function getStudent(req, res, next) {
  try {
    const row = await findStudentById(String(req.params.studentId));
    if (!row) {
      return res.status(404).json({ message: 'Student not found.' });
    }

    const { passwordHash, ...safe } = row;
    return res.status(200).json({ data: safe });
  } catch (error) {
    return next(error);
  }
}

module.exports = {
  getStudents,
  getStudent,
};
