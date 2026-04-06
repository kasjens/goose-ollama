# Goose AI with Local Ollama MiniMax and Skills

This project sets up Goose AI to work with a local Ollama instance accessing cloud models, integrated with MiniMax and Anthropic skills repositories.

✅ **Setup Complete!** Goose is now configured to use cloud models through local Ollama (no GPU/RAM requirements).

## Prerequisites

- **Ollama** installed and signed in (`ollama signin`)
- **Python 3.8+** for skill dependencies  
- **Internet connection** for cloud model access
- **Goose AI** (CLI + Desktop UI) will be installed automatically

## Project Structure

```
goose-ollama-minimax/
├── 📂 .agents/
│   └── skills/            # 31 auto-discovered skills
├── 📂 scripts/
│   ├── setup/            # Installation & configuration
│   ├── run/              # Execution scripts
│   └── utils/            # Maintenance & testing
├── 📂 docs/
│   ├── guides/           # Essential documentation
│   └── archive/          # Historical docs
├── 📂 config/            # Requirements & packages
├── 📂 anthropic-skills/  # Anthropic skills repository  
├── 📂 minimax-skills/    # MiniMax skills repository
├── 📂 brave-search-mcp/  # Web search integration
└── 📄 README.md          # This file
```

**Quick Access:** Convenience symlinks in root for `setup.sh`, `run-goose.sh`, and `validate.sh`

## Available Skills

### 🎯 **31 Skills Available** (Auto-Discovered)

All skills are **automatically detected** by Goose based on your requests - no manual loading needed!

#### 📄 **Document Processing (8 skills)**
- **PowerPoint**: `pptx`, `pptx-generator` - Professional presentation creation
- **Word**: `docx`, `minimax-docx` - Document creation with TOC, formatting
- **Excel**: `xlsx`, `minimax-xlsx` - Spreadsheet operations and analysis  
- **PDF**: `pdf`, `minimax-pdf` - PDF processing and manipulation

#### 📱 **Mobile Development (4 skills)**
- **iOS**: `ios-application-dev` - Native iOS app development
- **Android**: `android-native-dev` - Native Android development
- **React Native**: `react-native-dev` - Cross-platform mobile apps
- **Flutter**: `flutter-dev` - Google's UI toolkit

#### 🎨 **Creative & Design (6 skills)**
- **Frontend Design**: `frontend-design`, `frontend-dev` - UI/UX with animations
- **Art Creation**: `algorithmic-art`, `canvas-design` - Generative and visual art
- **Media**: `gif-sticker-maker`, `slack-gif-creator` - Animated content
- **Branding**: `theme-factory`, `brand-guidelines` - Professional theming

#### 💻 **Development Tools (6 skills)**
- **APIs**: `claude-api` - Build with Claude API/Anthropic SDK
- **MCP Servers**: `mcp-builder` - Create Model Context Protocol servers
- **Testing**: `webapp-testing` - Playwright-based web app testing
- **Full-Stack**: `fullstack-dev` - Complete web development
- **Shaders**: `shader-dev` - GLSL shader development  
- **Skills**: `skill-creator` - Create and improve AI skills

#### 💼 **Communication & Business (4 skills)**
- **Documentation**: `doc-coauthoring` - Structured doc writing
- **Internal Comms**: `internal-comms` - Professional communication
- **Vision**: `vision-analysis` - Computer vision and image analysis
- **Multimedia**: `minimax-multimodal-toolkit` - Audio/video/image tools

#### 🌐 **Web Development (3 skills)**
- **Artifacts**: `web-artifacts-builder` - HTML/CSS/JS applications
- **Frontend**: Advanced UI with animations and AI-generated assets
- **Testing**: Comprehensive web application testing and validation

### Web Search
- **Brave Search**: Integrated web search capability (2000 queries/month free)

## Quick Start (Fresh WSL2 Ubuntu)

1. **Run setup** (handles everything: Ollama, Goose, Python, skills)
   ```bash
   ./setup.sh
   ```

2. **Optional extras**
   ```bash
   scripts/setup/install-all-dependencies.sh  # Add PyTorch, Node.js, etc.
   scripts/setup/setup-brave-search.sh        # Web search (free API key)
   scripts/setup/install-goose-ui.sh          # Desktop UI
   ```

3. **Run Goose**
   ```bash
   ./run-goose.sh                # CLI (recommended)
   scripts/run/run-goose-ui.sh   # Desktop UI
   ```

4. **Validate**
   ```bash
   ./validate.sh
   ```

## Configuration

### Ollama Settings
- **Default Model**: `minimax-m2.7:cloud` 
- **Available Models**: 15+ cloud models (DeepSeek V3.2, Qwen3-Coder 480B, GPT-OSS 120B, etc.)
- **Base URL**: `http://localhost:11434`
- **Provider**: `ollama`
- **Cloud Integration**: Latest 2025 models via Ollama cloud

### Modifying Skills
Edit `.goose/config.yaml` to enable/disable specific skills:
```yaml
enabled_skills:
  - frontend-dev
  - fullstack-dev
  # Add or remove skills as needed
```

## Troubleshooting

### Multiple Goose Installations
This setup supports both user-local and system-wide Goose installations:

**User-Local Goose AI** (Recommended):
- Location: `~/.local/bin/goose`
- Type: Goose AI CLI (supports Ollama)
- Use: `./run-goose.sh`

**System-Wide Installation**:
- Location: `/usr/bin/goose`
- Type: May be GUI app or different version
- Use: `./run-goose-system.sh`

**Auto-Detection**:
- Use: `./run-goose.sh` (automatically chooses best)

### Ollama Not Running
If you see "Ollama is not running", ensure Ollama service is started:
```bash
ollama serve
```

### Model Not Found
If MiniMax model is not available:
```bash
ollama pull minimax-m2.7:cloud
```

### Port Conflicts
If port 11434 is in use, update the base_url in `.goose/config.yaml`

## Usage Examples

Just ask Goose naturally:
- "Create a PowerPoint about AI trends"
- "Build a landing page with animations"
- "Search for latest React best practices"
- "Help me create a Flutter app"
- "Generate a Word document"
- "Analyze this image"

## Key Paths

| What | Where |
|------|-------|
| Python venv | `~/.local/share/goose-ollama-minimax/venv` |
| Goose CLI | `~/.local/bin/goose` |
| Goose config | `~/.config/goose/config.yaml` |
| Skills | `.agents/skills/` (31 skills) |
| Scripts | `scripts/setup/`, `scripts/run/`, `scripts/utils/` |