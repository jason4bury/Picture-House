# Changelog

All notable changes to this project are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), with versions numbered
`<major>.<minor>` and a two-digit minor (v1.00, v1.01 ... v1.10) to match the exe file names.
The same list is in the app under **Settings → Version history**.

## [Unreleased]

## [1.00] - 2026-11-07
First release in the house style. Version numbers restart here; the history before this
(1.0.0 to 1.3.1) is kept in [docs/HISTORY-before-1.00.md](docs/HISTORY-before-1.00.md).

### Changed
- **Your data has moved** to `%APPDATA%\Picture House\` (settings and API keys, the film list,
  watched history, ratings, notes, the artwork cache, logs, exports and backups). The first
  time 1.00 starts it copies the old `Data` folder from beside the script or exe, then renames
  that folder `Data (moved to AppData)`. Nothing is deleted. Keeping the data out of the repo
  folder means it can never be committed, and rebuilding or updating can't touch it.
- **New repo layout.** The script is now `src/Picture-House.ps1`, the icon is
  `assets/Picture-House.ico`, and the old history is in `docs/`. Builds go to the project's
  `Builds\` folder, outside the repo.
- **Exe name.** Builds are now named `Picture House v<version>.exe`, e.g.
  `Picture House v1.00.exe`, and older builds stay alongside. `Build-Exe.cmd` replaces
  `Build-PictureHouseExe.cmd`. It also checks that `CHANGELOG.md` has an entry for the version
  being built, and it only redraws the icon when you ask (`-RedrawIcon`). It stays until the
  shared build script (`build.json`) takes over.
- The launchers (`Start-PictureHouse.cmd`, `Start-PictureHouse-Debug.cmd`) write their logs to
  `%APPDATA%\Picture House\`.
- **About window** shows the copyright and MIT licence. Version history in the app now starts
  at 1.00.
- Messages and help say where the data folder is, instead of `Data\…`. Help lists both
  default ignored folders (Intros and Seerr).

### Fixed
- **Move to shelf** with a loose file could take another film with it. A film named without
  a year (e.g. `Airplane.mkv`) treated `Airplane.II.1982.mkv` as one of its extras. Only
  non-video extras (subtitles, `.nfo`, artwork) now move with a film. If a move fails part-way,
  the files that had already moved are put back.
- Restarting after **Restore from backup** or **Bring in…** now finds `Start-PictureHouse.cmd`
  in the new layout.
- The debug launcher failed on a first run, before the `Data` folder existed, so it couldn't
  show why Picture House wasn't starting. It now creates the folder first and writes
  `console-debug.log`.
- Picture House no longer writes `Picture House.ico` into its own folder (which would have
  appeared as a new file in the repo). The shortcut copy is saved in the data folder.
