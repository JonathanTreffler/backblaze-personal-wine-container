# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## 1.6.1 - 2024-01-26

### Changed
- Updated known-good Backblaze version to 9.0.1.763

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

[Unreleased]: https://github.com/JonathanTreffler/backblaze-personal-wine-container/compare/v1.0...HEAD
