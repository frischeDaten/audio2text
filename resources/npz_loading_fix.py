"""
NPZ Loading Fix for PyInstaller/Bundled Environments

This module provides a monkey-patch for numpy.load to work around issues
with NPZ file loading in PyInstaller and other bundled environments.

The issue occurs because bundled environments virtualize the file system,
but NumPy's NPZ loading expects real file system access for ZIP operations.

This fix copies NPZ files to temporary locations when needed.
"""

import os
import sys
import tempfile
import shutil
from pathlib import Path

# Store original numpy.load function
_original_numpy_load = None
_temp_files = []

def _is_bundled_environment():
    """Detect if we're running in a bundled environment"""
    return (
        getattr(sys, 'frozen', False) or  # PyInstaller
        hasattr(sys, '_MEIPASS') or      # PyInstaller temp folder
        '__compiled__' in globals() or    # Nuitka
        'site-packages.zip' in sys.path[0]  # cx_Freeze
    )

def _copy_to_temp(file_path):
    """Copy file to temporary location and track for cleanup"""
    temp_file = tempfile.NamedTemporaryFile(delete=False, suffix='.npz')
    temp_file.close()
    
    shutil.copy2(file_path, temp_file.name)
    _temp_files.append(temp_file.name)
    
    return temp_file.name

def _patched_numpy_load(file, *args, **kwargs):
    """Patched version of numpy.load that handles bundled environments"""
    # If not in bundled environment, use original function
    if not _is_bundled_environment():
        return _original_numpy_load(file, *args, **kwargs)
    
    # Handle file path or file-like object
    if isinstance(file, (str, Path)):
        file_path = Path(file)
        
        # Check if it's an NPZ file
        if file_path.suffix.lower() == '.npz' and file_path.exists():
            try:
                # First try original load
                return _original_numpy_load(file, *args, **kwargs)
            except Exception as e:
                # If it fails and error mentions zip/file-like, try temp copy
                if 'zip' in str(e).lower() or 'file-like' in str(e).lower():
                    print(f"NPZ loading fix: copying {file_path} to temp location...")
                    temp_path = _copy_to_temp(file_path)
                    return _original_numpy_load(temp_path, *args, **kwargs)
                else:
                    raise
    
    # For non-NPZ files or file-like objects, use original
    return _original_numpy_load(file, *args, **kwargs)

def cleanup_temp_files():
    """Clean up temporary NPZ files"""
    for temp_file in _temp_files:
        try:
            if os.path.exists(temp_file):
                os.unlink(temp_file)
        except Exception:
            pass
    _temp_files.clear()

def apply_npz_fix():
    """Apply the NPZ loading fix"""
    global _original_numpy_load
    
    if _original_numpy_load is not None:
        return  # Already applied
    
    try:
        import numpy as np
        
        # Store original function
        _original_numpy_load = np.load
        
        # Apply patch
        np.load = _patched_numpy_load
        
        # Register cleanup at exit
        import atexit
        atexit.register(cleanup_temp_files)
        
        print("✅ NPZ loading fix applied successfully")
        
    except ImportError:
        print("⚠️  NumPy not available, NPZ fix not applied")
    except Exception as e:
        print(f"⚠️  Failed to apply NPZ fix: {e}")

# Auto-apply fix when module is imported
if _is_bundled_environment():
    apply_npz_fix()
else:
    print("🔧 NPZ loading fix available but not needed (not in bundled environment)")
