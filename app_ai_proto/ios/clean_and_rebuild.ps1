Write-Host "🧹 iOS 빌드 캐시 정리 중..." -ForegroundColor Green

# Flutter 캐시 정리
Write-Host "Flutter 캐시 정리 중..." -ForegroundColor Yellow
flutter clean
flutter pub get

# iOS 빌드 캐시 정리
Write-Host "iOS 빌드 캐시 정리 중..." -ForegroundColor Yellow
Set-Location ios

# 기존 파일들 삭제
if (Test-Path "Pods") { Remove-Item -Recurse -Force "Pods" }
if (Test-Path "Podfile.lock") { Remove-Item -Force "Podfile.lock" }
if (Test-Path ".symlinks") { Remove-Item -Recurse -Force ".symlinks" }
if (Test-Path "Flutter/Flutter.framework") { Remove-Item -Recurse -Force "Flutter/Flutter.framework" }
if (Test-Path "Flutter/Flutter.podspec") { Remove-Item -Force "Flutter/Flutter.podspec" }
if (Test-Path "Flutter/Generated.xcconfig") { Remove-Item -Force "Flutter/Generated.xcconfig" }

# Xcode 캐시 정리 (macOS에서만)
if ($IsMacOS -or $env:OS -eq "Darwin") {
    Write-Host "Xcode 캐시 정리 중..." -ForegroundColor Yellow
    if (Test-Path "$env:HOME/Library/Developer/Xcode/DerivedData") {
        Remove-Item -Recurse -Force "$env:HOME/Library/Developer/Xcode/DerivedData"
    }
    if (Test-Path "$env:HOME/Library/Caches/com.apple.dt.Xcode") {
        Remove-Item -Recurse -Force "$env:HOME/Library/Caches/com.apple.dt.Xcode"
    }
}

# Pod 재설치
Write-Host "Pod 재설치 중..." -ForegroundColor Yellow
pod deintegrate
pod cache clean --all
pod install --repo-update

Write-Host "✅ iOS 빌드 캐시 정리 완료!" -ForegroundColor Green
Write-Host "이제 다음 명령어로 빌드해보세요:" -ForegroundColor Cyan
Write-Host "flutter build ios --debug" -ForegroundColor White

