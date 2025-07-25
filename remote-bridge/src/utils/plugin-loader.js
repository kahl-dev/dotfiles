const fs = require('fs').promises;
const path = require('path');
const os = require('os');

async function loadPlugins(config) {
  const plugins = [];
  const pluginDir = path.join(os.homedir(), '.config', 'remote-bridge', 'plugins');
  
  // Check if plugin directory exists
  try {
    await fs.access(pluginDir);
  } catch {
    return plugins;
  }
  
  // Load enabled plugins
  if (!config.enabled || config.enabled.length === 0) {
    return plugins;
  }
  
  for (const pluginName of config.enabled) {
    try {
      const pluginPath = path.join(pluginDir, `${pluginName}.js`);
      
      // Check if plugin file exists
      await fs.access(pluginPath);
      
      // Clear require cache for hot reload
      delete require.cache[require.resolve(pluginPath)];
      
      // Load plugin
      const plugin = require(pluginPath);
      
      // Validate plugin
      if (!plugin.name) {
        console.error(`Plugin ${pluginName} missing required 'name' property`);
        continue;
      }
      
      plugins.push(plugin);
      console.log(`Loaded plugin: ${plugin.name} v${plugin.version || '1.0.0'}`);
      
    } catch (error) {
      console.error(`Failed to load plugin ${pluginName}:`, error);
    }
  }
  
  return plugins;
}

module.exports = { loadPlugins };