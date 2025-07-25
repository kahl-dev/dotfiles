const winston = require('winston');
const path = require('path');
const fs = require('fs').promises;

function createLogger(config) {
  // Ensure log directory exists
  const logDir = path.dirname(config.file);
  fs.mkdir(logDir, { recursive: true }).catch(() => {});
  
  const logger = winston.createLogger({
    level: config.level || 'info',
    format: winston.format.combine(
      winston.format.timestamp(),
      winston.format.errors({ stack: true }),
      winston.format.json()
    ),
    transports: [
      // File transport
      new winston.transports.File({
        filename: config.file,
        maxsize: parseSize(config.maxSize || '10MB'),
        maxFiles: config.maxFiles || 5,
        tailable: true
      }),
      // Console transport for development
      ...(process.env.NODE_ENV === 'development' || process.argv.includes('--dev') ? [
        new winston.transports.Console({
          format: winston.format.combine(
            winston.format.colorize(),
            winston.format.simple()
          )
        })
      ] : [])
    ]
  });
  
  // Add history method
  logger.getHistory = async function(limit = 50) {
    try {
      const logContent = await fs.readFile(config.file, 'utf8');
      const lines = logContent.trim().split('\n').filter(Boolean);
      const recent = lines.slice(-limit);
      
      return recent.map(line => {
        try {
          return JSON.parse(line);
        } catch {
          return { message: line };
        }
      }).reverse();
    } catch (error) {
      return [];
    }
  };
  
  return logger;
}

function parseSize(size) {
  const units = { KB: 1024, MB: 1024 * 1024, GB: 1024 * 1024 * 1024 };
  const match = size.match(/^(\d+)(KB|MB|GB)$/i);
  
  if (!match) return 10 * 1024 * 1024; // Default 10MB
  
  const [, num, unit] = match;
  return parseInt(num) * units[unit.toUpperCase()];
}

module.exports = { createLogger };