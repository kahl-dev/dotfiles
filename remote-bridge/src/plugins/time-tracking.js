const fs = require('fs').promises;
const path = require('path');
const os = require('os');

const TRACKING_DIR = path.join(os.homedir(), '.claude', 'time-tracking');

module.exports = {
  name: 'time-tracking',
  version: '1.0.0',

  endpoints: [
    {
      path: '/time-tracking',
      method: 'GET',
      handler: async function (req, res) {
        const datesParam = req.query.dates;
        if (!datesParam) {
          return res.status(400).json({
            error: 'Missing required query parameter: dates (comma-separated YYYY-MM-DD)',
          });
        }

        const dates = datesParam.split(',').map((d) => d.trim());
        const invalidDates = dates.filter((d) => !/^\d{4}-\d{2}-\d{2}$/.test(d));
        if (invalidDates.length > 0) {
          return res.status(400).json({
            error: `Invalid date format: ${invalidDates.join(', ')} (expected YYYY-MM-DD)`,
          });
        }

        const results = {};
        for (const date of dates) {
          const filePath = path.join(TRACKING_DIR, `${date}.jsonl`);
          try {
            const content = await fs.readFile(filePath, 'utf-8');
            results[date] = content;
          } catch (error) {
            if (error.code === 'ENOENT') {
              results[date] = '';
            } else {
              this.server.logger.error(`Failed to read ${filePath}: ${error.message}`);
              results[date] = '';
            }
          }
        }

        const hostname = os.hostname();

        res.json({
          hostname,
          tracking_dir: TRACKING_DIR,
          dates: results,
        });
      },
    },
    {
      path: '/time-tracking/dates',
      method: 'GET',
      handler: async function (req, res) {
        try {
          const files = await fs.readdir(TRACKING_DIR);
          const dates = files
            .filter((f) => /^\d{4}-\d{2}-\d{2}\.jsonl$/.test(f))
            .map((f) => f.replace('.jsonl', ''))
            .sort();
          res.json({ dates, hostname: os.hostname() });
        } catch (error) {
          if (error.code === 'ENOENT') {
            return res.json({ dates: [], hostname: os.hostname() });
          }
          throw error;
        }
      },
    },
    // v2 contract (Claude subset, Phase 1): strict query validation, explicit
    // present/absent file descriptors, structured session metadata and health
    // records, never an empty-string stand-in for a read failure. See
    // ./time-tracking-v2.js and claude-config
    // plans/multi-harness-time-tracking.md ("Remote Bridge v2 contract").
    //
    // Required lazily, at request time: a top-level require here would pull
    // in zod at plugin-load time, and a load failure (e.g. a deploy host
    // missing zod) would throw during require('./plugins/time-tracking'),
    // which server.js's loadPlugins() core-plugin loop catches by never
    // registering the plugin at all — taking down /time-tracking (the v1
    // rollback path) together with /time-tracking/v2. Lazy require confines
    // a v2 load failure to this one endpoint.
    {
      path: '/time-tracking/v2',
      method: 'GET',
      handler: async function (req, res) {
        return require('./time-tracking-v2').handler.call(this, req, res);
      },
    },
  ],

  initialize: function (server) {
    this.server = server;
    server.logger.info('Time tracking plugin loaded', { tracking_dir: TRACKING_DIR });
  },
};
