const { describe, it } = require('node:test');
const assert = require('node:assert/strict');
const fs = require('fs');
const path = require('path');
const yaml = require('js-yaml');
const notifyPlugin = require('../src/plugins/notify');

// Parse a config file the same way src/utils/config.js does (js-yaml's
// `load`), so this asserts against the real shipped/live rules — not a
// hand-built fixture.
function loadYaml(configPath) {
  return yaml.load(fs.readFileSync(configPath, 'utf8'));
}

const DEFAULT_CONFIG = loadYaml(path.join(__dirname, '..', 'config', 'default.yaml'));
const LIVE_CONFIG = loadYaml(path.join(__dirname, '..', '..', '.config', 'remote-bridge', 'config.yaml'));

// findMatchingRule reads notifyPlugin.config (a module-level singleton), so
// re-initialize immediately before each lookup: node:test runs every it()
// only after all describe bodies are collected, so initializing once in a
// describe body would leave only the LAST config active when the assertions
// finally run.
function ruleFor(config, type) {
  notifyPlugin.initialize({ config, logger: { info() {} } });
  return notifyPlugin.findMatchingRule(type);
}

// The shipped template is the canonical spec — pin its exact sounds. These
// mirror the local osascript branch in claude-config/hooks/idle-notify.sh
// (idle_prompt=Glass, permission_prompt=Ping) so the same Claude event sounds
// identical whether it fires locally or over the bridge.
describe('notify: shipped config/default.yaml routes Claude hook types to their canonical sounds', () => {
  it('claude-idle_prompt (idle-notify.sh notification_type=idle_prompt) resolves to Glass', () => {
    assert.equal(ruleFor(DEFAULT_CONFIG, 'claude-idle_prompt')?.sound, 'Glass');
  });

  it('claude-permission_prompt (idle-notify.sh notification_type=permission_prompt) resolves to Ping', () => {
    assert.equal(ruleFor(DEFAULT_CONFIG, 'claude-permission_prompt')?.sound, 'Ping');
  });

  it('error resolves to Basso', () => {
    assert.equal(ruleFor(DEFAULT_CONFIG, 'error')?.sound, 'Basso');
  });

  it('an unmatched type resolves to no rule (the notification then uses defaultSound)', () => {
    assert.equal(ruleFor(DEFAULT_CONFIG, 'no-such-type'), undefined);
  });
});

// The live config is what config.js actually reads on this machine (found
// before default.yaml, no merge). Its sounds are user-customizable, so assert
// only that every real notification type still MATCHES a rule of its own type
// — that guards the original bug (a type routing to no rule, as claude-hook
// once did) without turning a personal sound preference into a red test.
describe('notify: live .config/remote-bridge/config.yaml matches every real notification type to a rule', () => {
  for (const type of ['claude-idle_prompt', 'claude-permission_prompt', 'error']) {
    it(`${type} matches a rule of its own type`, () => {
      assert.equal(ruleFor(LIVE_CONFIG, type)?.type, type);
    });
  }

  it('an unmatched type resolves to no rule', () => {
    assert.equal(ruleFor(LIVE_CONFIG, 'no-such-type'), undefined);
  });
});
