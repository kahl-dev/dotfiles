const { execFile, execFileSync } = require('child_process');
const fs = require('fs');
const os = require('os');
const path = require('path');

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

/**
 * Get the vault path from the obsidian CLI.
 */
let cachedVaultPath = null;
function getVaultPath() {
  if (cachedVaultPath) return cachedVaultPath;
  try {
    const output = execFileSync(OBSIDIAN_BINARY, ['vault'], { encoding: 'utf-8', timeout: 5000 });
    const pathMatch = output.match(/path\t(.+)/);
    if (pathMatch) {
      cachedVaultPath = pathMatch[1].trim();
      return cachedVaultPath;
    }
  } catch {
    // fallback
  }
  return null;
}

/**
 * Handle stdin content by writing directly to the vault file system.
 * The obsidian CLI's content= arg breaks with multiline content via execFile,
 * so for create/append/prepend with --stdin, we write the file directly
 * and skip the CLI for the content part.
 */
function handleStdinCommand(arguments_, stdinData) {
  const vaultPath = getVaultPath();
  if (!vaultPath) {
    throw new Error('Could not determine vault path for direct file write');
  }

  // Extract command and path from arguments
  const command = arguments_[0]; // create, append, prepend
  let filePath = null;

  for (const argument of arguments_) {
    if (argument.startsWith('path=')) {
      filePath = argument.slice(5).replace(/^["']|["']$/g, '');
    }
  }

  if (!filePath) {
    throw new Error('No path= argument found for stdin content');
  }

  const fullPath = path.join(vaultPath, filePath);
  const directory = path.dirname(fullPath);

  // Ensure directory exists
  fs.mkdirSync(directory, { recursive: true });

  if (command === 'create') {
    const overwrite = arguments_.includes('overwrite');
    if (fs.existsSync(fullPath) && !overwrite) {
      // Obsidian creates "name 1.md" for duplicates — match that behavior
      const extension = path.extname(fullPath);
      const basePath = fullPath.slice(0, -extension.length);
      let counter = 1;
      let newPath = `${basePath} ${counter}${extension}`;
      while (fs.existsSync(newPath)) {
        counter++;
        newPath = `${basePath} ${counter}${extension}`;
      }
      fs.writeFileSync(newPath, stdinData, 'utf-8');
      const relativePath = path.relative(vaultPath, newPath);
      return { stdout: `Created: ${relativePath}\n`, stderr: '', exitCode: 0 };
    }
    fs.writeFileSync(fullPath, stdinData, 'utf-8');
    return { stdout: `Created: ${filePath}\n`, stderr: '', exitCode: 0 };
  }

  if (command === 'append') {
    if (!fs.existsSync(fullPath)) {
      return { stdout: '', stderr: `Error: File not found: ${filePath}\n`, exitCode: 1 };
    }
    fs.appendFileSync(fullPath, stdinData, 'utf-8');
    return { stdout: `Appended to: ${filePath}\n`, stderr: '', exitCode: 0 };
  }

  if (command === 'prepend') {
    if (!fs.existsSync(fullPath)) {
      return { stdout: '', stderr: `Error: File not found: ${filePath}\n`, exitCode: 1 };
    }
    const existing = fs.readFileSync(fullPath, 'utf-8');
    fs.writeFileSync(fullPath, stdinData + existing, 'utf-8');
    return { stdout: `Prepended to: ${filePath}\n`, stderr: '', exitCode: 0 };
  }

  throw new Error(`Unsupported stdin command: ${command}`);
}

/**
 * Check if command is a write command that should use direct file write.
 */
function isStdinWriteCommand(arguments_) {
  const command = arguments_[0];
  return ['create', 'append', 'prepend'].includes(command) &&
    arguments_.some(a => a === '--stdin' || a === '--content-file' || a.startsWith('--content-file='));
}

/**
 * Remove --stdin and --content-file flags from arguments.
 */
function stripStdinFlags(arguments_) {
  return arguments_.filter(a => a !== '--stdin' && a !== '--content-file' && !a.startsWith('--content-file='));
}

module.exports = {
  name: 'obsidian',
  version: '1.2.0',

  endpoints: [
    {
      path: '/obsidian/exec',
      method: 'POST',
      handler: async (request, response) => {
        const command = request.decodedData;
        const stdinData = request.stdinData;

        if (!command || typeof command !== 'string' || command.trim().length === 0) {
          return response.status(400).json({ error: 'No command provided' });
        }

        let arguments_ = parseArguments(command.trim());

        try {
          await ensureObsidianRunning();
        } catch (startupError) {
          return response.status(503).json({ error: startupError.message });
        }

        // For write commands with stdin: bypass CLI, write directly to vault
        if (stdinData && isStdinWriteCommand(arguments_)) {
          try {
            const cleanArgs = stripStdinFlags(arguments_);
            const result = handleStdinCommand(cleanArgs, stdinData);
            return response.json(result);
          } catch (writeError) {
            return response.status(500).json({ error: writeError.message });
          }
        }

        execFile(OBSIDIAN_BINARY, arguments_, { maxBuffer: 50 * 1024 * 1024 }, (error, stdout, stderr) => {
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
