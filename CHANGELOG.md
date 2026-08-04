# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Add an officially built Ubuntu 26.04 image under the `ubuntu26` tag

### Changed
- Pin and checksum the upstream winetricks script for reproducible image builds

### Fixed
- Exit after a failed initial installation instead of leaving an empty container running

## 2.1.1 - 2026-08-03

### Fixed
- Fail installer downloads on HTTP errors, retry transient failures, and reject
  responses that do not contain a Windows executable ([#267](https://github.com/JonathanTreffler/backblaze-personal-wine-container/pull/267))

## 2.1 - 2026-08-02

### Fixed
- Fix the ~0.7 Mbit/s per-connection upload slowdown affecting Backblaze client
  9.0.1 and later under Wine by shipping a patched, version-matched `wineserver`
  ([#130](https://github.com/JonathanTreffler/backblaze-personal-wine-container/discussions/130),
  [#186](https://github.com/JonathanTreffler/backblaze-personal-wine-container/issues/186))

## 2.0.1 - 2026-06-02

### Fixed
- Apply the supported-OS manifest to existing Wine prefixes so installations
  upgraded from v1.x can update to Backblaze client v10

## 2.0 - 2026-06-02

### Added
- Add an Ubuntu 24.04 image under the `ubuntu24` tag
- Add opt-in masking of NFS, SMB, and CIFS mounts so Backblaze can treat them as
  local fixed disks

### Changed
- Update to Wine 11 on Ubuntu 22.04 and Ubuntu 24.04
- Prepare the Wine prefix and .NET Framework 4.8 inside the image for faster and
  more reliable first-time installation
- Disable Wine's virtual desktop by default
- Rework Backblaze installation and update handling around the current upstream
  installer

### Removed
- Stop building the end-of-life Ubuntu 18.04 and Ubuntu 20.04 images
- Remove the obsolete pinned-installer mechanism; `FORCE_LATEST_UPDATE` remains
  accepted as a deprecated no-op

## 1.13 - 2025-02-24

### Fixed
- Fix a shell error introduced in version 1.12

## 1.12 - 2025-02-24

### Added
- Install .NET Framework 4.8 for the Backblaze installer

### Changed
- Update Wine to version 10
- Add `7zip` and `cabextract` as installer dependencies

## 1.11 - 2024-06-23

### Changed
- Install the current Backblaze release because the previous known-good installer
  is no longer available from the Internet Archive
- Disable automatic Backblaze updates by default

## 1.10 - 2024-06-16

### Changed
- Update known-good Backblaze version to 9.0.1.777
- Ubuntu 22 is now the default versioned image

## 1.9 - 2024-04-16

### Changed
- Try to prevent forced Backblaze client updates

## 1.8.1 - 2024-03-30

### Changed
- Optimize Dockerfiles to reduce layer count

## 1.8 - 2024-03-15

### Changed
- Update Backblaze automatically in the background
- Make startapp log file location configurable by an env var (#129, thanks @brokeh)

## 1.7.2 - 2024-02-23

### Changed
- Update known-good Backblaze version to 9.0.1.767
- Update Backblaze in the background 
- Mark ubuntu18 tag as "End of Life" and remove ubuntu18 specific troubleshooting from readme

## 1.7.1 - 2024-02-15

### Changed
- Set lower default values for DISPLAY_WIDTH and DISPLAY_HEIGHT

## 1.7 - 2024-02-13

### Added
- Automatically create symlinks for mounts (#110, thanks @xela1)
- Enable Wine Virtual Desktop mode by default

### Changed
- Updated known-good Backblaze version to 9.0.1.763
> [!NOTE]  
> Backblaze will automatically be updated to a known-good version mentioned above, if your installed version is older.
> This download of the new version may take some time, so you will only see a black screen until the download is finished. After that, the installer appears and you can update Backblaze by clicking on "install".
- Fix error `Make sure that your X server is running and that $DISPLAY is set correctly` when running basic CLI commands like `winecfg` by adding the DISPLAY environment variable to the Dockerfiles

## 1.6 - 2024-01-22

### Added
- Added backblaze client auto-update functionality to the docker (#88, thanks @traktuner)

### Changed
- By default a known-good version of the backblaze client will now be used
  - Can be overridden by adding the environment variable "FORCE_LATEST_UPDATE=true"
- The wine version in the Dockerfiles is now pinned to get more control over stability

## 1.5 - 2023-10-13
### Changed
- Dependency updates (see #18 (comment))

## 1.4 - 2023-03-22
### Changed
- Dependency updates

## 1.3 - 2023-01-11
### Changed
- Update README.md

## 1.2 - 2022-03-21
### Changed
- Fixed automated build

## 1.1 - 2022-03-21
### Added
- Ubuntu 18 based version to broaden compatibility

## 1.0 - 2022-03-05
### Added
- First versioned release
- Automatic docker build using Github Actions
- Initial platform support for linux/arm64
- Initial platform support for linux/arm/v7
- Initial platform support for linux/arm/v6

### Changed
- Updated Dependencies

[Unreleased]: https://github.com/JonathanTreffler/backblaze-personal-wine-container/compare/v2.1.1...HEAD
