# Snap Flutter SDK fix

## Summary

Fixed snap build failure (`flutter: command not found`) by cloning the Flutter SDK into the location the snapcraft flutter plugin expects during `override-pull`.

## Root cause

The snapcraft `flutter` plugin sets `PATH=<part_build_dir>/flutter-distro/bin:$PATH` via `get_build_environment`, but only creates the `flutter-distro` directory inside its default `get_build_commands()`. The custom `override-build` replaced those commands entirely, so Flutter was never installed and the `flutter` binary was not on PATH.

## Changes

- `snap/snapcraft.yaml`:
  - `override-pull`: after tar extract, clone Flutter SDK 3.44.4 (matching FVM pin) into `flutter-distro`, run `flutter precache --linux` and `flutter pub get`.
  - `override-build`: kept lean, now only runs `flutter build linux --release --target lib/main.dart --dart-define-from-file env.json` and copies the bundle. Flutter resolves on PATH via the plugin's env setup pointing at `flutter-distro/bin`.

## Files

- `snap/snapcraft.yaml` (edited)

## Verification

Rebuild with `snapcraft` (or `snapcraft --debug` to shell in on failure). Pull stage should clone Flutter 3.44.4 and precache Linux artifacts; build stage should run `flutter build linux` successfully.