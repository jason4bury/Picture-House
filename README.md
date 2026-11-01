<img src="docs/icon.png" alt="Picture House icon" width="96" align="right">

# Picture House

**A film library for the films on your NAS.** Picture House runs on your Windows PC, reads your film folders over the network and turns them into a browsable, searchable library: posters, film info, cast, collections, stats, and your own watched history and ratings.

![Version](https://img.shields.io/badge/version-1.3.1-173F3E)
![Platform](https://img.shields.io/badge/platform-Windows%2010%20%7C%2011-2A4A6B)
![PowerShell](https://img.shields.io/badge/PowerShell-5.1-5391FE)
![License](https://img.shields.io/badge/license-MIT-C8432B)

It is a single PowerShell script with a WPF interface. There's nothing to install, and you can optionally build it into an `.exe`.

<!-- Screenshots: add images to docs/ and link them here, e.g. ![Library](docs/library.png) -->

## Features

| | |
|---|---|
| **Library** | Poster wall or list, grouped by shelf, decade, letter or genre. Filter by unwatched, favourites, watchlist, genre, decade or quality. Search finds titles, people and genres. |
| **Film panel** | Backdrop, plot, cast & crew, trailer, TMDb/IMDb links, awards, your star rating, notes, watched / favourite / watchlist, play history, Fix match, Move to shelf. |
| **Collections** | Every franchise you own part of: what you have, what's missing, and one click to send the gaps to Radarr or Seerr. Also lists every Oscar Best Picture and BAFTA Best Film winner. |
| **Tonight's Pick** | Roll a 3D dice for a film, narrowed by shelf, length, era and unwatched / watchlist / favourites, with three runners-up. |
| **People** | Browse by actor or director. Photos, biographies and the films of theirs you don't have yet, plus how complete your collection of each person's films is. |
| **Coming soon** | Films Radarr is waiting for, with cinema, digital and disc release dates. |
| **Award winners** | Your Oscar, BAFTA and Golden Globe winners and nominees, from Wikidata. |
| **Health** | Missing info or posters, names without years, doubtful matches, duplicates, SD copies, split and loose files, and a Radarr comparison. |
| **Upgrades** | Copies below 1080p or 4K and duplicates. **Choose a copy…** lists every release your indexers have (size, quality, seeders) so you pick the download. Nothing happens automatically and nothing is ever deleted. |
| **Stats** | Charts, top lists and **Year in review**, which you can export as a web page. |
| **Utilities** | Web catalogue, printable list (print or save as PDF), CSV and health report exports; back up and restore; move your watched history and settings to another PC. |

## Requirements

- Windows 10 or 11
- Windows PowerShell 5.1 (built into Windows) with .NET Framework 4.7.2 or later
- Your films in folders on a NAS or network share (or a local drive)
- A free [TMDb API key](https://www.themoviedb.org/settings/api) for film info and artwork
- Optional: [Radarr](https://radarr.video/) and [Seerr](https://github.com/seerr-team/seerr) for adding and requesting films, and [Zoom Player](https://www.inmatrix.com/) or any other video player for playback

## Getting started

1. Download the latest release, or clone this repository, into a folder on your PC (for example `E:\Picture House`).
2. If you downloaded a zip: right-click it → **Properties** → tick **Unblock** *before* unzipping, so Windows doesn't block the scripts.
3. Double-click **Start-PictureHouse.cmd**.
4. Picture House opens on **Settings**. Add the folder that holds your films, e.g. `\\NAS\video\Films`, and press **Save and rescan**.
5. Paste your TMDb API key, press **Save settings**, then **Fetch missing film info** in the left rail.

If it doesn't open, run **Start-PictureHouse-Debug.cmd**: it keeps a console window open so you can see what went wrong. Start-up problems are also written to `Data\picture-house.log`.

## How your folders become shelves

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

## Build an exe (optional)

Double-click **Build-PictureHouseExe.cmd** to make `Picture House.exe` with the Picture House icon.

- It checks this PC first: Windows, PowerShell 5.1, .NET Framework, the C# compiler, WPF, free space, Picture House closed, and [PS2EXE](https://github.com/MScholtes/PS2EXE). Anything missing is listed with what to do.
- It installs PS2EXE for your user account the first time, which needs internet access to the PowerShell Gallery.
- It redraws `Picture House.ico` (included in the repository) at every size from 16 to 256 px, from the same code the app uses for its window and taskbar icon.
- The exe uses the same `Data` folder, so nothing is lost. Rebuild after each update.

Some antivirus programs flag PS2EXE executables by mistake. If the exe disappears straight after building, restore it from quarantine and add an exclusion for the folder.

## Your data and privacy

- Everything Picture House stores lives in the **Data** folder beside the script: settings, API keys, cached artwork, your ratings, notes and watched history. It stays on your PC.
- **Data is excluded from this repository** (see `.gitignore`). Never commit it: `settings.json` holds your API keys.
- Your NAS is only ever read, with one exception: **Move to shelf**, which you confirm each time and which only moves a film within the same share. Picture House never deletes films.
- Backups and "Send to my other PC" files can include your API keys. Keep them private.

## Credits

Created by Jason Rhodes, built with Claude (Anthropic).

- Film information and images from [TMDb](https://www.themoviedb.org/). *This product uses the TMDB API but is not endorsed or certified by TMDB.*
- Award data from [Wikidata](https://www.wikidata.org/) (CC0).
- Works with [Radarr](https://radarr.video/) and [Seerr](https://github.com/seerr-team/seerr).
- Exe builder uses [PS2EXE](https://github.com/MScholtes/PS2EXE).

## Changelog

See [CHANGELOG.md](CHANGELOG.md). The same list is in the app under **Settings → Version history**.

## License

[MIT](LICENSE) © 2026 Jason Rhodes
