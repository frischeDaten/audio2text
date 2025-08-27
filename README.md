# 🎙️ Audio2Text - MLX Whisper Distribution

**High-performance audio transcription for Apple Silicon Macs**

Transform your audio files into text with state-of-the-art AI, optimized for Apple's M1, M2, and M3 chips.

## Quick Start

### Automated Installation

For fresh macOS systems, use our automated installer:

```bash
# Run the installer
bash install.sh
```

This will handle everything automatically:
- ✅ System requirements check
- ✅ Install dependencies (Homebrew, Python, MLX)
- ✅ Set up virtual environment with exact package versions
- ✅ Create command-line tool and desktop app
- ✅ Download AI models

**Installation time:** 10-20 minutes

## What's Included

### 📁 Distribution Contents

```
Audio2Text-Distribution/
├── install.sh              # Automated installer script
├── README.md               # This file
├── docs/                   # Detailed documentation
│   └── INSTALLATION.md     # Step-by-step installation guide
└── resources/              # Application files
    ├── transcribe_standalone.py  # Main transcription script
    ├── npz_loading_fix.py         # NPZ compatibility fix
    ├── config/             # Configuration templates
    ├── docs/               # User documentation  
    └── test/               # Installation tests
```

### 🚀 Key Features

- **Apple Silicon Optimized** - Uses MLX framework for native M1/M2/M3 acceleration
- **Multiple AI Models** - MLX Whisper (primary) with WhisperX fallback
- **Speaker Diarization** - Identify and separate different speakers
- **Multi-language Support** - 99+ languages with auto-detection
- **Flexible Output** - Text, JSON, SRT subtitle formats
- **Audio Format Support** - WAV, MP3, M4A, FLAC, MP4, and more
- **Dual Interface** - Command-line tool and drag-drop desktop app

## System Requirements

| Requirement | Details |
|-------------|---------|
| **macOS** | 11.0+ (Big Sur or later) |
| **Hardware** | Apple Silicon Mac (M1/M2/M3) |
| **Storage** | 8GB free space |
| **Internet** | Required for setup and model downloads |

## Installation

### 🔧 Production Installation

For production use on fresh or existing macOS systems:

```bash
./install.sh
```

**Features:**
- ✅ Zero configuration required
- ✅ Installs all dependencies correctly
- ✅ Creates proper directory structure
- ✅ Works on fresh macOS systems
- ✅ Easy to uninstall
- ⏱️ Takes 10-20 minutes
- 💾 Downloads ~2-4GB of dependencies

### 🧪 Test Installation (For Developers)

For safe testing on development systems with existing Python/ML setups:

```bash
./install-test.sh
```

**Safe Testing Features:**
- 🔒 Completely isolated installation
- 🚫 No conflicts with existing Python packages
- 🚫 No system PATH modifications
- 📁 Installs to `~/Applications/Audio2Text-Test/`
- 🗑️ Easy removal: `rm -rf ~/Applications/Audio2Text-Test/`
- ⏱️ Faster setup with minimal dependencies

## Quick Usage

### Command Line

```bash
# Basic transcription
audio2text recording.wav

# German audio with speaker identification
audio2text --language de --speakers interview.mp3

# Output as SRT subtitles
audio2text --format srt --output-dir ~/Desktop video.m4a
```

### Desktop App

1. Double-click **Audio2Text.app** in Applications
2. Drag audio files onto the app window
3. Transcriptions save to `~/Applications/Audio2Text/output/`

## Configuration

### HuggingFace Token (Required)

To download AI models, you need a free HuggingFace token:

1. Create account at https://huggingface.co/join
2. Get token at https://huggingface.co/settings/tokens
3. Configure it:

```bash
# Edit config file
nano ~/Applications/Audio2Text/config/env

# Add your token
HF_TOKEN=your_token_here
```

## Troubleshooting

### Quick Diagnostics

```bash
# Test system compatibility
python ~/Applications/Audio2Text/test/test_installation.py

# Check logs
tail -f ~/Applications/Audio2Text/logs/audio2text_*.log

# Test core functionality
audio2text --help
```

### Common Issues

**"No transcription engines available"**
- Ensure you're on Apple Silicon Mac
- Check that MLX is properly installed
- Verify macOS version is 11.0+

**"Failed to download models"**
- Configure HuggingFace token
- Check internet connection
- Ensure sufficient disk space

**"Command not found: audio2text"**
- Restart terminal to pick up PATH changes
- Or run directly: `~/Applications/Audio2Text/bin/audio2text`

## Documentation

- 📖 **[Installation Guide](docs/INSTALLATION.md)** - Detailed setup instructions
- 📚 **[User Manual](resources/docs/README.md)** - Complete usage guide
- 🔧 **[Troubleshooting](docs/INSTALLATION.md#troubleshooting)** - Common issues and solutions

## Performance

### Benchmarks (M2 Pro)

| Model Size | Speed | Accuracy | Memory |
|------------|-------|----------|---------|
| `tiny` | 10x realtime | Good | 1GB |
| `base` | 8x realtime | Better | 1GB |
| `small` | 6x realtime | Very Good | 2GB |
| `medium` | 4x realtime | Excellent | 3GB |
| `large-v3` | 3x realtime | Best | 4GB |

*1 hour audio ≈ 3-6 minutes processing time*

## Uninstallation

```bash
# Run the uninstaller
~/Applications/Audio2Text/uninstall.sh

# Or manual cleanup
rm -rf ~/Applications/Audio2Text/
rm -rf ~/Applications/Audio2Text.app
```

## License & Legal

### Software License

Audio2Text is released under the **MIT License**. See [LICENSE](LICENSE) for full details.

### Third-Party Dependencies

This software uses several open-source components:

- **MLX Whisper** (Apache 2.0) - Apple's efficient Whisper implementation
- **WhisperX** (BSD-4-Clause) - Enhanced Whisper with alignment and diarization  
- **PyTorch** (BSD 3-Clause) - Machine learning framework
- **Transformers** (Apache 2.0) - Hugging Face transformer models
- **pyannote.audio** (MIT) - Speaker diarization toolkit
- **librosa** (ISC) - Audio analysis library

### AI Model Licenses

⚠️ **Important:** This software downloads AI models that have their own licenses:

- **OpenAI Whisper Models:** MIT License, free for commercial use
- **Pyannote Diarization Models:** May require Hugging Face agreement  
- **Other Hugging Face Models:** Individual licensing terms apply

**Users are responsible for ensuring compliance with all model licenses for their intended use case.**

### Commercial Use

The Audio2Text software itself is free for commercial use under MIT License. However:

1. ✅ Whisper models are MIT licensed (commercial OK)
2. ⚠️ Some speaker diarization models may have restrictions
3. ⚠️ Verify individual model licenses before commercial deployment

For commercial applications, we recommend:
- Reviewing all model licenses on [Hugging Face Hub](https://huggingface.co)
- Using only commercially-licensed models
- Consulting legal counsel for compliance

## Support

- **Installation Issues:** Check [INSTALLATION.md](docs/INSTALLATION.md)
- **Usage Questions:** See [User Manual](resources/docs/README.md)
- **Bug Reports:** Include logs from `~/Applications/Audio2Text/logs/`
- **License Questions:** See [LICENSE](LICENSE) file

---

🎙️ **Ready to start transcribing!**

Run the automated installer (`./install.sh`) for the best experience on Apple Silicon Macs.
