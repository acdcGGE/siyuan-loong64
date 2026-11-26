# SiYuan LoongArch64 构建

交叉编译 LoongArch64 版 SiYuan 桌面端（Go 内核 + 前端 + Electron 打包）。

## 依赖

- 系统包：`go`、`nodejs`、`pnpm`、`loongarch64-linux-gnu-gcc/g++`、`ar`、`tar`
- 网络：
  - Electron loong64 运行时：`darkyzhou/electron-loong64` 的 `v43.7.7` 产物，解压后目录通过 `ELECTRON_DIST` 指定
  - Go 模块与 npm 依赖：脚本默认走国内镜像，可用 `GOPROXY`、`NPM_REGISTRY` 覆盖

## 构建

```bash
export ELECTRON_DIST=$PWD/electron-v43.7.7-linux-loong64
scripts/loong64/build.sh     # 内核 + 前端 + linux-unpacked
scripts/loong64/package.sh   # deb + tar.gz
```

## 产物

- `app/build/linux-unpacked/`
- `app/build/siyuan-<version>-linux-loong64.tar.gz`
- `app/build/siyuan_<version>_loong64.deb`

## 说明

- 内核使用 cgo 交叉编译（`fts5 sqlcipher`，静态 PIE）。
- `go-ole` 缺少 loong64 支持，补丁版本放在 `third_party/go-ole`，经 `kernel/go.mod` 的相对 replace 引入。
- 上游未提供 loong64 的 OCR 运行时与 pandoc，打包时通过 `LOONG64_SKIP_OCR`、`LOONG64_SKIP_PANDOC` 跳过，OCR 与依赖 pandoc 的导出功能不可用。
- Electron 使用 43.7.7（loong64 当前可用版本），低于上游声明的 44.x。
- electron-builder 不支持 loong64 架构，因此以 `--linux dir --x64` 配合 `electronDist` 生成目录，再手工构造 `Architecture: loong64` 的 deb 与 tar.gz。
