const fs = require('fs').promises;
const path = require('path');
const os = require('os');

// Helper to parse decoded JSON data
function getRequestData(req) {
  if (typeof req.decodedData === 'string') {
    return JSON.parse(req.decodedData);
  }
  return req.decodedData;
}

module.exports = {
  name: 'vault',
  version: '1.0.0',

  endpoints: [
    {
      path: '/vault/read',
      method: 'POST',
      handler: async (req, res) => {
        const { path: notePath } = getRequestData(req);
        const vaultPath = getVaultPath();
        const fullPath = path.join(vaultPath, notePath);

        try {
          const content = await fs.readFile(fullPath, 'utf-8');
          const stats = await fs.stat(fullPath);

          res.json({
            path: notePath,
            content,
            size: stats.size,
            modified: stats.mtimeMs / 1000,
          });
        } catch (error) {
          res.status(404).json({ error: `Note not found: ${notePath}` });
        }
      }
    },

    {
      path: '/vault/read-batch',
      method: 'POST',
      handler: async (req, res) => {
        const { paths } = getRequestData(req);
        const vaultPath = getVaultPath();
        const results = [];

        for (const notePath of paths) {
          const fullPath = path.join(vaultPath, notePath);
          try {
            const content = await fs.readFile(fullPath, 'utf-8');
            const stats = await fs.stat(fullPath);
            results.push({
              path: notePath,
              content,
              size: stats.size,
              modified: stats.mtimeMs / 1000,
              success: true,
            });
          } catch (error) {
            results.push({
              path: notePath,
              error: error.message,
              success: false,
            });
          }
        }

        res.json({ notes: results });
      }
    },

    {
      path: '/vault/write',
      method: 'POST',
      handler: async (req, res) => {
        const { path: notePath, content } = getRequestData(req);
        const vaultPath = getVaultPath();
        const fullPath = path.join(vaultPath, notePath);

        try {
          await fs.mkdir(path.dirname(fullPath), { recursive: true });
          await fs.writeFile(fullPath, content, 'utf-8');
          res.json({ success: true, path: notePath });
        } catch (error) {
          res.status(500).json({ error: error.message });
        }
      }
    },

    {
      path: '/vault/append',
      method: 'POST',
      handler: async (req, res) => {
        const { path: notePath, content } = getRequestData(req);
        const vaultPath = getVaultPath();
        const fullPath = path.join(vaultPath, notePath);

        try {
          // Create file if doesn't exist
          await fs.mkdir(path.dirname(fullPath), { recursive: true });
          await fs.appendFile(fullPath, content, 'utf-8');
          res.json({ success: true, path: notePath });
        } catch (error) {
          res.status(500).json({ error: error.message });
        }
      }
    },

    {
      path: '/vault/list',
      method: 'POST',
      handler: async (req, res) => {
        const { path: dirPath = '' } = getRequestData(req);
        const vaultPath = getVaultPath();
        const fullPath = path.join(vaultPath, dirPath);

        try{
          const entries = await fs.readdir(fullPath, { withFileTypes: true });
          const files = entries
            .filter(entry => !entry.name.startsWith('.'))
            .map(entry => ({
              name: entry.name,
              type: entry.isDirectory() ? 'directory' : 'file',
              path: path.join(dirPath, entry.name),
            }));
          res.json({ path: fullPath, entries: files });
        } catch (error) {
          res.status(404).json({ error: `Directory not found: ${dirPath}` });
        }
      }
    },

    {
      path: '/vault/delete',
      method: 'POST',
      handler: async (req, res) => {
        const { path: notePath } = getRequestData(req);
        const vaultPath = getVaultPath();
        const fullPath = path.join(vaultPath, notePath);

        try {
          await fs.unlink(fullPath);
          res.json({ success: true, path: notePath });
        } catch (error) {
          res.status(404).json({ error: `Note not found: ${notePath}` });
        }
      }
    },

    {
      path: '/vault/search',
      method: 'POST',
      handler: async (req, res) => {
        const { query, context_length = 3 } = getRequestData(req);
        const vaultPath = getVaultPath();

        try {
          const matches = await searchVault(vaultPath, query, context_length);
          res.json({ matches });
        } catch (error) {
          res.status(500).json({ error: error.message });
        }
      }
    },

    {
      path: '/vault/recent-changes',
      method: 'POST',
      handler: async (req, res) => {
        const { days = 90, limit = 10 } = getRequestData(req);
        const vaultPath = getVaultPath();

        try {
          const files = await getRecentChanges(vaultPath, days, limit);
          res.json({ files });
        } catch (error) {
          res.status(500).json({ error: error.message });
        }
      }
    },

    {
      path: '/vault/get-periodic-note',
      method: 'POST',
      handler: async (req, res) => {
        const { period } = getRequestData(req);
        const vaultPath = getVaultPath();

        try {
          const result = await getPeriodicNote(vaultPath, period);
          res.json(result);
        } catch (error) {
          res.status(500).json({ error: error.message });
        }
      }
    },

    {
      path: '/vault/get-recent-periodic-notes',
      method: 'POST',
      handler: async (req, res) => {
        const { period, limit = 7, include_content = false } = getRequestData(req);
        const vaultPath = getVaultPath();

        try {
          const notes = await getRecentPeriodicNotes(vaultPath, period, limit, include_content);
          res.json({ period, notes, total: notes.length });
        } catch (error) {
          res.status(500).json({ error: error.message });
        }
      }
    },

    {
      path: '/vault/patch',
      method: 'POST',
      handler: async (req, res) => {
        const { path: notePath, target_type, target, operation, content } = getRequestData(req);
        const vaultPath = getVaultPath();
        const fullPath = path.join(vaultPath, notePath);

        try {
          const result = await patchContent(fullPath, target_type, target, operation, content);
          res.json({ ...result, path: notePath });
        } catch (error) {
          res.status(500).json({ error: error.message });
        }
      }
    },

    {
      path: '/vault/complex-search',
      method: 'POST',
      handler: async (req, res) => {
        const { query } = getRequestData(req);
        const vaultPath = getVaultPath();

        try {
          const results = await complexSearch(vaultPath, query);
          res.json({ query, results, total: results.length });
        } catch (error) {
          res.status(500).json({ error: error.message });
        }
      }
    },
  ],
};

function getVaultPath() {
  const vaultPath = process.env.OBSIDIAN_VAULT_PATH;
  if (!vaultPath) {
    throw new Error('OBSIDIAN_VAULT_PATH not set');
  }
  // Only replace ~ at the START of the path (home directory marker)
  // Don't replace ~ in the middle (like iCloud~md~obsidian)
  if (vaultPath.startsWith('~')) {
    return vaultPath.replace(/^~/, os.homedir());
  }
  return vaultPath;
}

async function searchVault(vaultPath, query, contextLength) {
  const matches = [];
  const queryLower = query.toLowerCase();

  async function searchDir(dir) {
    const entries = await fs.readdir(dir, { withFileTypes: true });

    for (const entry of entries) {
      if (entry.name.startsWith('.')) continue;

      const fullPath = path.join(dir, entry.name);

      if (entry.isDirectory()) {
        await searchDir(fullPath);
      } else if (entry.name.endsWith('.md')) {
        const content = await fs.readFile(fullPath, 'utf-8');
        const lines = content.split('\n');

        lines.forEach((line, index) => {
          if (line.toLowerCase().includes(queryLower)) {
            const relativePath = path.relative(vaultPath, fullPath);
            matches.push({
              file: relativePath,
              line: index + 1,
              content: line,
            });
          }
        });
      }
    }
  }

  await searchDir(vaultPath);
  return matches;
}

async function getRecentChanges(vaultPath, days, limit) {
  const files = [];
  const cutoffTime = Date.now() - (days * 24 * 60 * 60 * 1000);

  async function scanDir(dir) {
    const entries = await fs.readdir(dir, { withFileTypes: true });

    for (const entry of entries) {
      if (entry.name.startsWith('.')) continue;

      const fullPath = path.join(dir, entry.name);

      if (entry.isDirectory()) {
        await scanDir(fullPath);
      } else {
        const stats = await fs.stat(fullPath);
        if (stats.mtimeMs >= cutoffTime) {
          const relativePath = path.relative(vaultPath, fullPath);
          files.push({
            path: relativePath,
            modified: stats.mtimeMs / 1000,
            size: stats.size,
          });
        }
      }
    }
  }

  await scanDir(vaultPath);

  // Sort by modified time (most recent first)
  files.sort((a, b) => b.modified - a.modified);

  return files.slice(0, limit);
}

function getWeekNumber(date) {
  const d = new Date(Date.UTC(date.getFullYear(), date.getMonth(), date.getDate()));
  const dayNum = d.getUTCDay() || 7;
  d.setUTCDate(d.getUTCDate() + 4 - dayNum);
  const yearStart = new Date(Date.UTC(d.getUTCFullYear(), 0, 1));
  return Math.ceil((((d - yearStart) / 86400000) + 1) / 7);
}

function generatePeriodicFilename(period, date) {
  switch (period) {
    case 'daily':
      return date.toISOString().split('T')[0] + '.md';
    case 'weekly':
      const year = date.getFullYear();
      const weekNum = getWeekNumber(date);
      return `${year}-W${String(weekNum).padStart(2, '0')}.md`;
    case 'monthly':
      return `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, '0')}.md`;
    case 'quarterly':
      const quarter = Math.floor(date.getMonth() / 3) + 1;
      return `${date.getFullYear()}-Q${quarter}.md`;
    case 'yearly':
      return `${date.getFullYear()}.md`;
    default:
      throw new Error(`Invalid period: ${period}`);
  }
}

async function getPeriodicNote(vaultPath, period) {
  const filename = generatePeriodicFilename(period, new Date());

  const searchPaths = [
    path.join(vaultPath, filename),
    path.join(vaultPath, 'Daily Notes', filename),
    path.join(vaultPath, 'Weekly Notes', filename),
    path.join(vaultPath, 'Monthly Notes', filename),
    path.join(vaultPath, 'Periodic Notes', filename),
    path.join(vaultPath, 'Journal', filename)
  ];

  for (const searchPath of searchPaths) {
    try {
      const content = await fs.readFile(searchPath, 'utf-8');
      const stats = await fs.stat(searchPath);
      const relativePath = path.relative(vaultPath, searchPath);

      return {
        found: true,
        period,
        filename,
        path: relativePath,
        content,
        size: stats.size,
        modified: stats.mtimeMs / 1000
      };
    } catch (err) {
      // Continue searching
    }
  }

  return {
    found: false,
    period,
    filename,
    searched_locations: searchPaths.map(p => path.relative(vaultPath, p))
  };
}

async function getRecentPeriodicNotes(vaultPath, period, limit, include_content) {
  const notes = [];
  const now = new Date();

  for (let i = 0; i < limit; i++) {
    let date = new Date(now);

    switch (period) {
      case 'daily':
        date.setDate(date.getDate() - i);
        break;
      case 'weekly':
        date.setDate(date.getDate() - (i * 7));
        break;
      case 'monthly':
        date.setMonth(date.getMonth() - i);
        break;
      case 'quarterly':
        date.setMonth(date.getMonth() - (i * 3));
        break;
      case 'yearly':
        date.setFullYear(date.getFullYear() - i);
        break;
      default:
        throw new Error(`Invalid period: ${period}`);
    }

    const filename = generatePeriodicFilename(period, date);

    const searchPaths = [
      path.join(vaultPath, filename),
      path.join(vaultPath, 'Daily Notes', filename),
      path.join(vaultPath, 'Weekly Notes', filename),
      path.join(vaultPath, 'Monthly Notes', filename),
      path.join(vaultPath, 'Periodic Notes', filename),
      path.join(vaultPath, 'Journal', filename)
    ];

    for (const searchPath of searchPaths) {
      try {
        const stats = await fs.stat(searchPath);
        const relativePath = path.relative(vaultPath, searchPath);

        const note = {
          filename,
          path: relativePath,
          size: stats.size,
          modified: stats.mtimeMs / 1000,
          found: true
        };

        if (include_content) {
          note.content = await fs.readFile(searchPath, 'utf-8');
        }

        notes.push(note);
        break;
      } catch (err) {
        // Continue searching
      }
    }
  }

  return notes;
}

async function patchContent(fullPath, target_type, target, operation, content) {
  const fileContent = await fs.readFile(fullPath, 'utf-8');
  const lines = fileContent.split('\n');
  let targetLine = -1;

  if (target_type === 'heading') {
    targetLine = lines.findIndex(line => line.includes(target));
  } else if (target_type === 'block') {
    targetLine = lines.findIndex(line => line.includes(`^${target}`));
  } else if (target_type === 'frontmatter') {
    let inFrontmatter = false;
    for (let i = 0; i < lines.length; i++) {
      if (i === 0 && lines[i] === '---') {
        inFrontmatter = true;
        continue;
      }
      if (inFrontmatter && lines[i] === '---') {
        break;
      }
      if (inFrontmatter && lines[i].startsWith(`${target}:`)) {
        targetLine = i;
        break;
      }
    }
  }

  if (targetLine === -1) {
    throw new Error(`Target not found: ${target}`);
  }

  if (operation === 'append') {
    lines.splice(targetLine + 1, 0, content);
  } else if (operation === 'prepend') {
    lines.splice(targetLine, 0, content);
  } else if (operation === 'replace') {
    lines[targetLine] = content;
  } else {
    throw new Error(`Invalid operation: ${operation}`);
  }

  await fs.writeFile(fullPath, lines.join('\n'), 'utf-8');
  const stats = await fs.stat(fullPath);

  return {
    success: true,
    target_type,
    target,
    operation,
    size: stats.size,
    modified: stats.mtimeMs / 1000
  };
}

async function complexSearch(vaultPath, query) {
  const results = [];

  async function scanDir(dir) {
    const entries = await fs.readdir(dir, { withFileTypes: true });

    for (const entry of entries) {
      if (entry.name.startsWith('.')) continue;

      const fullPath = path.join(dir, entry.name);

      if (entry.isDirectory()) {
        await scanDir(fullPath);
      } else if (entry.isFile()) {
        const stats = await fs.stat(fullPath);
        const relativePath = path.relative(vaultPath, fullPath);

        const context = {
          path: relativePath,
          name: entry.name,
          size: stats.size,
          modified: stats.mtimeMs / 1000,
          extension: path.extname(entry.name),
          directory: path.dirname(relativePath)
        };

        if (evaluateJsonLogic(query, context)) {
          results.push(context);
        }
      }
    }
  }

  await scanDir(vaultPath);
  return results;
}

function evaluateJsonLogic(query, context) {
  if (query.glob) {
    const [pattern, valueRef] = query.glob;
    const value = valueRef.var ? context[valueRef.var] : valueRef;
    return minimatch(value, pattern);
  }

  if (query.regexp) {
    const [pattern, valueRef] = query.regexp;
    const value = valueRef.var ? context[valueRef.var] : valueRef;
    return new RegExp(pattern).test(value);
  }

  if (query.and) {
    return query.and.every(q => evaluateJsonLogic(q, context));
  }

  if (query.or) {
    return query.or.some(q => evaluateJsonLogic(q, context));
  }

  if (query.not) {
    return !evaluateJsonLogic(query.not, context);
  }

  if (query['==']) {
    const [a, b] = query['=='];
    return resolveValue(a, context) === resolveValue(b, context);
  }

  if (query['>']) {
    const [a, b] = query['>'];
    return resolveValue(a, context) > resolveValue(b, context);
  }

  if (query['<']) {
    const [a, b] = query['<'];
    return resolveValue(a, context) < resolveValue(b, context);
  }

  return false;
}

function resolveValue(value, context) {
  if (typeof value === 'object' && value.var) {
    return context[value.var];
  }
  return value;
}

function minimatch(value, pattern) {
  const regex = pattern
    .replace(/\./g, '\\.')
    .replace(/\*/g, '.*')
    .replace(/\?/g, '.');
  return new RegExp(`^${regex}$`).test(value);
}
