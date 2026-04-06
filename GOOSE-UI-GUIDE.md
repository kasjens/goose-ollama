# 🖥️ Goose Desktop UI Guide

This guide covers the Goose Desktop UI installation, configuration, and usage alongside the CLI version.

## 🌟 Overview

Goose provides both **Command Line Interface (CLI)** and **Desktop UI** versions:

- **CLI Version**: Terminal-based, lightweight, script-friendly
- **Desktop UI**: Graphical interface, user-friendly, visual conversations
- **Shared Configuration**: Both use the same models, skills, and settings

## 📦 Installation

### Automatic Installation (Recommended)
```bash
./install-goose-ui.sh
```

This script will:
- ✅ Download the official Goose Desktop .deb package (~143MB)
- ✅ Install the desktop application at `/usr/lib/goose/`
- ✅ Create application menu entry
- ✅ Set up desktop integration
- ✅ Verify installation

### Manual Installation
```bash
# Download the package
curl -L "https://github.com/block/goose/releases/latest/download/goose_1.29.1_amd64.deb" -o goose-desktop.deb

# Install (requires sudo)
sudo dpkg -i goose-desktop.deb
sudo apt-get install -f  # Fix any dependencies
```

## 🚀 Usage

### Launch Desktop UI

**Option 1: Using the launcher script (recommended)**
```bash
./run-goose-ui.sh
```

**Option 2: From Applications menu**
- Open Applications menu
- Look for "Goose" 
- Click to launch

**Option 3: Direct command**
```bash
/usr/lib/goose/Goose
```

### Launch CLI Version
```bash
./run-goose.sh
```

## ⚙️ Configuration

### Shared Settings
Both CLI and Desktop UI share:
- **Configuration**: `~/.config/goose/config.yaml`
- **Sessions**: `~/.local/share/goose/`
- **Provider settings**: Ollama with cloud models
- **Skills**: All 32 skills (18 Anthropic + 14 MiniMax)
- **Web search**: Brave Search API

### Desktop UI Specific Configuration

1. **Open Settings** (gear icon in UI)
2. **Configure Providers**: 
   - Provider: Ollama
   - Base URL: `http://localhost:11434`
   - Models: Cloud models (minimax-m2.7:cloud, etc.)

3. **Model Selection**:
   - Choose from available cloud models
   - Same models as CLI version

## 🔄 Switching Between CLI and UI

You can seamlessly switch between CLI and Desktop UI:

```bash
# Start session in CLI
./run-goose.sh

# Later, switch to Desktop UI  
./run-goose-ui.sh

# Both access the same sessions and configuration
```

## 🎯 Features Comparison

| Feature | CLI | Desktop UI |
|---------|-----|------------|
| **Cloud Models** | ✅ All available | ✅ All available |
| **Skills (32 total)** | ✅ Full access | ✅ Full access |
| **Web Search** | ✅ Brave Search | ✅ Brave Search |
| **Session Management** | ✅ Commands | ✅ Visual interface |
| **File Uploads** | ✅ Drag & drop | ✅ Drag & drop |
| **Copy/Paste** | ✅ Terminal | ✅ Rich text |
| **Syntax Highlighting** | ✅ Basic | ✅ Advanced |
| **Multi-threading** | ✅ Yes | ✅ Yes |
| **Extensions** | ✅ All | ✅ All |

## 🛠️ Troubleshooting

### Desktop UI Won't Launch

**Check installation:**
```bash
ls -la /usr/lib/goose/Goose
# Should show executable file
```

**Check dependencies:**
```bash
sudo apt-get install -f
```

**Check desktop entry:**
```bash
ls -la /usr/share/applications/goose.desktop
```

### Provider Configuration Issues

**Ensure Ollama is running:**
```bash
curl -s http://localhost:11434/api/tags
# Should return list of models
```

**Reset configuration:**
```bash
# Backup current config
cp ~/.config/goose/config.yaml ~/.config/goose/config.yaml.backup

# Restart configuration
./configure-cloud-models.sh
```

### Models Not Showing

**Check cloud models:**
```bash
ollama list | grep :cloud
# Should show minimax-m2.7:cloud, etc.
```

**Re-configure models:**
```bash
./configure-cloud-models.sh
```

### UI Stuck on "Loading Providers"

**Common fix:**
1. Close Goose Desktop UI
2. Restart Ollama: `ollama serve`
3. Wait 30 seconds
4. Restart Goose UI: `./run-goose-ui.sh`

**Alternative fix:**
```bash
# Clear UI cache
rm -rf ~/.local/share/goose/ui-cache/
./run-goose-ui.sh
```

## 🔍 Verification

### Check Installation Status
```bash
# Desktop UI binary
ls -la /usr/lib/goose/Goose

# Desktop integration
ls -la /usr/share/applications/goose.desktop

# System command (points to desktop)
ls -la /usr/bin/goose

# CLI binary (user-local)
ls -la ~/.local/bin/goose
```

### Test Both Interfaces
```bash
# Test CLI
./run-goose.sh
# Should start successfully

# Test Desktop UI (in another terminal)
./run-goose-ui.sh  
# Should launch GUI application
```

## 📊 Performance Notes

### Resource Usage
- **CLI**: Very lightweight (~50MB RAM)
- **Desktop UI**: Moderate (~200-400MB RAM)
- **Both**: Use same Ollama backend (cloud models)

### Recommended Usage
- **CLI**: Scripting, automation, quick tasks
- **Desktop UI**: Interactive sessions, file handling, visual feedback
- **Combined**: Use both as needed for different workflows

## 🎉 Success Indicators

✅ **Desktop UI Working:**
- Application launches without errors
- Provider shows "Ollama" 
- Models list shows cloud models
- Can start new conversation
- Skills accessible through chat

✅ **Full Integration:**
- CLI and UI sessions are interchangeable
- All 32 skills work in both interfaces
- Web search functional in both
- Cloud models accessible in both

---

**Result**: Complete Goose AI environment with both CLI and Desktop UI, sharing the same powerful cloud model and skills configuration! 🚀