# App Icon Creation Guide

## Quick Options

### Option 1: Online Icon Generator (Easiest) ⭐ Recommended

1. **Go to**: https://appicon.co
2. **Upload** your 1024x1024 logo/image
3. **Download** the generated icon pack
4. **Extract** the zip file
5. **Follow** installation steps below

### Option 2: Icon Kitchen

1. **Go to**: https://icon.kitchen
2. **Upload** your icon
3. **Download** Android icons
4. **Download** iOS icons (if needed)
5. **Follow** installation steps below

### Option 3: Flutter Icon Package

1. **Install**: `flutter pub add flutter_launcher_icons`
2. **Create** `flutter_launcher_icons.yaml`:
```yaml
flutter_launcher_icons:
  android: true
  ios: true
  image_path: "assets/icon/icon.png"  # Your 1024x1024 icon
```
3. **Run**: `flutter pub run flutter_launcher_icons`

---

## What You Need

### Source Image
- **Size**: 1024x1024 pixels
- **Format**: PNG (with transparent background recommended)
- **Design**: Should be recognizable at small sizes (simpler is better)

### If You Don't Have a Logo Yet

**Temporary Options:**
1. **Flaticon**: https://www.flaticon.com
   - Search for "booking" or "calendar" icons
   - Download 1024x1024 version
   - Free with attribution

2. **Simple Text Icon**:
   - Create a simple "B" or "Bookly" text icon
   - Use a design tool (Canva, Figma, etc.)
   - Export as 1024x1024 PNG

3. **AI Generated**:
   - Use DALL-E, Midjourney, or similar
   - Prompt: "App icon for appointment booking app, modern, minimalist, 1024x1024"
   - Export as PNG

---

## Installation Steps

### Android Icons

1. **Locate** the generated icon folders:
   - `mipmap-mdpi` (48x48)
   - `mipmap-hdpi` (72x72)
   - `mipmap-xhdpi` (96x96)
   - `mipmap-xxhdpi` (144x144)
   - `mipmap-xxxhdpi` (192x192)

2. **Copy** icons to your project:
   ```
   android/app/src/main/res/mipmap-mdpi/ic_launcher.png
   android/app/src/main/res/mipmap-hdpi/ic_launcher.png
   android/app/src/main/res/mipmap-xhdpi/ic_launcher.png
   android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png
   android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png
   ```

3. **Replace** existing `ic_launcher.png` files in each folder

4. **Also replace** `ic_launcher_round.png` if it exists

### iOS Icons (if doing iOS)

1. **Locate** generated iOS icons
2. **Open** `ios/Runner/Assets.xcassets/AppIcon.appiconset/`
3. **Replace** all icon files with generated ones
4. **Keep** the `Contents.json` file

---

## Icon Design Tips

### Best Practices
- ✅ **Simple**: Works at small sizes (16x16 to 192x192)
- ✅ **Recognizable**: Users can identify your app quickly
- ✅ **Consistent**: Matches your app's design theme
- ✅ **High Contrast**: Visible on different backgrounds
- ✅ **No Text**: Text becomes unreadable at small sizes

### What to Avoid
- ❌ Too much detail (gets lost at small sizes)
- ❌ Thin lines (disappear at small sizes)
- ❌ Complex gradients (may not render well)
- ❌ Text (unreadable at small sizes)
- ❌ Copyrighted images

---

## Testing Your Icons

### After Installation

1. **Clean build**:
   ```powershell
   flutter clean
   flutter pub get
   ```

2. **Rebuild app**:
   ```powershell
   flutter run
   ```

3. **Check**:
   - App icon appears on home screen
   - Icon looks good at different sizes
   - Icon is not pixelated
   - Icon matches your app's theme

---

## Icon Sizes Reference

### Android
- **mdpi**: 48x48 pixels
- **hdpi**: 72x72 pixels
- **xhdpi**: 96x96 pixels
- **xxhdpi**: 144x144 pixels
- **xxxhdpi**: 192x192 pixels

### iOS
- **20pt**: 20x20, 40x40, 60x60
- **29pt**: 29x29, 58x58, 87x87
- **40pt**: 40x40, 80x80, 120x120
- **60pt**: 120x120, 180x180
- **1024pt**: 1024x1024 (App Store)

---

## Quick Start (No Logo Yet)

1. **Go to**: https://www.flaticon.com
2. **Search**: "calendar booking appointment"
3. **Download**: Free icon (1024x1024 if available)
4. **Use**: https://appicon.co to generate all sizes
5. **Install**: Follow steps above
6. **Update later**: When you have your final logo

---

## Resources

- **AppIcon.co**: https://appicon.co (Icon generator)
- **Icon Kitchen**: https://icon.kitchen (Icon generator)
- **Flaticon**: https://www.flaticon.com (Free icons)
- **Canva**: https://www.canva.com (Design tool)
- **Figma**: https://www.figma.com (Design tool)

---

**Remember**: You can always update your icon later. Start with something simple and improve it over time!
