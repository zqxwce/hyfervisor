# hyfervisor

Apple Silicon Mac에서 macOS 커널을 live debugging 할 수 있는 가상화 도구

Apple이 지원하지 않는 커널 라이브 디버깅을 리눅스 QEMU처럼 사용 가능

- 직접 빌드한 XNU 커널과 직접 만든 kext 함께 부팅가능
- KASAN 커널 부팅 지원
- breakpoint를 통한 커버리지 확인 가능(불안정하고 느림)
- gui 1TR 접근 가능

## Screenshots

![Menu](image/menu.png)
![Menu2](image/menu2.png)
![Menu3](image/menu3.png)
![Custom Kernel](image/custom_kernel.png)
![Custom Kext](image/custom_kext.png)
![KASAN Kernel Boot](image/kasan_kernel_boot.png)
![Debug KASAN](image/debug_kasan.png)
![Coverage Check](image/coverage_check.png)

## Features

- macOS 가상머신 실행
- 하드웨어 가속 (CPU, 메모리, 그래픽, 네트워크, 오디오)
- GDB 디버그 스텁 지원
- 커스텀 커널/Kext 로딩

## Requirements

- Apple Silicon Mac (M1/M2/M3/M4)
- macOS 12.0 이상

## Build

```bash
# 전체 빌드
make all

# 설치 도구
make hyfervisor-InstallationTool-Objective-C

# 메인 앱
make hyfervisor-Objective-C

# 클린
make clean
```

## Usage

```bash
# 1. VM 설치
./build/Build/Products/Release/hyfervisor-InstallationTool-Objective-C <ipsw path>

# 2. 앱 실행
open build/Build/Products/Release/hyfervisor-Objective-C.app
```

---

![hyfervisor 1](image/hyfer1.jpeg)
![hyfervisor 2](image/hyfer2.jpeg)
![hyfervisor 3](image/hyfer3.jpeg)
