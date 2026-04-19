function normalizeQuestionImage(value) {
  if (value == null || value === '') {
    return null;
  }

  if (Buffer.isBuffer(value)) {
    return value;
  }

  if (value instanceof Uint8Array) {
    return Buffer.from(value);
  }

  if (typeof value === 'object') {
    if (value.type === 'Buffer' && Array.isArray(value.data)) {
      return Buffer.from(value.data);
    }

    if (Array.isArray(value.data)) {
      return Buffer.from(value.data);
    }
  }

  if (typeof value === 'string') {
    const trimmed = value.trim();
    if (!trimmed) {
      return null;
    }

    const base64 = trimmed.replace(/^data:[^;]+;base64,/, '');
    return Buffer.from(base64, 'base64');
  }

  return Buffer.from(String(value));
}

function serializeQuestionImage(value) {
  if (value == null) {
    return null;
  }

  if (Buffer.isBuffer(value)) {
    return value.toString('base64');
  }

  if (value instanceof Uint8Array) {
    return Buffer.from(value).toString('base64');
  }

  if (typeof value === 'object' && Array.isArray(value.data)) {
    return Buffer.from(value.data).toString('base64');
  }

  if (typeof value === 'string') {
    const trimmed = value.trim();
    if (!trimmed) {
      return null;
    }

    return trimmed.replace(/^data:[^;]+;base64,/, '');
  }

  return Buffer.from(String(value)).toString('base64');
}

module.exports = {
  normalizeQuestionImage,
  serializeQuestionImage,
};
