function pad(value) {
  return String(value).padStart(2, '0');
}

function normalizeDateOnly(input) {
  if (input === undefined || input === null) {
    return null;
  }

  const raw = String(input).trim();
  if (!raw) {
    return null;
  }

  const canonicalMatch = raw.match(/^(\d{4})-(\d{2})-(\d{2})$/);
  if (canonicalMatch) {
    return `${canonicalMatch[1]}-${canonicalMatch[2]}-${canonicalMatch[3]}`;
  }

  const slashMatch = raw.match(/^(\d{1,2})\/(\d{1,2})\/(\d{4})$/);
  if (slashMatch) {
    return `${slashMatch[3]}-${pad(slashMatch[1])}-${pad(slashMatch[2])}`;
  }

  const parsed = new Date(raw);
  if (Number.isNaN(parsed.getTime())) {
    return null;
  }

  return [
    parsed.getUTCFullYear(),
    pad(parsed.getUTCMonth() + 1),
    pad(parsed.getUTCDate()),
  ].join('-');
}

function normalizeTimestamp(input, fallback = null) {
  const raw = String(input || '').trim();

  if (!raw) {
    return fallback instanceof Date ? formatDate(fallback) : '';
  }

  const canonicalMatch = raw.match(
    /^(\d{4}-\d{2}-\d{2})[ T](\d{2}:\d{2}:\d{2})/
  );
  if (canonicalMatch) {
    return `${canonicalMatch[1]} ${canonicalMatch[2]}`;
  }

  const dateOnly = normalizeDateOnly(raw);
  if (dateOnly) {
    return `${dateOnly} 00:00:00`;
  }

  const parsed = new Date(raw);
  if (Number.isNaN(parsed.getTime())) {
    return fallback instanceof Date ? formatDate(fallback) : '';
  }

  return formatDate(parsed);
}

function formatDate(value) {
  return [
    value.getFullYear(),
    pad(value.getMonth() + 1),
    pad(value.getDate()),
  ].join('-') + ` ${pad(value.getHours())}:${pad(value.getMinutes())}:${pad(value.getSeconds())}`;
}

module.exports = {
  normalizeDateOnly,
  normalizeTimestamp,
};
