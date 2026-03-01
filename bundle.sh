#!/bin/bash
set -euo pipefail

APP_NAME="Mark Down"
BUNDLE_NAME="Mark Down.app"
EXECUTABLE="MarkDownApp"
IDENTIFIER="com.terrell.markdown"
PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
BUILD_DIR="$PROJECT_DIR/.build"
BUNDLE_DIR="$BUILD_DIR/$BUNDLE_NAME"

echo "Building release binary..."
swift build -c release --package-path "$PROJECT_DIR" 2>&1

echo "Creating app bundle..."
rm -rf "$BUNDLE_DIR"
mkdir -p "$BUNDLE_DIR/Contents/MacOS"
mkdir -p "$BUNDLE_DIR/Contents/Resources"

# Copy executable
cp "$BUILD_DIR/arm64-apple-macosx/release/$EXECUTABLE" "$BUNDLE_DIR/Contents/MacOS/$EXECUTABLE"

# Generate .icns from iconset
ICONSET_DIR="$PROJECT_DIR/AppIcon.iconset"
if [ -d "$ICONSET_DIR" ]; then
    echo "Generating AppIcon.icns..."
    iconutil -c icns "$ICONSET_DIR" -o "$BUNDLE_DIR/Contents/Resources/AppIcon.icns"
fi

# Write Info.plist
cat > "$BUNDLE_DIR/Contents/Info.plist" << 'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>
    <string>Mark Down</string>
    <key>CFBundleDisplayName</key>
    <string>Mark Down</string>
    <key>CFBundleIdentifier</key>
    <string>com.terrell.markdown</string>
    <key>CFBundleVersion</key>
    <string>1.0</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleExecutable</key>
    <string>MarkDownApp</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>LSMinimumSystemVersion</key>
    <string>15.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>CFBundleDocumentTypes</key>
    <array>
        <dict>
            <key>CFBundleTypeExtensions</key>
            <array>
                <string>md</string>
                <string>markdown</string>
                <string>mdown</string>
                <string>mkd</string>
            </array>
            <key>CFBundleTypeName</key>
            <string>Markdown Document</string>
            <key>CFBundleTypeRole</key>
            <string>Editor</string>
            <key>LSHandlerRank</key>
            <string>Default</string>
            <key>LSItemContentTypes</key>
            <array>
                <string>net.daringfireball.markdown</string>
                <string>public.plain-text</string>
            </array>
        </dict>
    </array>
    <key>UTImportedTypeDeclarations</key>
    <array>
        <dict>
            <key>UTTypeIdentifier</key>
            <string>net.daringfireball.markdown</string>
            <key>UTTypeDescription</key>
            <string>Markdown Document</string>
            <key>UTTypeConformsTo</key>
            <array>
                <string>public.plain-text</string>
            </array>
            <key>UTTypeTagSpecification</key>
            <dict>
                <key>public.filename-extension</key>
                <array>
                    <string>md</string>
                    <string>markdown</string>
                    <string>mdown</string>
                    <string>mkd</string>
                </array>
            </dict>
        </dict>
    </array>
</dict>
</plist>
PLIST

# Write PkgInfo
echo -n "APPL????" > "$BUNDLE_DIR/Contents/PkgInfo"

# --- Quick Look Preview Extension ---
echo "Building Quick Look extension..."

EXTENSION_NAME="MarkdownPreview"
EXTENSION_DIR="$BUNDLE_DIR/Contents/PlugIns/$EXTENSION_NAME.appex"
EXTENSION_SOURCES="$PROJECT_DIR/QuickLookExtension"

mkdir -p "$EXTENSION_DIR/Contents/MacOS"

# Compile extension
swiftc \
    "$EXTENSION_SOURCES/MarkdownToHTML.swift" \
    "$EXTENSION_SOURCES/PreviewViewController.swift" \
    -parse-as-library \
    -module-name "$EXTENSION_NAME" \
    -application-extension \
    -Xlinker -e -Xlinker _NSExtensionMain \
    -target arm64-apple-macosx15.0 \
    -o "$EXTENSION_DIR/Contents/MacOS/$EXTENSION_NAME" \
    2>&1

# Write extension Info.plist
cat > "$EXTENSION_DIR/Contents/Info.plist" << 'EXTPLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>
    <string>MarkdownPreview</string>
    <key>CFBundleDisplayName</key>
    <string>Markdown Preview</string>
    <key>CFBundleIdentifier</key>
    <string>com.terrell.markdown.quicklook</string>
    <key>CFBundleVersion</key>
    <string>1.0</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleExecutable</key>
    <string>MarkdownPreview</string>
    <key>CFBundlePackageType</key>
    <string>XPC!</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>LSMinimumSystemVersion</key>
    <string>15.0</string>
    <key>NSExtension</key>
    <dict>
        <key>NSExtensionPointIdentifier</key>
        <string>com.apple.quicklook.preview</string>
        <key>NSExtensionPrincipalClass</key>
        <string>MarkdownPreview.PreviewProvider</string>
        <key>NSExtensionAttributes</key>
        <dict>
            <key>QLIsDataBasedPreview</key>
            <true/>
            <key>QLSupportedContentTypes</key>
            <array>
                <string>net.daringfireball.markdown</string>
            </array>
        </dict>
    </dict>
</dict>
</plist>
EXTPLIST

# Write extension PkgInfo
echo -n "XPC!????" > "$EXTENSION_DIR/Contents/PkgInfo"

# Write extension entitlements
EXTENSION_ENTITLEMENTS="$BUILD_DIR/extension.entitlements"
cat > "$EXTENSION_ENTITLEMENTS" << 'ENTITLEMENTS'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.security.app-sandbox</key>
    <true/>
    <key>com.apple.security.files.user-selected.read-only</key>
    <true/>
</dict>
</plist>
ENTITLEMENTS

# Code sign inside-out: extension first (with entitlements), then app
echo "Code signing..."
codesign --force --sign - --entitlements "$EXTENSION_ENTITLEMENTS" "$EXTENSION_DIR"
codesign --force --sign - "$BUNDLE_DIR"

echo ""
echo "App bundle created at:"
echo "  $BUNDLE_DIR"
echo ""
echo "To install, run:"
echo "  cp -r \"$BUNDLE_DIR\" /Applications/"
echo ""
echo "After installing, reset the Quick Look cache:"
echo "  qlmanage -r"
echo ""
echo "To test Quick Look:"
echo "  qlmanage -p README.md"
echo ""
echo "To set as default for .md files:"
echo "  Right-click any .md file → Get Info → Open with → Mark Down → Change All"
