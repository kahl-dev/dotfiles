const { describe, it } = require('node:test');
const assert = require('node:assert/strict');
const fs = require('fs');
const os = require('os');
const path = require('path');
const { resolveExpectedToken } = require('../src/utils/token');

describe('resolveExpectedToken', () => {
  // Guards the launchd failure mode: the LaunchAgent plist defines no PATH, so
  // `which atuin` cannot resolve the mise shim. If the candidate list ever goes
  // stale again, this fails instead of the bridge silently fail-closing.
  it('prefers the mise shim over legacy install locations and never falls back to which', () => {
    const home = fs.mkdtempSync(path.join(os.tmpdir(), 'token-shim-'));
    const shim = path.join(home, '.local', 'share', 'mise', 'shims', 'atuin');
    const legacy = path.join(home, '.atuin', 'bin', 'atuin');

    for (const binary of [shim, legacy]) {
      fs.mkdirSync(path.dirname(binary), { recursive: true });
      fs.writeFileSync(binary, '#!/bin/sh\n', { mode: 0o755 });
    }

    const invoked = [];
    const execFileSync = (file, args) => {
      invoked.push(file);
      if (file === 'which') {
        throw new Error('which must not be reached while an executable candidate exists');
      }
      assert.deepEqual(args, ['dotfiles', 'var', 'list']);
      return 'export REMOTE_BRIDGE_TOKEN=shim-token\n';
    };

    try {
      const result = resolveExpectedToken({ env: {}, execFileSync, homedir: () => home });

      assert.deepEqual(result, { token: 'shim-token', error: null });
      assert.deepEqual(invoked, [shim], 'the mise shim must win over the legacy curl install');
    } finally {
      fs.rmSync(home, { recursive: true, force: true });
    }
  });

  it('returns the env var token without consulting atuin, even when atuin would also resolve one', () => {
    const execFileSync = () => {
      throw new Error('execFileSync must not be called when the env var is set');
    };

    const result = resolveExpectedToken({
      env: { REMOTE_BRIDGE_TOKEN: 'env-token' },
      execFileSync,
      homedir: () => '/nonexistent',
    });

    assert.deepEqual(result, { token: 'env-token', error: null });
  });

  it('falls back to atuin and trims a padded value from the "dotfiles var list" line', () => {
    const execFileSync = (file, args) => {
      if (file === 'which') {
        assert.deepEqual(args, ['atuin']);
        return 'atuin\n';
      }
      assert.deepEqual(args, ['dotfiles', 'var', 'list']);
      return 'export SOME_OTHER_VAR=x\nexport REMOTE_BRIDGE_TOKEN=  abc \nexport TRAILING=y\n';
    };

    const result = resolveExpectedToken({
      env: {},
      execFileSync,
      homedir: () => '/nonexistent',
    });

    assert.deepEqual(result, { token: 'abc', error: null });
  });

  it('returns an empty token plus the underlying error when atuin has no matching var (fail-closed trigger)', () => {
    const execFileSync = (file) => {
      if (file === 'which') {
        return 'atuin\n';
      }
      return 'export SOME_OTHER_VAR=x\n';
    };

    const result = resolveExpectedToken({
      env: {},
      execFileSync,
      homedir: () => '/nonexistent',
    });

    // No `export REMOTE_BRIDGE_TOKEN=` line matched, so loadTokenFromAtuin
    // returns '' — this is the fail-closed trigger, not an execFileSync
    // failure, so no error surfaces.
    assert.deepEqual(result, { token: '', error: null });
  });

  it('returns an empty token and the atuin error when the binary cannot be resolved at all', () => {
    const execFileSync = () => {
      throw new Error('command not found: atuin');
    };

    const result = resolveExpectedToken({
      env: {},
      execFileSync,
      homedir: () => '/nonexistent',
    });

    assert.equal(result.token, '');
    assert.ok(result.error instanceof Error);
    assert.match(result.error.message, /atuin/);
  });
});
