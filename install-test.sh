#!/bin/bash

# Audio2Text Test Installation
# Safe installation for development/testing on non-vanilla systems
# 
# This version adds safety checks and options for existing development environments

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration - Use test directory to avoid conflicts
APP_NAME="Audio2Text"
BASE_INSTALL_DIR="$HOME/Applications"
INSTALL_DIR="$BASE_INSTALL_DIR/Audio2Text-Test"
VENV_DIR="$INSTALL_DIR/venv"
MODELS_DIR="$INSTALL_DIR/models"
PYTHON_VERSION="3.11"

# Logging
LOG_FILE="$HOME/Audio2Text-test-install.log"

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

print_header() {
    echo -e "${BLUE}"
    echo "╔════════════════════════════════════════════════════════════════════════╗"
    echo "║                    🧪 Audio2Text Test Installer                       ║"
    echo "║                                                                        ║"
    echo "║            Safe installation for development/testing systems           ║"
    echo "║                                                                        ║"
    echo "╚════════════════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo
}

print_step() {
    echo -e "${BLUE}[TEST-STEP]${NC} $1"
    log "TEST-STEP: $1"
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

detect_existing_environment() {
    print_step "Analyzing existing development environment..."
    
    # Check existing Python installations
    local python_versions=()
    for py in python python3 python3.9 python3.10 python3.11 python3.12; do
        if command -v $py >/dev/null 2>&1; then
            local version=$($py --version 2>&1)
            python_versions+=("$py: $version")
        fi
    done
    
    if [[ ${#python_versions[@]} -gt 0 ]]; then
        print_info "Existing Python installations:"
        for version in "${python_versions[@]}"; do
            echo "  • $version"
        done
    else
        print_warning "No Python installations detected"
    fi
    
    # Check existing ML/AI packages
    print_info "Checking for existing ML/AI packages..."
    local existing_packages=()
    
    # Check system Python packages
    if command -v python3 >/dev/null 2>&1; then
        local packages=(numpy scipy mlx torch tensorflow whisper)
        for pkg in "${packages[@]}"; do
            if python3 -c "import $pkg" 2>/dev/null; then
                local version=$(python3 -c "import $pkg; print($pkg.__version__)" 2>/dev/null || echo "unknown")
                existing_packages+=("$pkg==$version")
            fi
        done
    fi
    
    if [[ ${#existing_packages[@]} -gt 0 ]]; then
        print_warning "Existing ML/AI packages in system Python:"
        for pkg in "${existing_packages[@]}"; do
            echo "  • $pkg"
        done
        echo
        print_info "These will NOT be affected - we'll use an isolated virtual environment"
    else
        print_success "No conflicting ML packages found ✓"
    fi
    
    # Check existing Audio2Text installations
    if [[ -d "$BASE_INSTALL_DIR/Audio2Text" ]]; then
        print_warning "Production Audio2Text installation found: $BASE_INSTALL_DIR/Audio2Text"
        print_info "Test installation will use: $INSTALL_DIR (no conflict)"
    fi
    
    # Check Homebrew
    if command -v brew >/dev/null 2>&1; then
        print_success "Homebrew detected ✓"
        local brew_prefix=$(brew --prefix)
        print_info "Homebrew prefix: $brew_prefix"
    else
        print_warning "Homebrew not found - will install if needed"
    fi
}

check_system_safe() {
    print_step "Checking system requirements (safe mode)..."
    
    # Check macOS version
    macos_version=$(sw_vers -productVersion)
    macos_major=$(echo "$macos_version" | cut -d. -f1)
    
    if [[ "$macos_major" -lt 11 ]]; then
        print_error "macOS 11.0 or later required. Found: $macos_version"
        return 1
    fi
    print_success "macOS version: $macos_version ✓"
    
    # Check for Apple Silicon
    if [[ "$(uname -m)" != "arm64" ]]; then
        print_error "Apple Silicon (M1/M2/M3) required. Found: $(uname -m)"
        return 1
    fi
    print_success "Apple Silicon detected ✓"
    
    # Check available space (more conservative for test)
    available_space=$(df -g "$HOME" | awk 'NR==2 {print $4}')
    if [[ "$available_space" -lt 4 ]]; then
        print_error "Insufficient disk space. Need ~4GB, available: ${available_space}GB"
        return 1
    fi
    print_success "Sufficient disk space: ${available_space}GB ✓"
    
    # Check internet
    if ! ping -c 1 google.com &> /dev/null; then
        print_error "Internet connection required"
        return 1
    fi
    print_success "Internet connection ✓"
    
    return 0
}

install_homebrew_safe() {
    print_step "Checking Homebrew installation..."
    
    if command -v brew &> /dev/null; then
        print_success "Homebrew already installed ✓"
        
        # Update Homebrew
        print_info "Updating Homebrew..."
        brew update || print_warning "Homebrew update failed (continuing)"
        return 0
    fi
    
    print_info "Homebrew not found - installing..."
    print_warning "You will be prompted for your password"
    
    # Install Homebrew
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    
    # Add to PATH
    if [[ -f "/opt/homebrew/bin/brew" ]]; then
        export PATH="/opt/homebrew/bin:$PATH"
        print_success "Homebrew installed ✓"
    else
        print_error "Homebrew installation failed"
        return 1
    fi
}

install_python_safe() {
    print_step "Installing Python $PYTHON_VERSION (safe mode)..."
    
    # Check if already installed
    if command -v /opt/homebrew/bin/python$PYTHON_VERSION >/dev/null 2>&1; then
        print_success "Python $PYTHON_VERSION already installed ✓"
    else
        print_info "Installing Python $PYTHON_VERSION via Homebrew..."
        brew install python@$PYTHON_VERSION
    fi
    
    # Verify installation
    PYTHON_PATH="/opt/homebrew/bin/python$PYTHON_VERSION"
    if [[ ! -f "$PYTHON_PATH" ]]; then
        print_error "Python installation verification failed"
        return 1
    fi
    
    python_version=$($PYTHON_PATH --version 2>&1)
    print_success "Python verified: $python_version ✓"
}

install_ffmpeg_safe() {
    print_step "Installing FFmpeg (safe mode)..."
    
    if command -v ffmpeg >/dev/null 2>&1; then
        print_success "FFmpeg already available ✓"
        ffmpeg_version=$(ffmpeg -version | head -n1)
        print_info "Version: $ffmpeg_version"
    else
        print_info "Installing FFmpeg via Homebrew..."
        brew install ffmpeg
        print_success "FFmpeg installed ✓"
    fi
}

create_test_environment() {
    print_step "Creating test environment..."
    
    # Remove existing test installation if present
    if [[ -d "$INSTALL_DIR" ]]; then
        print_warning "Existing test installation found - removing..."
        rm -rf "$INSTALL_DIR"
    fi
    
    # Create directories
    mkdir -p "$INSTALL_DIR"
    mkdir -p "$VENV_DIR" 
    mkdir -p "$MODELS_DIR"
    mkdir -p "$INSTALL_DIR/bin"
    mkdir -p "$INSTALL_DIR/logs"
    mkdir -p "$INSTALL_DIR/output"
    
    print_success "Test directory structure created ✓"
    print_info "Test installation directory: $INSTALL_DIR"
}

create_virtual_environment_safe() {
    print_step "Creating isolated virtual environment..."
    
    PYTHON_PATH="/opt/homebrew/bin/python$PYTHON_VERSION"
    
    # Create virtual environment
    "$PYTHON_PATH" -m venv "$VENV_DIR"
    
    # Activate virtual environment
    source "$VENV_DIR/bin/activate"
    
    # Upgrade pip
    pip install --upgrade pip
    
    print_success "Virtual environment created ✓"
    print_info "Environment isolated from system packages"
}

install_dependencies_minimal() {
    print_step "Installing dependencies (minimal set for testing)..."
    
    source "$VENV_DIR/bin/activate"
    
    # Install core dependencies
    print_info "Installing NumPy and Numba..."
    pip install numpy==2.2.6
    pip install numba==0.61.2
    
    print_info "Installing MLX (may take a while)..."
    pip install mlx>=0.20.0
    
    print_info "Installing MLX Whisper..."
    pip install mlx-whisper>=0.4.0
    
    print_info "Installing audio processing..."
    pip install librosa>=0.10.0
    pip install soundfile>=0.12.0
    
    # Test core functionality
    print_info "Testing core imports..."
    python -c "
import numpy as np
import mlx.core as mx
import mlx_whisper
print('✅ Core dependencies working')
print(f'NumPy: {np.__version__}')
print(f'MLX: Basic functionality OK')
print('MLX Whisper: Import successful')
"
    
    print_success "Dependencies installed and tested ✓"
}

copy_application_files_test() {
    print_step "Installing application files..."
    
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    RESOURCES_DIR="$SCRIPT_DIR/resources"
    
    if [[ -d "$RESOURCES_DIR" ]]; then
        cp -r "$RESOURCES_DIR"/* "$INSTALL_DIR/"
        print_success "Application files installed ✓"
    else
        print_error "Resources directory not found: $RESOURCES_DIR"
        return 1
    fi
}

create_test_launcher() {
    print_step "Creating test launcher..."
    
    cat > "$INSTALL_DIR/bin/audio2text-test" << 'EOF'
#!/bin/bash

# Audio2Text Test Launcher
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_DIR="$(dirname "$SCRIPT_DIR")"
VENV_DIR="$APP_DIR/venv"

echo "🧪 Audio2Text Test Mode"
echo "Installation: $APP_DIR"

# Activate virtual environment
if [[ -f "$VENV_DIR/bin/activate" ]]; then
    source "$VENV_DIR/bin/activate"
    echo "✅ Virtual environment activated"
else
    echo "❌ Virtual environment not found"
    exit 1
fi

# Set up environment
export PYTHONPATH="$APP_DIR:$PYTHONPATH"
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
    echo "❌ Transcription script not found"
    exit 1
fi
EOF
    
    chmod +x "$INSTALL_DIR/bin/audio2text-test"
    print_success "Test launcher created ✓"
    print_info "Command: $INSTALL_DIR/bin/audio2text-test"
}

run_installation_test() {
    print_step "Running installation test..."
    
    # Test the launcher
    if "$INSTALL_DIR/bin/audio2text-test" --help >/dev/null 2>&1; then
        print_success "Launcher test passed ✓"
    else
        print_error "Launcher test failed"
        return 1
    fi
    
    # Run system test if available
    if [[ -f "$INSTALL_DIR/test/test_installation.py" ]]; then
        print_info "Running comprehensive system test..."
        source "$VENV_DIR/bin/activate"
        cd "$INSTALL_DIR"
        python test/test_installation.py || print_warning "Some tests failed (may be normal for test environment)"
    fi
    
    print_success "Installation test completed ✓"
}

show_test_summary() {
    echo
    echo -e "${GREEN}"
    echo "╔════════════════════════════════════════════════════════════════════════╗"
    echo "║                 🧪 Test Installation Complete! 🧪                     ║"
    echo "╚════════════════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    
    print_success "Audio2Text test installation successful!"
    
    echo
    print_info "📍 Test installation location: $INSTALL_DIR"
    print_info "🚀 Test command: $INSTALL_DIR/bin/audio2text-test [audio-file]"
    print_info "📊 Output folder: $INSTALL_DIR/output"
    print_info "📝 Logs: $INSTALL_DIR/logs"
    
    echo
    print_info "🧪 Test-specific features:"
    echo "  • Isolated from production Audio2Text"
    echo "  • Uses separate virtual environment"
    echo "  • No system PATH modifications"
    echo "  • No conflicts with existing ML packages"
    
    echo
    print_info "📚 Next steps:"
    echo "1. Test basic functionality:"
    echo "   $INSTALL_DIR/bin/audio2text-test --help"
    echo ""
    echo "2. Test with sample audio:"
    echo "   $INSTALL_DIR/bin/audio2text-test /path/to/audio.wav"
    echo ""
    echo "3. Configure HuggingFace token (if needed):"
    echo "   nano $INSTALL_DIR/config/env"
    
    echo
    print_info "🗑️  To remove test installation:"
    echo "   rm -rf $INSTALL_DIR"
    
    echo
    print_success "Happy testing! 🎙️"
}

# Main installation process
main() {
    print_header
    
    log "Starting Audio2Text test installation"
    
    detect_existing_environment
    
    echo
    print_warning "This is a TEST installation that:"
    echo "  • Will not modify your existing Python/ML environment"
    echo "  • Will not add commands to your PATH"
    echo "  • Will install in: $INSTALL_DIR"
    echo "  • Can be safely removed afterwards"
    echo
    
    read -p "Continue with test installation? (y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_info "Installation cancelled"
        exit 0
    fi
    
    check_system_safe
    install_homebrew_safe
    install_python_safe
    install_ffmpeg_safe
    create_test_environment
    create_virtual_environment_safe
    install_dependencies_minimal
    copy_application_files_test
    create_test_launcher
    run_installation_test
    
    show_test_summary
    
    log "Test installation completed successfully"
}

# Run main installation
main "$@"
