# Linio (macOS)

Native macOS app distribution: sign in Xcode, export a **`.app`**, then build a **`.dmg`** with the included scripts. Optional **notarization** and **stapling** are documented below.

## Requirements

- **Xcode** (current stable release recommended)
- **Apple Developer Program** membership for **Developer ID Application** distribution outside the Mac App Store
- **Developer ID Application** certificate in Keychain (Xcode can create or refresh it under **Settings → Accounts**)

## Signing in Xcode

**Automatically manage signing** is convenient for day‑to‑day **Debug** builds, but Xcode often does **not** offer **Developer ID Application** while automatic signing is enabled.

For **Release** archives you ship to users:

1. Open your **`.xcodeproj`** or **`.xcworkspace`** (the target that produces **`YourApp.app`**), not the raw Swift package alone.
2. Select the app target → **Signing & Capabilities**.
3. Turn **off** **Automatically manage signing** for the configuration you archive (often **Release**), or leave automatic for **Debug** only if you use separate settings per configuration.
4. Set **Team** and **Signing Certificate** to **Developer ID Application**.

Archive builds must use the identity that matches how you export (**Developer ID**), not **Apple Development**, for distribution outside the store.

## Product → Archive (where to run it)

Run **Product → Archive** in the **Xcode project or workspace** that contains your **macOS App** target.

A Swift Package opened only via **`Package.swift`** is for libraries and command-line tools; **Archive** and **Distribute App** are meant for an **application** target that produces **`.app`**. If you use a generated host project (for example XcodeGen), open that project for archiving.

## Export the signed app (not the Mac App Store path)

After a successful archive:

1. **Window → Organizer** → select the archive → **Distribute App**.
2. Choose **Developer ID** / **Direct distribution** / **Upload for notarization** (wording varies by Xcode version). **Do not** pick **App Store Connect** if you are shipping a download or DMG outside the store.
3. Complete the wizard and **export** to a folder on disk. You should get **`YourApp.app`** (and related export metadata).

You will point the DMG script at this exported **`.app`**.

## Build a DMG from the exported app

From the repository root (or any directory):

```bash
./scripts/package_macos_dmg.sh /absolute/or/relative/path/to/YourApp.app
```

Optional second argument: output directory (default: **`dist/`**):

```bash
./scripts/package_macos_dmg.sh ~/Desktop/YourApp-Export/YourApp.app ./dist
```

The script:

- Copies the **`.app`** with **`ditto`** (preserves code signing extended attributes)
- Adds an **Applications** shortcut inside the disk image
- Produces **`dist/YourApp-<CFBundleShortVersionString>.dmg`** when the version is present in **`Info.plist`**

If **`chmod`** reports permission denied, run:

```bash
chmod +x scripts/package_macos_dmg.sh scripts/notarize_and_staple.sh
```

Or invoke with **`bash scripts/package_macos_dmg.sh ...`**.

## Notarization and stapling (recommended for downloads)

Apple expects **Developer ID** software distributed over the internet to be **notarized**. After you have a **`.dmg`** (or **`.zip`** containing the app), submit it to the notary service and **staple** the ticket.

### One-time: store credentials in the Keychain

Pick a profile name (example: **`NOTARYTOOL_PROFILE`**) and run:

```bash
xcrun notarytool store-credentials "NOTARYTOOL_PROFILE" \
  --apple-id "you@example.com" \
  --team-id "YOUR_TEAM_ID" \
  --password "your-app-specific-password"
```

Use an [app-specific password](https://support.apple.com/en-us/102654) for the Apple ID account. **Team ID** appears in the Apple Developer account membership page and in Xcode.

### Submit and staple

```bash
./scripts/notarize_and_staple.sh dist/YourApp-1.0.0.dmg NOTARYTOOL_PROFILE
```

The second argument is optional; it defaults to **`NOTARYTOOL_PROFILE`**. To use a different profile by default, either pass it explicitly or edit the default in **`scripts/notarize_and_staple.sh`**.

### Quick Gatekeeper check

```bash
spctl --assess --type open --context context:primary-signature -v dist/YourApp-1.0.0.dmg
```

## End-to-end checklist

1. **Archive** in Xcode with **Developer ID** signing for **Release**.
2. **Distribute App** from Organizer → export **`YourApp.app`** (non–App Store Connect path).
3. **`./scripts/package_macos_dmg.sh`** on the exported **`.app`** → **`dist/*.dmg`**.
4. **`./scripts/notarize_and_staple.sh`** on the **`.dmg`** (or notarize the **`.zip`** you ship, if you prefer).
5. Upload the **stapled** **`.dmg`** to your website or release channel.

## Scripts reference

| Script | Purpose |
|--------|---------|
| **`scripts/package_macos_dmg.sh`** | Stage **`.app`** + **Applications** link → compressed **`.dmg`** |
| **`scripts/notarize_and_staple.sh`** | **`notarytool submit --wait`** then **`stapler staple`** on the artifact |

## Git

**`dist/`** is ignored so local DMG output is not committed by default. Remove **`dist/`** from **`.gitignore`** if you intentionally version built artifacts (unusual).
