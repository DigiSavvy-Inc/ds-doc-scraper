#!/usr/bin/env python3
"""
Helper script to check if running in a virtual environment.
Can be imported by other scripts to provide warnings.
"""
import sys
import os

def is_virtual_env():
    """Check if we're running in a virtual environment."""
    # Check for common virtual environment indicators
    return (
        hasattr(sys, 'real_prefix') or  # virtualenv
        (hasattr(sys, 'base_prefix') and sys.base_prefix != sys.prefix) or  # venv
        'VIRTUAL_ENV' in os.environ  # Both virtualenv and venv set this
    )

def warn_if_not_venv():
    """Print a warning if not running in a virtual environment."""
    if not is_virtual_env():
        print("\n" + "="*60)
        print("⚠️  WARNING: Not running in a virtual environment!")
        print("="*60)
        print("It's recommended to use a virtual environment to avoid conflicts.")
        print("To set up and activate a virtual environment:")
        print("\n  bash setup.sh")
        print("\nOr manually:")
        print("  python -m venv venv")
        print("  source venv/bin/activate  # On macOS/Linux")
        print("  venv\\Scripts\\activate     # On Windows")
        print("="*60 + "\n")
        
        # Optional: Ask user if they want to continue
        response = input("Continue anyway? [y/N]: ").strip().lower()
        if response != 'y':
            print("Exiting. Please activate a virtual environment and try again.")
            sys.exit(1)

if __name__ == "__main__":
    if is_virtual_env():
        print("✓ Running in a virtual environment")
    else:
        print("✗ Not running in a virtual environment")
        warn_if_not_venv()