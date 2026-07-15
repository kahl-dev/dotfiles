const { execFileSync: realExecFileSync } = require('child_process');
const { accessSync, constants: fsConstants } = require('fs');
const os = require('os');
const path = require('path');

// launchd runs the server with a minimal PATH that excludes mise/homebrew
// shims, so `atuin` on PATH cannot be assumed — probe known install
// locations first, then fall back to `which` for anything else.
function resolveAtuinBinary({ homedir = os.homedir, execFileSync = realExecFileSync } = {}) {
  const candidates = [
    path.join(homedir(), '.atuin', 'bin', 'atuin'),
    '/opt/homebrew/bin/atuin',
    '/usr/local/bin/atuin',
  ];

  for (const candidate of candidates) {
    try {
      accessSync(candidate, fsConstants.X_OK);
      return candidate;
    } catch {
      // continue to next candidate
    }
  }

  return execFileSync('which', ['atuin'], { encoding: 'utf-8' }).trim();
}

function loadTokenFromAtuin({ homedir = os.homedir, execFileSync = realExecFileSync } = {}) {
  const atuinBinary = resolveAtuinBinary({ homedir, execFileSync });
  const output = execFileSync(atuinBinary, ['dotfiles', 'var', 'list'], { encoding: 'utf-8' });
  const match = output.match(/^export REMOTE_BRIDGE_TOKEN=(.+)$/m);
  return match ? match[1].trim() : '';
}

/**
 * Resolves the token launchd/interactive clients must present. Checked in
 * order: env (covers interactive launch) then atuin's synced dotfiles vars
 * (covers launchd, which starts with no interactive shell env).
 *
 * Returns { token: '', error } when neither yields a token — atuin missing,
 * not authenticated, or the var isn't set all collapse to an empty token,
 * but `error` carries the real cause so the caller can log it (never the
 * token value) before treating the empty result as fail-closed.
 */
function resolveExpectedToken({ env = process.env, execFileSync = realExecFileSync, homedir = os.homedir } = {}) {
  if (env.REMOTE_BRIDGE_TOKEN) {
    return { token: env.REMOTE_BRIDGE_TOKEN, error: null };
  }

  try {
    return { token: loadTokenFromAtuin({ homedir, execFileSync }), error: null };
  } catch (error) {
    return { token: '', error };
  }
}

module.exports = { resolveExpectedToken, loadTokenFromAtuin, resolveAtuinBinary };
