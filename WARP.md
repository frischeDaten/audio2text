# WARP.md

This file provides guidance to WARP (warp.dev) when working with code in this repository.

## Project Overview

Audio2Text is a high-performance audio transcription system for Apple Silicon Macs using MLX Whisper. The project provides both command-line and GUI interfaces for converting audio files to text with speaker diarization capabilities.

## Architecture

### Core Components

- **`resources/transcribe_standalone.py`** - Main transcription engine with MLX Whisper integration
- **Installation System** - Multiple installer scripts for different deployment scenarios
- **Configuration Management** - JSON settings and environment variable configuration
- **Multi-Engine Support** - Primary MLX Whisper with WhisperX fallback

### Key Technologies
- **MLX Framework** - Apple's ML framework for Apple Silicon optimization
- **MLX Whisper** - Apple Silicon optimized Whisper implementation
- **pyannote.audio** - Speaker diarization
- **Python 3.11** - Runtime environment with virtual environment isolation

### Installation Architecture
The project uses a multi-layered installation approach:
1. **Production Installer** (`install.sh`) - Full installation from scratch
2. **Test Installer** (`install-test.sh`) - Safe installation for development environments
3. **PKG Installer** (`installer/postinstall`) - macOS package installation
4. **Uninstaller** (`uninstall.sh`) - Complete removal utility

### Directory Structure
- Installation target: `~/Applications/Audio2Text/`
- Virtual environment: `~/Applications/Audio2Text/venv/`
- Models cache: `~/Applications/Audio2Text/models/`
- Output directory: `~/Applications/Audio2Text/output/`
- Configuration: `~/Applications/Audio2Text/config/`

## Common Development Tasks

### Installation and Setup

```bash
# Production installation (fresh systems)
./install.sh

# Safe test installation (development systems)
./install-test.sh

# Test installation validation
python resources/test/test_installation.py
```

### Configuration Management

```bash
# Configure HuggingFace token
nano ~/Applications/Audio2Text/config/env
# Add: HF_TOKEN=your_token_here

# View configuration
cat resources/config/settings.json
```

### Running Transcription

```bash
# Basic transcription
audio2text input.wav

# With speaker diarization
audio2text --speakers --format json input.mp3

# Specify model and language
audio2text --model large-v3 --language de input.m4a

# Test standalone script directly
python resources/transcribe_standalone.py --help
```

### Testing and Validation

```bash
# Run comprehensive installation test
python resources/test/test_installation.py

# Check system compatibility
# Test runs: system requirements, Python environment, dependencies, audio processing, model access

# View logs
tail -f ~/Applications/Audio2Text/logs/audio2text_*.log
```

### Development Environment

```bash
# Create development virtual environment
python3.11 -m venv dev-venv
source dev-venv/bin/activate

# Install dependencies for development
pip install numpy==2.2.6 numba==0.61.2
pip install mlx>=0.20.0 mlx-whisper>=0.4.0
pip install librosa>=0.10.0 soundfile>=0.12.0
pip install transformers>=4.35.0 huggingface-hub>=0.17.0
```

### Uninstallation

```bash
# Complete removal
./uninstall.sh
# Or: ~/Applications/Audio2Text/uninstall.sh

# Manual cleanup if needed
rm -rf ~/Applications/Audio2Text/
rm -rf ~/Applications/Audio2Text.app
```

## Key Implementation Details

### MLX Integration
- Primary transcription engine uses MLX for Apple Silicon optimization
- Automatic fallback to WhisperX for compatibility
- NPZ loading compatibility fix applied via `npz_loading_fix.py`

### Model Management
- Models downloaded from HuggingFace Hub
- Requires HF_TOKEN for access to some models
- Models cached in `~/Applications/Audio2Text/models/`
- Supports multiple Whisper model sizes: tiny, base, small, medium, large-v3-turbo

### Audio Processing Pipeline
1. Audio preprocessing with librosa/soundfile
2. Format conversion via FFmpeg
3. MLX Whisper transcription
4. Optional speaker diarization with pyannote.audio
5. Output formatting (text, JSON, SRT)

### Error Handling and Logging
- Comprehensive logging to `~/Applications/Audio2Text/logs/`
- Graceful fallback between transcription engines
- System compatibility checks before installation
- Installation validation with test suite

### Configuration System
- JSON-based settings in `resources/config/settings.json`
- Environment variables via `config/env` file
- Template configuration in `resources/config/env.template`
- Performance tuning parameters for different hardware configs

## System Requirements

- macOS 11.0+ (Big Sur or later)
- Apple Silicon Mac (M1/M2/M3)
- Python 3.11
- 8GB free disk space
- Internet connection for model downloads

## Troubleshooting Commands

```bash
# Check system compatibility
uname -m  # Should show: arm64
sw_vers -productVersion  # Should be 11.0+

# Verify MLX installation
python -c "import mlx.core as mx; print('MLX OK')"
python -c "import mlx_whisper; print('MLX Whisper OK')"

# Test HuggingFace access
python -c "from huggingface_hub import whoami; print(whoami())"

# Check audio file support
python -c "import soundfile as sf; print('SoundFile OK')"
python -c "import librosa; print('Librosa OK')"
```
