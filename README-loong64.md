# SiYuan LoongArch64 原生构建

在 LoongArch64 上原生编译 SiYuan 桌面端（Go 内核 + 前端 + Electron 打包）。

## 依赖

- 系统包：`go`、`nodejs`、`pnpm`、`gcc`/`g++`、`ar`、`tar`、`bsdtar`、`patchelf`
- 网络：
  - Electron loong64 运行时：`darkyzhou/electron-loong64` 的 `v43.7.7` 产物，解压后目录通过 `ELECTRON_DIST` 指定
  - OCR：`onnxruntime-cpu`（Arch loong64 仓库）与 PP-OCRv6 模型（HuggingFace）
  - pandoc：Debian loong64 构建的 `pandoc` 及其动态库
  - Go 模块与 npm 依赖：脚本默认走国内镜像，可用 `GOPROXY`、`NPM_REGISTRY` 覆盖

## 构建

```bash
export ELECTRON_DIST=$PWD/electron-v43.7.7-linux-loong64
scripts/loong64/ocr.sh       # OCR 运行时 + worker + 模型
scripts/loong64/pandoc.sh    # pandoc-linux-loong64.zip
scripts/loong64/build.sh     # 内核 + 前端 + linux-unpacked
scripts/loong64/package.sh   # deb + tar.gz
scripts/loong64/pkg.sh       # Arch Linux 包（需 makepkg）
```

`build.sh` 会自动调用 `ocr.sh` 与 `pandoc.sh`，单独执行便于排查资源问题。

## 产物

- `app/build/linux-unpacked/`
- `app/build/siyuan-<version>-linux-loong64.tar.gz`
- `app/build/siyuan_<version>_loong64.deb`
- `app/build/siyuan-<version>-<rel>-loong64.pkg.tar.zst`

## 说明

- 内核使用本机 cgo 编译（`fts5 sqlcipher`，静态 PIE）。
- OCR：`stage/ocr/runtime/linux-loong64` 内含 `libonnxruntime.so` 与 `siyuan-ocr` worker；内核按 `GOOS-GOARCH` 查找。
- pandoc：3.11（Debian loong64），已内置 `liblua5.4`、`libyaml`、`libgmp`、`libffi`、`libnuma` 并设置 rpath，要求 glibc ≥ 2.38。
- `go-ole` 缺少 loong64 支持，补丁版本放在 `third_party/go-ole`，经 `kernel/go.mod` 的相对 replace 引入。
- Electron 使用 43.7.7（loong64 当前可用版本），低于上游声明的 44.x。
- electron-builder 不支持 loong64 架构，因此以 `--linux dir --x64` 配合 `electronDist` 生成目录，再手工构造 `Architecture: loong64` 的 deb 与 tar.gz。
