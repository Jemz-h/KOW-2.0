// Centralized Error Handling Middleware
const errorHandler = (err, req, res, next) => {
  // If the status code is still 200 (default), change it to 500 (Server Error)
  const statusCode = res.statusCode === 200 ? 500 : res.statusCode;
  
  res.status(statusCode);
  
  // Respond with a consistent JSON format
  res.json({
    success: false,
    message: err.message || 'Internal Server Error',
    // Only show stack trace in development mode for security
    stack: process.env.NODE_ENV === 'production' ? null : err.stack,
  });
};

// Middleware to handle 404 Not Found routes
const notFound = (req, res, next) => {
  const error = new Error(`Not Found - ${req.originalUrl}`);
  res.status(404);
  next(error); // Pass the error to the errorHandler
};

module.exports = { errorHandler, notFound };
