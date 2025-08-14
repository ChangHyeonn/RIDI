#!/bin/bash

echo "🧹 iOS 빌드 캐시 정리 중..."

# Flutter 캐시 정리
flutter clean
flutter pub get

# iOS 빌드 캐시 정리
cd ios
rm -rf Pods
rm -rf Podfile.lock
rm -rf .symlinks
rm -rf Flutter/Flutter.framework
rm -rf Flutter/Flutter.podspec
rm -rf Flutter/Generated.xcconfig

# Xcode 캐시 정리
rm -rf ~/Library/Developer/Xcode/DerivedData
rm -rf ~/Library/Caches/com.apple.dt.Xcode

# Pod 재설치
pod deintegrate
pod cache clean --all
pod install --repo-update

echo "✅ iOS 빌드 캐시 정리 완료!"
echo "이제 다음 명령어로 빌드해보세요:"
echo "flutter build ios --debug"

