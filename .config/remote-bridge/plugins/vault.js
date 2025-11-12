const fs = require('fs').promises;
const path = require('path');
const os = require('os');

module.exports = {
  name: 'vault',
  version: '1.0.0',

  endpoints: [
    {
      path: '/vault/read',
      method: 'POST',
      handler: async (req, res) => {
        const { path: notePath } = req.decodedData;
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
        const { paths } = req.decodedData;
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
        const { path: notePath, content } = req.decodedData;
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
        const { path: notePath, content } = req.decodedData;
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
        const { path: dirPath = '' } = req.decodedData;
        const vaultPath = getVaultPath();
        const fullPath = path.join(vaultPath, dirPath);

        try {
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
        const { path: notePath } = req.decodedData;
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
        const { query, context_length = 3 } = req.decodedData;
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
        const { days = 90, limit = 10 } = req.decodedData;
        const vaultPath = getVaultPath();

        try {
          const files = await getRecentChanges(vaultPath, days, limit);
          res.json({ files });
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
  return vaultPath.replace('~', os.homedir());
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
