# iOS 빌드 최적화 가이드

## 🚀 빌드 속도 개선 방법

### 1. 캐시 정리 및 재설치
```bash
# 스크립트 실행
chmod +x clean_and_rebuild.sh
./clean_and_rebuild.sh
```

### 2. 수동 캐시 정리
```bash
# Flutter 캐시 정리
flutter clean
flutter pub get

# iOS 캐시 정리
cd ios
rm -rf Pods Podfile.lock .symlinks
pod deintegrate
pod cache clean --all
pod install --repo-update
```

### 3. Xcode 설정 최적화
- **Product > Clean Build Folder** 실행
- **Window > Organizer**에서 오래된 아카이브 삭제
- **Preferences > Locations**에서 DerivedData 경로 확인

### 4. 빌드 명령어 최적화
```bash
# Debug 빌드 (빠름)
flutter build ios --debug

# Release 빌드 (최적화됨)
flutter build ios --release

# 특정 시뮬레이터용 빌드
flutter build ios --debug --simulator
```

### 5. Xcode에서 빌드 시 최적화
- **Build Settings > Swift Compiler - Optimization** 설정 확인
- **Build Settings > Enable Bitcode** = NO
- **Build Settings > Swift Compilation Mode** = wholemodule (Release)

### 6. 시스템 최적화
- macOS 업데이트
- Xcode 업데이트
- 충분한 디스크 공간 확보 (최소 10GB)
- RAM 8GB 이상 권장

## 🔧 적용된 최적화 설정

### Podfile 최적화
- `ENABLE_BITCODE = 'NO'`
- `SWIFT_COMPILATION_MODE = 'wholemodule'`
- `SWIFT_OPTIMIZATION_LEVEL` 최적화

### Xcode 설정 최적화
- Debug: `SWIFT_COMPILATION_MODE = singlefile`
- Release: `SWIFT_COMPILATION_MODE = wholemodule`
- `ENABLE_BITCODE = NO`

## 📊 예상 개선 효과
- **첫 빌드**: 30-50% 단축
- **재빌드**: 60-80% 단축
- **Pod 설치**: 40-60% 단축

## 🚨 주의사항
- 캐시 정리 후 첫 빌드는 여전히 시간이 걸릴 수 있습니다
- Release 빌드는 최적화를 위해 시간이 더 걸릴 수 있습니다
- 시뮬레이터 빌드가 실제 기기 빌드보다 빠릅니다

