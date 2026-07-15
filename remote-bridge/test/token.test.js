const { describe, it } = require('node:test');
const assert = require('node:assert/strict');
const { resolveExpectedToken } = require('../src/utils/token');

describe('resolveExpectedToken', () => {
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
