<p align="center">
  <img src="assets/Picture-House.png" alt="Picture House icon" width="160">
</p>

# Picture House

A film library for the films on your NAS: posters, film info, cast, collections, stats, and your own watched history and ratings, in a PowerShell/WPF window on your PC.

![Version](https://img.shields.io/badge/version-v1.02-blue) ![Platform](https://img.shields.io/badge/platform-Windows-0078D6) ![PowerShell](https://img.shields.io/badge/PowerShell-5.1-5391FE) ![Licence](https://img.shields.io/badge/licence-MIT-green) ![Last commit](https://img.shields.io/github/last-commit/jason4bury/Picture-House)

## ✨ Features

Picture House reads your film folders over the network and turns them into a browsable, searchable library. It's a single PowerShell script with a WPF interface.

- **Library**: a poster wall or list, grouped by shelf, decade, letter or genre. Filter by unwatched, favourites, watchlist, genre, decade or quality. Search finds titles, people and genres.
- **Film panel**: backdrop, plot, cast and crew, trailer, TMDb/IMDb links, awards, your star rating, notes, watched / favourite / watchlist, play history, Fix match and Move to shelf.
- **Collections**: every franchise you own part of, with what you have, what's missing, and one click to send the gaps to Radarr or Seerr. Also lists every Oscar Best Picture and BAFTA Best Film winner.
- **Tonight's Pick**: roll a 3D dice for a film, narrowed by shelf, length, era and unwatched / watchlist / favourites, with three runners-up.
- **People**: browse by actor or director, with photos, biographies, the films of theirs you don't have yet, and how complete your collection of each person's films is.
- **Coming soon**: films Radarr is waiting for, with cinema, digital and disc release dates.
- **Award winners**: your Oscar, BAFTA and Golden Globe winners and nominees, from Wikidata.
- **Health**: missing info or posters, names without years, doubtful matches, duplicates, SD copies, split and loose files, and a Radarr comparison.
- **Upgrades**: copies below 1080p or 4K, and duplicates. **Choose a copy…** lists every release your indexers have (size, quality, seeders) so you pick the download. Nothing happens automatically and nothing is ever deleted.
- **Stats**: charts, top lists and **Year in review**, which you can export as a web page.
- **Utilities**: web catalogue, printable list (print or save as PDF), CSV and health report exports, back up and restore, and moving your watched history and settings to another PC.

## 📋 Requirements

- Windows 10 or 11.
- Windows PowerShell 5.1 (built into Windows) with .NET Framework 4.7.2 or later.
- Your films in folders on a NAS or network share (or a local drive).
- A free [TMDb API key](https://www.themoviedb.org/settings/api) for film info and artwork.
- Optional: [Radarr](https://radarr.video/) and [Seerr](https://github.com/seerr-team/seerr) for adding and requesting films, and [Zoom Player](https://www.inmatrix.com/) or any other video player for playback.

## 📦 Installation

1. Download `Picture-House-v1.02.zip` from the [latest release](../../releases/latest) and unzip it wherever you like to keep it.
2. Double-click **Picture House.cmd** in the unzipped folder. It makes a **Picture House** shortcut there and in the Start menu, and starts Picture House. From then on, use the shortcut, the Start menu or a pinned taskbar button.

Nothing is installed and no Windows settings are changed. The shortcut runs the script with PowerShell's execution policy bypassed for that run only.

**From the repo:** clone it, or download it as a zip. If you download a zip, right-click it, choose **Properties** and tick **Unblock** *before* unzipping, so Windows doesn't block the scripts. Then double-click **Start-PictureHouse.cmd**.

**Updating from v1.00 (the exe):** unzip the new release, double-click **Picture House.cmd**, and delete `Picture House v1.00.exe` and any shortcut to it. Your films, settings and watched history are in `%APPDATA%\Picture House\`, so they carry straight over.

### Why no exe

Home tools used to ship as PS2EXE exes, and antivirus programs (ESET among them) kept flagging those exes as generic trojans by mistake. A plain script and a shortcut give the same one-click start without the false alarms, and you can read exactly what runs.

### Build a release

Double-click **Build.cmd** in the repo folder. It reads `build.json`, checks every script for syntax errors and that `$AppVersion` matches the newest `CHANGELOG.md` entry, runs PSScriptAnalyzer if it's installed, copies the release files into `..\Builds\Picture House v<version>\`, zips that folder for the GitHub release, refreshes `..\Builds\Picture House.lnk` (what the Home Launcher starts) and scans the result with ESET's command-line scanner if it's installed.

## 🚀 Usage

1. Start Picture House (the shortcut, the Start menu, **Picture House.cmd**, or **Start-PictureHouse.cmd** in the repo). The first time, it opens on **Settings**.
2. Add the folder that holds your films, e.g. `\\NAS\video\Films`, and press **Save and rescan**.
3. Paste your TMDb API key, press **Save settings**, then **Fetch missing film info** in the left rail.

If it doesn't open, run `"Picture House.cmd" debug` from a command prompt in the release folder to see any errors in that window (in the repo, run **Start-PictureHouse-Debug.cmd**: everything it prints goes to `console-debug.log` in the data folder). Start-up problems are also written to `picture-house.log` there.

The **Help** button in the app explains every page. Keys: Ctrl+F search, F5 rescan, Esc clear search, Ctrl+P play the open film.

### How your folders become shelves

```
\\NAS\video\Films              <- the folder you add in Settings
├── Action                     <- shelf
│   ├── The Matrix (1999)      <- film (one folder per film)
│   └── Marvel                 <- sub-shelf
│       └── Iron Man (2008)
├── Comedy
│   └── Airplane.1980.720p.mkv <- loose files work too
└── Kids
    └── Toy Story (1995)
        └── VIDEO_TS           <- DVD / Blu-ray folder rips are recognised
```

Picture House also understands:

- `{tmdb-603}`, `[tmdbid-603]` and `tt0133093` tags in names, and `{edition-…}`
- CD1/CD2 split films and ISOs
- `.nfo`, `poster.jpg` and `fanart.jpg` files written by Radarr, Jellyfin, Plex or Kodi

Synology `@eaDir` folders are skipped, as is any folder listed under **Settings → Folders to ignore** (`Intros` and `Seerr` by default).

## ⚙️ Configuration

Everything is set in the app under **Settings**: NAS folders, TMDb key and language, Radarr and Seerr addresses and keys, video player, folders to ignore and file types.

**Where settings live:** everything Picture House stores is in `%APPDATA%\Picture House\`: settings and API keys, the film list, cached artwork, your ratings, notes and watched history, logs, exports and backups. **Utilities → Open data folder** takes you there. It stays on your PC and is never inside the repo, the release folder or the `Builds\` folder.

**Upgrading from 1.3.x or earlier:** those versions kept everything in a `Data` folder beside the script. The first time v1.00 starts, it copies that folder to `%APPDATA%\Picture House\` and renames the old one `Data (moved to AppData)`. Once you've checked everything is there, you can delete the old folder.

**Privacy:**

- Your NAS is only ever read, with one exception: **Move to shelf**, which you confirm each time and which only moves a film within the same share. Picture House never deletes films.
- Backups and "Send to my other PC" files can include your API keys. Keep them private.

## 📝 Changelog

See [CHANGELOG.md](CHANGELOG.md). The same list is in the app under **Settings → Version history**. Changes before v1.00 are in [docs/HISTORY-before-1.00.md](docs/HISTORY-before-1.00.md).

## 📄 Licence

[MIT](LICENSE). Copyright (c) 2026 Jason Rhodes.

Created by Jason Rhodes, built with Claude (Anthropic).

- Film information and images from [TMDb](https://www.themoviedb.org/). *This product uses the TMDB API but is not endorsed or certified by TMDB.*
- Award data from [Wikidata](https://www.wikidata.org/) (CC0).
- Works with [Radarr](https://radarr.video/) and [Seerr](https://github.com/seerr-team/seerr).
