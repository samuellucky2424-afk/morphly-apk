# Native Platform Setup

Run this after Flutter is installed:

```sh
flutter create . --platforms=android,ios
flutter pub get
dart run flutter_native_splash:create
```

## Android

Add these permissions to `android/app/src/main/AndroidManifest.xml` if Flutter does not merge them from the local Decart plugin:

```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.RECORD_AUDIO" />
<uses-permission android:name="android.permission.READ_MEDIA_IMAGES" />
```

Use minSdk 24 or higher. Google Play Billing product IDs should match the `google_product_id` values in `credit_packages`.

## iOS

Add these keys to `ios/Runner/Info.plist`:

```xml
<key>NSCameraUsageDescription</key>
<string>Morphly uses the camera to create live AI morph previews.</string>
<key>NSMicrophoneUsageDescription</key>
<string>Morphly may use microphone access for realtime camera sessions.</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>Morphly lets you choose a reference image for AI morphing.</string>
<key>NSPhotoLibraryAddUsageDescription</key>
<string>Morphly can save generated morph outputs to your library.</string>
```

Configure StoreKit product IDs to match the `apple_product_id` values in `credit_packages`.

## Decart SDK Hook

The local Flutter plugin compiles as a bridge shell. Add the official Decart Android/iOS SDK dependencies in the plugin native folders and replace the marked production hooks with the realtime session setup from the Decart dashboard/docs.
