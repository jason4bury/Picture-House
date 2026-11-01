# Changelog

All notable changes to Picture House. The newest version is first.

The same list is in the app under **Settings → Version history**.

## [1.3.1]

- Restore from backup (Utilities): choose a backup and see what's in it — films, watched, rated, notes — next to what you have now, tick which parts to put back, and Picture House restarts with it. Your data as it was is saved first in Data\Backups, so you can always go back.
- Move to my other PC (Utilities): Send to my other PC makes one file with your watched history, ratings, notes, favourites, watchlist and settings (keys and film list optional). Bring in… on the other PC merges it — a film watched on either PC stays watched, and nothing on that PC is lost. Window size and other per-PC settings stay put.
- Printable list (Utilities): a tidy page of one shelf or the whole collection — choose all, not watched, watched, watchlist or favourites, how to sort, what each line shows, grouped by shelf, in two columns, with tick boxes. It opens in your browser to print or save as a PDF.
- Utilities is tidied into Export, Library, Your data and Housekeeping.
- Build-PictureHouseExe.cmd makes Picture House.exe with the Picture House icon (every size from 16 to 256 px). It checks first that the PC has everything the build needs and says what to do if not, keeps your old exe if anything goes wrong, and can add a desktop shortcut.

## [1.3.0]

- Its own icon: a teal film-strip tile with a cream "P" on the taskbar and title bar (instead of PowerShell's), saved as Picture House.ico for shortcuts too.
- A new About button (next to Settings) with the version and credits; this list is now called Version history.
- Smoother and tidier: talking to Radarr and Seerr now happens in the background (no more frozen window while they answer), the film panel keeps Play / Watched / Favourite / Watchlist up front with everything else under More ▾ (and every right-click menu now has the app's cream, rounded look), and the pop-up windows (Add to Radarr, Choose a copy, Fix match) match the app — teal header, red and cream buttons.
- Tidier: easier-to-read text under the posters, the film panel closes when you open Stats or Upgrades, Year in review shows a simple message until you've watched something, and Health points to Upgrades for SD copies and duplicates.
- Import it anyway: Picture House follows every copy you pick until Radarr swaps it in ("Your picks" on the Upgrades page). If Radarr downloads it but holds it back — e.g. "not an upgrade" — a card pops up with one button to import that file anyway. Your Radarr settings are never changed.
- Choose a copy: on the Upgrades page (and when you add a film to Radarr) you now pick the download yourself — every English-language copy your indexers have, with its size, quality, seeders and age, sortable and filterable by maximum size. Radarr only downloads the one you choose, and Picture House tells you when it reaches your download client.
- You can see what Radarr and Seerr did: a card pops up bottom-right when you add a film, request it or search for a better copy, and Picture House keeps an eye on Radarr afterwards — "Radarr found a 1080p copy… downloading now" or "nothing better yet". The Upgrades list shows the latest news on each film too.
- People: how complete are you? Every director and actor shows "You have 6 of the 14 films they directed" with a progress bar, the list shows "6 of 14" under each name, and Sort → Most complete puts the ones you're closest to finishing first.
- Award winners: a new shelf in the rail for your Oscar, BAFTA and Golden Globe winners and nominees (grouped), the awards listed in the film panel, and two new lists in Collections — every Oscar Best Picture and BAFTA Best Film winner, with the ones you're missing ready for Radarr or Seerr. From Wikidata, free and automatic.
- Upgrades & duplicates: a new tab listing copies below 1080p or 4K and films you have twice, with what Radarr's quality profile thinks of each. Nothing is automatic — "Search for a better copy" asks first and only searches for that one film.
- Stats → Year in review: your year in film — films watched, hours, favourite shelf and genre, busiest month, longest sit, your top rated, faces you saw most and every film in order. Export it as a web page to share.

## [1.2.34]

- Tooltips have a new look — a dark teal card with cream text, to match the app. Coming soon films show a tidy card: title, cinema / digital / disc dates, the shelf it will land on and the story.
- Coming soon: the posters no longer have COMING SOON / IN CINEMAS labels over them — the page title and the dates under each poster say it already.
- Search: people whose name matches (e.g. "helen") now appear in a strip above the films, with photo, actor or director and how many of your films they're in. Click one to open their page.
- The search box: what you type now starts exactly where the grey "Search titles, people, genres…" hint sits, instead of halfway along it.
- People no longer freezes for a few seconds the first time you open it — sorting actors from producers now uses a small index file, built in the background if it's missing.
- Opening: a small "Opening your film library…" card shows straight away so you know it's on its way, the window comes to the front when it's ready, and if something stops it opening you get a message instead of nothing.

## [1.2.33]

- People → Actors only lists actors and directors. Producers, writers and other crew who happen to have a small part in a film (TMDb says what each person is mainly known for) are left out.

## [1.2.32]

- Tonight's Pick: the dice looks like a proper cube again (less fish-eye), the pick sits in the middle of the stage with a bigger poster, and the small captions are easier to read.
- Tonight's Pick: the films-in-the-hat count is now a big red number in the middle of the header.
- Tonight's Pick: a Reset choices button (under the chips) puts shelf, length, era and "from" back to the start (and lets skipped films back in the hat).

## [1.2.31]

- Tonight's Pick: a bigger dice, and the films-in-the-hat count is now a bold badge so it's easy to see.

## [1.2.30]

- Tonight's Pick redesigned: click the 3D dice to roll for a film. One-click chips for shelf, length, era and where from (unwatched, watchlist, favourites or anything), a live count of films in the hat, and three "Or maybe" runners-up you can swap in. Rolling again skips the last pick.

## [1.2.29]

- Tonight's Pick: the genre filter has gone — pick by shelf, decade, running time and rating instead.

## [1.2.28]

- People: cast and crew details (photo, biography, birth date, other films) are now fetched automatically in the background — most-seen people first — so clicking someone shows their details straight away. Runs after film info is fetched and at start-up, refreshes every 90 days, and stops with Cancel.

## [1.2.27]

- Settings → Start again: two separate buttons. Clear all data: wipes Picture House's stored data (film list, info, posters, your watched history and ratings) as if no scan had been done (settings kept, offers a backup first). Clear settings: resets every setting to first-run (your films, info and watched history kept). Nothing on the NAS is touched by either.

## [1.2.26]

- Web catalogue: the film pop-up has proper buttons — TMDb ↗, Trailer ↗ and Close — instead of a plain link.

## [1.2.25]

- New Utilities tab: exports (web catalogue, CSV, health report), Refresh all film info, show hidden shelves, open the log, open the data folder — and Back up my data, which saves your watched history, ratings, notes and settings to one .zip.

## [1.2.24]

- Stats: the top lists sit four across on a wide screen, and their bars fill the card so the numbers sit next to them.

## [1.2.23]

- People lists every actor, not just those in two or more of your films.

## [1.2.22]

- Collections and People: the film title no longer shows through faded posters like a watermark — it only appears when there's no poster at all.

## [1.2.21]

- Collections are checked against TMDb automatically — at start-up, after new film info is fetched and when you open the tab (anything not checked for a week). ‘Check TMDb’ still forces a full refresh.

## [1.2.20]

- People → Directors now lists every director (the ‘2 or more films’ filter only applies to actors).

## [1.2.19]

- The empty ‘Choose a film’ panel no longer flashes up on the right when Picture House opens.

## [1.2.18]

- People: tidier ‘More films’ (no ‘not owned’ tags; buttons on one row), biographies without pronunciation guides, and the status bar no longer gets stuck on ‘Getting details…’.

## [1.2.17]

- People: clicking a cast member or director fetches their profile from TMDb — photo, biography, birth date and place, links — plus the other films of theirs you don't have yet, with + Radarr / Seerr buttons.

## [1.2.16]

- Click the poster in the film panel to see it big — the sharpest copy available (your NAS poster, or TMDb's full-resolution one).

## [1.2.15]

- Slim beige scrollbars throughout (no grey bar or arrow buttons); they widen a little when you hover over them.
- Dropdown lists open taller, so most fit without scrolling.

## [1.2.14]

- Removed the quality tag (1080p / 720p / SD) from the corner of each poster.

## [1.2.13]

- Easier-to-see progress: while scanning or fetching, the status bar shows a pill with what's running, a larger progress bar, the percentage and a Cancel button.

## [1.2.12]

- MKV files: picture quality is now read straight from the MKV itself (Windows can't read MKV details on its own).

## [1.2.11]

- Picture quality (4K / 1080p / 720p / SD) is now read from each video file itself during a scan, so the quality filter, Stats and Health know every film's real resolution. Results are remembered, so later scans only check new films.
- Library growth chart: month labels no longer overlap at the right-hand end.

## [1.2.10]

- Fixed: Stats charts didn't appear on Windows PowerShell 5.1.
- Fixed: the bars in the Stats top lists didn't show — only the numbers.
- Each chart is drawn on its own, so one problem can't blank the others (and any problem is logged in detail).

## [1.2.8]

- New dropdowns everywhere: rounded cream pills that open a soft list with a tick on the current choice. Filter dropdowns turn teal while a filter is in use.

## [1.2.7]

- The quality profile list stays put (even after a restart) — it only refreshes when you press ‘Load quality profiles’.

## [1.2.6]

- No more Root folder setting: when you send a film to Radarr, the box lists Radarr's folders (with free space) and you choose the genre folder each time.

## [1.2.5]

- Removed the Display setting — Picture House simply opens maximised at normal size.

## [1.2.4]

- Settings is laid out in columns — your library, online services and version info side by side on wide screens (two columns on smaller ones) — with the Save buttons at the top.
- The header above the posters refreshes once film info has been fetched.

## [1.2.2]

- The film panel stays out of the way until you click a poster, so the wall uses the full width.
- Poster rows now stretch to fill the width — no gap at the right.
- ‘Hours of film’ only shows once running times are known, with correct wording.
- The film-panel button (top right) now shows a proper icon.
- The Seerr folder on the NAS is ignored (Settings → Folders to ignore).

## [1.2.1]

- Graphics back to their normal size — still opens maximised. Settings → Display (or Ctrl + / Ctrl −) can still make everything bigger or smaller if you ever want it.

## [1.2.0]

- Opens maximised.
- Stats uses three chart columns when there's room.

## [1.1.0]

- Stats now has proper charts: a shelves donut, progress rings (watched, film info, HD, posters), films by decade, library growth over two years, TMDb ratings, running times, watched shelf-by-shelf and a picture-quality donut. Hover for numbers; click a slice, column or bar to jump to those films.

## [1.0.10]

- Folders to ignore (Settings): ‘Intros’ is skipped everywhere — never a shelf, film, Health item or export. Add more names, separated by commas.

## [1.0.9]

- Health: “Export HTML report” — a searchable web page of every issue, grouped with counts, ready to print.

## [1.0.8]

- Always opens on All films in the Library.

## [1.0.7]

- Coming soon: films Radarr is waiting for that aren't out yet, with cinema / digital / disc dates and a countdown, grouped by month.
- Health no longer flags the empty folders Radarr makes for unreleased films. Once a film's release date has passed and it still hasn't arrived, it shows as ‘Released — still missing’.

## [1.0.6]

- Opens much bigger — about 92% of the screen, centred (not full screen). If you resize it, your size is remembered.

## [1.0.5]

- “Test Radarr” button: checks the address and key, and shows Radarr's version, root folders with free space, and any health warnings.

## [1.0.4]

- “Get a free API key” button beside the TMDb key.
- Seerr: a Test button, and an optional Seerr API key — with it, the Seerr button on missing collection films sends the request straight to Seerr.

## [1.0.3]

- Fixed “Cannot convert System.Object[] to System.Int32” when connecting to Radarr on Windows PowerShell 5.1.

## [1.0.2]

- Radarr connection is more forgiving: the address is tidied up automatically (missing http://, stray double dots, pasted page paths), it warns when the port belongs to another app such as Deluge, and errors now show the address tried, the reply, and what to check.

## [1.0.1]

- Every genre shelf has its own fixed colour (Action red, Horror blood red, Sci-Fi cyan, Mum rose…) — no two shelves share one.

## [1.0.0]

- First release.
