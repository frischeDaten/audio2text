#!/bin/bash

# Audio2Text Installer
# Installs MLX Whisper transcription system on macOS from scratch
# 
# This installer works on fresh macOS systems (macOS 11.0+ with Apple Silicon)
# and sets up everything needed for audio transcription with MLX Whisper.

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
APP_NAME="Audio2Text"
INSTALL_DIR="$HOME/Applications/Audio2Text"
VENV_DIR="$INSTALL_DIR/venv"
MODELS_DIR="$INSTALL_DIR/models"
PYTHON_VERSION="3.11"

# Logging
LOG_FILE="$HOME/Audio2Text-install.log"

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

print_header() {
    echo -e "${BLUE}"
    echo "╔════════════════════════════════════════════════════════════════════════╗"
    echo "║                          🎙️  Audio2Text Installer                      ║"
    echo "║                                                                        ║"
    echo "║           MLX Whisper Audio Transcription for Apple Silicon           ║"
    echo "║                                                                        ║"
    echo "╚════════════════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo
}

print_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
    log "STEP: $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
    log "SUCCESS: $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
    log "WARNING: $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
    log "ERROR: $1"
}

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
    log "INFO: $1"
}

check_system() {
    print_step "Checking system requirements..."
    
    # Check macOS version
    macos_version=$(sw_vers -productVersion)
    macos_major=$(echo "$macos_version" | cut -d. -f1)
    macos_minor=$(echo "$macos_version" | cut -d. -f2)
    
    if [[ "$macos_major" -lt 11 ]]; then
        print_error "macOS 11.0 or later required. Found: $macos_version"
        exit 1
    fi
    print_success "macOS version: $macos_version ✓"
    
    # Check for Apple Silicon
    if [[ "$(uname -m)" != "arm64" ]]; then
        print_error "Apple Silicon (M1/M2/M3) required. Found: $(uname -m)"
        print_error "This version is optimized for Apple Silicon Macs only."
        exit 1
    fi
    print_success "Apple Silicon detected ✓"
    
    # Check available space (need ~8GB)
    available_space=$(df -g "$HOME" | awk 'NR==2 {print $4}')
    if [[ "$available_space" -lt 8 ]]; then
        print_warning "Low disk space. Need ~8GB, available: ${available_space}GB"
        echo "Continue anyway? (y/n)"
        read -r response
        if [[ ! "$response" =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
    print_success "Sufficient disk space ✓"
    
    # Check internet connection
    if ! ping -c 1 google.com &> /dev/null; then
        print_error "Internet connection required for installation"
        exit 1
    fi
    print_success "Internet connection ✓"
}

install_homebrew() {
    print_step "Installing Homebrew (macOS package manager)..."
    
    if command -v brew &> /dev/null; then
        print_success "Homebrew already installed ✓"
        return
    fi
    
    print_info "Downloading and installing Homebrew..."
    print_info "You may be prompted for your password and to install Xcode Command Line Tools"
    
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    
    # Add Homebrew to PATH for this session
    if [[ -f "/opt/homebrew/bin/brew" ]]; then
        export PATH="/opt/homebrew/bin:$PATH"
        print_success "Homebrew installed successfully ✓"
    else
        print_error "Homebrew installation failed"
        exit 1
    fi
}

install_python() {
    print_step "Installing Python $PYTHON_VERSION..."
    
    # Update Homebrew
    print_info "Updating Homebrew..."
    brew update
    
    # Install Python
    if ! brew list python@$PYTHON_VERSION &> /dev/null; then
        print_info "Installing Python $PYTHON_VERSION via Homebrew..."
        brew install python@$PYTHON_VERSION
    else
        print_success "Python $PYTHON_VERSION already installed ✓"
    fi
    
    # Verify Python installation
    PYTHON_PATH="/opt/homebrew/bin/python$PYTHON_VERSION"
    if [[ ! -f "$PYTHON_PATH" ]]; then
        print_error "Python installation failed"
        exit 1
    fi
    
    python_version=$($PYTHON_PATH --version 2>&1)
    print_success "Python installed: $python_version ✓"
}

install_ffmpeg() {
    print_step "Installing FFmpeg (for audio processing)..."
    
    if ! brew list ffmpeg &> /dev/null; then
        print_info "Installing FFmpeg via Homebrew..."
        brew install ffmpeg
    else
        print_success "FFmpeg already installed ✓"
    fi
    
    ffmpeg_version=$(ffmpeg -version | head -n1)
    print_success "FFmpeg installed: $ffmpeg_version ✓"
}

create_app_structure() {
    print_step "Creating application directory structure..."
    
    # Create directories
    mkdir -p "$INSTALL_DIR"
    mkdir -p "$VENV_DIR" 
    mkdir -p "$MODELS_DIR"
    mkdir -p "$INSTALL_DIR/bin"
    mkdir -p "$INSTALL_DIR/logs"
    mkdir -p "$INSTALL_DIR/output"
    
    print_success "Directory structure created ✓"
    print_info "Installation directory: $INSTALL_DIR"
}

create_virtual_environment() {
    print_step "Creating Python virtual environment..."
    
    PYTHON_PATH="/opt/homebrew/bin/python$PYTHON_VERSION"
    
    # Create virtual environment
    "$PYTHON_PATH" -m venv "$VENV_DIR"
    
    # Activate virtual environment
    source "$VENV_DIR/bin/activate"
    
    # Upgrade pip
    pip install --upgrade pip
    
    print_success "Virtual environment created ✓"
}

install_python_dependencies() {
    print_step "Installing Python dependencies..."
    
    source "$VENV_DIR/bin/activate"
    
    # Install core dependencies with specific versions
    print_info "Installing NumPy 2.2.6 (required for MLX compatibility)..."
    pip install numpy==2.2.6
    
    print_info "Installing Numba 0.61.2 (compatible with NumPy 2.2.6)..."
    pip install numba==0.61.2
    
    print_info "Installing MLX and MLX Whisper..."
    pip install 'mlx>=0.20.0'
    pip install 'mlx-whisper>=0.4.0'
    
    print_info "Installing audio processing libraries..."
    pip install 'librosa>=0.10.0'
    pip install 'soundfile>=0.12.0'
    
    print_info "Installing PyTorch (CPU version for compatibility)..."
    pip install 'torch>=2.0.0' 'torchaudio>=2.0.0'
    
    print_info "Installing speaker diarization..."
    pip install 'pyannote.audio>=3.0.0'
    pip install 'speechbrain>=0.5.0'
    
    print_info "Installing additional ML libraries..."
    pip install 'transformers>=4.35.0'
    pip install 'huggingface-hub>=0.17.0'
    pip install 'requests>=2.31.0'
    pip install 'pandas>=2.0.0'
    pip install 'scipy>=1.11.0'
    
    # Optional: WhisperX fallback
    print_info "Installing WhisperX (fallback transcription)..."
    pip install 'whisperx>=3.1.0' || print_warning "WhisperX installation failed (optional)"
    
    print_success "Python dependencies installed ✓"
}

copy_application_files() {
    print_step "Installing application files..."
    
    # Copy main application files from the installer bundle
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    RESOURCES_DIR="$SCRIPT_DIR/resources"
    
    if [[ -d "$RESOURCES_DIR" ]]; then
        # Copy all resource files
        cp -r "$RESOURCES_DIR"/* "$INSTALL_DIR/"
        
        # Only chmod bin files if they exist
        if [[ -d "$INSTALL_DIR/bin" ]] && [[ -n "$(ls -A "$INSTALL_DIR/bin" 2>/dev/null)" ]]; then
            chmod +x "$INSTALL_DIR/bin"/*
        fi
        
        print_success "Application files installed ✓"
    else
        print_warning "No application files found in installer"
    fi
}

create_launcher_script() {
    print_step "Creating launcher script..."
    
    cat > "$INSTALL_DIR/bin/audio2text" << 'EOF'
#!/bin/bash

# Audio2Text Launcher Script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_DIR="$(dirname "$SCRIPT_DIR")"
VENV_DIR="$APP_DIR/venv"

# Activate virtual environment
source "$VENV_DIR/bin/activate"

# Add current directory to Python path
export PYTHONPATH="$APP_DIR:$PYTHONPATH"

# Set up environment
export HF_HOME="$APP_DIR/cache"
export TRANSFORMERS_CACHE="$APP_DIR/cache"
export MLX_CACHE_DIR="$APP_DIR/cache"

# Create cache directory
mkdir -p "$APP_DIR/cache"

# Run the application
if [[ -f "$APP_DIR/transcribe_standalone.py" ]]; then
    cd "$APP_DIR"
    python transcribe_standalone.py "$@"
else
    echo "Error: Audio2Text application files not found"
    echo "Please reinstall Audio2Text"
    exit 1
fi
EOF
    
    chmod +x "$INSTALL_DIR/bin/audio2text"
    print_success "Launcher script created ✓"
}

create_desktop_app() {
    print_step "Creating Desktop Application..."
    
    APP_BUNDLE="$HOME/Applications/Audio2Text.app"
    mkdir -p "$APP_BUNDLE/Contents/MacOS"
    mkdir -p "$APP_BUNDLE/Contents/Resources"
    
    # Create app launcher
    cat > "$APP_BUNDLE/Contents/MacOS/Audio2Text" << 'EOF'
#!/bin/bash
INSTALL_DIR="$HOME/Applications/Audio2Text"
"$INSTALL_DIR/bin/audio2text" "$@"
EOF
    chmod +x "$APP_BUNDLE/Contents/MacOS/Audio2Text"
    
    # Create Info.plist
    cat > "$APP_BUNDLE/Contents/Info.plist" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>Audio2Text</string>
    <key>CFBundleIdentifier</key>
    <string>com.audio2text.transcriber</string>
    <key>CFBundleName</key>
    <string>Audio2Text</string>
    <key>CFBundleVersion</key>
    <string>1.0.0</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>LSMinimumSystemVersion</key>
    <string>11.0</string>
    <key>LSRequiresNativeExecution</key>
    <true/>
    <key>CFBundleDocumentTypes</key>
    <array>
        <dict>
            <key>CFBundleTypeName</key>
            <string>Audio Files</string>
            <key>CFBundleTypeRole</key>
            <string>Viewer</string>
            <key>LSItemContentTypes</key>
            <array>
                <string>public.audio</string>
                <string>public.mp3</string>
                <string>public.mpeg-4-audio</string>
                <string>com.microsoft.waveform-audio</string>
            </array>
            <key>LSHandlerRank</key>
            <string>Default</string>
        </dict>
    </array>
    <key>NSMicrophoneUsageDescription</key>
    <string>This app processes audio files for transcription.</string>
</dict>
</plist>
EOF
    
    print_success "Desktop application created ✓"
}

setup_hf_token() {
    print_step "Setting up Hugging Face token..."
    
    echo
    print_info "Audio2Text requires a Hugging Face token to download AI models."
    print_info "This is free and takes 2 minutes to set up:"
    print_info "1. Go to https://huggingface.co/join"
    print_info "2. Create a free account"
    print_info "3. Go to https://huggingface.co/settings/tokens"
    print_info "4. Create a new token (read access is sufficient)"
    echo
    
    echo "Do you have a Hugging Face token? (y/n)"
    read -r has_token
    
    if [[ "$has_token" =~ ^[Yy]$ ]]; then
        echo "Please paste your Hugging Face token:"
        read -r -s hf_token
        
        # Save token to config file
        mkdir -p "$INSTALL_DIR/config"
        echo "HF_TOKEN=$hf_token" > "$INSTALL_DIR/config/env"
        chmod 600 "$INSTALL_DIR/config/env"
        
        print_success "Hugging Face token configured ✓"
    else
        print_warning "Skipping token setup. You can set it up later."
        print_info "To set up later, edit: $INSTALL_DIR/config/env"
    fi
}

download_initial_models() {
    print_step "Downloading initial AI models..."
    
    source "$VENV_DIR/bin/activate"
    
    # Load HF token if available
    if [[ -f "$INSTALL_DIR/config/env" ]]; then
        source "$INSTALL_DIR/config/env"
        export HF_TOKEN="$HF_TOKEN"
    fi
    
    if [[ -z "$HF_TOKEN" ]]; then
        print_warning "No Hugging Face token configured"
        print_info "Models will be downloaded on first use"
        return
    fi
    
    print_info "Downloading German Whisper model (this may take a while)..."
    
    # Create a simple model download script
    cat > "$INSTALL_DIR/download_models.py" << 'EOF'
import os
from huggingface_hub import snapshot_download

def download_model(repo_id, local_dir):
    try:
        print(f"Downloading {repo_id}...")
        snapshot_download(
            repo_id=repo_id,
            local_dir=local_dir,
            token=os.getenv('HF_TOKEN'),
            ignore_patterns=["*.md", "*.txt", ".gitattributes"]
        )
        print(f"✓ Downloaded {repo_id}")
        return True
    except Exception as e:
        print(f"✗ Failed to download {repo_id}: {e}")
        return False

models_dir = os.path.expanduser("~/Applications/Audio2Text/models")
os.makedirs(models_dir, exist_ok=True)

# Download key models
success = True
success &= download_model("mlx-community/whisper-large-v3-turbo", f"{models_dir}/whisper")
success &= download_model("pyannote/speaker-diarization-3.1", f"{models_dir}/diarization") 

if success:
    print("\n✅ All models downloaded successfully!")
else:
    print("\n⚠️  Some models failed to download. They will be downloaded on first use.")
EOF
    
    cd "$INSTALL_DIR"
    python download_models.py
    
    print_success "Model download completed ✓"
}

create_uninstaller() {
    print_step "Creating uninstaller..."
    
    cat > "$INSTALL_DIR/uninstall.sh" << 'EOF'
#!/bin/bash

echo "🗑️  Audio2Text Uninstaller"
echo
echo "This will completely remove Audio2Text from your system."
echo "Are you sure? (y/n)"
read -r confirm

if [[ "$confirm" =~ ^[Yy]$ ]]; then
    echo "Removing Audio2Text..."
    
    # Remove installation directory
    rm -rf "$HOME/Applications/Audio2Text"
    
    # Remove desktop app
    rm -rf "$HOME/Applications/Audio2Text.app"
    
    # Remove from system PATH if added
    # (This would need to be customized based on shell)
    
    echo "✅ Audio2Text has been completely removed."
    echo "You may also want to remove Homebrew if it was installed only for Audio2Text:"
    echo "/bin/bash -c \"$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/uninstall.sh)\""
else
    echo "Uninstall cancelled."
fi
EOF
    
    chmod +x "$INSTALL_DIR/uninstall.sh"
    print_success "Uninstaller created ✓"
}

add_to_path() {
    print_step "Adding Audio2Text to system PATH..."
    
    SHELL_RC=""
    if [[ "$SHELL" == *"zsh"* ]]; then
        SHELL_RC="$HOME/.zshrc"
    elif [[ "$SHELL" == *"bash"* ]]; then
        SHELL_RC="$HOME/.bash_profile"
    fi
    
    if [[ -n "$SHELL_RC" ]]; then
        if ! grep -q "Audio2Text/bin" "$SHELL_RC" 2>/dev/null; then
            echo "" >> "$SHELL_RC"
            echo "# Audio2Text" >> "$SHELL_RC"
            echo "export PATH=\"\$HOME/Applications/Audio2Text/bin:\$PATH\"" >> "$SHELL_RC"
            print_success "Added to PATH in $SHELL_RC ✓"
        else
            print_success "Already in PATH ✓"
        fi
    fi
}

run_initial_test() {
    print_step "Running initial system test..."
    
    source "$VENV_DIR/bin/activate"
    
    # Load environment
    if [[ -f "$INSTALL_DIR/config/env" ]]; then
        source "$INSTALL_DIR/config/env"
    fi
    
    cd "$INSTALL_DIR"
    
    # Test Python imports
    python -c "
import sys
print('Python version:', sys.version)
try:
    import numpy as np
    print('NumPy version:', np.__version__)
    import numba
    print('Numba version:', numba.__version__)
    import mlx.core as mx
    print('MLX core: OK')
    test_array = mx.array([1, 2, 3])
    print('MLX test array:', test_array)
    import mlx_whisper
    print('MLX Whisper: OK')
    print('✅ All core dependencies working!')
except Exception as e:
    print('❌ Error:', e)
    sys.exit(1)
" || {
        print_error "System test failed"
        exit 1
    }
    
    print_success "System test passed ✓"
}

print_completion_message() {
    echo
    echo -e "${GREEN}"
    echo "╔════════════════════════════════════════════════════════════════════════╗"
    echo "║                    🎉 Installation Complete! 🎉                       ║"
    echo "╚════════════════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    
    print_success "Audio2Text has been successfully installed!"
    echo
    print_info "📍 Installation location: $INSTALL_DIR"
    print_info "🖥️  Desktop app: ~/Applications/Audio2Text.app"
    print_info "📋 Command line: audio2text [audio-file]"
    print_info "📊 Output folder: $INSTALL_DIR/output"
    print_info "📝 Logs: $INSTALL_DIR/logs"
    
    echo
    print_info "🚀 To get started:"
    echo "   1. Restart your terminal (to pick up PATH changes)"
    echo "   2. Run: audio2text /path/to/your/audio/file.wav"
    echo "   3. Or drag an audio file onto the Audio2Text app"
    
    echo
    print_info "📚 Documentation: $INSTALL_DIR/docs/"
    print_info "🗑️  To uninstall: $INSTALL_DIR/uninstall.sh"
    
    if [[ -z "$HF_TOKEN" ]]; then
        echo
        print_warning "⚠️  Remember to set up your Hugging Face token:"
        print_info "   Edit: $INSTALL_DIR/config/env"
        print_info "   Add: HF_TOKEN=your_token_here"
    fi
    
    echo
    print_success "Happy transcribing! 🎙️"
}

# Main installation process
main() {
    print_header
    
    log "Starting Audio2Text installation"
    
    check_system
    install_homebrew
    install_python
    install_ffmpeg
    create_app_structure
    create_virtual_environment
    install_python_dependencies
    copy_application_files
    create_launcher_script
    create_desktop_app
    setup_hf_token
    download_initial_models
    create_uninstaller
    add_to_path
    run_initial_test
    
    print_completion_message
    
    log "Installation completed successfully"
}

# Run main installation
main "$@"
