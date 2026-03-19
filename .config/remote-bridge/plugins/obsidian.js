const { execFile, execFileSync } = require('child_process');

const OBSIDIAN_BINARY = findObsidianBinary();

function findObsidianBinary() {
  // Try common locations
  const candidates = [
    '/Applications/Obsidian.app/Contents/MacOS/obsidian',
    '/usr/local/bin/obsidian',
    '/opt/homebrew/bin/obsidian',
  ];

  for (const candidate of candidates) {
    try {
      require('fs').accessSync(candidate, require('fs').constants.X_OK);
      return candidate;
    } catch {
      // continue
    }
  }

  // Fallback: try to resolve from PATH at startup
  try {
    return execFileSync('which', ['obsidian'], { encoding: 'utf-8' }).trim();
  } catch {
    return 'obsidian';
  }
}

function isObsidianRunning() {
  try {
    execFileSync('pgrep', ['-x', 'Obsidian'], { stdio: 'ignore' });
    return true;
  } catch {
    return false;
  }
}

function ensureObsidianRunning() {
  return new Promise((resolve, reject) => {
    if (isObsidianRunning()) {
      return resolve();
    }

    // Start Obsidian in background (no focus steal)
    execFile('open', ['-g', '-a', 'Obsidian'], (error) => {
      if (error) {
        return reject(new Error(`Failed to start Obsidian: ${error.message}`));
      }

      // Poll for CLI readiness
      let attempts = 0;
      const maxAttempts = 30;

      const poll = setInterval(() => {
        attempts += 1;

        try {
          execFileSync(OBSIDIAN_BINARY, ['version'], {
            stdio: 'ignore',
            timeout: 2000,
          });
          clearInterval(poll);
          resolve();
        } catch {
          if (attempts >= maxAttempts) {
            clearInterval(poll);
            reject(new Error(`Obsidian failed to start within ${maxAttempts}s`));
          }
        }
      }, 1000);
    });
  });
}

function parseArguments(commandString) {
  const arguments_ = [];
  let current = '';
  let inQuotes = false;
  let quoteChar = '';

  for (const character of commandString) {
    if (!inQuotes && (character === '"' || character === "'")) {
      inQuotes = true;
      quoteChar = character;
    } else if (inQuotes && character === quoteChar) {
      inQuotes = false;
    } else if (!inQuotes && character === ' ') {
      if (current) arguments_.push(current);
      current = '';
    } else {
      current += character;
    }
  }
  if (current) arguments_.push(current);
  return arguments_;
}

module.exports = {
  name: 'obsidian',
  version: '1.0.0',

  endpoints: [
    {
      path: '/obsidian/exec',
      method: 'POST',
      handler: async (request, response) => {
        const command = request.decodedData;

        if (!command || typeof command !== 'string' || command.trim().length === 0) {
          return response.status(400).json({ error: 'No command provided' });
        }

        const arguments_ = parseArguments(command.trim());

        try {
          await ensureObsidianRunning();
        } catch (startupError) {
          return response.status(503).json({ error: startupError.message });
        }

        execFile(OBSIDIAN_BINARY, arguments_, (error, stdout, stderr) => {
          const exitCode = error
            ? (typeof error.code === 'number' ? error.code : 1)
            : 0;

          response.json({
            stdout: stdout || '',
            stderr: stderr || '',
            exitCode,
          });
        });
      },
    },
  ],
};
