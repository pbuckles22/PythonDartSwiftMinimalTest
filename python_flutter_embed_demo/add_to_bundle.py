#!/usr/bin/env python3
"""
Script to add python-stdlib and minimal.py to Xcode's Copy Bundle Resources
"""

import os
import subprocess
import sys

def run_command(cmd):
    """Run a command and return the output"""
    try:
        result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
        return result.stdout, result.stderr, result.returncode
    except Exception as e:
        return "", str(e), 1

def main():
    print("🔧 Adding files to Xcode Copy Bundle Resources...")
    
    # Check if we're in the right directory
    if not os.path.exists("ios/Runner.xcworkspace"):
        print("❌ Error: ios/Runner.xcworkspace not found. Run this from the Flutter project root.")
        sys.exit(1)
    
    # Check if files exist
    if not os.path.exists("ios/python-stdlib"):
        print("❌ Error: ios/python-stdlib not found")
        sys.exit(1)
    
    if not os.path.exists("ios/Runner/Python/minimal.py"):
        print("❌ Error: ios/Runner/Python/minimal.py not found")
        sys.exit(1)
    
    print("✅ Files found. Adding to Xcode project...")
    
    # Use xcodebuild to add files to the project
    # This is a more direct approach than trying to modify the .pbxproj file
    
    print("\n📋 Manual steps required:")
    print("1. In Xcode, select the 'Runner' target")
    print("2. Go to 'Build Phases' tab")
    print("3. Expand 'Copy Bundle Resources'")
    print("4. Click the '+' button")
    print("5. Add these files:")
    print("   - ios/python-stdlib (as blue folder reference)")
    print("   - ios/Runner/Python/minimal.py (as blue folder reference)")
    print("\n6. Make sure they appear as blue folders, not yellow groups")
    print("7. Build and run the project")
    
    print("\n🔍 Alternative: Check if files are already in the project but not being copied...")
    
    # Check if the files are already referenced in the project
    stdout, stderr, code = run_command("find ios -name '*.pbxproj' -exec grep -l 'python-stdlib' {} \\;")
    if code == 0 and stdout.strip():
        print("✅ python-stdlib is already referenced in the project")
    else:
        print("❌ python-stdlib is NOT referenced in the project")
    
    stdout, stderr, code = run_command("find ios -name '*.pbxproj' -exec grep -l 'minimal.py' {} \\;")
    if code == 0 and stdout.strip():
        print("✅ minimal.py is already referenced in the project")
    else:
        print("❌ minimal.py is NOT referenced in the project")

if __name__ == "__main__":
    main() 