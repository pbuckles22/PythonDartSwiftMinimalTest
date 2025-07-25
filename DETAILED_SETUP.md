# Detailed Step-by-Step Guide: Embedding Python in a Flutter iOS App

> **Note:** For a real-world log of issues and fixes encountered during this process, see `BUILD_DEBUG_LOG.md` in this repo.

## Step 0: Create a New Flutter Project

1. **Open Terminal** and navigate to your desired parent directory:
   ```bash
   cd ~/dev
   ```
2. **Create a new Flutter project** (replace `MyPythonFlutterApp` with your desired name):
   ```bash
   flutter create MyPythonFlutterApp
   cd MyPythonFlutterApp
   ```
3. **Open the project in your IDE** (or Xcode for iOS-specific steps):
   ```bash
   code .   # or open ios/Runner.xcworkspace in Xcode
   ```
4. **Verify iOS build works**:
   ```bash
   flutter run
   ```
   - This should launch the default Flutter app on your iOS simulator or device.

---

## Step 1: Create Minimal Python Script

**File:** `ios/Runner/Python/minimal.py`

```
def add_one_and_one():
    return 1 + 1
```

- This is the only Python code needed for the minimal test.
- Place this file in the `Python` directory inside your iOS Runner target.
- Ensure the `Python` directory is added as a blue folder reference in Xcode (not a group/yellow folder).

**Next:** Obtain the Python.xcframework and stdlib for embedding.

---

## Step 2: Obtain and Integrate Python.xcframework and Standard Library

### 2.1 Download Python-Apple-support

- Go to the [Python-Apple-support GitHub Releases](https://github.com/beeware/Python-Apple-support/releases)
- Download the latest release for your desired Python version (e.g., `Python-3.11.x-iOS-support.bX.tar.gz`)
- Save the `.tar.gz` file somewhere accessible (e.g., your Downloads folder)

### 2.2 Extract the Framework and Standard Library

- Open Terminal and navigate to your download location:
  ```bash
  cd ~/Downloads
  tar -xzf Python-3.11.x-iOS-support.bX.tar.gz
  ```
- This will extract a folder containing:
  - `Python.xcframework` (the Python interpreter for iOS)
  - `lib/python3.x` (the Python standard library)

### 2.3 Add to Your Flutter iOS Project

- Copy `Python.xcframework` to your Flutter project's `ios/` directory:
  ```bash
  cp -r ~/Downloads/Python.xcframework ~/dev/MyPythonFlutterApp/ios/
  ```
- Copy the standard library folder to your `ios/` directory as well:
  ```bash
  cp -r ~/Downloads/lib/python3.x ~/dev/MyPythonFlutterApp/ios/python-stdlib
  ```
  (Rename to `python-stdlib` for clarity.)

### 2.4 Add to Xcode as Blue Folder References

1. Open your Flutter project in Xcode: open `ios/Runner.xcworkspace` (not `.xcodeproj`).
2. In the Project Navigator (left sidebar):
   - **Add Python.xcframework:**
     - Right-click on the `ios` folder > **Add Files to "Runner"...**
     - Select `Python.xcframework`.
     - Make sure **Add to targets: Runner** is checked.
     - Click **Add**.
   - **Add python-stdlib:**
     - Right-click on the `ios` folder > **Add Files to "Runner"...**
     - Select the `python-stdlib` folder.
     - In the dialog, choose **Create folder references** (so it appears as a blue folder, not yellow group).
     - Make sure **Add to targets: Runner** is checked.
     - Click **Add**.

**Result:**
- `Python.xcframework` should appear in the Frameworks section.
- `python-stdlib` should appear as a blue folder in the Project Navigator.

**Next:** Configure Xcode build settings and code signing for embedded Python.

---

## Step 3: Configure Xcode Build Settings and Code Signing

### 3.1 Set User Script Sandboxing to No

1. In Xcode, select the **Runner** target in the Project Navigator.
2. Go to the **Build Settings** tab.
3. In the search bar, type `User Script Sandboxing`.
4. Set **User Script Sandboxing** to `No`.
   - This is required for PythonKit to load dynamic libraries at runtime.

### 3.2 Add Framework Search Paths

1. Still in the **Build Settings** tab, search for `Framework Search Paths`.
2. Add the following entry:
   - `$(PROJECT_DIR)`
   - This tells Xcode to look for frameworks (like Python.xcframework) in your project directory.

### 3.3 Add Build Phase to Sign Python Modules

Python's standard library includes dynamic modules (`.so` files) that must be code signed for iOS.

1. Select the **Runner** target.
2. Go to the **Build Phases** tab.
3. Click the `+` button at the top left and choose **New Run Script Phase**.
4. Drag this new phase so it runs **before** "Embed Frameworks" (but after "Copy Bundle Resources").
5. Name the phase: `Sign Embedded Python Modules`.
6. Paste the following script:
   ```sh
   set -e
   echo "Signing embedded Python modules..."
   find "$CODESIGNING_FOLDER_PATH/python-stdlib/lib-dynload" -name "*.so" -exec /usr/bin/codesign --force --sign "$EXPANDED_CODE_SIGN_IDENTITY" --timestamp=none --preserve-metadata=identifier,entitlements,flags {} \;
   echo "✅ Python modules signed successfully"
   ```
7. Make sure the shell is `/bin/sh` (default).

### 3.4 Clean and Build

- In Xcode, select **Product > Clean Build Folder** (hold Option and click Product menu to see this option).
- Then build your project to ensure everything is set up correctly.

**Result:**
- Your app is now configured to embed and sign Python, ready for Swift integration.

**Next:** Implement Swift code to initialize Python and call the minimal Python function. 