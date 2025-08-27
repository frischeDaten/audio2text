# Audio2Text Installation Guide

🎙️ **Complete installation guide for Audio2Text on Apple Silicon Macs**

## Quick Installation

### For Fresh macOS Systems

If you're starting with a clean macOS system, use the automated installer:

```bash
# Download and run the installer
bash install.sh
```

The installer will:
- ✅ Install Homebrew (macOS package manager)
- ✅ Install Python 3.11 and dependencies  
- ✅ Create isolated virtual environment
- ✅ Install MLX, Whisper, and all required packages
- ✅ Set up command-line and desktop interfaces
- ✅ Configure HuggingFace token setup
- ✅ Download initial AI models
- ✅ Create uninstaller for easy removal

**Installation time:** 10-20 minutes (depending on internet speed)

### System Requirements

Before installation, ensure your system meets these requirements:

| Requirement | Details |
|-------------|---------|
| **macOS Version** | macOS 11.0 (Big Sur) or later |
| **Hardware** | Apple Silicon Mac (M1, M2, M3, or newer) |
| **Free Space** | 8GB minimum (for models and dependencies) |
| **Internet** | Required for downloading packages and AI models |
| **Admin Rights** | Required for Homebrew installation |

### Pre-Installation Steps

1. **Update macOS** (recommended)
   ```bash
   # Check current version
   sw_vers -productVersion
   
   # Update if needed via System Preferences > Software Update
   ```

2. **Free up disk space** (if needed)
   - Check available space: `df -h ~/`
   - Need at least 8GB free in your home directory

3. **Ensure stable internet connection**
   - Installation downloads ~2-4GB of packages and models

## Installation Process

### Step 1: Download Audio2Text

```bash
# Option 1: Download via curl (if available online)
curl -L -o audio2text-installer.zip https://github.com/your-repo/audio2text/releases/latest/download/installer.zip
unzip audio2text-installer.zip
cd Audio2Text-Distribution

# Option 2: If you have the distribution folder locally
cd /path/to/Audio2Text-Distribution
```

### Step 2: Run the Installer

```bash
# Make installer executable
chmod +x install.sh

# Run installation (will prompt for password when needed)
./install.sh
```

### Step 3: Follow Installation Prompts

The installer will guide you through:

1. **System verification** - Checks macOS version and hardware
2. **Homebrew installation** - Installs macOS package manager (if needed)
3. **Python setup** - Installs Python 3.11 and creates virtual environment
4. **Dependency installation** - Installs MLX, Whisper, audio libraries
5. **HuggingFace token setup** - Configure access to AI models
6. **Model downloading** - Download initial Whisper models
7. **Interface setup** - Create command-line tool and desktop app

### Step 4: HuggingFace Token Configuration

Audio2Text requires a free HuggingFace account to download AI models:

1. **Create account** at https://huggingface.co/join
2. **Get token** at https://huggingface.co/settings/tokens
   - Click "New Token"
   - Choose "Read" access level
   - Copy the generated token
3. **Configure during installation** or manually edit:
   ```bash
   nano ~/Applications/Audio2Text/config/env
   # Add: HF_TOKEN=your_token_here
   ```

## Verification

### Test Installation

After installation, verify everything works:

```bash
# Test command line interface
audio2text --help

# Run comprehensive system test
~/Applications/Audio2Text/test/test_installation.py

# Test with sample audio (create a short recording or use test file)
audio2text /path/to/test/audio.wav
```

### Expected Output Structure

After successful installation:

```
~/Applications/Audio2Text/
├── bin/                    # Command-line executables
│   └── audio2text         # Main CLI tool
├── venv/                  # Python virtual environment  
├── config/                # Configuration files
│   ├── env               # Environment variables (HF token)
│   └── settings.json     # App settings
├── output/               # Transcription results
├── logs/                 # Application logs  
├── models/               # Downloaded AI models
├── cache/                # Temporary cache
├── docs/                 # Documentation
├── test/                 # Test scripts
└── uninstall.sh          # Removal script
```

Desktop app at: `~/Applications/Audio2Text.app`

## Alternative Installation Methods

### Manual Installation

If the automated installer doesn't work, you can install manually:

#### Prerequisites

```bash
# Install Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install Python 3.11
brew install python@3.11

# Install FFmpeg
brew install ffmpeg
```

#### Python Environment

```bash
# Create project directory
mkdir -p ~/Applications/Audio2Text
cd ~/Applications/Audio2Text

# Create virtual environment
/opt/homebrew/bin/python3.11 -m venv venv
source venv/bin/activate

# Upgrade pip
pip install --upgrade pip
```

#### Core Dependencies

```bash
# Install with specific compatible versions
pip install numpy==2.2.6
pip install numba==0.61.2
pip install mlx>=0.20.0
pip install mlx-whisper>=0.4.0

# Audio processing
pip install librosa>=0.10.0
pip install soundfile>=0.12.0

# ML libraries  
pip install transformers>=4.35.0
pip install huggingface-hub>=0.17.0
pip install torch>=2.0.0 torchaudio>=2.0.0

# Speaker diarization (optional)
pip install pyannote.audio>=3.0.0
pip install speechbrain>=0.5.0

# WhisperX fallback (optional)
pip install whisperx>=3.1.0
```

#### Application Files

```bash
# Copy application files from distribution
cp -r /path/to/Audio2Text-Distribution/resources/* ~/Applications/Audio2Text/

# Create launcher script
# (Copy the launcher script content from install.sh)
```

### Development Installation

For development or customization:

```bash
# Clone or copy source
git clone https://github.com/your-repo/audio2text.git
cd audio2text

# Create development environment  
python3.11 -m venv venv
source venv/bin/activate

# Install in development mode
pip install -e .

# Install additional dev dependencies
pip install pytest black isort mypy
```

## Troubleshooting

### Common Installation Issues

**"Command not found: brew"**
```bash
# Homebrew not in PATH - add to shell profile
echo 'export PATH="/opt/homebrew/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
```

**"Python 3.11 not found"**
```bash
# Verify Homebrew Python installation
brew list python@3.11
/opt/homebrew/bin/python3.11 --version
```

**"MLX installation failed"**
```bash
# Ensure Apple Silicon Mac
uname -m  # Should show: arm64

# Verify macOS version
sw_vers -productVersion  # Should be 11.0+

# Clear pip cache and retry
pip cache purge
pip install mlx mlx-whisper
```

**"Permission denied during installation"**
```bash
# Make sure you have admin rights
sudo -v

# Fix Homebrew permissions
sudo chown -R $(whoami) /opt/homebrew/
```

**"Failed to download models"**
```bash
# Check HuggingFace token
cat ~/Applications/Audio2Text/config/env

# Test token manually
export HF_TOKEN=your_token_here
python -c "from huggingface_hub import whoami; print(whoami())"

# Clear cache and retry
rm -rf ~/.cache/huggingface
```

**"Audio2text command not found"**
```bash
# Add to PATH manually
echo 'export PATH="$HOME/Applications/Audio2Text/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc

# Or run directly
~/Applications/Audio2Text/bin/audio2text --help
```

### System Diagnostics

Run the comprehensive test to identify issues:

```bash
# Full system test
python ~/Applications/Audio2Text/test/test_installation.py

# Check logs
tail -f ~/Applications/Audio2Text/logs/audio2text_*.log

# Test individual components
python -c "import mlx.core as mx; print('MLX OK')"
python -c "import mlx_whisper; print('MLX Whisper OK')"
```

### Performance Issues

**Slow transcription:**
- Use smaller model: `--model base` instead of `large-v3`
- Close other applications to free RAM
- Ensure sufficient disk space for temporary files

**High memory usage:**
- Use `medium` or `small` model
- Process shorter audio segments
- Restart application between large files

### Getting Support

If you continue having issues:

1. **Check installation logs:** `~/Applications/Audio2Text/logs/`
2. **Run diagnostics:** `~/Applications/Audio2Text/test/test_installation.py`
3. **Verify requirements:** Ensure Apple Silicon Mac with macOS 11.0+
4. **Clean reinstall:** Use uninstaller then run installer again
5. **Report issues:** Include log files and system information

## Uninstallation  

To completely remove Audio2Text:

```bash
# Run the uninstaller
~/Applications/Audio2Text/uninstall.sh

# Manual cleanup (if needed)
rm -rf ~/Applications/Audio2Text/
rm -rf ~/Applications/Audio2Text.app
# Remove from shell profile if added to PATH
```

---

🎙️ **Ready to start transcribing!** Once installed, check out the [Usage Guide](README.md) for how to use Audio2Text.
