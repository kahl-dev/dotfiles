// Exercises bin/rtime's fetch-v2 subcommand end-to-end against a minimal
// real HTTP server (real auth middleware + real v2 handler, isolated
// tracking/home directories) — never against ~/.claude, and never starting
// the production Remote Bridge service.
//
// Listens on a Unix socket, not TCP: rtime resolves its transport via
// resolve_bridge_endpoint() (lib/bridge-endpoint.sh), which only recognizes
// TCP localhost:8377 on Darwin — this test runs non-Darwin CI/dev hosts, so
// the client only ever speaks the Unix socket path (REMOTE_BRIDGE_SOCKET).
//
// Uses the async execFile (not execFileSync): the test bridge server runs in
// this same Node process, so a *synchronous* child-process call would block
// the event loop the server needs to answer the request — a deadlock, not a
// flake. execFileSync is fine only when the server under test is a genuinely
// separate OS process.

const { describe, it, beforeEach, afterEach } = require('node:test');
const assert = require('node:assert/strict');
const fs = require('fs');
const path = require('path');
const crypto = require('crypto');
const { execFile } = require('child_process');
const { promisify } = require('util');

const execFileAsync = promisify(execFile);

const { createAuthMiddleware } = require('../src/middleware/auth');
const timeTrackingV2 = require('../src/plugins/time-tracking-v2');
const { mkTempDir, stopTestBridge, startTestBridge: startBridge } = require('./support');

const RTIME_BIN = path.join(__dirname, '..', 'bin', 'rtime');
const TEST_TOKEN = 'rtime-fetch-v2-test-token';

async function startTestBridge({ trackingDir, homedir, socketPath }) {
  const server = await startBridge(socketPath, (app) => {
    app.use(createAuthMiddleware(TEST_TOKEN));
    app.get(
      '/time-tracking/v2',
      timeTrackingV2.createHandler({
        trackingDir,
        homedir,
        hostnameFn: () => 'test-bridge-host',
      })
    );
  });
  return { server };
}

async function startResponseBridge({ socketPath, response, delayMs = 0 }) {
  const server = await startBridge(socketPath, (app) => {
    app.use(createAuthMiddleware(TEST_TOKEN));
    app.get('/time-tracking/v2', (req, res) => {
      if (delayMs > 0) {
        setTimeout(() => res.json(response), delayMs);
        return;
      }
      if (typeof response === 'string') {
        res.type('application/json').send(response);
        return;
      }
      res.json(response);
    });
  });
  return { server };
}

describe('rtime fetch-v2', () => {
  let trackingDir;
  let homedir;
  let socketDir;
  let socketPath;
  let server;
  let eventContent;

  beforeEach(async () => {
    trackingDir = mkTempDir('rtime-v2-tracking-');
    homedir = mkTempDir('rtime-v2-home-');
    socketDir = mkTempDir('rtime-v2-socket-');
    socketPath = path.join(socketDir, 'bridge.sock');
    eventContent = '{"session_id":"s1"}\n{"session_id":"s2"}\n';
    fs.writeFileSync(path.join(trackingDir, '2026-01-01.jsonl'), eventContent, 'utf-8');

    ({ server } = await startTestBridge({ trackingDir, homedir, socketPath }));
  });

  afterEach(async () => {
    await stopTestBridge(server, socketPath);
    fs.rmSync(trackingDir, { recursive: true, force: true });
    fs.rmSync(homedir, { recursive: true, force: true });
    fs.rmSync(socketDir, { recursive: true, force: true });
  });

  function runRtime(args, extraEnv = {}) {
    return execFileAsync(RTIME_BIN, args, {
      env: { ...process.env, ...extraEnv, REMOTE_BRIDGE_SOCKET: socketPath, REMOTE_BRIDGE_TOKEN: TEST_TOKEN },
      encoding: 'utf-8',
    });
  }

  function validResponse() {
    const content = 'synthetic\n';
    return {
      schema_version: 2,
      hostname: 'test-bridge-host',
      timezone: 'Europe/Berlin',
      requested_dates: ['2026-01-01'],
      requested_harnesses: ['claude'],
      installed_harnesses: [],
      collector_versions: {},
      files: [{
        kind: 'events', harness: 'claude', business_date: '2026-01-01', basename: '2026-01-01.jsonl', present: true,
        sha256: crypto.createHash('sha256').update(Buffer.from(content, 'utf-8')).digest('hex'), content,
      }],
      session_metadata: [], health: [], errors: [],
    };
  }

  it('prints the v2 JSON to stdout without --output', async () => {
    const { stdout } = await runRtime(['fetch-v2', '--dates', '2026-01-01', '--harnesses', 'claude']);
    const parsed = JSON.parse(stdout);

    assert.equal(parsed.schema_version, 2);
    assert.equal(parsed.hostname, 'test-bridge-host');
    assert.equal(parsed.timezone, 'Europe/Berlin');
    assert.deepEqual(parsed.requested_dates, ['2026-01-01']);
    assert.deepEqual(parsed.requested_harnesses, ['claude']);
    assert.equal(parsed.files.length, 1);
    assert.equal(parsed.files[0].present, true);
    assert.equal(parsed.files[0].content, eventContent);
  });

  it('prints a schema-valid partial response with source errors without --output', async () => {
    await stopTestBridge(server, socketPath);
    const response = validResponse();
    response.errors = [{ code: 'permissions_invalid', message: 'file could not be read', file: '2026-01-01.jsonl', line: null }];
    ({ server } = await startResponseBridge({ socketPath, response }));

    const result = await runRtime(['fetch-v2', '--dates', '2026-01-01', '--harnesses', 'claude']);
    assert.deepEqual(JSON.parse(result.stdout), response);
    assert.equal(result.stderr, '');
  });

  it('with --output: writes the exact received event basename and a source-result.json into a new empty directory', async () => {
    const outDir = path.join(mkTempDir('rtime-v2-out-parent-'), 'fresh-output');

    const previousUmask = process.umask(0o022);
    try {
      await runRtime(['fetch-v2', '--dates', '2026-01-01', '--harnesses', 'claude', '--output', outDir]);
    } finally {
      process.umask(previousUmask);
    }

    const writtenEvent = fs.readFileSync(path.join(outDir, '2026-01-01.jsonl'), 'utf-8');
    assert.equal(writtenEvent, eventContent, 'the written event file must be byte-for-byte identical to the source content');

    const expectedSha256 = crypto.createHash('sha256').update(Buffer.from(eventContent, 'utf-8')).digest('hex');
    const sourceResult = JSON.parse(fs.readFileSync(path.join(outDir, 'source-result.json'), 'utf-8'));
    assert.equal(sourceResult.schema_version, 2);
    assert.equal(sourceResult.files[0].sha256, expectedSha256);

    const writtenFiles = fs.readdirSync(outDir).sort();
    assert.deepEqual(writtenFiles, ['2026-01-01.jsonl', 'source-result.json']);
    assert.equal(fs.statSync(outDir).mode & 0o777, 0o700);
    assert.equal(fs.statSync(path.join(outDir, '2026-01-01.jsonl')).mode & 0o777, 0o600);
    assert.equal(fs.statSync(path.join(outDir, 'source-result.json')).mode & 0o777, 0o600);
  });

  // E1 efficiency fix: write_v2_output (bin/rtime) now moves every present
  // file's content through a single jq pass, base64-encoded, instead of one
  // `jq -j '.content'` call per file. The previous approach reproduced raw
  // bytes exactly (jq -j writes UTF-8 straight through); this test proves
  // the base64 round-trip (jq's @base64 encode, then `base64 -d`/-D decode)
  // preserves the exact bytes too — tabs, embedded newlines, a literal
  // quote, umlauts, a NUL byte, and a multibyte emoji, none of which may be
  // corrupted, escaped, or line-wrapped along the way.
  //
  // The fixture content is deliberately not valid JSONL, so the server also
  // reports one malformed_json source error per line (see extractSessionIds)
  // — the same "partial response, non-zero exit, but the file is still
  // written" contract already covered by the source-errors test above; this
  // test focuses on the written bytes, not the error reporting.
  it('with --output: writes byte-identical content for tabs, embedded newlines, a quote, umlauts, a NUL byte, and an emoji', async () => {
    const specialContent = 'tab\there\nsecond line\nquote:"here"\numlaut:äöü\nemoji:\u{1F600}\x00\n';
    fs.writeFileSync(path.join(trackingDir, '2026-01-01.jsonl'), specialContent, 'utf-8');
    const expectedBytes = Buffer.from(specialContent, 'utf-8');

    const outDir = path.join(mkTempDir('rtime-v2-special-parent-'), 'output');

    await assert.rejects(
      runRtime(['fetch-v2', '--dates', '2026-01-01', '--harnesses', 'claude', '--output', outDir]),
      (error) => {
        assert.notEqual(error.code, 0);
        assert.match(error.stderr.toString(), /source error/);
        return true;
      }
    );

    const writtenBytes = fs.readFileSync(path.join(outDir, '2026-01-01.jsonl'));
    assert.equal(writtenBytes.length, expectedBytes.length);
    assert.deepEqual(writtenBytes, expectedBytes, 'the written event file must be byte-for-byte identical, including tabs, embedded newlines, a quote, umlauts, a NUL byte, and an emoji');

    const expectedSha256 = crypto.createHash('sha256').update(expectedBytes).digest('hex');
    const sourceResult = JSON.parse(fs.readFileSync(path.join(outDir, 'source-result.json'), 'utf-8'));
    assert.equal(sourceResult.files[0].sha256, expectedSha256);
  });

  it('with --output: refuses a non-empty destination directory and writes nothing', async () => {
    const outDir = mkTempDir('rtime-v2-nonempty-');
    fs.writeFileSync(path.join(outDir, 'pre-existing.txt'), 'do not touch', 'utf-8');

    await assert.rejects(
      runRtime(['fetch-v2', '--dates', '2026-01-01', '--harnesses', 'claude', '--output', outDir]),
      (error) => {
        assert.notEqual(error.code, 0);
        assert.match(error.stderr.toString(), /already exists/);
        return true;
      }
    );

    const remainingFiles = fs.readdirSync(outDir).sort();
    assert.deepEqual(remainingFiles, ['pre-existing.txt'], 'the refusal must happen before any bridge call or write');
  });

  it('reports a missing --dates as a usage error without contacting the bridge', async () => {
    await assert.rejects(
      runRtime(['fetch-v2', '--harnesses', 'claude']),
      (error) => {
        assert.notEqual(error.code, 0);
        assert.match(error.stderr.toString(), /--dates is required/);
        return true;
      }
    );
  });

  it('surfaces a server-validated 400 (unsupported harness) distinctly from a connection failure', async () => {
    await assert.rejects(
      runRtime(['fetch-v2', '--dates', '2026-01-01', '--harnesses', 'opencode']),
      (error) => {
        assert.notEqual(error.code, 0);
        assert.match(error.stderr.toString(), /unsupported harnesses value: opencode/);
        return true;
      }
    );
  });

  it('rejects malformed, traversal, digest-mismatched, and duplicate payloads before creating output', async () => {
    const payloads = [
      '{not-json',
      { ...validResponse(), files: [{ ...validResponse().files[0], basename: '../escape.jsonl' }] },
      { ...validResponse(), files: [{ ...validResponse().files[0], sha256: '0'.repeat(64) }] },
      { ...validResponse(), files: [validResponse().files[0], validResponse().files[0]] },
      { ...validResponse(), files: [] },
    ];

    for (const payload of payloads) {
      await stopTestBridge(server, socketPath);
      ({ server } = await startResponseBridge({ socketPath, response: payload }));
      const outDir = path.join(mkTempDir('rtime-v2-invalid-parent-'), 'output');
      await assert.rejects(runRtime(['fetch-v2', '--dates', '2026-01-01', '--harnesses', 'claude', '--output', outDir]));
      assert.equal(fs.existsSync(outDir), false);
    }
  });

  // Bug fix (review finding WARNING 5): a schema-valid partial response
  // (present files plus a non-empty errors array) previously made
  // validate_v2_response abort with `reject_source_errors=1` before
  // write_v2_output ever ran, discarding every already-fetched file and
  // leaving no source-result.json — exactly when the errors array is most
  // needed for diagnosis. The plan (multi-harness-time-tracking.md,
  // "Remote Bridge v2 contract") describes --output as writing "exact
  // received event basenames plus source-result.json; refuses a non-empty
  // destination" — nothing about discarding on source errors.
  it('with --output: writes the partial response and source-result.json, then exits non-zero, when the response carries source errors', async () => {
    await stopTestBridge(server, socketPath);
    const response = validResponse();
    response.errors = [{ code: 'permissions_invalid', message: 'file could not be read', file: '2026-01-01.jsonl', line: null }];
    ({ server } = await startResponseBridge({ socketPath, response }));

    const outDir = path.join(mkTempDir('rtime-v2-partial-parent-'), 'output');

    await assert.rejects(
      runRtime(['fetch-v2', '--dates', '2026-01-01', '--harnesses', 'claude', '--output', outDir]),
      (error) => {
        assert.notEqual(error.code, 0);
        assert.match(error.stderr.toString(), /source error/);
        return true;
      }
    );

    const writtenEvent = fs.readFileSync(path.join(outDir, '2026-01-01.jsonl'), 'utf-8');
    assert.equal(writtenEvent, 'synthetic\n');

    const sourceResult = JSON.parse(fs.readFileSync(path.join(outDir, 'source-result.json'), 'utf-8'));
    assert.deepEqual(sourceResult.errors, response.errors);

    const writtenFiles = fs.readdirSync(outDir).sort();
    assert.deepEqual(writtenFiles, ['2026-01-01.jsonl', 'source-result.json']);
  });

  it('fails before creating output when the bridge socket is unavailable', async () => {
    await stopTestBridge(server, socketPath);
    const outDir = path.join(mkTempDir('rtime-v2-unavailable-parent-'), 'output');
    await assert.rejects(runRtime(['fetch-v2', '--dates', '2026-01-01', '--harnesses', 'claude', '--output', outDir]));
    assert.equal(fs.existsSync(outDir), false);
    ({ server } = await startTestBridge({ trackingDir, homedir, socketPath }));
  });

  it('fails before creating output when the v2 request times out', async () => {
    await stopTestBridge(server, socketPath);
    ({ server } = await startResponseBridge({ socketPath, response: validResponse(), delayMs: 11_000 }));
    const outDir = path.join(mkTempDir('rtime-v2-timeout-parent-'), 'output');
    await assert.rejects(runRtime(['fetch-v2', '--dates', '2026-01-01', '--harnesses', 'claude', '--output', outDir]));
    assert.equal(fs.existsSync(outDir), false);
  });

  // Bug fix (review finding BLOCKER 3): the final publish used to be
  // `mkdir "$output_dir"` followed by moving each staged file in
  // individually — an attacker (or any other process) that wins the race
  // and replaces `$output_dir` with a symlink between
  // assert_empty_output_dir's earlier check and this call used to be
  // caught by the `mkdir` call itself failing atomically. The fix replaced
  // that multi-step publish with a single atomic rename of the whole
  // staging directory (via Node's fs.renameSync, not the `mv` command —
  // see write_v2_output's comment for why), so the race must now be
  // exercised against that rename call instead: the fake `mv`/`mkdir`
  // binaries are gone; the hook is a fake `node` shim that plants the
  // symlink immediately before delegating to the real `node` binary, which
  // is what actually performs the rename.
  it('does not publish into a destination replaced by a symlink during the final claim', async () => {
    const parentDir = mkTempDir('rtime-v2-race-parent-');
    const outDir = path.join(parentDir, 'output');
    const outsideDir = mkTempDir('rtime-v2-race-outside-');
    const fakeBin = mkTempDir('rtime-v2-race-bin-');
    const realNode = process.execPath;
    const fakeNode = path.join(fakeBin, 'node');
    fs.writeFileSync(fakeNode, [
      '#!/usr/bin/env bash',
      'for arg in "$@"; do',
      '  if [ "$arg" = "$RTIME_RACE_DESTINATION" ]; then',
      '    ln -s "$RTIME_RACE_OUTSIDE" "$RTIME_RACE_DESTINATION"',
      '    break',
      '  fi',
      'done',
      `exec "${realNode}" "$@"`,
      '',
    ].join('\n'), { mode: 0o700 });

    await assert.rejects(runRtime(
      ['fetch-v2', '--dates', '2026-01-01', '--harnesses', 'claude', '--output', outDir],
      { PATH: `${fakeBin}:${process.env.PATH}`, RTIME_RACE_DESTINATION: outDir, RTIME_RACE_OUTSIDE: outsideDir }
    ));

    assert.equal(fs.lstatSync(outDir).isSymbolicLink(), true);
    assert.deepEqual(fs.readdirSync(outsideDir), []);
    fs.rmSync(parentDir, { recursive: true, force: true });
    fs.rmSync(outsideDir, { recursive: true, force: true });
    fs.rmSync(fakeBin, { recursive: true, force: true });
  });

  // Bug fix (review findings BLOCKER 2 and BLOCKER 3-downgraded-WARNING):
  // under `set -euo pipefail`, a write failure partway through the decode
  // loop (e.g. base64 hitting ENOSPC) used to kill the whole shell via
  // errexit without ever running write_v2_output's cleanup — a RETURN trap
  // does not fire on that abort path — leaving the staging directory
  // (`.rtime-v2.XXXXXX`, holding already-decoded, potentially sensitive
  // content) behind in the output directory's parent. The fix switched to
  // an EXIT trap on a non-local `stage_dir` so cleanup runs regardless of
  // how the shell exits. The same failure, happening entirely inside the
  // write loop, also proves the destination is never created: the final
  // atomic rename (finding 3) is never reached.
  it('cleans up the staging directory, exits non-zero, and never creates the destination when a write fails mid-loop', async () => {
    await stopTestBridge(server, socketPath);
    const firstFile = validResponse().files[0];
    const response = {
      ...validResponse(),
      requested_dates: ['2026-01-01', '2026-01-02'],
      files: [firstFile, { ...firstFile, business_date: '2026-01-02', basename: '2026-01-02.jsonl' }],
    };
    ({ server } = await startResponseBridge({ socketPath, response }));

    const parentDir = mkTempDir('rtime-v2-write-fail-parent-');
    const outDir = path.join(parentDir, 'output');
    const fakeBin = mkTempDir('rtime-v2-write-fail-bin-');
    const counterFile = path.join(fakeBin, 'base64-call-count');
    const fakeBase64 = path.join(fakeBin, 'base64');
    fs.writeFileSync(fakeBase64, [
      '#!/usr/bin/env bash',
      'counter_file="$RTIME_BASE64_COUNTER_FILE"',
      'count=0',
      '[ -f "$counter_file" ] && count=$(cat "$counter_file")',
      'count=$((count + 1))',
      'echo "$count" > "$counter_file"',
      'if [ "$count" -ge "$RTIME_BASE64_FAIL_ON" ]; then',
      '  echo "fake base64: simulated write failure" >&2',
      '  exit 1',
      'fi',
      'exec /usr/bin/base64 "$@"',
      '',
    ].join('\n'), { mode: 0o700 });

    await assert.rejects(
      runRtime(
        ['fetch-v2', '--dates', '2026-01-01,2026-01-02', '--harnesses', 'claude', '--output', outDir],
        { PATH: `${fakeBin}:${process.env.PATH}`, RTIME_BASE64_COUNTER_FILE: counterFile, RTIME_BASE64_FAIL_ON: '2' }
      ),
      (error) => {
        assert.notEqual(error.code, 0);
        return true;
      }
    );

    assert.equal(fs.existsSync(outDir), false, 'the destination directory must not exist when the process aborted before the final publish');
    assert.deepEqual(fs.readdirSync(parentDir), [], 'no .rtime-v2.* staging directory may remain after a mid-loop write failure');

    fs.rmSync(parentDir, { recursive: true, force: true });
    fs.rmSync(fakeBin, { recursive: true, force: true });
  });
});
