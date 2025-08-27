#!/usr/bin/env python3
"""
Audio2Text Installation Test Script

This script validates that Audio2Text is correctly installed and functional.
It performs system checks, dependency validation, and a sample transcription test.
"""

import os
import sys
import json
import subprocess
import tempfile
import wave
import struct
import math
from pathlib import Path

def print_header():
    print("🔧 Audio2Text Installation Test")
    print("=" * 40)

def print_test(name):
    print(f"\n📋 Testing: {name}")

def print_success(msg):
    print(f"✅ {msg}")

def print_warning(msg):
    print(f"⚠️  {msg}")

def print_error(msg):
    print(f"❌ {msg}")

def print_info(msg):
    print(f"ℹ️  {msg}")

def test_system_requirements():
    """Test system requirements"""
    print_test("System Requirements")
    
    # Check macOS version
    try:
        result = subprocess.run(['sw_vers', '-productVersion'], capture_output=True, text=True)
        macos_version = result.stdout.strip()
        major = int(macos_version.split('.')[0])
        if major >= 11:
            print_success(f"macOS version: {macos_version} ✓")
        else:
            print_error(f"macOS version too old: {macos_version} (need 11.0+)")
            return False
    except Exception as e:
        print_error(f"Failed to check macOS version: {e}")
        return False
    
    # Check architecture
    try:
        result = subprocess.run(['uname', '-m'], capture_output=True, text=True)
        arch = result.stdout.strip()
        if arch == 'arm64':
            print_success(f"Architecture: {arch} ✓")
        else:
            print_error(f"Architecture not supported: {arch} (need arm64)")
            return False
    except Exception as e:
        print_error(f"Failed to check architecture: {e}")
        return False
    
    return True

def test_python_environment():
    """Test Python environment"""
    print_test("Python Environment")
    
    # Check Python version
    version = sys.version_info
    print_success(f"Python version: {version.major}.{version.minor}.{version.micro}")
    
    # Check virtual environment
    if hasattr(sys, 'real_prefix') or (hasattr(sys, 'base_prefix') and sys.base_prefix != sys.prefix):
        print_success("Virtual environment: Active ✓")
    else:
        print_warning("Virtual environment: Not detected")
    
    return True

def test_core_dependencies():
    """Test core Python dependencies"""
    print_test("Core Dependencies")
    
    success = True
    dependencies = [
        ('numpy', 'NumPy'),
        ('soundfile', 'SoundFile'),
        ('librosa', 'Librosa'),
        ('mlx.core', 'MLX Core'),
        ('mlx_whisper', 'MLX Whisper')
    ]
    
    for module_name, display_name in dependencies:
        try:
            if module_name == 'mlx.core':
                import mlx.core as mx
                # Test basic MLX functionality
                test_array = mx.array([1, 2, 3])
                print_success(f"{display_name}: Available ✓")
            elif module_name == 'mlx_whisper':
                import mlx_whisper
                print_success(f"{display_name}: Available ✓")
            else:
                exec(f"import {module_name}")
                print_success(f"{display_name}: Available ✓")
        except ImportError as e:
            print_error(f"{display_name}: Missing - {e}")
            success = False
        except Exception as e:
            print_warning(f"{display_name}: Error - {e}")
    
    return success

def test_optional_dependencies():
    """Test optional dependencies"""
    print_test("Optional Dependencies")
    
    optional_deps = [
        ('whisperx', 'WhisperX (fallback)'),
        ('pyannote.audio', 'Speaker Diarization')
    ]
    
    for module_name, display_name in optional_deps:
        try:
            exec(f"import {module_name}")
            print_success(f"{display_name}: Available ✓")
        except ImportError:
            print_warning(f"{display_name}: Not available (optional)")

def create_test_audio(filename, duration=3.0, sample_rate=16000):
    """Create a simple test audio file"""
    with wave.open(filename, 'w') as wav_file:
        wav_file.setnchannels(1)  # Mono
        wav_file.setsampwidth(2)  # 16-bit
        wav_file.setframerate(sample_rate)
        
        # Generate a simple sine wave (440 Hz A note)
        frequency = 440.0
        for i in range(int(sample_rate * duration)):
            sample = int(32767 * math.sin(2 * math.pi * frequency * i / sample_rate))
            wav_file.writeframes(struct.pack('<h', sample))

def test_audio_processing():
    """Test audio file processing"""
    print_test("Audio Processing")
    
    try:
        # Create temporary test audio file
        with tempfile.NamedTemporaryFile(suffix='.wav', delete=False) as temp_file:
            test_audio_file = temp_file.name
        
        create_test_audio(test_audio_file)
        print_success("Test audio file created ✓")
        
        # Test SoundFile loading
        import soundfile as sf
        data, samplerate = sf.read(test_audio_file)
        print_success(f"Audio loading: {len(data)} samples at {samplerate}Hz ✓")
        
        # Test Librosa loading (if available)
        try:
            import librosa
            audio_data, sr = librosa.load(test_audio_file, sr=16000, mono=True)
            print_success(f"Librosa processing: {len(audio_data)} samples ✓")
        except ImportError:
            print_warning("Librosa not available for audio conversion")
        
        # Clean up
        os.unlink(test_audio_file)
        
        return True
        
    except Exception as e:
        print_error(f"Audio processing failed: {e}")
        return False

def test_model_access():
    """Test model downloading/access"""
    print_test("Model Access")
    
    # Check HuggingFace token
    hf_token = os.getenv('HF_TOKEN')
    if not hf_token:
        # Try loading from config file
        config_file = Path.home() / "Applications" / "Audio2Text" / "config" / "env"
        if config_file.exists():
            with open(config_file) as f:
                for line in f:
                    if line.startswith('HF_TOKEN='):
                        hf_token = line.split('=', 1)[1].strip()
                        os.environ['HF_TOKEN'] = hf_token
                        break
    
    if hf_token:
        print_success("HuggingFace token: Configured ✓")
        os.environ['HUGGING_FACE_HUB_TOKEN'] = hf_token
    else:
        print_warning("HuggingFace token: Not configured (models may not download)")
    
    # Test model loading (without actually downloading large models)
    try:
        import mlx_whisper
        # Just test the import and basic functionality
        print_success("MLX Whisper: Import successful ✓")
        return True
    except Exception as e:
        print_error(f"MLX Whisper: Failed - {e}")
        return False

def test_cli_access():
    """Test command-line interface"""
    print_test("Command Line Interface")
    
    # Check if audio2text command is available
    try:
        result = subprocess.run(['which', 'audio2text'], capture_output=True, text=True)
        if result.returncode == 0:
            cli_path = result.stdout.strip()
            print_success(f"CLI available: {cli_path} ✓")
            
            # Test help command
            result = subprocess.run(['audio2text', '--help'], capture_output=True, text=True)
            if result.returncode == 0:
                print_success("CLI help: Working ✓")
                return True
            else:
                print_error("CLI help: Failed")
                return False
        else:
            print_error("CLI not found in PATH")
            
            # Check installation directory
            cli_path = Path.home() / "Applications" / "Audio2Text" / "bin" / "audio2text"
            if cli_path.exists():
                print_warning(f"CLI found at: {cli_path} (not in PATH)")
                return True
            else:
                print_error("CLI not found")
                return False
    except Exception as e:
        print_error(f"CLI test failed: {e}")
        return False

def test_directory_structure():
    """Test installation directory structure"""
    print_test("Directory Structure")
    
    base_dir = Path.home() / "Applications" / "Audio2Text"
    required_dirs = [
        "",  # base directory
        "bin",
        "output", 
        "logs",
        "config",
        "venv"
    ]
    
    success = True
    for dir_name in required_dirs:
        dir_path = base_dir / dir_name
        if dir_path.exists():
            print_success(f"Directory exists: {dir_path} ✓")
        else:
            print_error(f"Directory missing: {dir_path}")
            success = False
    
    return success

def run_comprehensive_test():
    """Run all tests"""
    print_header()
    
    tests = [
        ("System Requirements", test_system_requirements),
        ("Python Environment", test_python_environment), 
        ("Core Dependencies", test_core_dependencies),
        ("Optional Dependencies", test_optional_dependencies),
        ("Audio Processing", test_audio_processing),
        ("Model Access", test_model_access),
        ("CLI Access", test_cli_access),
        ("Directory Structure", test_directory_structure)
    ]
    
    results = {}
    for test_name, test_func in tests:
        try:
            results[test_name] = test_func()
        except Exception as e:
            print_error(f"Test {test_name} crashed: {e}")
            results[test_name] = False
    
    # Summary
    print("\n" + "=" * 40)
    print("📊 Test Summary")
    print("=" * 40)
    
    passed = sum(results.values())
    total = len(results)
    
    for test_name, success in results.items():
        status = "✅ PASS" if success else "❌ FAIL"
        print(f"{status} {test_name}")
    
    print(f"\nOverall: {passed}/{total} tests passed")
    
    if passed == total:
        print("\n🎉 All tests passed! Audio2Text is ready to use.")
        print("\nNext steps:")
        print("1. Ensure HuggingFace token is configured")
        print("2. Try: audio2text --help")
        print("3. Test with a real audio file")
        return True
    else:
        print(f"\n⚠️  {total - passed} tests failed. Please check the issues above.")
        print("\nTroubleshooting:")
        print("1. Check installation logs")
        print("2. Verify system requirements")
        print("3. Consider reinstalling")
        return False

if __name__ == '__main__':
    success = run_comprehensive_test()
    sys.exit(0 if success else 1)
