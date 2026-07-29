// GET /time-tracking/v2 — Claude-subset implementation of the Remote Bridge v2
// contract (see claude-config plans/multi-harness-time-tracking.md, "Remote
// Bridge v2 contract" and "Persisted schemas"). Phase 1 supports only the
// `claude` harness; Phase 3 extends SUPPORTED_HARNESSES and the file basename
// mapping for `opencode`.
//
// Every path root (tracking directory, home directory, settings.json path) is
// injectable so tests never touch the real ~/.claude tree. createHandler()
// wires the real defaults for production use.

const fs = require('fs');
const fsp = require('fs').promises;
const path = require('path');
const os = require('os');
const crypto = require('crypto');
const { TextDecoder } = require('util');
const { z } = require('zod');

const TRACKING_DIR = path.join(os.homedir(), '.claude', 'time-tracking');
const SUPPORTED_HARNESSES = ['claude'];
const MAX_DATES = 31;
const MAX_URI_BYTES = 4096;
// A daily per-harness JSONL event file has no legitimate reason to approach
// this size; a file over it is treated as a source error instead of being
// read into memory and echoed verbatim into the response.
const MAX_EVENT_FILE_BYTES = 8 * 1024 * 1024;
// Caps the number of per-line/per-file error records carried in one
// response: without a bound, a single catastrophically malformed file (one
// error per line) can make the errors array dominate response size.
const MAX_ERRORS = 500;
const DATE_RE = /^\d{4}-\d{2}-\d{2}$/;
const HARNESS_TOKEN_RE = /^[a-z]+$/;
const UTC_TIMESTAMP_RE = /^(\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2})(?:\.(\d{3}))?Z$/;
// The collector version string reported per installed harness in the v2
// response's collector_versions map (Phase 1 supports only 'claude'; Phase 3
// adds 'opencode'). Shared between the handler (which builds the map) and
// ResponseSchema (which independently recomputes the expected map to
// validate a possibly-untrusted response — see FileDescriptorSchema's
// sha256 recomputation above for the same defense-in-depth reasoning).
const COLLECTOR_VERSIONS = { claude: 'claude-hook-v3', opencode: 'opencode-plugin-v1' };

class ValidationError extends Error {}

// --- Canonical JSON + digest (must match the plan's Python
// json.dumps(value, ensure_ascii=False, sort_keys=True, separators=(",", ":"))
// byte for byte: JSON.stringify already leaves non-ASCII characters literal,
// so the only gap to close is key ordering, which we sort recursively.
function canonicalJSON(value) {
  if (value === null || typeof value !== 'object') {
    return JSON.stringify(value);
  }
  if (Array.isArray(value)) {
    return `[${value.map(canonicalJSON).join(',')}]`;
  }
  const keys = Object.keys(value).sort();
  return `{${keys.map((key) => `${JSON.stringify(key)}:${canonicalJSON(value[key])}`).join(',')}}`;
}

function digest(label, value) {
  const hash = crypto.createHash('sha256');
  hash.update(Buffer.from(label, 'ascii'));
  hash.update(Buffer.from([0]));
  hash.update(Buffer.from(canonicalJSON(value), 'utf-8'));
  return hash.digest('hex');
}

// --- Timestamps
// Native updatedAt/modified arrive as epoch milliseconds (number) or an
// ISO-8601 string with millisecond precision; both convert to the plan's
// canonical whole-second UTC "YYYY-MM-DDTHH:MM:SSZ" format before any
// metadata_id is derived from them.
function toCanonicalTimestamp(value) {
  let timestamp;
  if (typeof value === 'number' && Number.isSafeInteger(value)) {
    timestamp = new Date(value);
  } else if (typeof value === 'string') {
    const match = UTC_TIMESTAMP_RE.exec(value);
    if (!match) {
      throw new Error('invalid timestamp value');
    }
    timestamp = new Date(value);
    const expected = `${match[1]}.${match[2] || '000'}Z`;
    if (Number.isNaN(timestamp.getTime()) || timestamp.toISOString() !== expected) {
      throw new Error('invalid timestamp value');
    }
  } else {
    throw new Error('invalid timestamp value');
  }
  if (Number.isNaN(timestamp.getTime())) {
    throw new Error('invalid timestamp value');
  }
  const canonical = timestamp.toISOString().replace(/\.\d{3}Z$/, 'Z');
  // 8.64e15 ms is a safe integer and the largest value Date accepts without
  // overflowing to NaN, but it lands on year 275760: toISOString() renders
  // that as an extended, signed, 6-digit year ("+275760-...") instead of the
  // canonical 4-digit form. Catch it here, at the source, rather than
  // letting it reach TimestampSchema deep inside validateResponse where it
  // would fail the whole response instead of just this one record.
  if (!TIMESTAMP_RE.test(canonical)) {
    throw new Error('invalid timestamp value');
  }
  return canonical;
}

// --- Hostname
// (CLAUDE_HOSTNAME or os.hostname()).split('.')[0].lower(); an empty result
// is a schema error rather than a silently-accepted blank hostname.
function canonicalHostname({ env = process.env, hostnameFn = () => os.hostname() } = {}) {
  const raw = env.CLAUDE_HOSTNAME || hostnameFn();
  const short = raw.split('.')[0].toLowerCase();
  if (!short) {
    throw new Error('canonical hostname resolved to an empty string');
  }
  return short;
}

// --- Query validation
const QuerySchema = z.object({
  dates: z.string(),
  harnesses: z.string(),
}).strict();

// Rejects a shape-valid but calendar-invalid date (e.g. 2026-13-40, or
// 2026-02-30): reparsing as UTC and comparing the components back out
// catches everything Date silently normalizes instead of rejecting.
function isValidCalendarDate(dateStr) {
  if (!DATE_RE.test(dateStr)) return false;
  const [year, month, day] = dateStr.split('-').map(Number);
  const date = new Date(Date.UTC(year, month - 1, day));
  return date.getUTCFullYear() === year && date.getUTCMonth() === month - 1 && date.getUTCDate() === day;
}

function parseCsvField(raw, { label, itemValidator, isSupported, maxItems }) {
  const items = raw.split(',');
  if (items.some((item) => item.length === 0)) {
    throw new ValidationError(`${label} must not contain empty values`);
  }
  for (const item of items) {
    if (!itemValidator(item)) {
      throw new ValidationError(`invalid ${label} value: ${item}`);
    }
    if (isSupported && !isSupported(item)) {
      throw new ValidationError(`unsupported ${label} value: ${item}`);
    }
  }
  const seen = new Set();
  for (const item of items) {
    if (seen.has(item)) {
      throw new ValidationError(`duplicate ${label} value: ${item}`);
    }
    seen.add(item);
  }
  const sorted = [...items].sort();
  for (let index = 0; index < items.length; index += 1) {
    if (items[index] !== sorted[index]) {
      throw new ValidationError(`${label} must be sorted ascending`);
    }
  }
  if (maxItems !== undefined && items.length > maxItems) {
    throw new ValidationError(`too many ${label} values: ${items.length} exceeds max ${maxItems}`);
  }
  return items;
}

function isUriTooLong(originalUrl) {
  return Buffer.byteLength(originalUrl, 'utf-8') > MAX_URI_BYTES;
}

function parseQuery(rawQuery) {
  const result = QuerySchema.safeParse(rawQuery);
  if (!result.success) {
    const message = result.error.issues
      .map((issue) => `${issue.path.join('.') || '(query)'}: ${issue.message}`)
      .join('; ');
    throw new ValidationError(message);
  }

  const dates = parseCsvField(result.data.dates, {
    label: 'dates',
    itemValidator: isValidCalendarDate,
    maxItems: MAX_DATES,
  });
  const harnesses = parseCsvField(result.data.harnesses, {
    label: 'harnesses',
    itemValidator: (item) => HARNESS_TOKEN_RE.test(item),
    isSupported: (item) => SUPPORTED_HARNESSES.includes(item),
  });

  return { dates, harnesses };
}

// --- Event file descriptors
// Phase 1 only ever reaches this with harness === 'claude', so the basename
// is hardcoded to the authoritative daily file; Phase 3 must extend this
// mapping for '<date>.opencode.jsonl'.
function eventBasename(harness, date) {
  if (harness !== 'claude') {
    throw new Error(`eventBasename: unsupported harness for Phase 1: ${harness}`);
  }
  return `${date}.jsonl`;
}

const SOURCE_ERROR_CODES = ['missing_file', 'transport_timeout', 'transport_error', 'malformed_json', 'unsupported_schema', 'suffix_harness_mismatch', 'metadata_missing_parent', 'metadata_cycle', 'duplicate_id_conflict', 'lock_timeout', 'write_failed', 'permissions_invalid', 'collector_version_mismatch', 'self_loop'];
const SHA256_RE = /^[0-9a-f]{64}$/;
const ID_RE = /^[!-~]{1,160}$/;
const TIMESTAMP_RE = /^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z$/;

function isSortedUnique(values) {
  return values.length > 0 && values.every((value, index) => (index === 0 || values[index - 1] < value));
}

function isApprovedBasename(value) {
  return typeof value === 'string' && value === path.basename(value) && !value.includes(path.sep) && !value.includes('/');
}

function errorRecord(code, file, line = null) {
  const messages = {
    permissions_invalid: 'file could not be read',
    malformed_json: 'source JSON is invalid',
    unsupported_schema: 'source schema is unsupported',
    transport_error: 'file exceeds the maximum supported size',
  };
  return { code, message: messages[code], file, line };
}

function decodeUtf8(bytes) {
  return new TextDecoder('utf-8', { fatal: true }).decode(bytes);
}

// Hashes the exact UTF-8 content string a file descriptor reports, not raw
// bytes: TextDecoder strips a leading UTF-8 BOM by default, so a
// BOM-prefixed file's raw bytes never match the digest of the `content`
// string actually returned in the response. Used both to compute the
// descriptor's sha256 (buildFileDescriptor) and to independently recompute
// it for validation (FileDescriptorSchema's superRefine) — see that
// superRefine's comment for why the recomputation stays even though it
// duplicates this call.
function contentSha256(content) {
  return crypto.createHash('sha256').update(Buffer.from(content, 'utf-8')).digest('hex');
}

async function buildFileDescriptor({ trackingDir, harness, date, errors, readFile = fsp.readFile, stat = fsp.stat }) {
  const basename = eventBasename(harness, date);
  const filePath = path.join(trackingDir, basename);

  // Check the size before reading: stat costs a syscall, not the file's
  // bytes, so an oversized file is rejected without ever loading it into
  // memory. Checking buffer.length after readFile (the previous approach)
  // gave no protection at all — the whole file was already resident by the
  // time the check ran.
  let fileStat;
  try {
    fileStat = await stat(filePath);
  } catch (error) {
    if (error.code === 'ENOENT') {
      return { kind: 'events', harness, business_date: date, basename, present: false, sha256: null, content: null };
    }
    errors.push(errorRecord('permissions_invalid', basename));
    return { kind: 'events', harness, business_date: date, basename, present: false, sha256: null, content: null };
  }

  if (fileStat.size > MAX_EVENT_FILE_BYTES) {
    errors.push(errorRecord('transport_error', basename));
    return { kind: 'events', harness, business_date: date, basename, present: false, sha256: null, content: null };
  }

  let buffer;
  try {
    buffer = await readFile(filePath);
  } catch (error) {
    if (error.code === 'ENOENT') {
      return { kind: 'events', harness, business_date: date, basename, present: false, sha256: null, content: null };
    }
    // Never substitute an empty string for a read failure — record it.
    errors.push(errorRecord('permissions_invalid', basename));
    return { kind: 'events', harness, business_date: date, basename, present: false, sha256: null, content: null };
  }

  let content;
  try {
    content = decodeUtf8(buffer);
  } catch {
    errors.push(errorRecord('malformed_json', basename));
    return { kind: 'events', harness, business_date: date, basename, present: false, sha256: null, content: null };
  }
  const sha256 = contentSha256(content);
  return { kind: 'events', harness, business_date: date, basename, present: true, sha256, content };
}

function splitLines(text) {
  const lines = text.split('\n');
  if (lines.length > 0 && lines[lines.length - 1] === '') {
    lines.pop();
  }
  return lines;
}

// Parses only session_id out of each requested event file's lines; a
// malformed line is recorded as an error rather than silently skipped.
function extractSessionIds(content, basename, sessionIds, errors) {
  splitLines(content).forEach((line, index) => {
    let parsed;
    try {
      parsed = JSON.parse(line);
    } catch (error) {
      errors.push(errorRecord('malformed_json', basename, index + 1));
      return;
    }
    if (parsed && typeof parsed.session_id === 'string' && parsed.session_id.length > 0) {
      sessionIds.add(parsed.session_id);
    }
  });
}

// --- ClaudeSessionMetadataV1 projection
// Absent directories (ENOENT) are optional metadata sources, not errors; any
// other readdir failure (permissions, races) is a genuine source error
// recorded under `label`, the sanitized name surfaced in the response
// instead of the real path.
async function readdirOrRecordError(dirPath, label, options, { readdir, errors }) {
  try {
    return await readdir(dirPath, options);
  } catch (error) {
    if (error.code === 'ENOENT') return [];
    errors.push(errorRecord('permissions_invalid', label));
    return [];
  }
}

async function globSessionsIndexFiles(homedir, { readdir = fsp.readdir, errors }) {
  const projectsDir = path.join(homedir, '.claude', 'projects');
  const entries = await readdirOrRecordError(projectsDir, 'projects', { withFileTypes: true }, { readdir, errors });
  return entries
    .filter((entry) => entry.isDirectory())
    .map((entry) => path.join(projectsDir, entry.name, 'sessions-index.json'));
}

async function globSessionFiles(homedir, { readdir = fsp.readdir, errors }) {
  const sessionsDir = path.join(homedir, '.claude', 'sessions');
  const entries = await readdirOrRecordError(sessionsDir, 'sessions', undefined, { readdir, errors });
  return entries
    .filter((name) => /^[0-9].*\.json$/.test(name))
    .map((name) => path.join(sessionsDir, name));
}

function claudeMetadataId({ hostname, sessionId, name, updatedAt }) {
  return `clm_${digest('claude-session-metadata-v1', { hostname, session_id: sessionId, name, updated_at: updatedAt })}`;
}

function isRecord(value) {
  return value !== null && typeof value === 'object' && !Array.isArray(value);
}

// Reads and JSON-parses one metadata source file, recording the appropriate
// error for every failure mode: a read failure other than ENOENT is
// `permissions_invalid`, and invalid UTF-8 or invalid JSON is
// `malformed_json`. Returns `undefined` for every failure (including ENOENT,
// which is an absent optional file, not an error, so nothing is pushed for
// it) — distinct from a legitimate parsed value of `null`, which callers
// still route through their own structure checks below.
async function readJsonFile(filePath, { readFile, errors }) {
  const basename = path.basename(filePath);
  let bytes;
  try {
    bytes = await readFile(filePath);
  } catch (error) {
    if (error.code === 'ENOENT') return undefined;
    errors.push(errorRecord('permissions_invalid', basename));
    return undefined;
  }

  let raw;
  try {
    raw = decodeUtf8(bytes);
  } catch {
    errors.push(errorRecord('malformed_json', basename));
    return undefined;
  }

  try {
    return JSON.parse(raw);
  } catch {
    errors.push(errorRecord('malformed_json', basename));
    return undefined;
  }
}

async function projectClaudeSessionMetadata({ homedir, hostname, sessionIds, errors, observedAt, readFile = fsp.readFile, readdir = fsp.readdir }) {
  if (sessionIds.size === 0) {
    return [];
  }

  const records = [];

  const indexFiles = await globSessionsIndexFiles(homedir, { readdir, errors });
  for (const filePath of indexFiles) {
    const basename = path.basename(filePath);
    // A project directory without its own sessions-index.json is an absent
    // optional file, not an error — readJsonFile only records genuine read
    // failures (permissions, races) and malformed content.
    const parsed = await readJsonFile(filePath, { readFile, errors });
    if (parsed === undefined) continue;

    if (!isRecord(parsed) || !Array.isArray(parsed.entries)) {
      errors.push(errorRecord('malformed_json', basename));
      continue;
    }
    const entries = parsed.entries;
    for (const entry of entries) {
      if (!isRecord(entry)) {
        errors.push(errorRecord('malformed_json', basename));
        continue;
      }
      if (!sessionIds.has(entry.sessionId)) continue;
      if (typeof entry.customTitle !== 'string' || entry.customTitle.length === 0) continue;
      if (typeof entry.modified !== 'string' || entry.modified.length === 0) {
        errors.push(errorRecord('malformed_json', basename));
        continue;
      }

      let updatedAt;
      try {
        updatedAt = toCanonicalTimestamp(entry.modified);
      } catch (error) {
        errors.push(errorRecord('malformed_json', basename));
        continue;
      }

      records.push({
        schema_version: 1,
        harness: 'claude',
        metadata_id: claudeMetadataId({ hostname, sessionId: entry.sessionId, name: entry.customTitle, updatedAt }),
        hostname,
        observed_at: observedAt,
        session_id: entry.sessionId,
        name: entry.customTitle,
        updated_at: updatedAt,
      });
    }
  }

  const sessionFiles = await globSessionFiles(homedir, { readdir, errors });
  for (const filePath of sessionFiles) {
    const basename = path.basename(filePath);
    const parsed = await readJsonFile(filePath, { readFile, errors });
    if (parsed === undefined) continue;

    if (!isRecord(parsed)) {
      errors.push(errorRecord('malformed_json', basename));
      continue;
    }
    if (typeof parsed.sessionId !== 'string' || parsed.sessionId.length === 0) {
      if (Object.prototype.hasOwnProperty.call(parsed, 'name')
        || Object.prototype.hasOwnProperty.call(parsed, 'nameSource')
        || Object.prototype.hasOwnProperty.call(parsed, 'updatedAt')) {
        errors.push(errorRecord('malformed_json', basename));
      }
      continue;
    }
    if (!sessionIds.has(parsed.sessionId)) continue;
    if (typeof parsed.name !== 'string' || parsed.name.length === 0) continue;

    const nameSource = Object.prototype.hasOwnProperty.call(parsed, 'nameSource') ? parsed.nameSource : undefined;
    const isExplicit = nameSource === 'user' || nameSource === null || nameSource === undefined;
    const isKnownImplicit = nameSource === 'auto' || nameSource === 'derived';

    if (!isExplicit && !isKnownImplicit) {
      errors.push(errorRecord('unsupported_schema', basename));
      continue;
    }
    if (!isExplicit) continue;

    if (typeof parsed.updatedAt !== 'number' && typeof parsed.updatedAt !== 'string') {
      errors.push(errorRecord('malformed_json', basename));
      continue;
    }

    let updatedAt;
    try {
      updatedAt = toCanonicalTimestamp(parsed.updatedAt);
    } catch (error) {
      errors.push(errorRecord('malformed_json', basename));
      continue;
    }

    records.push({
      schema_version: 1,
      harness: 'claude',
      metadata_id: claudeMetadataId({ hostname, sessionId: parsed.sessionId, name: parsed.name, updatedAt }),
      hostname,
      observed_at: observedAt,
      session_id: parsed.sessionId,
      name: parsed.name,
      updated_at: updatedAt,
    });
  }

  return records;
}

// --- CollectorHealthV1
function isCanonicalTimestamp(value) {
  try {
    return typeof value === 'string' && TIMESTAMP_RE.test(value) && toCanonicalTimestamp(value) === value;
  } catch {
    return false;
  }
}

const HealthRecordSchema = z.object({
  schema_version: z.literal(1),
  health_id: z.string().regex(ID_RE),
  harness: z.enum(['claude', 'opencode']),
  hostname: z.string().min(1).refine((value) => value === value.toLowerCase()),
  collector_instance_id: z.string().regex(ID_RE),
  timestamp: z.string().refine(isCanonicalTimestamp),
  status: z.enum(['collector_started', 'collector_stopped', 'write_failed', 'lock_timeout', 'schema_rejected']),
  event_id: z.string().regex(ID_RE).nullable(),
  error_code: z.enum(SOURCE_ERROR_CODES).nullable(),
  detail: z.string().max(512).nullable(),
}).strict().refine((record) => record.error_code !== 'permissions_invalid' || record.status === 'write_failed');

const IdSchema = z.string().regex(ID_RE);
const TimestampSchema = z.string().refine(isCanonicalTimestamp, 'timestamp must be a valid whole-second UTC timestamp');
const HostnameSchema = z.string().min(1).refine((value) => value === value.toLowerCase(), 'hostname must be lowercase');
const SourceErrorSchema = z.object({
  code: z.enum(SOURCE_ERROR_CODES),
  message: z.string().min(1),
  file: z.string().refine(isApprovedBasename, 'file must be an approved basename').nullable(),
  line: z.number().int().positive().nullable(),
}).strict();
const FileDescriptorSchema = z.object({
  kind: z.literal('events'),
  harness: z.enum(['claude', 'opencode']),
  business_date: z.string().refine(isValidCalendarDate, 'business_date must be a valid date'),
  basename: z.string(),
  present: z.boolean(),
  sha256: z.string().regex(SHA256_RE).nullable(),
  content: z.string().nullable(),
}).strict().superRefine((descriptor, context) => {
  const expectedBasename = descriptor.harness === 'claude'
    ? `${descriptor.business_date}.jsonl`
    : `${descriptor.business_date}.opencode.jsonl`;
  if (descriptor.basename !== expectedBasename || !isApprovedBasename(descriptor.basename)) {
    context.addIssue({ code: z.ZodIssueCode.custom, message: 'descriptor basename is invalid' });
  }
  if (descriptor.present !== (descriptor.content !== null && descriptor.sha256 !== null)) {
    context.addIssue({ code: z.ZodIssueCode.custom, message: 'descriptor presence and nullable fields disagree' });
  }
  if (descriptor.present) {
    const actual = contentSha256(descriptor.content);
    if (descriptor.sha256 !== actual) {
      context.addIssue({ code: z.ZodIssueCode.custom, message: 'descriptor sha256 does not match content' });
    }
  }
});
const ClaudeMetadataSchema = z.object({
  schema_version: z.literal(1), harness: z.literal('claude'), metadata_id: IdSchema, hostname: HostnameSchema,
  observed_at: TimestampSchema, session_id: z.string().min(1), name: z.string().min(1), updated_at: TimestampSchema,
}).strict();
const OpenCodeMetadataSchema = z.object({
  schema_version: z.literal(1), harness: z.literal('opencode'), metadata_id: IdSchema, hostname: HostnameSchema,
  observed_at: TimestampSchema, session_id: z.string().min(1), parent_session_id: z.string().min(1).nullable(), title: z.string(), updated_at: TimestampSchema,
}).strict();
const ResponseSchema = z.object({
  schema_version: z.literal(2),
  hostname: HostnameSchema,
  timezone: z.literal('Europe/Berlin'),
  requested_dates: z.array(z.string().refine(isValidCalendarDate)).min(1).refine(isSortedUnique, 'requested_dates must be sorted and unique'),
  requested_harnesses: z.array(z.enum(['claude', 'opencode'])).min(1).refine(isSortedUnique, 'requested_harnesses must be sorted and unique'),
  installed_harnesses: z.array(z.enum(['claude', 'opencode'])).refine((values) => values.length === 0 || isSortedUnique(values), 'installed_harnesses must be sorted and unique'),
  collector_versions: z.record(z.enum(['claude', 'opencode']), z.string().min(1)),
  files: z.array(FileDescriptorSchema),
  session_metadata: z.array(z.discriminatedUnion('harness', [ClaudeMetadataSchema, OpenCodeMetadataSchema])),
  health: z.array(HealthRecordSchema),
  errors: z.array(SourceErrorSchema).max(MAX_ERRORS),
}).strict().superRefine((response, context) => {
  const installed = new Set(response.installed_harnesses);
  const keys = Object.keys(response.collector_versions);
  if (keys.length !== installed.size || keys.some((key) => !installed.has(key)) || keys.some((key) => response.collector_versions[key] !== COLLECTOR_VERSIONS[key])) {
    context.addIssue({ code: z.ZodIssueCode.custom, message: 'collector_versions must exactly match installed_harnesses' });
  }
  const expected = new Set(response.requested_dates.flatMap((date) => response.requested_harnesses.map((harness) => `${date}:${harness}`)));
  const actual = response.files.map((file) => `${file.business_date}:${file.harness}`);
  if (actual.length !== expected.size || new Set(actual).size !== actual.length || actual.some((pair) => !expected.has(pair))) {
    context.addIssue({ code: z.ZodIssueCode.custom, message: 'files must exactly match requested date and harness pairs' });
  }
});

function validateResponse(response, expectedRequest) {
  const parsed = ResponseSchema.parse(response);
  if (expectedRequest && (JSON.stringify(parsed.requested_dates) !== JSON.stringify(expectedRequest.dates)
    || JSON.stringify(parsed.requested_harnesses) !== JSON.stringify(expectedRequest.harnesses))) {
    throw new Error('response request scope does not match the requested dates and harnesses');
  }
  return parsed;
}

async function readHealthRecords({ trackingDir, date, errors, readFile = fsp.readFile }) {
  const basename = `${date}.claude-health.jsonl`;
  const filePath = path.join(trackingDir, basename);

  let bytes;
  try {
    bytes = await readFile(filePath);
  } catch (error) {
    if (error.code === 'ENOENT') {
      return [];
    }
    errors.push(errorRecord('permissions_invalid', basename));
    return [];
  }

  let raw;
  try {
    raw = decodeUtf8(bytes);
  } catch {
    errors.push(errorRecord('malformed_json', basename));
    return [];
  }

  const records = [];
  splitLines(raw).forEach((line, index) => {
    let parsed;
    try {
      parsed = JSON.parse(line);
    } catch (error) {
      errors.push(errorRecord('malformed_json', basename, index + 1));
      return;
    }

    const result = HealthRecordSchema.safeParse(parsed);
    if (!result.success) {
      errors.push(errorRecord('unsupported_schema', basename, index + 1));
      return;
    }

    records.push(result.data);
  });

  return records;
}

// --- Installed-harness detection
// "Claude is installed only when the executable hook exists and the
// effective Claude settings register it" (source health decision table).
function collectHookCommands(node, commands = []) {
  if (Array.isArray(node)) {
    node.forEach((child) => collectHookCommands(child, commands));
  } else if (node && typeof node === 'object') {
    if (typeof node.command === 'string') {
      commands.push(node.command);
    }
    Object.values(node).forEach((child) => collectHookCommands(child, commands));
  }
  return commands;
}

// Distinguishes "genuinely not installed" (no error: settings.json absent,
// or present and parses but registers no time-tracker.sh hook) from
// "installed but broken" (a source error per the plan's source health
// decision table: "Installed but disabled, unreadable, or version-mismatched
// collectors are source errors, not uninstalled sources"). A settings.json
// that exists but cannot be read or parsed makes registration status
// undeterminable, which is itself a source error, not a clean absence.
async function detectClaudeInstalled({ settingsPath, homedir, access = fsp.access, errors }) {
  const resolvedHomedir = homedir || os.homedir();
  const resolvedSettingsPath = settingsPath || path.join(resolvedHomedir, '.claude', 'settings.json');

  let raw;
  try {
    raw = await fsp.readFile(resolvedSettingsPath, 'utf-8');
  } catch (error) {
    if (error.code === 'ENOENT') {
      return false;
    }
    errors.push(errorRecord('permissions_invalid', 'settings.json'));
    return false;
  }

  let settings;
  try {
    settings = JSON.parse(raw);
  } catch {
    errors.push(errorRecord('malformed_json', 'settings.json'));
    return false;
  }

  const commands = collectHookCommands(settings.hooks || {});
  const hookCommand = commands.find((command) => /time-tracker\.sh/.test(command));
  if (!hookCommand) {
    return false;
  }

  const match = hookCommand.match(/(\S*time-tracker\.sh)/);
  if (!match) {
    return false;
  }

  const scriptPath = match[1].startsWith('~') ? path.join(resolvedHomedir, match[1].slice(1)) : match[1];

  try {
    await access(scriptPath, fs.constants.X_OK);
    return true;
  } catch {
    // Registered in settings.json but not executable (missing file, wrong
    // permissions) is a broken collector, not an absent one.
    errors.push(errorRecord('permissions_invalid', path.basename(scriptPath)));
    return false;
  }
}

async function mapSeries(values, mapper) {
  const results = [];
  for (const value of values) {
    results.push(await mapper(value));
  }
  return results;
}

// --- HTTP handler
function createHandler({
  trackingDir = TRACKING_DIR,
  homedir = os.homedir(),
  settingsPath,
  env = process.env,
  hostnameFn = () => os.hostname(),
  clock = () => Date.now(),
  readFile = fsp.readFile,
  stat = fsp.stat,
} = {}) {
  return async function timeTrackingV2Handler(req, res) {
    if (isUriTooLong(req.originalUrl)) {
      return res.status(400).json({ error: `request URI exceeds ${MAX_URI_BYTES} bytes` });
    }

    let query;
    try {
      query = parseQuery(req.query);
    } catch (error) {
      if (error instanceof ValidationError) {
        return res.status(400).json({ error: error.message });
      }
      throw error;
    }

    const { dates, harnesses } = query;
    const hostname = canonicalHostname({ env, hostnameFn });
    const errors = [];

    const files = await mapSeries(
      harnesses.flatMap((harness) => dates.map((date) => ({ harness, date }))),
      ({ harness, date }) => buildFileDescriptor({ trackingDir, harness, date, errors, readFile, stat })
    );

    const sessionIds = new Set();
    for (const file of files) {
      if (file.present && file.content) {
        extractSessionIds(file.content, file.basename, sessionIds, errors);
      }
    }

    const observedAt = toCanonicalTimestamp(clock());
    const sessionMetadata = await projectClaudeSessionMetadata({ homedir, hostname, sessionIds, errors, observedAt, readFile });

    const health = (await mapSeries(dates, (date) => readHealthRecords({ trackingDir, date, errors, readFile }))).flat();

    const installedClaude = await detectClaudeInstalled({ settingsPath, homedir, errors });
    const installedHarnesses = installedClaude ? ['claude'] : [];
    const collectorVersions = installedClaude ? { claude: COLLECTOR_VERSIONS.claude } : {};

    if (errors.length > 0 && this && this.server && this.server.logger) {
      this.server.logger.error('time-tracking/v2 returned source errors', { count: errors.length, codes: errors.map((error) => error.code) });
    }

    // Cap the wire-response errors array independently of the true count
    // logged above: a catastrophically malformed source (thousands of
    // malformed lines) must not let the errors array dominate the response.
    const responseErrors = errors.slice(0, MAX_ERRORS);

    const response = {
      schema_version: 2,
      hostname,
      timezone: 'Europe/Berlin',
      requested_dates: dates,
      requested_harnesses: harnesses,
      installed_harnesses: installedHarnesses,
      collector_versions: collectorVersions,
      files,
      session_metadata: sessionMetadata,
      health,
      errors: responseErrors,
    };
    validateResponse(response, { dates, harnesses });
    res.json(response);
  };
}

module.exports = {
  TRACKING_DIR,
  SUPPORTED_HARNESSES,
  MAX_DATES,
  MAX_URI_BYTES,
  MAX_EVENT_FILE_BYTES,
  MAX_ERRORS,
  DATE_RE,
  ValidationError,
  canonicalJSON,
  digest,
  toCanonicalTimestamp,
  canonicalHostname,
  parseCsvField,
  isValidCalendarDate,
  parseQuery,
  isUriTooLong,
  eventBasename,
  errorRecord,
  decodeUtf8,
  buildFileDescriptor,
  splitLines,
  extractSessionIds,
  globSessionsIndexFiles,
  globSessionFiles,
  claudeMetadataId,
  projectClaudeSessionMetadata,
  readHealthRecords,
  HealthRecordSchema,
  ResponseSchema,
  validateResponse,
  mapSeries,
  detectClaudeInstalled,
  createHandler,
  handler: createHandler(),
};
