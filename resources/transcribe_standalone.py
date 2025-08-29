#!/usr/bin/env python3
"""
Audio2Text Standalone Transcription Script

A self-contained audio transcription system using MLX Whisper for Apple Silicon Macs.
Supports multiple languages, speaker diarization, and various audio formats.

Usage:
    python transcribe_standalone.py input.wav
    python transcribe_standalone.py --model large-v3 --language de input.mp3
    python transcribe_standalone.py --speakers --format json input.m4a
"""

import os
import sys
import json
import argparse
import logging
import tempfile
import traceback
from pathlib import Path
from datetime import datetime
import subprocess

# Import NPZ loading fix first (before any numpy imports)
try:
    import npz_loading_fix
    print("🔧 Applied NPZ loading compatibility fix")
except ImportError:
    print("⚠️  NPZ loading fix not found - may have issues in bundled environments")

# Core dependencies
import numpy as np
import soundfile as sf

# MLX and ML dependencies
try:
    import mlx.core as mx
    import mlx_whisper
    MLX_AVAILABLE = True
    print("✅ MLX Whisper available")
except ImportError as e:
    MLX_AVAILABLE = False
    print(f"❌ MLX Whisper not available: {e}")

# Audio processing
try:
    import librosa
    LIBROSA_AVAILABLE = True
except ImportError:
    LIBROSA_AVAILABLE = False
    print("⚠️  Librosa not available - limited audio format support")

# Speaker diarization
try:
    from pyannote.audio import Pipeline
    DIARIZATION_AVAILABLE = True
    print("✅ Speaker diarization available")
except ImportError:
    DIARIZATION_AVAILABLE = False
    print("⚠️  Speaker diarization not available")

# Fallback: WhisperX
try:
    import whisperx
    WHISPERX_AVAILABLE = True
    print("✅ WhisperX fallback available")
except ImportError:
    WHISPERX_AVAILABLE = False
    print("⚠️  WhisperX fallback not available")


class Audio2TextTranscriber:
    """Main transcription class with multiple engine support"""
    
    def __init__(self, model_size="large-v3-turbo", language=None, device="auto", output_dir=None):
        self.model_size = model_size
        self.language = language
        self.device = device
        self.output_dir = Path(output_dir) if output_dir else None
        if self.output_dir:
            self.output_dir.mkdir(exist_ok=True)
        
        # Set up logging
        self.setup_logging()
        
        # Initialize models
        self.diarization_pipeline = None
        self.whisperx_model = None
        
        # Load configuration
        self.load_config()
        
    def setup_logging(self):
        """Configure logging"""
        # Use a temporary log location if output_dir is None
        if self.output_dir:
            log_dir = self.output_dir.parent / "logs"
        else:
            log_dir = Path.home() / "Applications" / "Audio2Text" / "logs"
        log_dir.mkdir(exist_ok=True)
        
        log_file = log_dir / f"audio2text_{datetime.now().strftime('%Y%m%d_%H%M%S')}.log"
        
        logging.basicConfig(
            level=logging.INFO,
            format='%(asctime)s - %(levelname)s - %(message)s',
            handlers=[
                logging.FileHandler(log_file),
                logging.StreamHandler()
            ]
        )
        self.logger = logging.getLogger(__name__)
        
    def load_config(self):
        """Load configuration from environment and config files"""
        # HuggingFace token
        hf_token = os.getenv('HF_TOKEN')
        if not hf_token:
            # Try to load from config file
            config_file = Path.home() / "Applications" / "Audio2Text" / "config" / "env"
            if config_file.exists():
                with open(config_file) as f:
                    for line in f:
                        if line.startswith('HF_TOKEN='):
                            hf_token = line.split('=', 1)[1].strip()
                            os.environ['HF_TOKEN'] = hf_token
                            break
        
        if hf_token:
            os.environ['HUGGING_FACE_HUB_TOKEN'] = hf_token
            self.logger.info("✅ Hugging Face token configured")
        else:
            self.logger.warning("⚠️  No Hugging Face token found - some models may not download")
    
    
    def load_diarization_model(self):
        """Load speaker diarization model"""
        if not DIARIZATION_AVAILABLE:
            return False
            
        try:
            self.logger.info("Loading speaker diarization model...")
            
            # Check for valid local pipeline directory
            models_dir = Path.home() / "Applications" / "Audio2Text" / "models" / "diarization"
            
            # A valid pipeline directory should contain config.yaml and have the right structure
            # The current local directory is not a valid pipeline, so always use HF repo
            if (models_dir.exists() and 
                (models_dir / "config.yaml").exists() and 
                (models_dir / "pytorch_model.bin").exists()):
                # Only use local if it's a complete pipeline
                self.logger.info("Loading from local pipeline directory...")
                self.diarization_pipeline = Pipeline.from_pretrained(str(models_dir))
            else:
                # Load from Hugging Face repository
                self.logger.info("Loading from Hugging Face repository...")
                self.diarization_pipeline = Pipeline.from_pretrained(
                    "pyannote/speaker-diarization-3.1",
                    use_auth_token=os.getenv('HF_TOKEN')
                )
            
            self.logger.info("✅ Speaker diarization model loaded")
            return True
            
        except Exception as e:
            self.logger.error(f"Failed to load diarization model: {e}")
            return False
    
    def load_whisperx_model(self):
        """Load WhisperX fallback model"""
        if not WHISPERX_AVAILABLE:
            return False
            
        try:
            self.logger.info(f"Loading WhisperX model: {self.model_size}")
            self.whisperx_model = whisperx.load_model(
                self.model_size,
                device="cpu"  # Use CPU for compatibility
            )
            self.logger.info("✅ WhisperX model loaded")
            return True
            
        except Exception as e:
            self.logger.error(f"Failed to load WhisperX model: {e}")
            return False
    
    def preprocess_audio(self, audio_path):
        """Preprocess audio file to compatible format"""
        audio_path = Path(audio_path)
        if not audio_path.exists():
            raise FileNotFoundError(f"Audio file not found: {audio_path}")
        
        self.logger.info(f"Processing audio file: {audio_path}")
        
        # Check if we need to convert the audio
        if audio_path.suffix.lower() in ['.wav', '.flac'] and LIBROSA_AVAILABLE:
            # Try direct loading first
            try:
                audio_data, sample_rate = sf.read(str(audio_path))
                if sample_rate == 16000:
                    self.logger.info("✅ Audio already in correct format")
                    return str(audio_path), audio_data, sample_rate
            except Exception:
                pass
        
        # Convert audio using librosa or ffmpeg
        temp_wav = None
        try:
            if LIBROSA_AVAILABLE:
                # Use librosa for conversion
                self.logger.info("Converting audio with librosa...")
                audio_data, sample_rate = librosa.load(str(audio_path), sr=16000, mono=True)
                
                # Save to temporary file
                temp_wav = tempfile.NamedTemporaryFile(suffix='.wav', delete=False)
                sf.write(temp_wav.name, audio_data, 16000)
                temp_wav.close()
                
                self.logger.info("✅ Audio converted successfully")
                return temp_wav.name, audio_data, 16000
                
            else:
                # Use ffmpeg fallback
                self.logger.info("Converting audio with ffmpeg...")
                temp_wav = tempfile.NamedTemporaryFile(suffix='.wav', delete=False)
                temp_wav.close()
                
                cmd = [
                    'ffmpeg', '-i', str(audio_path),
                    '-ar', '16000', '-ac', '1', '-f', 'wav',
                    '-y', temp_wav.name
                ]
                
                result = subprocess.run(cmd, capture_output=True, text=True)
                if result.returncode != 0:
                    raise RuntimeError(f"FFmpeg conversion failed: {result.stderr}")
                
                # Load the converted audio
                audio_data, sample_rate = sf.read(temp_wav.name)
                self.logger.info("✅ Audio converted with ffmpeg")
                return temp_wav.name, audio_data, sample_rate
                
        except Exception as e:
            if temp_wav and os.path.exists(temp_wav.name):
                os.unlink(temp_wav.name)
            raise RuntimeError(f"Audio preprocessing failed: {e}")
    
    def transcribe_with_mlx(self, audio_path):
        """Transcribe using MLX Whisper"""
        try:
            self.logger.info("Transcribing with MLX Whisper...")
            
            # Determine model path
            # Handle special case for turbo model which doesn't have -mlx suffix
            if "turbo" in self.model_size:
                model_name = f"mlx-community/whisper-{self.model_size}"
            else:
                model_name = f"mlx-community/whisper-{self.model_size}-mlx"
            
            # Transcribe using the direct API
            result = mlx_whisper.transcribe(
                audio_path,
                path_or_hf_repo=model_name,
                verbose=True
            )
            
            # Add language if detected
            if self.language:
                result['language'] = self.language
            
            self.logger.info("✅ MLX transcription completed")
            return result
            
        except Exception as e:
            self.logger.error(f"MLX transcription failed: {e}")
            raise
    
    def transcribe_with_whisperx(self, audio_path, audio_data, sample_rate):
        """Transcribe using WhisperX fallback"""
        if not self.whisperx_model:
            if not self.load_whisperx_model():
                raise RuntimeError("Failed to load WhisperX model")
        
        try:
            self.logger.info("Transcribing with WhisperX...")
            
            result = self.whisperx_model.transcribe(audio_data)
            
            self.logger.info("✅ WhisperX transcription completed")
            return result
            
        except Exception as e:
            self.logger.error(f"WhisperX transcription failed: {e}")
            raise
    
    def add_speaker_diarization(self, audio_path, transcription_result):
        """Add speaker diarization to transcription"""
        if not self.diarization_pipeline:
            if not self.load_diarization_model():
                self.logger.warning("Speaker diarization not available")
                return transcription_result
        
        try:
            self.logger.info("Adding speaker diarization...")
            
            # Run diarization
            diarization = self.diarization_pipeline(audio_path)
            
            # Merge with transcription
            segments = transcription_result.get('segments', [])
            for segment in segments:
                start_time = segment['start']
                end_time = segment['end']
                
                # Find speaker for this segment
                speakers = []
                for turn, _, speaker in diarization.itertracks(yield_label=True):
                    if turn.start <= start_time <= turn.end or turn.start <= end_time <= turn.end:
                        speakers.append(speaker)
                
                if speakers:
                    segment['speaker'] = max(set(speakers), key=speakers.count)
                else:
                    segment['speaker'] = 'UNKNOWN'
            
            self.logger.info("✅ Speaker diarization completed")
            return transcription_result
            
        except Exception as e:
            self.logger.error(f"Speaker diarization failed: {e}")
            return transcription_result
    
    def format_output(self, result, format_type, include_speakers=False):
        """Format transcription result"""
        if format_type == 'json':
            return json.dumps(result, indent=2, ensure_ascii=False)
        
        elif format_type == 'srt':
            srt_content = []
            segments = result.get('segments', [])
            
            for i, segment in enumerate(segments, 1):
                start = self.format_timestamp_srt(segment['start'])
                end = self.format_timestamp_srt(segment['end'])
                text = segment['text'].strip()
                
                if include_speakers and 'speaker' in segment:
                    text = f"[{segment['speaker']}] {text}"
                
                srt_content.extend([
                    str(i),
                    f"{start} --> {end}",
                    text,
                    ""
                ])
            
            return "\n".join(srt_content)
        
        elif format_type == 'txt':
            if 'text' in result:
                return result['text']
            else:
                segments = result.get('segments', [])
                lines = []
                for segment in segments:
                    text = segment['text'].strip()
                    if include_speakers and 'speaker' in segment:
                        text = f"[{segment['speaker']}] {text}"
                    lines.append(text)
                return "\n".join(lines)
        
        else:
            return str(result)
    
    def format_timestamp_srt(self, seconds):
        """Format timestamp for SRT format"""
        hours = int(seconds // 3600)
        minutes = int((seconds % 3600) // 60)
        secs = int(seconds % 60)
        millisecs = int((seconds % 1) * 1000)
        return f"{hours:02d}:{minutes:02d}:{secs:02d},{millisecs:03d}"
    
    def transcribe_file(self, audio_path, output_format='txt', include_speakers=False):
        """Main transcription method"""
        audio_path = Path(audio_path)
        self.logger.info(f"🎙️  Starting transcription: {audio_path}")
        
        processed_audio_path = None
        try:
            # Preprocess audio
            processed_audio_path, audio_data, sample_rate = self.preprocess_audio(audio_path)
            
            # Try transcription engines in order of preference
            result = None
            
            # 1. Try MLX Whisper first (best for Apple Silicon)
            if MLX_AVAILABLE:
                try:
                    result = self.transcribe_with_mlx(processed_audio_path)
                    engine_used = "MLX Whisper"
                except Exception as e:
                    self.logger.warning(f"MLX transcription failed, trying fallback: {e}")
            
            # 2. Try WhisperX fallback
            if not result and WHISPERX_AVAILABLE:
                try:
                    result = self.transcribe_with_whisperx(processed_audio_path, audio_data, sample_rate)
                    engine_used = "WhisperX"
                except Exception as e:
                    self.logger.warning(f"WhisperX transcription failed: {e}")
            
            if not result:
                raise RuntimeError("All transcription engines failed")
            
            # Add speaker diarization if requested
            if include_speakers:
                result = self.add_speaker_diarization(processed_audio_path, result)
            
            # Format output
            formatted_result = self.format_output(result, output_format, include_speakers)
            
            # Save to file
            output_filename = f"{audio_path.stem}_transcript.{output_format}"
            if self.output_dir:
                # Use specified output directory
                output_path = self.output_dir / output_filename
            else:
                # Save next to the original audio file
                output_path = audio_path.parent / output_filename
            
            with open(output_path, 'w', encoding='utf-8') as f:
                f.write(formatted_result)
            
            # Log success
            self.logger.info(f"✅ Transcription completed successfully!")
            self.logger.info(f"   Engine: {engine_used}")
            self.logger.info(f"   Language: {self.language or 'auto-detected'}")
            self.logger.info(f"   Output: {output_path}")
            
            return {
                'success': True,
                'output_path': str(output_path),
                'engine': engine_used,
                'result': result
            }
            
        except Exception as e:
            self.logger.error(f"❌ Transcription failed: {e}")
            self.logger.error(traceback.format_exc())
            return {
                'success': False,
                'error': str(e)
            }
        
        finally:
            # Clean up temporary files
            if processed_audio_path and processed_audio_path != str(audio_path):
                try:
                    os.unlink(processed_audio_path)
                except:
                    pass


def main():
    """Main command line interface"""
    parser = argparse.ArgumentParser(
        description='Audio2Text - MLX Whisper Transcription for Apple Silicon',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  %(prog)s audio.wav
  %(prog)s --model large-v3 --language de audio.mp3
  %(prog)s --speakers --format srt audio.m4a
  %(prog)s --output-dir ~/Documents audio.wav

Supported formats: WAV, MP3, M4A, FLAC, MP4, and more
Supported languages: Auto-detect or specify (en, de, fr, es, it, etc.)
        """
    )
    
    parser.add_argument('audio_file', help='Input audio file path')
    parser.add_argument('--model', '-m', default='large-v3-turbo',
                       choices=['tiny', 'base', 'small', 'medium', 'large', 'large-v2', 'large-v3', 'large-v3-turbo'],
                       help='Whisper model size (default: large-v3-turbo)')
    parser.add_argument('--language', '-l', help='Audio language (auto-detect if not specified)')
    parser.add_argument('--format', '-f', default='txt',
                       choices=['txt', 'json', 'srt'],
                       help='Output format (default: txt)')
    parser.add_argument('--speakers', '-s', action='store_true',
                       help='Enable speaker diarization')
    parser.add_argument('--output-dir', '-o', help='Output directory (default: ./output)')
    parser.add_argument('--verbose', '-v', action='store_true',
                       help='Verbose logging')
    
    args = parser.parse_args()
    
    # Print banner
    print("🎙️  Audio2Text - MLX Whisper Transcription")
    print("=" * 50)
    
    # Check system
    if not MLX_AVAILABLE and not WHISPERX_AVAILABLE:
        print("❌ Error: No transcription engines available!")
        print("   Please install mlx-whisper or whisperx")
        sys.exit(1)
    
    # Check input file
    if not Path(args.audio_file).exists():
        print(f"❌ Error: Audio file not found: {args.audio_file}")
        sys.exit(1)
    
    # Create transcriber
    transcriber = Audio2TextTranscriber(
        model_size=args.model,
        language=args.language,
        output_dir=args.output_dir
    )
    
    # Run transcription
    result = transcriber.transcribe_file(
        args.audio_file,
        output_format=args.format,
        include_speakers=args.speakers
    )
    
    # Print results
    if result['success']:
        print(f"\n✅ Success! Transcript saved to: {result['output_path']}")
        print(f"   Engine: {result['engine']}")
        
        if args.verbose:
            print("\nTranscript preview:")
            print("-" * 30)
            if args.format == 'txt':
                preview = result['result'].get('text', '')[:500]
                print(preview + ("..." if len(preview) >= 500 else ""))
    else:
        print(f"\n❌ Error: {result['error']}")
        sys.exit(1)


if __name__ == '__main__':
    main()
