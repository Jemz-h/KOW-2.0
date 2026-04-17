function notFoundHandler(req, res) {
  return res.status(404).json({ message: 'Route not found.' });
}

function errorHandler(err, req, res, next) {
  if (res.headersSent) {
    return next(err);
  }

  const statusCode = err.statusCode || 500;
  return res.status(statusCode).json({
    message: err.message || 'Internal server error.',
  });
}

module.exports = {
  notFoundHandler,
  errorHandler,
};
