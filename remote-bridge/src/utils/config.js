const fs = require('fs').promises;
const path = require('path');
const yaml = require('js-yaml');
const os = require('os');

async function loadConfig() {
  const defaultConfig = {
    service: {
      port: 8377,
      logLevel: 'info'
    },
    notifications: {
      rules: [],
      defaultSound: 'Pop'
    },
    rateLimit: {
      windowMs: 60000,
      maxRequests: 60,
      maxPerHost: 20
    },
    logging: {
      file: '~/.local/share/remote-bridge/activity.log',
      maxSize: '10MB',
      maxFiles: 5
    },
    plugins: {
      enabled: []
    }
  };
  
  // Try to load user config
  const configPaths = [
    path.join(os.homedir(), '.config', 'remote-bridge', 'config.yaml'),
    path.join(__dirname, '..', '..', 'config', 'default.yaml')
  ];
  
  let userConfig = {};
  
  for (const configPath of configPaths) {
    try {
      const configFile = await fs.readFile(configPath, 'utf8');
      userConfig = yaml.load(configFile);
      console.log(`Loaded config from: ${configPath}`);
      break;
    } catch (error) {
      // Continue to next path
    }
  }
  
  // Merge configs
  const config = deepMerge(defaultConfig, userConfig);
  
  // Expand paths
  config.logging.file = expandPath(config.logging.file);
  
  return config;
}

function expandPath(filePath) {
  if (filePath.startsWith('~/')) {
    return path.join(os.homedir(), filePath.slice(2));
  }
  return filePath;
}

function deepMerge(target, source) {
  const output = Object.assign({}, target);
  
  if (isObject(target) && isObject(source)) {
    Object.keys(source).forEach(key => {
      if (isObject(source[key])) {
        if (!(key in target)) {
          Object.assign(output, { [key]: source[key] });
        } else {
          output[key] = deepMerge(target[key], source[key]);
        }
      } else {
        Object.assign(output, { [key]: source[key] });
      }
    });
  }
  
  return output;
}

function isObject(item) {
  return item && typeof item === 'object' && !Array.isArray(item);
}

module.exports = { loadConfig, expandPath };