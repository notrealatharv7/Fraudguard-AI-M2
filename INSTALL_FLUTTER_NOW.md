# Quick Flutter Installation Guide

## Step-by-Step Installation

### Method 1: Using Git (Fastest)

1. **Open PowerShell as Administrator**

2. **Navigate to C:\ and clone Flutter:**
   ```powershell
   cd C:\
   git clone https://github.com/flutter/flutter.git -b stable
   ```

3. **Add Flutter to PATH (Permanent):**
   ```powershell
   [Environment]::SetEnvironmentVariable("Path", $env:Path + ";C:\flutter\bin", "User")
   ```

4. **Close and reopen PowerShell**, then verify:
   ```powershell
   flutter --version
   ```

### Method 2: Manual Download

1. **Download Flutter SDK:**
   - Go to: https://docs.flutter.dev/get-started/install/windows
   - Click "Download Flutter SDK"
   - Download the ZIP file (about 1.5 GB)

2. **Extract:**
   - Extract to `C:\flutter` (create the folder if needed)
   - **Important:** Don't extract to a folder with spaces or special characters

3. **Add to PATH:**
   - Press `Win + X` → **System**
   - Click **Advanced system settings**
   - Click **Environment Variables**
   - Under **User variables**, find **Path** and click **Edit**
   - Click **New** and add: `C:\flutter\bin`
   - Click **OK** on all dialogs

4. **Restart PowerShell** and verify:
   ```powershell
   flutter --version
   ```

### After Installation

Run Flutter doctor to check what else you need:
```powershell
flutter doctor
```

This will tell you if you need:
- Android Studio (for Android development)
- VS Code (optional, but recommended)
- Android SDK licenses

### Quick Test

Once installed, test with your project:
```powershell
cd D:\fraudguard\flutter_app\fraud_detector
flutter pub get
flutter doctor
```

## Troubleshooting

**"git: command not found"**
- Install Git: https://git-scm.com/download/win

**"flutter: command not found" after adding to PATH**
- Close and reopen PowerShell/Terminal
- Restart your computer if needed
- Verify PATH: `$env:PATH -split ';' | Select-String flutter`

**Need help?**
- Flutter Docs: https://docs.flutter.dev
- Flutter Community: https://flutter.dev/community

