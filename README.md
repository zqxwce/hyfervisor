# hyfervisor

Virtualization tool for live-debugging the macOS kernel on Apple Silicon Macs

Lets you live-debug kernels Apple doesn’t officially support, similar to QEMU on Linux

- Boot a self-built XNU kernel alongside custom kexts
- Supports booting KASAN kernels
- Can check coverage via breakpoints (unstable and slow)
- GUI access to 1TR

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

- Run macOS virtual machines
- Hardware acceleration (CPU, memory, graphics, networking, audio)
- GDB debug stub support
- Load custom kernels/kexts

## Requirements

- Apple Silicon Mac (M1/M2/M3/M4/M5)
- macOS 12.0 or later

## Build

```bash
# Full build
make all

# Installation tool
make hyfervisor-InstallationTool-Objective-C

# Main app
make hyfervisor-Objective-C

# Clean
make clean
```

## Usage

```bash
# 1. Install the VM
./build/Build/Products/Release/hyfervisor-InstallationTool-Objective-C <ipsw path> [vm bundle path]

# 2. Launch the app
open build/Build/Products/Release/hyfervisor.app
# or from CLI with a custom bundle path:
# open build/Build/Products/Release/hyfervisor.app --args /path/to/VM.bundle
```

Pass an explicit VM bundle path if you want the VM artifacts somewhere other than `~/VM.bundle`.
You can supply the path as the second argument to the installer and as the first argument to `hyfervisor.app` (via `--args`) so both tools operate on the same VM bundle.

---

![hyfervisor 1](image/hyfer1.jpeg)
![hyfervisor 2](image/hyfer2.jpeg)
![hyfervisor 3](image/hyfer3.jpeg)
