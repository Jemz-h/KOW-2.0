const fs = require('fs');
const path = require('path');
const { spawnSync } = require('child_process');
const { connectDatabase, closeDatabase, execute, isSqlite } = require('../config/db');

const SUBJECT_IDS = {
  reading: 4,
  writing: 4,
  numeracy: 1,
  'senses and observation': 2,
};

const GRADE_LEVEL_IDS = {
  punla: 1,
  binhi: 2,
};

const DIFFICULTY_IDS = {
  binhi: 1,
  punla: 2,
  advanced: 3,
};

function decodeHtmlEntities(value) {
  return value
    .replace(/&nbsp;/gi, ' ')
    .replace(/&quot;/gi, '"')
    .replace(/&#39;|&apos;/gi, "'")
    .replace(/&rsquo;|&lsquo;/gi, "'")
    .replace(/&ndash;|&mdash;/gi, '-')
    .replace(/&bull;/gi, '•')
    .replace(/&amp;/gi, '&')
    .replace(/&lt;/gi, '<')
    .replace(/&gt;/gi, '>');
}

function normalizeText(value) {
  return value
    .replace(/\s+/g, ' ')
    .replace(/[“”]/g, '"')
    .replace(/[‘’]/g, "'")
    .trim();
}

function stripTags(value) {
  return value.replace(/<[^>]+>/g, ' ');
}

function extractTokens(html) {
  const tokens = [];
  const blockRegex = /<(p|li)\b[^>]*>([\s\S]*?)<\/\1>/gi;
  let match;

  while ((match = blockRegex.exec(html)) !== null) {
    const tag = match[1].toLowerCase();
    const innerHtml = match[2];

    const imageRegex = /<img[^>]*src="([^"]+)"[^>]*>/gi;
    let imageMatch;
    while ((imageMatch = imageRegex.exec(innerHtml)) !== null) {
      tokens.push({ type: 'image', tag, value: imageMatch[1] });
    }

    const plainText = normalizeText(decodeHtmlEntities(stripTags(innerHtml)));
    if (plainText) {
      tokens.push({ type: 'text', tag, value: plainText });
    }
  }

  return tokens;
}

function normalizeQuestionText(line) {
  return normalizeText(line.replace(/^\d+\s*[.)]\s*/, ''));
}

function isHeading(line) {
  const lower = line.toLowerCase();
  return (
    lower === 'reading' ||
    lower === 'writing' ||
    lower === 'numeracy' ||
    lower === 'senses and observation'
  );
}

function normalizeForCompare(value) {
  return value
    .toLowerCase()
    .replace(/[\[\](){}]/g, '')
    .replace(/\s+/g, ' ')
    .trim();
}

function looksLikeQuestion(line) {
  const text = normalizeQuestionText(line);
  const lower = text.toLowerCase();

  if (!text) {
    return false;
  }

  if (/^answer\s*:/i.test(text)) {
    return false;
  }

  if (/^[a-d]\s*[.)]\s+/.test(text)) {
    return false;
  }

  if (/^[-_]{3,}$/.test(text)) {
    return false;
  }

  if (isHeading(text)) {
    return false;
  }

  if (
    lower.includes('?') ||
    lower.includes('___') ||
    lower.startsWith('choose ') ||
    lower.startsWith('complete ') ||
    lower.startsWith('fill in') ||
    lower.startsWith('in the') ||
    lower.startsWith('people are')
  ) {
    return true;
  }

  return false;
}

function mapHeading(line, state) {
  const lower = line.toLowerCase();

  if (SUBJECT_IDS[lower]) {
    state.subjectId = SUBJECT_IDS[lower];
    state.diffId = DIFFICULTY_IDS.binhi;
    return true;
  }

  if (lower.includes('binhi level') || lower === 'binhi') {
    state.gradeLevelId = GRADE_LEVEL_IDS.binhi;
    state.diffId = DIFFICULTY_IDS.binhi;
    return true;
  }

  if (lower.includes('punla level') || lower === 'punla' || lower === 'punla level') {
    state.gradeLevelId = GRADE_LEVEL_IDS.punla;
    state.diffId = DIFFICULTY_IDS.punla;
    return true;
  }

  if (
    lower.includes('difficult/advanced level') ||
    lower === 'advance' ||
    lower === 'advanced' ||
    lower.includes('advance 12 questions') ||
    lower.includes('difficult')
  ) {
    state.diffId = DIFFICULTY_IDS.advanced;
    return true;
  }

  if (lower === 'binhi 5 questions' || lower === 'punla 8 questions' || lower === 'advance 12 questions') {
    return true;
  }

  if (lower.includes('__________________________________')) {
    return true;
  }

  return false;
}

function resolveCorrectOption(answerValue, options) {
  const cleaned = normalizeText(answerValue);
  const letterMatch = cleaned.match(/^([a-d])$/i);
  if (letterMatch) {
    return letterMatch[1].toUpperCase();
  }

  const normalizedAnswer = normalizeForCompare(cleaned);
  const letters = ['A', 'B', 'C', 'D'];

  for (let i = 0; i < options.length; i += 1) {
    if (normalizeForCompare(options[i] || '') === normalizedAnswer) {
      return letters[i];
    }
  }

  return null;
}

function parseQuestions(html) {
  const tokens = extractTokens(html);
  const state = {
    subjectId: SUBJECT_IDS.reading,
    gradeLevelId: GRADE_LEVEL_IDS.binhi,
    diffId: DIFFICULTY_IDS.binhi,
    pendingImage: null,
    current: null,
    questions: [],
  };

  function beginQuestion(text) {
    state.current = {
      questionTxt: normalizeQuestionText(text),
      options: [null, null, null, null],
      optionImages: [null, null, null, null],
      listOptions: [],
      listOptionImages: [],
      pendingOptionImage: null,
      answer: null,
      imagePath: state.pendingImage,
      subjectId: state.subjectId,
      gradeLevelId: state.gradeLevelId,
      diffId: state.diffId,
    };
    state.pendingImage = null;
  }

  function commitQuestion() {
    if (!state.current) {
      return;
    }

    const current = state.current;

    if (current.listOptions.length === 4 && !current.options.some(Boolean)) {
      current.options = current.listOptions.slice(0, 4);
    }

    if (!current.questionTxt || !current.answer || current.options.some((opt) => !opt)) {
      state.current = null;
      return;
    }

    const correctOpt = resolveCorrectOption(current.answer, current.options);
    if (!correctOpt) {
      state.current = null;
      return;
    }

    state.questions.push({
      subject_id: current.subjectId,
      gradelvl_id: current.gradeLevelId,
      diff_id: current.diffId,
      question_txt: current.questionTxt,
      image_rel_path: current.imagePath,
      option_a: current.options[0],
      option_b: current.options[1],
      option_c: current.options[2],
      option_d: current.options[3],
      option_a_image_rel_path: current.optionImages[0],
      option_b_image_rel_path: current.optionImages[1],
      option_c_image_rel_path: current.optionImages[2],
      option_d_image_rel_path: current.optionImages[3],
      correct_opt: correctOpt,
    });

    state.current = null;
  }

  for (const token of tokens) {
    if (token.type === 'image') {
      if (state.current) {
        if (token.tag === 'li' && state.current.listOptionImages.length < 4) {
          state.current.listOptionImages.push(token.value);
        } else if (
          state.current.options.some((opt) => !opt) ||
          state.current.listOptions.length < 4
        ) {
          state.current.pendingOptionImage = token.value;
        } else {
          state.pendingImage = token.value;
        }
      } else {
        state.pendingImage = token.value;
      }
      continue;
    }

    const line = normalizeText(token.value);
    if (!line) {
      continue;
    }

    if (mapHeading(line, state)) {
      continue;
    }

    if (/^answer\s*:/i.test(line)) {
      if (state.current) {
        state.current.answer = normalizeText(line.replace(/^answer\s*:/i, ''));
        commitQuestion();
      }
      continue;
    }

    const alphaOptionMatch = line.match(/^([a-d])\s*[.)]\s*(.+)$/i);
    if (alphaOptionMatch && state.current) {
      const optionIndex = alphaOptionMatch[1].toUpperCase().charCodeAt(0) - 65;
      if (optionIndex >= 0 && optionIndex < 4) {
        state.current.options[optionIndex] = normalizeText(alphaOptionMatch[2]);
        if (state.current.listOptionImages[optionIndex]) {
          state.current.optionImages[optionIndex] = state.current.listOptionImages[optionIndex];
        } else if (state.current.pendingOptionImage) {
          state.current.optionImages[optionIndex] = state.current.pendingOptionImage;
          state.current.pendingOptionImage = null;
        }
      }
      continue;
    }

    if (token.tag === 'li' && state.current && state.current.listOptions.length < 4) {
      state.current.listOptions.push(line);
      if (state.current.listOptionImages[state.current.listOptions.length - 1]) {
        state.current.optionImages[state.current.listOptions.length - 1] =
          state.current.listOptionImages[state.current.listOptions.length - 1];
      } else if (state.current.pendingOptionImage) {
        state.current.optionImages[state.current.listOptions.length - 1] =
          state.current.pendingOptionImage;
        state.current.pendingOptionImage = null;
      }
      continue;
    }

    if (looksLikeQuestion(line)) {
      if (state.current) {
        commitQuestion();
      }
      beginQuestion(line);
      continue;
    }
  }

  if (state.current) {
    commitQuestion();
  }

  const unique = [];
  const seen = new Set();

  for (const question of state.questions) {
    const key = [
      question.subject_id,
      question.gradelvl_id,
      question.diff_id,
      question.question_txt.toLowerCase(),
      question.correct_opt,
    ].join('|');

    if (!seen.has(key)) {
      seen.add(key);
      unique.push(question);
    }
  }

  return unique;
}

function resolveImageBuffer(imageRelPath, imagesDir) {
  if (!imageRelPath) {
    return null;
  }

  const cleaned = imageRelPath.replace(/^\.\//, '').replace(/^images\//i, '');
  const absolutePath = path.join(imagesDir, cleaned);

  if (!fs.existsSync(absolutePath)) {
    return null;
  }

  return fs.readFileSync(absolutePath);
}

async function ensureSqliteQuestionImageColumns() {
  if (!isSqlite()) {
    return;
  }

  const tableCheck = await execute(
    `SELECT name
     FROM sqlite_master
     WHERE type = 'table'
       AND name = 'questionTb'`
  );

  if (tableCheck.rows.length === 0) {
    throw new Error(
      "SQLite questionTb table was not found. Start backend once in offline mode to bootstrap schema, then rerun import."
    );
  }

  const info = await execute(`SELECT name FROM pragma_table_info('questionTb')`);
  const existing = new Set(info.rows.map((row) => String(row.name || row.NAME || '').toLowerCase()));

  const requiredColumns = [
    'question_image',
    'option_a_image',
    'option_b_image',
    'option_c_image',
    'option_d_image',
  ];

  for (const column of requiredColumns) {
    if (!existing.has(column)) {
      await execute(`ALTER TABLE questionTb ADD COLUMN ${column} BLOB`);
    }
  }
}

async function upsertQuestion(question, imageBuffer, optionImageBuffers) {
  const existing = await execute(
    `SELECT question_id
     FROM questionTb
     WHERE subject_id = :subject_id
       AND gradelvl_id = :gradelvl_id
       AND diff_id = :diff_id
       AND question_txt = :question_txt
       AND correct_opt = :correct_opt`,
    {
      subject_id: question.subject_id,
      gradelvl_id: question.gradelvl_id,
      diff_id: question.diff_id,
      question_txt: question.question_txt,
      correct_opt: question.correct_opt,
    }
  );

  if (existing.rows.length > 0) {
    return false;
  }

  await execute(
    `INSERT INTO questionTb (
      subject_id,
      gradelvl_id,
      diff_id,
      question_txt,
      question_image,
      option_a,
      option_b,
      option_c,
      option_d,
      option_a_image,
      option_b_image,
      option_c_image,
      option_d_image,
      correct_opt
    ) VALUES (
      :subject_id,
      :gradelvl_id,
      :diff_id,
      :question_txt,
      :question_image,
      :option_a,
      :option_b,
      :option_c,
      :option_d,
      :option_a_image,
      :option_b_image,
      :option_c_image,
      :option_d_image,
      :correct_opt
    )`,
    {
      subject_id: question.subject_id,
      gradelvl_id: question.gradelvl_id,
      diff_id: question.diff_id,
      question_txt: question.question_txt,
      question_image: imageBuffer,
      option_a: question.option_a,
      option_b: question.option_b,
      option_c: question.option_c,
      option_d: question.option_d,
      option_a_image: optionImageBuffers[0],
      option_b_image: optionImageBuffers[1],
      option_c_image: optionImageBuffers[2],
      option_d_image: optionImageBuffers[3],
      correct_opt: question.correct_opt,
    },
    { autoCommit: true }
  );

  return true;
}

function parseCliArgs(argv) {
  const args = argv.slice(2);
  let sourceDirArg;
  let targets = 'current';
  let childRun = false;

  for (const arg of args) {
    if (arg === '--child-run') {
      childRun = true;
      continue;
    }

    if (arg.startsWith('--targets=')) {
      targets = arg.split('=')[1] || 'current';
      continue;
    }

    if (!arg.startsWith('--') && !sourceDirArg) {
      sourceDirArg = arg;
    }
  }

  return { sourceDirArg, targets: targets.toLowerCase(), childRun };
}

function runChildImport({ mode, sourceDirArg }) {
  const childArgs = [__filename];
  if (sourceDirArg) {
    childArgs.push(sourceDirArg);
  }
  childArgs.push('--child-run');

  const result = spawnSync(process.execPath, childArgs, {
    stdio: 'inherit',
    env: {
      ...process.env,
      DB_MODE: mode,
    },
  });

  return result.status ?? 1;
}

function runAllTargets({ sourceDirArg }) {
  const targets = [
    { mode: 'online', label: 'oracle' },
    { mode: 'offline', label: 'sqlite' },
  ];

  const failures = [];
  for (const target of targets) {
    console.log(`\n=== Import target: ${target.label} (DB_MODE=${target.mode}) ===`);
    const status = runChildImport({ mode: target.mode, sourceDirArg });
    if (status !== 0) {
      failures.push(target.label);
    }
  }

  if (failures.length === targets.length) {
    throw new Error(`Import failed for all targets: ${failures.join(', ')}`);
  }

  if (failures.length > 0) {
    console.warn(`Import completed with partial failures: ${failures.join(', ')}`);
  }
}

async function run() {
  const { sourceDirArg, targets, childRun } = parseCliArgs(process.argv);

  if (!childRun && targets === 'all') {
    runAllTargets({ sourceDirArg });
    return;
  }

  const sourceDir = sourceDirArg
    ? path.resolve(process.cwd(), sourceDirArg)
    : path.resolve(__dirname, '../../data/kow_questions');

  const htmlPath = path.join(sourceDir, 'KOWQuestions.html');
  const imagesDir = path.join(sourceDir, 'images');

  if (!fs.existsSync(htmlPath)) {
    throw new Error(`Could not find HTML source: ${htmlPath}`);
  }

  const html = fs.readFileSync(htmlPath, 'utf8');
  const questions = parseQuestions(html);

  if (questions.length === 0) {
    throw new Error('No questions were parsed from the source HTML.');
  }

  await connectDatabase();
  await ensureSqliteQuestionImageColumns();

  let insertedCount = 0;
  let skippedCount = 0;
  let withImageCount = 0;

  try {
    for (const question of questions) {
      const imageBuffer = resolveImageBuffer(question.image_rel_path, imagesDir);
      const optionImageBuffers = [
        resolveImageBuffer(question.option_a_image_rel_path, imagesDir),
        resolveImageBuffer(question.option_b_image_rel_path, imagesDir),
        resolveImageBuffer(question.option_c_image_rel_path, imagesDir),
        resolveImageBuffer(question.option_d_image_rel_path, imagesDir),
      ];
      if (imageBuffer) {
        withImageCount += 1;
      }
      const inserted = await upsertQuestion(question, imageBuffer, optionImageBuffers);
      if (inserted) {
        insertedCount += 1;
      } else {
        skippedCount += 1;
      }
    }
  } finally {
    await closeDatabase();
  }

  console.log(`Parsed questions: ${questions.length}`);
  console.log(`Inserted questions: ${insertedCount}`);
  console.log(`Skipped existing questions: ${skippedCount}`);
  console.log(`Questions with images found: ${withImageCount}`);
}

run().catch((error) => {
  console.error(error.message || error);
  process.exit(1);
});
