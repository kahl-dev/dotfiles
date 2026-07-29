const { describe, it, beforeEach, afterEach } = require('node:test');
const assert = require('node:assert/strict');
const fs = require('fs');
const fsp = require('fs').promises;
const path = require('path');
const crypto = require('crypto');
const { execFileSync } = require('child_process');
const express = require('express');
const supertest = require('supertest');

const v2 = require('../src/plugins/time-tracking-v2');
const { mkTempDir } = require('./support');

function createTestApp(handler) {
  const app = express();
  app.get('/time-tracking/v2', async (req, res) => {
    await handler(req, res);
  });
  return app;
}

describe('time-tracking v2: parseQuery (strict rejection)', () => {
  it('rejects an unknown query parameter', () => {
    assert.throws(
      () => v2.parseQuery({ dates: '2026-01-01', harnesses: 'claude', foo: '1' }),
      /Unrecognized key\(s\).*foo/
    );
  });

  it('rejects a duplicate date value', () => {
    assert.throws(
      () => v2.parseQuery({ dates: '2026-01-01,2026-01-01', harnesses: 'claude' }),
      /duplicate dates value: 2026-01-01/
    );
  });

  it('rejects dates that are not sorted ascending', () => {
    assert.throws(
      () => v2.parseQuery({ dates: '2026-01-02,2026-01-01', harnesses: 'claude' }),
      /dates must be sorted ascending/
    );
  });

  it('rejects an invalid date', () => {
    assert.throws(
      () => v2.parseQuery({ dates: '2026-13-40', harnesses: 'claude' }),
      /invalid dates value: 2026-13-40/
    );
  });

  it('rejects more than 31 dates', () => {
    const dates = Array.from({ length: 32 }, (_, i) => `2026-01-${String(i + 1).padStart(2, '0')}`)
      .slice(0, 32);
    // Keep within January (max 31 valid calendar days) by using two months worth of day tokens sorted.
    const csv = dates.slice(0, 31).concat(['2026-02-01']).join(',');
    assert.throws(
      () => v2.parseQuery({ dates: csv, harnesses: 'claude' }),
      /too many dates values: 32 exceeds max 31/
    );
  });

  it('rejects the unsupported "opencode" harness like any unsupported value (Phase 1 is Claude-only)', () => {
    assert.throws(
      () => v2.parseQuery({ dates: '2026-01-01', harnesses: 'opencode' }),
      /unsupported harnesses value: opencode/
    );
  });

  it('rejects a garbage harness token the same way as a recognized-but-unsupported one', () => {
    assert.throws(
      () => v2.parseQuery({ dates: '2026-01-01', harnesses: 'not-a-harness' }),
      /invalid harnesses value: not-a-harness/
    );
  });

  it('accepts a single valid claude request', () => {
    assert.deepEqual(
      v2.parseQuery({ dates: '2026-01-01,2026-01-02', harnesses: 'claude' }),
      { dates: ['2026-01-01', '2026-01-02'], harnesses: ['claude'] }
    );
  });
});

describe('time-tracking v2: isUriTooLong', () => {
  it('accepts a normal-length URL', () => {
    assert.equal(v2.isUriTooLong('/time-tracking/v2?dates=2026-01-01&harnesses=claude'), false);
  });

  it('rejects a URL over 4096 bytes', () => {
    const longUrl = `/time-tracking/v2?dates=${'2026-01-01,'.repeat(400)}2026-01-01&harnesses=claude`;
    assert.ok(Buffer.byteLength(longUrl, 'utf-8') > 4096);
    assert.equal(v2.isUriTooLong(longUrl), true);
  });
});

describe('time-tracking v2: buildFileDescriptor', () => {
  let trackingDir;

  beforeEach(() => {
    trackingDir = mkTempDir('tt-v2-files-');
  });

  afterEach(() => {
    fs.rmSync(trackingDir, { recursive: true, force: true });
  });

  it('reports present:false with null sha256/content for a missing date', async () => {
    const errors = [];
    const descriptor = await v2.buildFileDescriptor({ trackingDir, harness: 'claude', date: '2026-01-01', errors });

    assert.deepEqual(descriptor, {
      kind: 'events',
      harness: 'claude',
      business_date: '2026-01-01',
      basename: '2026-01-01.jsonl',
      present: false,
      sha256: null,
      content: null,
    });
    assert.deepEqual(errors, []);
  });

  it('returns exact UTF-8 content and a lowercase-hex sha256 matching the exact bytes for a present file', async () => {
    const content = '{"session_id":"s1"}\n{"session_id":"s2"}\n';
    fs.writeFileSync(path.join(trackingDir, '2026-01-01.jsonl'), content, 'utf-8');
    const expectedSha256 = crypto.createHash('sha256').update(Buffer.from(content, 'utf-8')).digest('hex');

    const errors = [];
    const descriptor = await v2.buildFileDescriptor({ trackingDir, harness: 'claude', date: '2026-01-01', errors });

    assert.equal(descriptor.present, true);
    assert.equal(descriptor.content, content);
    assert.equal(descriptor.sha256, expectedSha256);
    assert.equal(descriptor.sha256, descriptor.sha256.toLowerCase());
    assert.deepEqual(errors, []);
  });

  it('returns an absent descriptor and a sanitized permissions error on a deterministic read failure', async () => {
    const errors = [];
    const descriptor = await v2.buildFileDescriptor({
      trackingDir,
      harness: 'claude',
      date: '2026-01-01',
      errors,
      stat: async () => ({ size: 0 }),
      readFile: async () => {
        const error = new Error('/private/path/secret-value');
        error.code = 'EACCES';
        throw error;
      },
    });

    assert.deepEqual(descriptor, {
      kind: 'events', harness: 'claude', business_date: '2026-01-01', basename: '2026-01-01.jsonl', present: false, sha256: null, content: null,
    });
    assert.deepEqual(errors, [{ code: 'permissions_invalid', message: 'file could not be read', file: '2026-01-01.jsonl', line: null }]);
  });

  // Bug fix (review finding WARNING 3): a leading UTF-8 BOM is stripped from
  // `content` by TextDecoder's default ignoreBOM:false, but sha256 was
  // previously hashed over the raw bytes (BOM included) — a digest that
  // could never match Buffer.from(content, 'utf-8'), tripping
  // FileDescriptorSchema's independent recomputation in superRefine and
  // turning one BOM-prefixed event file into an HTTP 500 for the whole
  // response.
  it('computes sha256 over the BOM-stripped content that is actually returned, not the raw bytes with BOM', async () => {
    const jsonlContent = '{"session_id":"s1"}\n';
    const bomBytes = Buffer.concat([Buffer.from([0xef, 0xbb, 0xbf]), Buffer.from(jsonlContent, 'utf-8')]);
    const errors = [];

    const descriptor = await v2.buildFileDescriptor({
      trackingDir,
      harness: 'claude',
      date: '2026-01-01',
      errors,
      stat: async () => ({ size: bomBytes.length }),
      readFile: async () => bomBytes,
    });

    assert.equal(descriptor.present, true);
    assert.equal(descriptor.content, jsonlContent, 'TextDecoder strips the leading BOM from content by default');
    const expectedSha256 = crypto.createHash('sha256').update(Buffer.from(jsonlContent, 'utf-8')).digest('hex');
    assert.equal(descriptor.sha256, expectedSha256);
    assert.deepEqual(errors, []);
  });

  // Bug fix (review finding WARNING 7): buildFileDescriptor read the whole
  // file into memory and echoed it verbatim into the JSON response with no
  // size ceiling — a single oversized event file could balloon the response
  // (up to MAX_DATES requested dates' worth) without any transport-level
  // bound. An oversized file now becomes a source error instead of content.
  //
  // E3 efficiency fix: the size check now runs off fsp.stat() before any
  // read, so an oversized file is rejected without ever being loaded into
  // memory — the `readFile` spy below throws if it is ever invoked, proving
  // that.
  it('records a transport_error and omits content for a file over the maximum supported size, without reading it into memory', async () => {
    const errors = [];

    const descriptor = await v2.buildFileDescriptor({
      trackingDir,
      harness: 'claude',
      date: '2026-01-01',
      errors,
      stat: async () => ({ size: v2.MAX_EVENT_FILE_BYTES + 1 }),
      readFile: async () => { throw new Error('must not read an oversized file into memory'); },
    });

    assert.deepEqual(descriptor, {
      kind: 'events', harness: 'claude', business_date: '2026-01-01', basename: '2026-01-01.jsonl', present: false, sha256: null, content: null,
    });
    assert.deepEqual(errors, [{ code: 'transport_error', message: 'file exceeds the maximum supported size', file: '2026-01-01.jsonl', line: null }]);
  });

  it('accepts a file exactly at the maximum supported size', async () => {
    const content = 'a'.repeat(v2.MAX_EVENT_FILE_BYTES);
    const errors = [];

    const descriptor = await v2.buildFileDescriptor({
      trackingDir,
      harness: 'claude',
      date: '2026-01-01',
      errors,
      stat: async () => ({ size: v2.MAX_EVENT_FILE_BYTES }),
      readFile: async () => Buffer.from(content, 'utf-8'),
    });

    assert.equal(descriptor.present, true);
    assert.deepEqual(errors, []);
  });
});

describe('time-tracking v2: extractSessionIds (malformed line -> error record)', () => {
  it('collects session_id from valid lines and records an error for a malformed line, without throwing', () => {
    const content = '{"session_id":"s1"}\nnot json\n{"session_id":"s2"}\n{"session_id":""}\n';
    const sessionIds = new Set();
    const errors = [];

    v2.extractSessionIds(content, '2026-01-01.jsonl', sessionIds, errors);

    assert.deepEqual([...sessionIds].sort(), ['s1', 's2']);
    assert.equal(errors.length, 1);
    assert.equal(errors[0].code, 'malformed_json');
    assert.equal(errors[0].file, '2026-01-01.jsonl');
    assert.equal(errors[0].line, 2);
  });
});

describe('time-tracking v2: toCanonicalTimestamp', () => {
  it('converts epoch milliseconds to whole-second UTC format', () => {
    assert.equal(v2.toCanonicalTimestamp(1768982165267), '2026-01-21T07:56:05Z');
  });

  it('converts an ISO-8601 string with millisecond precision to whole-second UTC format', () => {
    assert.equal(v2.toCanonicalTimestamp('2026-01-16T16:40:23.800Z'), '2026-01-16T16:40:23Z');
  });

  it('throws on an unparseable timestamp rather than guessing', () => {
    assert.throws(() => v2.toCanonicalTimestamp('not-a-timestamp'), /invalid timestamp value/);
  });

  it('rejects timezone-less, offset, locale, normalized-calendar, fractional, and unsafe timestamp inputs', () => {
    for (const value of [
      '2026-01-01T00:00:00',
      '2026-01-01T00:00:00+01:00',
      'January 1, 2026',
      '2026-02-30T00:00:00Z',
      '2026-01-01T00:00:00.12Z',
      1768982165267.5,
      Number.MAX_SAFE_INTEGER + 1,
    ]) {
      assert.throws(() => v2.toCanonicalTimestamp(value), /invalid timestamp value/);
    }
  });

  // Bug fix (review finding WARNING 4): 8.64e15 is a safe integer and the
  // maximum epoch-millisecond value the Date object accepts without
  // overflowing to NaN, but Date#toISOString() renders it with an extended,
  // signed, 6-digit year ("+275760-09-13T00:00:00.000Z") — a value that
  // slips past the old implementation's NaN-only check, then fails
  // TimestampSchema deep inside validateResponse and surfaces as an
  // unhandled 500 for the entire response instead of a per-session error.
  it('rejects an epoch-millisecond value that produces a non-4-digit-year ISO string instead of silently returning it', () => {
    assert.throws(() => v2.toCanonicalTimestamp(8.64e15), /invalid timestamp value/);
  });

  it('accepts only UTC ISO timestamps with optional millisecond precision', () => {
    assert.equal(v2.toCanonicalTimestamp('2026-01-16T16:40:23Z'), '2026-01-16T16:40:23Z');
    assert.equal(v2.toCanonicalTimestamp('2026-01-16T16:40:23.800Z'), '2026-01-16T16:40:23Z');
  });

  it('produces the same canonical timestamp regardless of the host timezone', () => {
    const modulePath = path.join(__dirname, '..', 'src', 'plugins', 'time-tracking-v2.js');
    const script = `const v2 = require(${JSON.stringify(modulePath)}); const updatedAt = v2.toCanonicalTimestamp('2026-01-16T16:40:23.800Z'); process.stdout.write(JSON.stringify({ updatedAt, metadataId: v2.claudeMetadataId({ hostname: 'typo3', sessionId: 'session', name: 'synthetic', updatedAt }) }));`;
    const outputs = ['UTC', 'Pacific/Auckland', 'America/Los_Angeles'].map((timezone) => execFileSync(
      process.execPath,
      ['-e', script],
      { encoding: 'utf-8', env: { ...process.env, TZ: timezone } }
    ));

    assert.deepEqual(outputs.map(JSON.parse), [
      { updatedAt: '2026-01-16T16:40:23Z', metadataId: 'clm_cc6d360fa3ecfa28561600709a41e9f551a8d0952a3dd960d6fec0b365d87324' },
      { updatedAt: '2026-01-16T16:40:23Z', metadataId: 'clm_cc6d360fa3ecfa28561600709a41e9f551a8d0952a3dd960d6fec0b365d87324' },
      { updatedAt: '2026-01-16T16:40:23Z', metadataId: 'clm_cc6d360fa3ecfa28561600709a41e9f551a8d0952a3dd960d6fec0b365d87324' },
    ]);
  });
});

describe('time-tracking v2: canonical digest (hand-computed golden vector)', () => {
  it('matches a hand-computed SHA-256 over label + NUL + canonical JSON', () => {
    // canonical_json = {"a":1,"b":2} (sorted keys, no whitespace)
    // sha256(ascii("test-label") + b"\x00" + b'{"a":1,"b":2}')
    // computed independently with Python hashlib for this test vector.
    const expected = '6dbce8db9c2c562740596c886641e490e5eb86dead373b89c1bf89a03dc9b419';
    assert.equal(expected.length, 64);
    assert.equal(v2.digest('test-label', { b: 2, a: 1 }), expected);
  });

  it('produces the metadata_id "clm_" digest matching the hand-computed Python vector', () => {
    // Python: hashlib.sha256(b"claude-session-metadata-v1\x00" +
    //   b'{"hostname":"typo3","name":"Foo","session_id":"abc","updated_at":"2026-01-01T00:00:00Z"}').hexdigest()
    const expected = 'clm_a28f99a6fd0f3532c6e58aa8459cfc33a11e9a10edad5045b1b36725ab2d3f3e';
    assert.equal(
      v2.claudeMetadataId({ hostname: 'typo3', sessionId: 'abc', name: 'Foo', updatedAt: '2026-01-01T00:00:00Z' }),
      expected
    );
  });
});

describe('time-tracking v2: projectClaudeSessionMetadata (nameSource acceptance matrix)', () => {
  let homedir;

  beforeEach(async () => {
    homedir = mkTempDir('tt-v2-home-');
    await fsp.mkdir(path.join(homedir, '.claude', 'projects', 'proj-a'), { recursive: true });
    await fsp.mkdir(path.join(homedir, '.claude', 'sessions'), { recursive: true });
  });

  afterEach(() => {
    fs.rmSync(homedir, { recursive: true, force: true });
  });

  async function writeSessionsIndex(entries) {
    await fsp.writeFile(
      path.join(homedir, '.claude', 'projects', 'proj-a', 'sessions-index.json'),
      JSON.stringify({ version: 1, entries }),
      'utf-8'
    );
  }

  async function writeSessionFile(name, data) {
    await fsp.writeFile(path.join(homedir, '.claude', 'sessions', name), JSON.stringify(data), 'utf-8');
  }

  it('accepts a customTitle record from sessions-index.json (always explicit, no nameSource concept there)', async () => {
    await writeSessionsIndex([{ sessionId: 's1', customTitle: 'synthetic-session-title', modified: '2026-01-16T16:40:23.800Z' }]);

    const errors = [];
    const records = await v2.projectClaudeSessionMetadata({
      homedir,
      hostname: 'typo3',
      sessionIds: new Set(['s1']),
      errors,
      observedAt: '2026-01-01T00:00:00Z',
    });

    assert.equal(records.length, 1);
    assert.equal(records[0].name, 'synthetic-session-title');
    assert.equal(records[0].session_id, 's1');
    assert.equal(records[0].updated_at, '2026-01-16T16:40:23Z');
    assert.deepEqual(errors, []);
  });

  it('nameSource matrix: "user" is explicit', async () => {
    await writeSessionFile('111.json', { sessionId: 's-user', name: 'named-user', nameSource: 'user', updatedAt: 1768982165267 });
    const errors = [];
    const records = await v2.projectClaudeSessionMetadata({ homedir, hostname: 'typo3', sessionIds: new Set(['s-user']), errors, observedAt: 'x' });
    assert.equal(records.length, 1);
    assert.equal(records[0].name, 'named-user');
  });

  it('nameSource matrix: null is explicit', async () => {
    await writeSessionFile('112.json', { sessionId: 's-null', name: 'named-null', nameSource: null, updatedAt: 1768982165267 });
    const errors = [];
    const records = await v2.projectClaudeSessionMetadata({ homedir, hostname: 'typo3', sessionIds: new Set(['s-null']), errors, observedAt: 'x' });
    assert.equal(records.length, 1);
    assert.equal(records[0].name, 'named-null');
  });

  it('nameSource matrix: absent field is explicit', async () => {
    await writeSessionFile('113.json', { sessionId: 's-absent', name: 'named-absent', updatedAt: 1768982165267 });
    const errors = [];
    const records = await v2.projectClaudeSessionMetadata({ homedir, hostname: 'typo3', sessionIds: new Set(['s-absent']), errors, observedAt: 'x' });
    assert.equal(records.length, 1);
    assert.equal(records[0].name, 'named-absent');
  });

  it('nameSource matrix: "auto" contributes nothing and no error', async () => {
    await writeSessionFile('114.json', { sessionId: 's-auto', name: 'named-auto', nameSource: 'auto', updatedAt: 1768982165267 });
    const errors = [];
    const records = await v2.projectClaudeSessionMetadata({ homedir, hostname: 'typo3', sessionIds: new Set(['s-auto']), errors, observedAt: 'x' });
    assert.equal(records.length, 0);
    assert.deepEqual(errors, []);
  });

  it('nameSource matrix: "derived" contributes nothing and no error', async () => {
    await writeSessionFile('115.json', { sessionId: 's-derived', name: 'named-derived', nameSource: 'derived', updatedAt: 1768982165267 });
    const errors = [];
    const records = await v2.projectClaudeSessionMetadata({ homedir, hostname: 'typo3', sessionIds: new Set(['s-derived']), errors, observedAt: 'x' });
    assert.equal(records.length, 0);
    assert.deepEqual(errors, []);
  });

  it('records a malformed_json error instead of a broken record for a session file with an out-of-range updatedAt', async () => {
    await writeSessionFile('116b.json', { sessionId: 's-overflow', name: 'named-overflow', updatedAt: 8.64e15 });
    const errors = [];
    const records = await v2.projectClaudeSessionMetadata({ homedir, hostname: 'typo3', sessionIds: new Set(['s-overflow']), errors, observedAt: 'x' });
    assert.equal(records.length, 0);
    assert.equal(errors.length, 1);
    assert.equal(errors[0].code, 'malformed_json');
    assert.equal(errors[0].file, '116b.json');
  });

  it('nameSource matrix: an unexpected string value produces an error record and no metadata record', async () => {
    await writeSessionFile('116.json', { sessionId: 's-custom', name: 'named-custom', nameSource: 'custom', updatedAt: 1768982165267 });
    const errors = [];
    const records = await v2.projectClaudeSessionMetadata({ homedir, hostname: 'typo3', sessionIds: new Set(['s-custom']), errors, observedAt: 'x' });
    assert.equal(records.length, 0);
    assert.equal(errors.length, 1);
    assert.equal(errors[0].code, 'unsupported_schema');
    assert.equal(errors[0].message, 'source schema is unsupported');
  });

  it('ignores sessions not in the requested session-ID set', async () => {
    await writeSessionFile('117.json', { sessionId: 's-unrelated', name: 'unrelated', updatedAt: 1768982165267 });
    const errors = [];
    const records = await v2.projectClaudeSessionMetadata({ homedir, hostname: 'typo3', sessionIds: new Set(['s-relevant']), errors, observedAt: 'x' });
    assert.equal(records.length, 0);
  });

  it('records an error instead of throwing on malformed JSON in a session file', async () => {
    await fsp.writeFile(path.join(homedir, '.claude', 'sessions', '118.json'), 'not json', 'utf-8');
    const errors = [];
    const records = await v2.projectClaudeSessionMetadata({ homedir, hostname: 'typo3', sessionIds: new Set(['s1']), errors, observedAt: 'x' });
    assert.equal(records.length, 0);
    assert.equal(errors.length, 1);
    assert.equal(errors[0].code, 'malformed_json');
  });

  it('rejects invalid sessions-index and session-file top-level structures without exposing source values', async () => {
    await fsp.writeFile(path.join(homedir, '.claude', 'projects', 'proj-a', 'sessions-index.json'), JSON.stringify({ entries: {} }), 'utf-8');
    await fsp.writeFile(path.join(homedir, '.claude', 'sessions', '119.json'), JSON.stringify(['synthetic-title']), 'utf-8');
    await fsp.writeFile(path.join(homedir, '.claude', 'sessions', '120.json'), JSON.stringify({ name: 'synthetic-title', updatedAt: '2026-01-01T00:00:00Z' }), 'utf-8');
    const errors = [];

    const records = await v2.projectClaudeSessionMetadata({ homedir, hostname: 'typo3', sessionIds: new Set(['s1']), errors, observedAt: 'x' });

    assert.deepEqual(records, []);
    assert.deepEqual(errors, [
      { code: 'malformed_json', message: 'source JSON is invalid', file: 'sessions-index.json', line: null },
      { code: 'malformed_json', message: 'source JSON is invalid', file: '119.json', line: null },
      { code: 'malformed_json', message: 'source JSON is invalid', file: '120.json', line: null },
    ]);
    assert.doesNotMatch(JSON.stringify(errors), /synthetic-title/);
  });

  it('records a sanitized directory read error and treats missing metadata directories as optional', async () => {
    const errors = [];
    const failure = new Error('/private/example/projects');
    failure.code = 'EACCES';
    const records = await v2.projectClaudeSessionMetadata({
      homedir,
      hostname: 'typo3',
      sessionIds: new Set(['s1']),
      errors,
      observedAt: 'x',
      readdir: async () => { throw failure; },
    });

    assert.deepEqual(records, []);
    assert.deepEqual(errors, [
      { code: 'permissions_invalid', message: 'file could not be read', file: 'projects', line: null },
      { code: 'permissions_invalid', message: 'file could not be read', file: 'sessions', line: null },
    ]);
    assert.doesNotMatch(JSON.stringify(errors), /private|example/);
  });

  it('rejects invalid UTF-8 in sessions-index and session metadata files without replacement characters', async () => {
    await fsp.writeFile(path.join(homedir, '.claude', 'projects', 'proj-a', 'sessions-index.json'), Buffer.from([0xc3, 0x28]));
    await fsp.writeFile(path.join(homedir, '.claude', 'sessions', '121.json'), Buffer.from([0xc3, 0x28]));
    const errors = [];

    const records = await v2.projectClaudeSessionMetadata({ homedir, hostname: 'typo3', sessionIds: new Set(['s1']), errors, observedAt: 'x' });

    assert.deepEqual(records, []);
    assert.deepEqual(errors, [
      { code: 'malformed_json', message: 'source JSON is invalid', file: 'sessions-index.json', line: null },
      { code: 'malformed_json', message: 'source JSON is invalid', file: '121.json', line: null },
    ]);
    assert.doesNotMatch(JSON.stringify(errors), /�/);
  });
});

describe('time-tracking v2: invalid UTF-8 event content', () => {
  it('returns an absent descriptor and sanitized malformed_json error', async () => {
    const errors = [];
    const descriptor = await v2.buildFileDescriptor({
      trackingDir: '/synthetic',
      harness: 'claude',
      date: '2026-01-01',
      errors,
      stat: async () => ({ size: 2 }),
      readFile: async () => Buffer.from([0xc3, 0x28]),
    });

    assert.deepEqual(descriptor, {
      kind: 'events', harness: 'claude', business_date: '2026-01-01', basename: '2026-01-01.jsonl', present: false, sha256: null, content: null,
    });
    assert.deepEqual(errors, [{ code: 'malformed_json', message: 'source JSON is invalid', file: '2026-01-01.jsonl', line: null }]);
  });
});

describe('time-tracking v2: readHealthRecords', () => {
  let trackingDir;

  beforeEach(() => {
    trackingDir = mkTempDir('tt-v2-health-');
  });

  afterEach(() => {
    fs.rmSync(trackingDir, { recursive: true, force: true });
  });

  it('returns an empty array (not an error) when the health file is absent', async () => {
    const errors = [];
    const records = await v2.readHealthRecords({ trackingDir, date: '2026-01-01', errors });
    assert.deepEqual(records, []);
    assert.deepEqual(errors, []);
  });

  it('parses a valid record and records an error for a malformed line without dropping the valid one', async () => {
    const validRecord = {
      schema_version: 1,
      health_id: 'hlt_11111111-1111-4111-8111-111111111111',
      harness: 'claude',
      hostname: 'typo3',
      collector_instance_id: 'col_22222222-2222-4222-8222-222222222222',
      timestamp: '2026-01-01T00:00:00Z',
      status: 'collector_started',
      event_id: null,
      error_code: null,
      detail: null,
    };
    const content = `${JSON.stringify(validRecord)}\nnot json\n`;
    fs.writeFileSync(path.join(trackingDir, '2026-01-01.claude-health.jsonl'), content, 'utf-8');

    const errors = [];
    const records = await v2.readHealthRecords({ trackingDir, date: '2026-01-01', errors });

    assert.equal(records.length, 1);
    assert.deepEqual(records[0], validRecord);
    assert.equal(errors.length, 1);
    assert.equal(errors[0].code, 'malformed_json');
    assert.equal(errors[0].line, 2);
  });

  it('records an unsupported_schema error for a line that fails CollectorHealthV1 validation', async () => {
    const invalidRecord = { schema_version: 1, harness: 'claude', status: 'not-a-real-status' };
    fs.writeFileSync(path.join(trackingDir, '2026-01-01.claude-health.jsonl'), `${JSON.stringify(invalidRecord)}\n`, 'utf-8');

    const errors = [];
    const records = await v2.readHealthRecords({ trackingDir, date: '2026-01-01', errors });

    assert.deepEqual(records, []);
    assert.equal(errors.length, 1);
    assert.equal(errors[0].code, 'unsupported_schema');
  });

  it('rejects invalid UTF-8 health bytes before JSON parsing', async () => {
    fs.writeFileSync(path.join(trackingDir, '2026-01-01.claude-health.jsonl'), Buffer.from([0xc3, 0x28]));
    const errors = [];

    const records = await v2.readHealthRecords({ trackingDir, date: '2026-01-01', errors });

    assert.deepEqual(records, []);
    assert.deepEqual(errors, [{ code: 'malformed_json', message: 'source JSON is invalid', file: '2026-01-01.claude-health.jsonl', line: null }]);
    assert.doesNotMatch(JSON.stringify(errors), /�/);
  });
});

describe('time-tracking v2: detectClaudeInstalled', () => {
  let homedir;

  beforeEach(() => {
    homedir = mkTempDir('tt-v2-installed-');
  });

  afterEach(() => {
    fs.rmSync(homedir, { recursive: true, force: true });
  });

  it('returns false with no error when settings.json is absent (genuinely not installed)', async () => {
    const errors = [];
    const installed = await v2.detectClaudeInstalled({ homedir, errors });
    assert.equal(installed, false);
    assert.deepEqual(errors, []);
  });

  it('returns false with no error when settings.json has no time-tracker.sh hook (genuinely not registered)', async () => {
    await fsp.mkdir(path.join(homedir, '.claude'), { recursive: true });
    await fsp.writeFile(path.join(homedir, '.claude', 'settings.json'), JSON.stringify({ hooks: { Stop: [{ hooks: [{ type: 'command', command: 'echo hi' }] }] } }), 'utf-8');

    const errors = [];
    const installed = await v2.detectClaudeInstalled({ homedir, errors });
    assert.equal(installed, false);
    assert.deepEqual(errors, []);
  });

  it('returns true when the hook is registered and the script is executable', async () => {
    await fsp.mkdir(path.join(homedir, '.claude', 'hooks'), { recursive: true });
    const scriptPath = path.join(homedir, '.claude', 'hooks', 'time-tracker.sh');
    await fsp.writeFile(scriptPath, '#!/usr/bin/env bash\n', { mode: 0o700 });
    await fsp.writeFile(
      path.join(homedir, '.claude', 'settings.json'),
      JSON.stringify({ hooks: { Stop: [{ hooks: [{ type: 'command', command: '~/.claude/hooks/time-tracker.sh', timeout: 5 }] }] } }),
      'utf-8'
    );

    const errors = [];
    const installed = await v2.detectClaudeInstalled({ homedir, errors });
    assert.equal(installed, true);
    assert.deepEqual(errors, []);
  });

  // Bug fix (review finding BLOCKER 1): this test previously asserted
  // `installed === false` with no error record for a registered-but-broken
  // hook, which is the exact bug the plan's source health decision table
  // forbids ("Installed but disabled, unreadable, or version-mismatched
  // collectors are source errors, not uninstalled sources") — the consumer
  // could not distinguish "Claude was never set up" from "Claude's collector
  // is broken." Rewritten to require a permissions_invalid error record
  // alongside the false return.
  it('returns false with a permissions_invalid error when the hook is registered but the script is not executable', async () => {
    await fsp.mkdir(path.join(homedir, '.claude', 'hooks'), { recursive: true });
    const scriptPath = path.join(homedir, '.claude', 'hooks', 'time-tracker.sh');
    await fsp.writeFile(scriptPath, '#!/usr/bin/env bash\n', { mode: 0o600 });
    await fsp.writeFile(
      path.join(homedir, '.claude', 'settings.json'),
      JSON.stringify({ hooks: { Stop: [{ hooks: [{ type: 'command', command: '~/.claude/hooks/time-tracker.sh', timeout: 5 }] }] } }),
      'utf-8'
    );

    const errors = [];
    const installed = await v2.detectClaudeInstalled({ homedir, errors });
    assert.equal(installed, false);
    assert.deepEqual(errors, [{ code: 'permissions_invalid', message: 'file could not be read', file: 'time-tracker.sh', line: null }]);
  });

  // Bug fix (review finding WARNING 1): this test previously asserted
  // `permissions_invalid` for a settings.json that was read successfully
  // but contained invalid JSON — the wrong error code, since the file
  // *was* read fine; only its content failed to parse. The sibling
  // function `readJsonFile` in the same file already makes this
  // distinction correctly (non-ENOENT read failure -> permissions_invalid,
  // JSON.parse failure -> malformed_json). Rewritten to require the
  // correct `malformed_json` code.
  it('returns false with a malformed_json error when settings.json exists and is readable but is not valid JSON', async () => {
    await fsp.mkdir(path.join(homedir, '.claude'), { recursive: true });
    await fsp.writeFile(path.join(homedir, '.claude', 'settings.json'), 'not json', 'utf-8');

    const errors = [];
    const installed = await v2.detectClaudeInstalled({ homedir, errors });
    assert.equal(installed, false);
    assert.deepEqual(errors, [{ code: 'malformed_json', message: 'source JSON is invalid', file: 'settings.json', line: null }]);
  });

  it('returns false with a permissions_invalid error when settings.json cannot be read for a non-ENOENT reason', async () => {
    // A directory in place of settings.json makes fsp.readFile fail with
    // EISDIR — a deterministic, cross-platform stand-in for "exists but
    // unreadable" that does not require chmod-based permission tricks.
    await fsp.mkdir(path.join(homedir, '.claude', 'settings.json'), { recursive: true });

    const errors = [];
    const installed = await v2.detectClaudeInstalled({ homedir, errors });
    assert.equal(installed, false);
    assert.deepEqual(errors, [{ code: 'permissions_invalid', message: 'file could not be read', file: 'settings.json', line: null }]);
  });

  // Separates the two non-ENOENT failure modes explicitly: an unreadable
  // file (EACCES) is permissions_invalid; a readable file with broken JSON
  // content is malformed_json. Guards against the two codes being
  // conflated again in either direction.
  it('distinguishes an unreadable settings.json (permissions_invalid) from a readable-but-malformed one (malformed_json)', async () => {
    await fsp.mkdir(path.join(homedir, '.claude'), { recursive: true });
    const settingsPath = path.join(homedir, '.claude', 'settings.json');
    await fsp.writeFile(settingsPath, JSON.stringify({ hooks: {} }), 'utf-8');
    await fsp.chmod(settingsPath, 0o000);

    const unreadableErrors = [];
    const unreadableInstalled = await v2.detectClaudeInstalled({ homedir, errors: unreadableErrors });
    await fsp.chmod(settingsPath, 0o600);

    assert.equal(unreadableInstalled, false);
    assert.deepEqual(unreadableErrors, [{ code: 'permissions_invalid', message: 'file could not be read', file: 'settings.json', line: null }]);

    await fsp.writeFile(settingsPath, '{ trailing comma, }', 'utf-8');
    const malformedErrors = [];
    const malformedInstalled = await v2.detectClaudeInstalled({ homedir, errors: malformedErrors });

    assert.equal(malformedInstalled, false);
    assert.deepEqual(malformedErrors, [{ code: 'malformed_json', message: 'source JSON is invalid', file: 'settings.json', line: null }]);
  });
});

describe('time-tracking v2: HTTP endpoint (createHandler)', () => {
  let trackingDir;
  let homedir;

  beforeEach(async () => {
    trackingDir = mkTempDir('tt-v2-http-tracking-');
    homedir = mkTempDir('tt-v2-http-home-');
    await fsp.mkdir(path.join(homedir, '.claude', 'sessions'), { recursive: true });
  });

  afterEach(() => {
    fs.rmSync(trackingDir, { recursive: true, force: true });
    fs.rmSync(homedir, { recursive: true, force: true });
  });

  function buildApp() {
    const handler = v2.createHandler({
      trackingDir,
      homedir,
      env: {},
      hostnameFn: () => 'Typo3.local',
      clock: () => Date.parse('2026-01-01T00:00:00Z'),
    });
    return createTestApp(handler);
  }

  it('returns the exact response shape for one requested claude/date pair with a present file', async () => {
    const content = '{"session_id":"s1"}\n';
    fs.writeFileSync(path.join(trackingDir, '2026-01-01.jsonl'), content, 'utf-8');

    const response = await supertest(buildApp())
      .get('/time-tracking/v2')
      .query({ dates: '2026-01-01', harnesses: 'claude' })
      .expect(200);

    assert.equal(response.body.schema_version, 2);
    assert.equal(response.body.hostname, 'typo3');
    assert.equal(response.body.timezone, 'Europe/Berlin');
    assert.deepEqual(response.body.requested_dates, ['2026-01-01']);
    assert.deepEqual(response.body.requested_harnesses, ['claude']);
    assert.deepEqual(response.body.installed_harnesses, []);
    assert.deepEqual(response.body.collector_versions, {});
    assert.equal(response.body.files.length, 1);
    assert.equal(response.body.files[0].present, true);
    assert.equal(response.body.files[0].content, content);
    assert.equal(response.body.files[0].kind, 'events');
    assert.equal(response.body.files[0].basename, '2026-01-01.jsonl');
    assert.deepEqual(response.body.health, []);
    assert.deepEqual(response.body.errors, []);
  });

  it('returns present:false with null sha256/content for a missing requested date', async () => {
    const response = await supertest(buildApp())
      .get('/time-tracking/v2')
      .query({ dates: '2026-01-01', harnesses: 'claude' })
      .expect(200);

    assert.deepEqual(response.body.files[0], {
      kind: 'events',
      harness: 'claude',
      business_date: '2026-01-01',
      basename: '2026-01-01.jsonl',
      present: false,
      sha256: null,
      content: null,
    });
  });

  it('does not expose raw filesystem details in response errors', async () => {
    const handler = v2.createHandler({
      trackingDir,
      homedir,
      env: {},
      hostnameFn: () => 'typo3',
      stat: async (filePath) => (path.basename(filePath) === '2026-01-01.jsonl'
        ? { size: 0 }
        : fsp.stat(filePath)),
      readFile: async (filePath) => {
        if (path.basename(filePath) === '2026-01-01.jsonl') {
          const error = new Error('/private/example/redacted-value');
          error.code = 'EACCES';
          throw error;
        }
        return fsp.readFile(filePath);
      },
    });
    const response = await supertest(createTestApp(handler))
      .get('/time-tracking/v2')
      .query({ dates: '2026-01-01', harnesses: 'claude' })
      .expect(200);

    assert.deepEqual(response.body.errors, [{ code: 'permissions_invalid', message: 'file could not be read', file: '2026-01-01.jsonl', line: null }]);
    assert.doesNotMatch(JSON.stringify(response.body.errors), /private|example|redacted-value/);
  });

  it('reports a registered-but-not-executable hook as a source error, not a silently absent harness', async () => {
    await fsp.mkdir(path.join(homedir, '.claude', 'hooks'), { recursive: true });
    const scriptPath = path.join(homedir, '.claude', 'hooks', 'time-tracker.sh');
    await fsp.writeFile(scriptPath, '#!/usr/bin/env bash\n', { mode: 0o600 });
    await fsp.writeFile(
      path.join(homedir, '.claude', 'settings.json'),
      JSON.stringify({ hooks: { Stop: [{ hooks: [{ type: 'command', command: '~/.claude/hooks/time-tracker.sh', timeout: 5 }] }] } }),
      'utf-8'
    );
    const handler = v2.createHandler({ trackingDir, homedir, env: {}, hostnameFn: () => 'typo3' });

    const response = await supertest(createTestApp(handler))
      .get('/time-tracking/v2')
      .query({ dates: '2026-01-01', harnesses: 'claude' })
      .expect(200);

    assert.deepEqual(response.body.installed_harnesses, []);
    assert.deepEqual(response.body.collector_versions, {});
    assert.deepEqual(response.body.errors, [{ code: 'permissions_invalid', message: 'file could not be read', file: 'time-tracker.sh', line: null }]);
  });

  it('returns 200 with the BOM stripped and a matching digest for an event file with a leading UTF-8 BOM', async () => {
    const jsonlContent = '{"session_id":"s1"}\n';
    const bomBytes = Buffer.concat([Buffer.from([0xef, 0xbb, 0xbf]), Buffer.from(jsonlContent, 'utf-8')]);
    fs.writeFileSync(path.join(trackingDir, '2026-01-01.jsonl'), bomBytes);

    const response = await supertest(buildApp())
      .get('/time-tracking/v2')
      .query({ dates: '2026-01-01', harnesses: 'claude' })
      .expect(200);

    assert.equal(response.body.files[0].present, true);
    assert.equal(response.body.files[0].content, jsonlContent);
    assert.deepEqual(response.body.errors, []);
  });

  it('returns a partial response instead of HTTP 500 for invalid UTF-8 event bytes', async () => {
    const handler = v2.createHandler({
      trackingDir,
      homedir,
      env: {},
      hostnameFn: () => 'typo3',
      stat: async (filePath) => (path.basename(filePath) === '2026-01-01.jsonl'
        ? { size: 2 }
        : fsp.stat(filePath)),
      readFile: async (filePath) => (path.basename(filePath) === '2026-01-01.jsonl'
        ? Buffer.from([0xc3, 0x28])
        : fsp.readFile(filePath)),
    });
    const response = await supertest(createTestApp(handler))
      .get('/time-tracking/v2')
      .query({ dates: '2026-01-01', harnesses: 'claude' })
      .expect(200);

    assert.deepEqual(response.body.files[0], {
      kind: 'events', harness: 'claude', business_date: '2026-01-01', basename: '2026-01-01.jsonl', present: false, sha256: null, content: null,
    });
    assert.deepEqual(response.body.errors, [{ code: 'malformed_json', message: 'source JSON is invalid', file: '2026-01-01.jsonl', line: null }]);
  });

  it('returns a schema-valid partial response for invalid UTF-8 metadata and health bytes', async () => {
    fs.writeFileSync(path.join(trackingDir, '2026-01-01.jsonl'), '{"session_id":"s1"}\n', 'utf-8');
    await fsp.mkdir(path.join(homedir, '.claude', 'projects', 'proj-a'), { recursive: true });
    await fsp.writeFile(path.join(homedir, '.claude', 'projects', 'proj-a', 'sessions-index.json'), Buffer.from([0xc3, 0x28]));
    await fsp.writeFile(path.join(homedir, '.claude', 'sessions', '122.json'), Buffer.from([0xc3, 0x28]));
    fs.writeFileSync(path.join(trackingDir, '2026-01-01.claude-health.jsonl'), Buffer.from([0xc3, 0x28]));

    const response = await supertest(buildApp())
      .get('/time-tracking/v2')
      .query({ dates: '2026-01-01', harnesses: 'claude' })
      .expect(200);

    assert.deepEqual(response.body.errors, [
      { code: 'malformed_json', message: 'source JSON is invalid', file: 'sessions-index.json', line: null },
      { code: 'malformed_json', message: 'source JSON is invalid', file: '122.json', line: null },
      { code: 'malformed_json', message: 'source JSON is invalid', file: '2026-01-01.claude-health.jsonl', line: null },
    ]);
    assert.doesNotMatch(JSON.stringify(response.body), /�/);
  });

  it('rejects an unknown query parameter with HTTP 400', async () => {
    const response = await supertest(buildApp())
      .get('/time-tracking/v2')
      .query({ dates: '2026-01-01', harnesses: 'claude', extra: '1' })
      .expect(400);

    assert.match(response.body.error, /Unrecognized key/);
  });

  it('rejects the unsupported opencode harness with HTTP 400', async () => {
    const response = await supertest(buildApp())
      .get('/time-tracking/v2')
      .query({ dates: '2026-01-01', harnesses: 'opencode' })
      .expect(400);

    assert.match(response.body.error, /unsupported harnesses value: opencode/);
  });

  it('rejects a request URI over 4096 bytes with HTTP 400', async () => {
    const dates = '2026-01-01,'.repeat(400) + '2026-01-01';
    const url = `/time-tracking/v2?dates=${dates}&harnesses=claude`;
    assert.ok(Buffer.byteLength(url, 'utf-8') > 4096, 'fixture URL must actually exceed the limit');

    const response = await supertest(buildApp()).get(url).expect(400);

    assert.match(response.body.error, /exceeds 4096 bytes/);
  });

  // Bug fix (review finding WARNING 8): every malformed JSONL line adds one
  // record to the shared `errors` array with no upper bound — a
  // catastrophically malformed event file (thousands of garbage lines)
  // could make the errors array dominate the response instead of the actual
  // requested data. The response now caps at MAX_ERRORS records.
  it('caps the errors array at MAX_ERRORS even when far more malformed lines exist', async () => {
    const lineCount = v2.MAX_ERRORS + 20;
    const content = `${'not json\n'.repeat(lineCount)}`;
    fs.writeFileSync(path.join(trackingDir, '2026-01-01.jsonl'), content, 'utf-8');

    const response = await supertest(buildApp())
      .get('/time-tracking/v2')
      .query({ dates: '2026-01-01', harnesses: 'claude' })
      .expect(200);

    assert.equal(response.body.errors.length, v2.MAX_ERRORS);
    assert.equal(response.body.errors[0].code, 'malformed_json');
  });

  it('rejects a response whose descriptor digest does not match its content', () => {
    assert.throws(() => v2.validateResponse({
      schema_version: 2, hostname: 'typo3', timezone: 'Europe/Berlin', requested_dates: ['2026-01-01'], requested_harnesses: ['claude'],
      installed_harnesses: [], collector_versions: {}, session_metadata: [], health: [], errors: [],
      files: [{ kind: 'events', harness: 'claude', business_date: '2026-01-01', basename: '2026-01-01.jsonl', present: true, sha256: '0'.repeat(64), content: 'synthetic' }],
    }, { dates: ['2026-01-01'], harnesses: ['claude'] }));
  });

  // A3: ResponseSchema must reject an oversized errors array on its own —
  // the handler's own MAX_ERRORS cap (see "caps the errors array at
  // MAX_ERRORS" above) only protects requests served by *this* process.
  // validateResponse/ResponseSchema is also used by bin/rtime (see
  // validate_v2_response, rtime:136-141) to validate a response from a
  // FOREIGN host, where the handler-side cap gives no protection at all.
  it('rejects a response whose errors array exceeds MAX_ERRORS even though every entry is individually schema-valid', () => {
    const errors = Array.from({ length: v2.MAX_ERRORS + 1 }, () => ({
      code: 'malformed_json', message: 'source JSON is invalid', file: '2026-01-01.jsonl', line: null,
    }));
    assert.throws(() => v2.validateResponse({
      schema_version: 2, hostname: 'typo3', timezone: 'Europe/Berlin', requested_dates: ['2026-01-01'], requested_harnesses: ['claude'],
      installed_harnesses: [], collector_versions: {}, session_metadata: [], health: [], errors,
      files: [{ kind: 'events', harness: 'claude', business_date: '2026-01-01', basename: '2026-01-01.jsonl', present: false, sha256: null, content: null }],
    }, { dates: ['2026-01-01'], harnesses: ['claude'] }));
  });
});
