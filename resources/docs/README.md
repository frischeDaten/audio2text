# Audio2Text - MLX Whisper Transcription

🎙️ **High-performance audio transcription for Apple Silicon Macs**

Audio2Text is a powerful transcription system that leverages Apple's MLX framework for incredibly fast and accurate speech-to-text conversion on Apple Silicon Macs (M1, M2, M3).

## Features

✅ **Optimized for Apple Silicon** - Uses MLX for native Apple Silicon acceleration  
✅ **Multiple AI Models** - MLX Whisper (primary) with WhisperX fallback  
✅ **Speaker Diarization** - Identify and separate different speakers  
✅ **Multiple Languages** - Auto-detect or specify language  
✅ **Flexible Output** - Text, JSON, SRT subtitle formats  
✅ **Audio Format Support** - WAV, MP3, M4A, FLAC, MP4, and more  
✅ **Batch Processing** - Process multiple files efficiently  
✅ **Command Line + GUI** - Both terminal and desktop app interfaces  

## System Requirements

- **macOS 11.0+** (Big Sur or later)
- **Apple Silicon Mac** (M1, M2, M3, or newer)
- **8GB free disk space** (for models and dependencies)
- **Internet connection** (for initial setup and model downloads)

## Quick Start

### Command Line Usage

```bash
# Basic transcription
audio2text recording.wav

# Specify language and model
audio2text --model large-v3 --language de interview.mp3

# Enable speaker identification
audio2text --speakers --format srt meeting.m4a

# Custom output directory
audio2text --output-dir ~/Documents presentation.wav
```

### Desktop App Usage

1. Double-click the **Audio2Text** app in your Applications folder
2. Drag and drop audio files onto the app
3. Transcriptions will be saved to `~/Applications/Audio2Text/output/`

## Available Options

### Models
- `tiny` - Fastest, least accurate (39MB)
- `base` - Fast, basic accuracy (74MB)  
- `small` - Good balance (244MB)
- `medium` - Better accuracy (769MB)
- `large-v2` - High accuracy (1550MB)
- `large-v3` - Best accuracy (1550MB) **[Default]**

### Languages
Auto-detection is enabled by default. Specify manually for better performance:
- `en` - English
- `de` - German  
- `fr` - French
- `es` - Spanish
- `it` - Italian
- `pt` - Portuguese
- `ru` - Russian
- `ja` - Japanese
- `zh` - Chinese
- [Many more languages supported]

### Output Formats
- `txt` - Plain text **[Default]**
- `json` - Detailed JSON with timestamps and metadata
- `srt` - SRT subtitle format with timecodes

## Configuration

### HuggingFace Token Setup

Audio2Text requires a free HuggingFace token to download AI models:

1. Go to https://huggingface.co/join and create a free account
2. Visit https://huggingface.co/settings/tokens
3. Create a new token (read access is sufficient)
4. Add your token to the config file:

```bash
# Edit the config file
nano ~/Applications/Audio2Text/config/env

# Add your token
HF_TOKEN=your_token_here
```

### Advanced Settings

The configuration file is located at:
`~/Applications/Audio2Text/config/settings.json`

You can modify:
- Model preferences
- Audio processing settings
- Output formatting
- Performance parameters
- Cache directories

## File Locations

| Directory | Purpose |
|-----------|---------|
| `~/Applications/Audio2Text/` | Main installation directory |
| `~/Applications/Audio2Text/bin/` | Executable scripts |
| `~/Applications/Audio2Text/output/` | Transcription results |
| `~/Applications/Audio2Text/logs/` | System logs |
| `~/Applications/Audio2Text/models/` | Downloaded AI models |
| `~/Applications/Audio2Text/cache/` | Temporary cache files |
| `~/Applications/Audio2Text/config/` | Configuration files |

## Troubleshooting

### Common Issues

**"No transcription engines available"**
- Ensure MLX Whisper installed correctly
- Check Apple Silicon compatibility
- Verify Python virtual environment is active

**"Failed to download models"**
- Check internet connection
- Verify HuggingFace token is configured
- Ensure sufficient disk space

**"Audio file format not supported"**
- Install FFmpeg: `brew install ffmpeg`
- Convert to WAV/MP3 format first
- Check file isn't corrupted

**"MLX not available"**
- Ensure you're on Apple Silicon Mac
- Check macOS version (11.0+ required)
- Reinstall with: `pip install mlx mlx-whisper`

### Performance Issues

**Slow transcription:**
- Use smaller model (e.g., `base` instead of `large-v3`)
- Disable speaker diarization if not needed
- Close other resource-intensive applications
- Ensure sufficient RAM available

**High memory usage:**
- Use `small` or `medium` model instead of `large-v3`
- Process shorter audio segments
- Restart the application periodically

### Getting Help

1. **Check logs:** `~/Applications/Audio2Text/logs/`
2. **Verbose mode:** Add `--verbose` to command line
3. **System test:** Run diagnostic mode
4. **Reinstall:** Use the uninstaller and run installer again

## Examples

### Basic Transcription
```bash
# Transcribe a podcast episode
audio2text podcast_episode.mp3

# Output: podcast_episode_transcript.txt
```

### Meeting Transcription with Speakers
```bash
# Business meeting with speaker identification
audio2text --speakers --format srt --language en business_meeting.wav

# Output: business_meeting_transcript.srt with speaker labels
```

### Multi-language Content
```bash
# German interview
audio2text --language de --model large-v3 interview_deutsch.m4a

# Auto-detect language
audio2text --format json multilingual_content.wav
```

### Batch Processing
```bash
# Process multiple files
for file in *.wav; do
    audio2text --speakers --format json "$file"
done
```

## Technical Details

### Architecture
- **Primary Engine:** MLX Whisper (Apple Silicon optimized)
- **Fallback Engine:** WhisperX (CPU-based)
- **Speaker Diarization:** pyannote.audio
- **Audio Processing:** librosa + FFmpeg
- **Language:** Python 3.11
- **Framework:** MLX (Apple's machine learning framework)

### Performance Benchmarks
On Apple M2 Pro with large-v3 model:
- **1 hour audio:** ~3-5 minutes transcription time
- **Memory usage:** ~4-6GB RAM
- **Accuracy:** >95% for clear English audio
- **Languages:** 99+ languages supported

### Model Details
Models are downloaded from HuggingFace and cached locally:
- **MLX-optimized Whisper models** for best Apple Silicon performance
- **Quantized models** for reduced memory usage
- **Automatic caching** to avoid re-downloads

## License and Credits

This project builds upon several open-source technologies:
- **OpenAI Whisper** - Speech recognition model
- **MLX** - Apple's machine learning framework  
- **MLX Whisper** - Apple Silicon optimized Whisper
- **pyannote.audio** - Speaker diarization
- **librosa** - Audio processing

---

🎙️ **Happy transcribing!** For support and updates, visit the project repository.
