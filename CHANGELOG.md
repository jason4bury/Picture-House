# Changelog

All notable changes to this project are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), with versions numbered
`<major>.<minor>` and a two-digit minor (v1.00, v1.01 ... v1.10) to match the release names.
The same list is in the app under **Settings → Version history**.

## [Unreleased]

## [1.03] - 2026-11-19

### Added
- **A dark look.** Settings has a new **Look** card: **Light** (the cream look, as before, and the
  default), **Dark**, or **Follow Windows**. In the dark look the paper, cards, lines and text go
  dark in every window, chart and dialog, with a dark title bar; the teal header bands, the red
  buttons, the cream text on them and the shelf colours stay the same. The look is chosen when
  Picture House starts, so a change shows the next time it starts. Exports (web catalogue,
  reports, printable list) keep the cream look.

### Changed
- Tick boxes, option buttons, lists, tables and the Settings fields take their text colour from the
  look instead of Windows' default black.
- Version history (Settings) notes what's new in 1.03.

## [1.02] - 2026-11-18

### Changed
- **Messages and questions in Picture House's own look.** Every message and Yes/No question
  (about 100 of them) used Windows' plain grey message box. They now open in a Picture House
  window: cream background, teal header band, a coloured badge (teal for information, amber for a
  warning, dark teal for a question) and the app's red and cream pill buttons. Enter presses the
  red button and Esc the other one.
- They open over whichever Picture House window is in front (for example **Fix match** or
  **Choose a copy**), not always over the main window, and the text can be selected and copied.
- **Clear all data** asks about a backup with plain buttons (**Back up, then clear**,
  **Clear without a backup**, **Don't clear anything**) instead of Yes / No / Cancel.
- **Web catalogue** asks **Put posters in the file** or **Load posters from TMDb** instead of
  Yes / No, and has a **Cancel** button.
- The one-time warning if moving your old `Data` folder fails uses the same window.

Kept as they were: Windows' own Open, Save and folder pickers, and the plain box that says
Picture House couldn't open (it has to work even when the window can't be built).

## [1.01] - 2026-11-16

### Changed
- **No exe any more.** Antivirus programs (ESET among them) kept flagging the PS2EXE exe as a
  generic trojan by mistake, so Picture House now ships as its script, like the other Home tools.
  The release is `Picture-House-v1.01.zip`: unzip it and double-click **Picture House.cmd**, which
  makes a **Picture House** shortcut in that folder and in the Start menu and starts Picture House
  without a console window. `"Picture House.cmd" debug` starts it in a console to show any errors.
- **Build.cmd** replaces `Build-Exe.cmd` and `Build-Exe.ps1`. It checks the scripts and the
  version, runs PSScriptAnalyzer, makes `..\Builds\Picture House v<version>\` and its zip, refreshes
  `..\Builds\Picture House.lnk` for the Home Launcher and scans the build with ESET.
  `build.json` lists the release files.
- The window and taskbar icon come from `assets\Picture-House.ico` (sharp at every size), and
  Picture House sets its own taskbar ID, so its taskbar button shows its icon and pinning it pins
  Picture House rather than PowerShell. If the icon file is missing it's drawn as before.
- Restart after **Restore from backup** or **Bring in…** uses the Picture House shortcut, and no
  longer looks for an exe.

### Removed
- The exe-only code (finding the folder and restarting from the exe).

Your data stays in `%APPDATA%\Picture House\`; nothing moves.

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
