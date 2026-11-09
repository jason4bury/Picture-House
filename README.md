<p align="center">
  <img src="assets/Picture-House.png" alt="Picture House icon" width="160">
</p>

# Picture House

A film library for the films on your NAS: posters, film info, cast, collections, stats, and your own watched history and ratings, in a PowerShell/WPF window on your PC.

![Version](https://img.shields.io/badge/version-v1.00-blue) ![Platform](https://img.shields.io/badge/platform-Windows-0078D6) ![PowerShell](https://img.shields.io/badge/PowerShell-5.1-5391FE) ![Licence](https://img.shields.io/badge/licence-MIT-green) ![Last commit](https://img.shields.io/github/last-commit/jason4bury/Picture-House)

## ✨ Features

Picture House reads your film folders over the network and turns them into a browsable, searchable library. It's a single PowerShell script with a WPF interface, and you can build it into an exe.

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

**Exe:** download `Picture House v1.00.exe` from the [latest release](../../releases/latest) and run it. Nothing else to install.

**Script:** clone the repo, or download it as a zip. If you download a zip, right-click it, choose **Properties** and tick **Unblock** *before* unzipping, so Windows doesn't block the scripts. Then double-click **Start-PictureHouse.cmd**.

### Build the exe

Builds use the standard build script, which reads `build.json`, runs PSScriptAnalyzer, compiles the exe with [PS2EXE](https://github.com/MScholtes/PS2EXE) and saves it to the project's `Builds\` folder (outside the repo) as `Picture House v<version>.exe`:

```powershell
E:\Created\_shared\Build-Tool.ps1 -Project "E:\Created\Home\Picture-House"
```

Until the shared build script is in place, double-click **Build-Exe.cmd** in the repo folder instead:

- It checks this PC first: Windows, PowerShell 5.1, .NET Framework, the C# compiler, WPF, free space, that Picture House is closed, that `CHANGELOG.md` has an entry for the version, and PS2EXE. Anything missing is listed with what to do.
- It installs PS2EXE for your user account the first time, which needs internet access to the PowerShell Gallery.
- It saves `..\Builds\Picture House v<version>.exe` and can add a desktop shortcut. Older builds stay alongside.
- `assets\Picture-House.ico` is used as it is. Run `Build-Exe.cmd -RedrawIcon` to remake it at every size from 16 to 256 px from the same code the app uses for its window and taskbar icon.

The version comes from `$AppVersion` at the top of the script, which matches the newest CHANGELOG entry. Some antivirus programs flag PS2EXE executables by mistake. If the exe disappears straight after building, restore it from quarantine and add an exclusion for the `Builds` folder.

## 🚀 Usage

1. Start Picture House (the exe, or **Start-PictureHouse.cmd**). The first time, it opens on **Settings**.
2. Add the folder that holds your films, e.g. `\\NAS\video\Films`, and press **Save and rescan**.
3. Paste your TMDb API key, press **Save settings**, then **Fetch missing film info** in the left rail.

If it doesn't open, run **Start-PictureHouse-Debug.cmd**: everything it prints goes to `console-debug.log` in the data folder. Start-up problems are also written to `picture-house.log` there.

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

**Where settings live:** everything Picture House stores is in `%APPDATA%\Picture House\`: settings and API keys, the film list, cached artwork, your ratings, notes and watched history, logs, exports and backups. **Utilities → Open data folder** takes you there. It stays on your PC and is never inside the repo or the `Builds\` folder.

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
- The exe is built with [PS2EXE](https://github.com/MScholtes/PS2EXE).
