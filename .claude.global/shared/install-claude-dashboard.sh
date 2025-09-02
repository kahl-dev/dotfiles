#!/usr/bin/env bash
# Claude Code Dashboard Installation Script
# Sets up the complete Claude Code session tracking and dashboard system

set -euo pipefail

readonly SCRIPT_NAME="Claude Dashboard Installer"
readonly CLAUDE_DIR="$HOME/.claude"
readonly HOOKS_DIR="$CLAUDE_DIR/hooks"
readonly SHARED_DIR="$CLAUDE_DIR/shared"
readonly SESSIONS_DIR="$CLAUDE_DIR/sessions"

# Color definitions
readonly COLOR_RESET='\033[0m'
readonly COLOR_RED='\033[0;31m'
readonly COLOR_GREEN='\033[0;32m'
readonly COLOR_YELLOW='\033[1;33m'
readonly COLOR_BLUE='\033[0;34m'
readonly COLOR_PURPLE='\033[0;35m'
readonly COLOR_CYAN='\033[0;36m'
readonly COLOR_WHITE='\033[1;37m'
readonly COLOR_GRAY='\033[0;90m'
readonly COLOR_BOLD='\033[1m'

# Print colored output
print_color() {
  local color="$1"
  shift
  echo -e "${color}$*${COLOR_RESET}"
}

# Print header
print_header() {
  echo ""
  print_color "$COLOR_BOLD$COLOR_CYAN" "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  print_color "$COLOR_BOLD$COLOR_WHITE" "                      🎛️  Claude Code Dashboard Installer                       "
  print_color "$COLOR_BOLD$COLOR_CYAN" "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
}

# Print footer
print_footer() {
  echo ""
  print_color "$COLOR_BOLD$COLOR_CYAN" "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

# Check if command exists
command_exists() {
  command -v "$1" >/dev/null 2>&1
}

# Check dependencies
check_dependencies() {
  print_color "$COLOR_YELLOW" "🔍 Checking dependencies..."
  
  local missing_deps=()
  
  if ! command_exists jq; then
    missing_deps+=("jq")
  fi
  
  if ! command_exists tmux; then
    missing_deps+=("tmux")
  fi
  
  if [[ ${#missing_deps[@]} -gt 0 ]]; then
    print_color "$COLOR_RED" "❌ Missing dependencies: ${missing_deps[*]}"
    echo ""
    print_color "$COLOR_WHITE" "Please install the missing dependencies:"
    
    if [[ "$OSTYPE" == "darwin"* ]]; then
      print_color "$COLOR_CYAN" "  brew install ${missing_deps[*]}"
    elif command_exists apt-get; then
      print_color "$COLOR_CYAN" "  sudo apt-get install ${missing_deps[*]}"
    elif command_exists yum; then
      print_color "$COLOR_CYAN" "  sudo yum install ${missing_deps[*]}"
    else
      print_color "$COLOR_CYAN" "  Please install: ${missing_deps[*]}"
    fi
    
    exit 1
  fi
  
  print_color "$COLOR_GREEN" "✅ All dependencies are installed"
}

# Create directory structure
create_directories() {
  print_color "$COLOR_YELLOW" "📁 Creating directory structure..."
  
  local dirs=("$CLAUDE_DIR" "$HOOKS_DIR" "$SHARED_DIR" "$SESSIONS_DIR")
  
  for dir in "${dirs[@]}"; do
    if [[ ! -d "$dir" ]]; then
      mkdir -p "$dir"
      print_color "$COLOR_GREEN" "  Created: $dir"
    else
      print_color "$COLOR_GRAY" "  Exists: $dir"
    fi
  done
}

# Check if files exist
check_installation() {
  local files_exist=true
  
  if [[ ! -f "$HOOKS_DIR/track-session.sh" ]]; then
    files_exist=false
  fi
  
  if [[ ! -f "$SHARED_DIR/tmux-claude-dashboard.sh" ]]; then
    files_exist=false
  fi
  
  if [[ ! -f "$SHARED_DIR/tmux-claude-monitor.sh" ]]; then
    files_exist=false
  fi
  
  echo "$files_exist"
}

# Verify Claude Code settings
check_claude_settings() {
  print_color "$COLOR_YELLOW" "⚙️  Checking Claude Code settings..."
  
  local settings_file="$CLAUDE_DIR/settings.json"
  
  if [[ ! -f "$settings_file" ]]; then
    print_color "$COLOR_RED" "❌ Claude Code settings.json not found at $settings_file"
    return 1
  fi
  
  # Check if our hooks are configured
  if grep -q "track-session.sh" "$settings_file"; then
    print_color "$COLOR_GREEN" "✅ Session tracking hooks are configured"
    return 0
  else
    print_color "$COLOR_YELLOW" "⚠️  Session tracking hooks not found in settings.json"
    return 1
  fi
}

# Show post-installation setup
show_setup_instructions() {
  print_footer
  print_color "$COLOR_BOLD$COLOR_GREEN" "🎉 Installation completed successfully!"
  echo ""
  
  print_color "$COLOR_BOLD$COLOR_WHITE" "📋 Quick Start Guide:"
  echo ""
  
  print_color "$COLOR_BOLD$COLOR_CYAN" "1. Choose your dashboard style:"
  print_color "$COLOR_WHITE" "   ccd                     # Simple dashboard (original)"
  print_color "$COLOR_WHITE" "   ccd-enhanced            # Enhanced with filtering & priorities"
  print_color "$COLOR_WHITE" "   ccd-gui                 # GUI with split-screen & mouse support"
  print_color "$COLOR_WHITE" "   ccd-waiting             # Show only sessions waiting for response"
  echo ""
  
  print_color "$COLOR_BOLD$COLOR_CYAN" "2. Start background monitoring (optional):"
  print_color "$COLOR_WHITE" "   claude-monitor start    # Start background notifications"
  print_color "$COLOR_WHITE" "   ccm status              # Check monitor status"
  echo ""
  
  print_color "$COLOR_BOLD$COLOR_CYAN" "3. Use with tmux:"
  print_color "$COLOR_GRAY" "   • Start Claude Code in any tmux session"
  print_color "$COLOR_GRAY" "   • Sessions will automatically appear in dashboard"
  print_color "$COLOR_GRAY" "   • Get notifications when Claude is waiting for input"
  echo ""
  
  print_color "$COLOR_BOLD$COLOR_CYAN" "4. Enhanced tmux status line integration:"
  print_color "$COLOR_WHITE" "   Add to your ~/.tmux.conf (choose one):"
  print_color "$COLOR_GRAY" "   # Basic status"
  print_color "$COLOR_GRAY" "   set -g status-right '#(~/.claude/shared/tmux-claude-status.sh) %H:%M'"
  print_color "$COLOR_GRAY" "   # Enhanced with blinking alerts"
  print_color "$COLOR_GRAY" "   set -g status-right '#(~/.claude/shared/tmux-claude-status-enhanced.sh) %H:%M'"
  print_color "$COLOR_GRAY" "   # Current session + global summary"
  print_color "$COLOR_GRAY" "   set -g status-right '#(~/.claude/shared/tmux-claude-status-enhanced.sh detailed) %H:%M'"
  echo ""
  
  print_color "$COLOR_BOLD$COLOR_WHITE" "🚀 Available Commands:"
  echo ""
  print_color "$COLOR_CYAN" "  Dashboard Variants:"
  print_color "$COLOR_WHITE" "    ccd                    # Simple interactive dashboard"
  print_color "$COLOR_WHITE" "    ccd-enhanced           # Enhanced with priorities & filtering"
  print_color "$COLOR_WHITE" "    ccd-gui                # GUI with mouse support (100x30 min)"
  print_color "$COLOR_WHITE" "    ccd-waiting            # Show only sessions ready for response"
  print_color "$COLOR_WHITE" "    ccd -o                 # Show status once and exit"
  echo ""
  print_color "$COLOR_CYAN" "  Monitor:"
  print_color "$COLOR_WHITE" "    claude-monitor start   # Start background monitoring"
  print_color "$COLOR_WHITE" "    claude-monitor stop    # Stop background monitoring"
  print_color "$COLOR_WHITE" "    claude-monitor status  # Check monitor status"
  print_color "$COLOR_WHITE" "    claude-monitor logs    # View recent log entries"
  echo ""
  
  print_color "$COLOR_BOLD$COLOR_YELLOW" "💡 Tips:"
  print_color "$COLOR_GRAY" "  • The dashboard auto-refreshes every 2 seconds"
  print_color "$COLOR_GRAY" "  • Use numbers 1-9 to switch between sessions quickly"
  print_color "$COLOR_GRAY" "  • Press 'h' in dashboard to toggle help"
  print_color "$COLOR_GRAY" "  • Monitor sends macOS notifications when sessions need attention"
  echo ""
  
  print_color "$COLOR_BOLD$COLOR_WHITE" "📁 File Locations:"
  print_color "$COLOR_GRAY" "  Status file:   ~/.claude/sessions/status.json"
  print_color "$COLOR_GRAY" "  Logs:          ~/.claude/sessions/*.log"
  print_color "$COLOR_GRAY" "  Scripts:       ~/.claude/shared/tmux-claude-*.sh"
  print_color "$COLOR_GRAY" "  Hooks:         ~/.claude/hooks/track-session.sh"
  
  print_footer
  echo ""
  print_color "$COLOR_BOLD$COLOR_GREEN" "Ready to use! Start Claude Code in a tmux session and run 'claude-dashboard' 🎉"
  echo ""
}

# Show status of installation
show_status() {
  print_header
  print_color "$COLOR_BOLD$COLOR_WHITE" "📊 Current Installation Status"
  echo ""
  
  # Check dependencies
  print_color "$COLOR_BOLD$COLOR_CYAN" "Dependencies:"
  if command_exists jq; then
    print_color "$COLOR_GREEN" "  ✅ jq installed"
  else
    print_color "$COLOR_RED" "  ❌ jq not installed"
  fi
  
  if command_exists tmux; then
    print_color "$COLOR_GREEN" "  ✅ tmux installed"
  else
    print_color "$COLOR_RED" "  ❌ tmux not installed"
  fi
  
  echo ""
  
  # Check files
  print_color "$COLOR_BOLD$COLOR_CYAN" "Dashboard Files:"
  
  local files=(
    "$HOOKS_DIR/track-session.sh:Session tracking hook"
    "$SHARED_DIR/tmux-claude-dashboard.sh:Main dashboard (simple)"
    "$SHARED_DIR/tmux-claude-dashboard-gui.sh:GUI dashboard (mouse support)"
    "$SHARED_DIR/tmux-claude-dashboard-enhanced.sh:Enhanced dashboard (filters)"
    "$SHARED_DIR/tmux-claude-monitor.sh:Background monitor"
    "$SHARED_DIR/tmux-claude-status.sh:Status line integration"
    "$SHARED_DIR/tmux-claude-status-enhanced.sh:Enhanced status line"
  )
  
  for file_info in "${files[@]}"; do
    IFS=':' read -r file_path description <<< "$file_info"
    if [[ -f "$file_path" ]]; then
      print_color "$COLOR_GREEN" "  ✅ $description"
    else
      print_color "$COLOR_RED" "  ❌ $description (missing: $file_path)"
    fi
  done
  
  echo ""
  
  # Check Claude settings
  print_color "$COLOR_BOLD$COLOR_CYAN" "Claude Code Configuration:"
  if check_claude_settings >/dev/null 2>&1; then
    print_color "$COLOR_GREEN" "  ✅ Hooks configured in settings.json"
  else
    print_color "$COLOR_YELLOW" "  ⚠️  Hooks not configured (may need manual setup)"
  fi
  
  echo ""
  
  # Check if monitor is running
  print_color "$COLOR_BOLD$COLOR_CYAN" "Background Services:"
  if [[ -f "$SESSIONS_DIR/monitor.pid" ]] && ps -p "$(cat "$SESSIONS_DIR/monitor.pid")" >/dev/null 2>&1; then
    print_color "$COLOR_GREEN" "  ✅ Monitor running (PID: $(cat "$SESSIONS_DIR/monitor.pid"))"
  else
    print_color "$COLOR_GRAY" "  💤 Monitor not running"
  fi
  
  echo ""
  
  # Show available commands
  print_color "$COLOR_BOLD$COLOR_CYAN" "Available Commands:"
  
  if command -v claude-dashboard >/dev/null 2>&1; then
    print_color "$COLOR_GREEN" "  ✅ claude-dashboard (alias configured)"
  else
    print_color "$COLOR_YELLOW" "  ⚠️  claude-dashboard (alias not configured)"
  fi
  
  if command -v claude-monitor >/dev/null 2>&1; then
    print_color "$COLOR_GREEN" "  ✅ claude-monitor (alias configured)"
  else
    print_color "$COLOR_YELLOW" "  ⚠️  claude-monitor (alias not configured)"
  fi
  
  print_footer
}

# Show usage
show_usage() {
  cat << EOF
$SCRIPT_NAME

USAGE:
  $0 [COMMAND]

COMMANDS:
  install     Install the complete dashboard system (default)
  status      Show installation status
  test        Test the installation
  uninstall   Remove all dashboard components
  help        Show this help message

EXAMPLES:
  $0               # Install dashboard system
  $0 status        # Check installation status
  $0 test          # Test the system

EOF
}

# Test installation
test_installation() {
  print_header
  print_color "$COLOR_BOLD$COLOR_WHITE" "🧪 Testing Installation"
  echo ""
  
  local test_passed=true
  
  # Test 1: Check if scripts exist and are executable
  print_color "$COLOR_YELLOW" "Test 1: Checking script files..."
  
  local scripts=(
    "$HOOKS_DIR/track-session.sh"
    "$SHARED_DIR/tmux-claude-dashboard.sh"
    "$SHARED_DIR/tmux-claude-monitor.sh"
    "$SHARED_DIR/tmux-claude-status.sh"
  )
  
  for script in "${scripts[@]}"; do
    if [[ -x "$script" ]]; then
      print_color "$COLOR_GREEN" "  ✅ $(basename "$script") is executable"
    else
      print_color "$COLOR_RED" "  ❌ $(basename "$script") not found or not executable"
      test_passed=false
    fi
  done
  
  echo ""
  
  # Test 2: Test session tracking script
  print_color "$COLOR_YELLOW" "Test 2: Testing session tracking..."
  
  if "$HOOKS_DIR/track-session.sh" start >/dev/null 2>&1; then
    print_color "$COLOR_GREEN" "  ✅ Session tracking script works"
  else
    print_color "$COLOR_RED" "  ❌ Session tracking script failed"
    test_passed=false
  fi
  
  echo ""
  
  # Test 3: Test dashboard variants
  print_color "$COLOR_YELLOW" "Test 3: Testing dashboard variants..."
  
  if "$SHARED_DIR/tmux-claude-dashboard.sh" --oneshot >/dev/null 2>&1; then
    print_color "$COLOR_GREEN" "  ✅ Simple dashboard works"
  else
    print_color "$COLOR_RED" "  ❌ Simple dashboard failed"
    test_passed=false
  fi
  
  if "$SHARED_DIR/tmux-claude-dashboard-enhanced.sh" --oneshot >/dev/null 2>&1; then
    print_color "$COLOR_GREEN" "  ✅ Enhanced dashboard works"
  else
    print_color "$COLOR_RED" "  ❌ Enhanced dashboard failed"
    test_passed=false
  fi
  
  if "$SHARED_DIR/tmux-claude-dashboard-gui.sh" --help >/dev/null 2>&1; then
    print_color "$COLOR_GREEN" "  ✅ GUI dashboard syntax is valid"
  else
    print_color "$COLOR_RED" "  ❌ GUI dashboard has syntax errors"
    test_passed=false
  fi
  
  echo ""
  
  # Test 4: Test status script
  print_color "$COLOR_YELLOW" "Test 4: Testing status integration..."
  
  if "$SHARED_DIR/tmux-claude-status.sh" >/dev/null 2>&1; then
    print_color "$COLOR_GREEN" "  ✅ Status integration works"
  else
    print_color "$COLOR_RED" "  ❌ Status integration failed"
    test_passed=false
  fi
  
  echo ""
  
  # Test results
  if [[ "$test_passed" == "true" ]]; then
    print_color "$COLOR_BOLD$COLOR_GREEN" "🎉 All tests passed! Installation is working correctly."
  else
    print_color "$COLOR_BOLD$COLOR_RED" "❌ Some tests failed. Please check the installation."
  fi
  
  print_footer
}

# Main installation function
install_dashboard() {
  print_header
  print_color "$COLOR_BOLD$COLOR_WHITE" "Installing Claude Code Dashboard System..."
  echo ""
  
  # Check if already installed
  if [[ "$(check_installation)" == "true" ]]; then
    print_color "$COLOR_YELLOW" "⚠️  Dashboard appears to be already installed."
    echo ""
    read -r -p "Do you want to reinstall? [y/N]: " confirm
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
      print_color "$COLOR_GRAY" "Installation cancelled."
      exit 0
    fi
    echo ""
  fi
  
  # Check dependencies
  check_dependencies
  echo ""
  
  # Create directories
  create_directories
  echo ""
  
  # Check Claude settings
  if ! check_claude_settings; then
    print_color "$COLOR_RED" "❌ Claude Code settings.json configuration needs to be updated manually."
    print_color "$COLOR_YELLOW" "   The hook configuration should already be in place if this script is"
    print_color "$COLOR_YELLOW" "   running from the dotfiles repository setup."
    echo ""
  fi
  
  # Show success message
  show_setup_instructions
}

# Uninstall function
uninstall_dashboard() {
  print_header
  print_color "$COLOR_BOLD$COLOR_YELLOW" "⚠️  Uninstalling Claude Code Dashboard System"
  echo ""
  
  print_color "$COLOR_RED" "This will remove:"
  print_color "$COLOR_GRAY" "  • All dashboard scripts"
  print_color "$COLOR_GRAY" "  • Session tracking hooks"
  print_color "$COLOR_GRAY" "  • Status files and logs"
  print_color "$COLOR_GRAY" "  • Background monitor processes"
  echo ""
  
  read -r -p "Are you sure you want to uninstall? [y/N]: " confirm
  if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
    print_color "$COLOR_GRAY" "Uninstall cancelled."
    exit 0
  fi
  
  echo ""
  print_color "$COLOR_YELLOW" "Uninstalling..."
  
  # Stop monitor if running
  if [[ -f "$SHARED_DIR/tmux-claude-monitor.sh" ]]; then
    "$SHARED_DIR/tmux-claude-monitor.sh" stop >/dev/null 2>&1 || true
  fi
  
  # Remove files
  local files=(
    "$HOOKS_DIR/track-session.sh"
    "$SHARED_DIR/tmux-claude-dashboard.sh"
    "$SHARED_DIR/tmux-claude-monitor.sh"
    "$SHARED_DIR/tmux-claude-status.sh"
    "$SESSIONS_DIR"
  )
  
  for file in "${files[@]}"; do
    if [[ -e "$file" ]]; then
      rm -rf "$file"
      print_color "$COLOR_GREEN" "  Removed: $file"
    fi
  done
  
  echo ""
  print_color "$COLOR_BOLD$COLOR_GREEN" "✅ Uninstall completed!"
  print_color "$COLOR_GRAY" "Note: Claude Code settings.json hooks need to be removed manually if desired."
  
  print_footer
}

# Main function
main() {
  local command="${1:-install}"
  
  case "$command" in
    install)
      install_dashboard
      ;;
    status)
      show_status
      ;;
    test)
      test_installation
      ;;
    uninstall)
      uninstall_dashboard
      ;;
    help|-h|--help)
      show_usage
      ;;
    *)
      print_color "$COLOR_RED" "Unknown command: $command"
      show_usage
      exit 1
      ;;
  esac
}

# Check if running on supported platform
if [[ ! "$OSTYPE" =~ ^(darwin|linux) ]]; then
  print_color "$COLOR_YELLOW" "⚠️  This script is designed for macOS and Linux. Some features may not work on $OSTYPE."
fi

# Run main function
main "$@"