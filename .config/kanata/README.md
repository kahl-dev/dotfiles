# Kanata macOS Setup

This folder contains configurations and scripts to set up and manage **Kanata** on macOS. These scripts handle installation, autostart configuration, and service control for Kanata.

## Prerequisites

Before proceeding, ensure **Kanata** is installed via Homebrew:

```bash
brew install kanata
```

## Setting Up Autostart

To enable Kanata to start automatically on macOS boot, follow these steps:

1. Copy the **`dev.kahl.kanata.plist`** file to the `LaunchAgents` directory:

   ```bash
   sudo cp dev.kahl.kanata.plist ~/Library/LaunchAgents/
   ```

2. Load and start the launch agent:

   ```bash
   sudo launchctl load -w ~/Library/LaunchAgents/dev.kahl.kanata.plist
   ```

### Automated Setup

Instead of performing these steps manually, you can use the **`handle.plist.sh`** script, which automates the entire setup:

```bash
sudo /Users/kahl-dev/.dotfiles/.config/kanata/handle.plist.sh
```

## Managing Kanata Service

This folder also contains scripts to **start, stop, and restart** the Kanata service:

- **Start Kanata:**

  ```bash
  sudo /Users/kahl-dev/.dotfiles/.config/kanata/start.kanata.sh
  ```

- **Stop Kanata:**

  ```bash
  sudo /Users/kahl-dev/.dotfiles/.config/kanata/stop.kanata.sh
  ```

- **Restart Kanata:**

  ```bash
  sudo /Users/kahl-dev/.dotfiles/.config/kanata/restart.kanata.sh
  ```

## Granting Execution Rights

Since these scripts require `sudo` access, they should be added to the **sudoers file** to allow execution without entering a password. To do this, edit the sudoers file:

```bash
sudo visudo
```

Then add the following lines at the end of the file:

```bash
kahl-dev ALL=(ALL) NOPASSWD: /Users/kahl-dev/.dotfiles/.config/kanata/handle.plist.sh
kahl-dev ALL=(ALL) NOPASSWD: /Users/kahl-dev/.dotfiles/.config/kanata/stop.kanata.sh
kahl-dev ALL=(ALL) NOPASSWD: /Users/kahl-dev/.dotfiles/.config/kanata/start.kanata.sh
kahl-dev ALL=(ALL) NOPASSWD: /Users/kahl-dev/.dotfiles/.config/kanata/restart.kanata.sh
```

This allows the specified scripts to be executed with `sudo` **without requiring a password**.

---

Now, Kanata is set up and can be managed easily using the provided scripts!
