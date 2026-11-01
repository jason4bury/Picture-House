<#
    Build-PictureHouseExe.ps1
    Builds "Picture House.exe" from Picture-House.ps1, with the Picture House icon.

    1. Checks this PC has everything the build needs (and says what to do if not).
    2. Makes "Picture House.ico" from the same drawing the app uses, so the exe, taskbar and title bar all match.
    3. Builds the exe with PS2EXE (free, from the PowerShell Gallery). The exe has no console window.

    Run it again whenever Picture-House.ps1 is updated. Your Data folder is never touched.
    The exe keeps using the Data folder beside it, so your library, settings and watched history carry on as before.
#>
param([switch]$NoPause)

$ErrorActionPreference = 'Stop'
$here    = Split-Path -Parent $MyInvocation.MyCommand.Path
$src     = Join-Path $here 'Picture-House.ps1'
$exe     = Join-Path $here 'Picture House.exe'
$ico     = Join-Path $here 'Picture House.ico'
$logFile = Join-Path $here 'Build-PictureHouseExe.log'

# ---- WPF (used to draw the icon) needs Windows PowerShell 5.1 on an STA thread ----
if ($PSVersionTable.PSEdition -eq 'Core' -or [Threading.Thread]::CurrentThread.GetApartmentState() -ne 'STA') {
    $wps = $(if ($env:SystemRoot) { Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe' } else { '' })
    if ($wps -and (Test-Path -LiteralPath $wps)) {
        Write-Host 'Switching to Windows PowerShell 5.1 (needed for the build)...'
        & $wps -NoProfile -ExecutionPolicy Bypass -STA -File $MyInvocation.MyCommand.Path @(if ($NoPause) { '-NoPause' })
        exit $LASTEXITCODE
    }
}

function Write-Line([string]$text, [string]$colour = 'Gray') {
    Write-Host $text -ForegroundColor $colour
    try { Add-Content -LiteralPath $logFile -Value $text -Encoding UTF8 } catch {}
}
function Pass([string]$what, [string]$detail = '') { Write-Line ("  [ OK ]  $what" + $(if ($detail) { " - $detail" } else { '' })) 'Green' }
function Warn([string]$what, [string]$detail = '') { $Script:Warnings++; Write-Line ("  [ !! ]  $what" + $(if ($detail) { " - $detail" } else { '' })) 'Yellow' }
function Fail([string]$what, [string]$detail = '') { $Script:Failures++; Write-Line ("  [FAIL]  $what" + $(if ($detail) { " - $detail" } else { '' })) 'Red' }
function Hint([string]$text) { Write-Line ("          $text") 'DarkGray' }
function Finish([int]$code) {
    Write-Line ''
    Write-Line "A copy of this report is in $logFile" 'DarkGray'
    if (-not $NoPause) { Write-Host ''; [void](Read-Host 'Press Enter to close') }
    exit $code
}

$Script:Failures = 0; $Script:Warnings = 0
try { Set-Content -LiteralPath $logFile -Value ('Picture House exe build  ' + (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')) -Encoding UTF8 } catch {}

Write-Line ''
Write-Line '  P I C T U R E   H O U S E   -   build the exe' 'Cyan'
Write-Line ''
Write-Line 'Checking requirements' 'White'

# 1. Windows
if ([Environment]::OSVersion.Platform -eq 'Win32NT') {
    $os = (Get-CimInstance Win32_OperatingSystem -ErrorAction SilentlyContinue).Caption
    if ([Environment]::OSVersion.Version.Major -ge 10) { Pass 'Windows' $os } else { Warn 'Windows' "$os - Picture House is tested on Windows 10 and 11" }
} else { Fail 'Windows' 'the exe can only be built and run on Windows'; Finish 1 }

# 2. 64-bit
if ([Environment]::Is64BitOperatingSystem) { Pass '64-bit Windows' } else { Warn '64-bit Windows' 'this is 32-bit Windows; the exe will be built for it, but large libraries may run short of memory' }

# 3. Windows PowerShell 5.1
$psv = $PSVersionTable.PSVersion
if ($psv.Major -eq 5 -and $psv.Minor -ge 1) { Pass 'Windows PowerShell 5.1' $psv.ToString() }
else { Fail 'Windows PowerShell 5.1' "found $psv"; Hint 'Install Windows Management Framework 5.1 from Microsoft, then run this again.' }

# 4. .NET Framework 4.7.2 or later (WPF, and the C# compiler PS2EXE uses)
$rel = 0
try { $rel = [int](Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full' -Name Release -ErrorAction Stop).Release } catch {}
$netName = switch ($rel) { { $_ -ge 533320 } { '4.8.1'; break } { $_ -ge 528040 } { '4.8'; break } { $_ -ge 461808 } { '4.7.2'; break } { $_ -ge 460798 } { '4.7'; break } { $_ -ge 394802 } { '4.6.2'; break } { $_ -ge 378389 } { '4.5'; break } default { 'not found' } }
if ($rel -ge 461808) { Pass '.NET Framework 4.7.2 or later' $netName }
elseif ($rel -ge 378389) { Warn '.NET Framework 4.7.2 or later' "found $netName - the build should work, but updating to 4.8 is recommended" }
else { Fail '.NET Framework 4.x' 'not found'; Hint 'Install .NET Framework 4.8 from Microsoft (Windows Update usually offers it).' }

# 5. The C# compiler that ships with .NET Framework (PS2EXE uses it to make the exe)
$csc = Join-Path $env:SystemRoot ('Microsoft.NET\' + $(if ([Environment]::Is64BitOperatingSystem) { 'Framework64' } else { 'Framework' }) + '\v4.0.30319\csc.exe')
if (Test-Path -LiteralPath $csc) { Pass 'C# compiler' $csc } else { Fail 'C# compiler' "not found at $csc"; Hint 'Repair or reinstall .NET Framework 4.8.' }

# 6. WPF (draws the icon; Picture House itself needs it too)
try { Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase; Pass 'WPF' }
catch { Fail 'WPF' $_.Exception.Message }

# 7. Georgia font (the cream "P" on the icon)
$fontDir = Join-Path $env:SystemRoot 'Fonts'
if (Get-ChildItem -LiteralPath $fontDir -Filter 'georgia*.ttf' -ErrorAction SilentlyContinue) { Pass 'Georgia font' }
else { Warn 'Georgia font' 'not installed - the icon will use a stand-in font' }

# 8. Picture-House.ps1 is here and reads cleanly
$appVer = '1.0.0'
if (-not (Test-Path -LiteralPath $src)) {
    Fail 'Picture-House.ps1' "not found in $here"; Hint 'Keep this build script in the same folder as Picture-House.ps1.'
} else {
    $tok = $null; $errs = $null
    $ast = [Management.Automation.Language.Parser]::ParseFile($src, [ref]$tok, [ref]$errs)
    if ($errs -and $errs.Count) { Fail 'Picture-House.ps1' ("has an error on line $($errs[0].Extent.StartLineNumber): $($errs[0].Message)"); Hint 'Use an unedited copy from the Picture House zip.' }
    else {
        $m = Select-String -LiteralPath $src -Pattern "^\`$AppVersion = '([\d\.]+)'" | Select-Object -First 1
        if ($m) { $appVer = $m.Matches[0].Groups[1].Value }
        $kb = [math]::Round((Get-Item -LiteralPath $src).Length / 1KB)
        Pass 'Picture-House.ps1' "version $appVer, $kb KB, no errors"
    }
}

# 9. The folder can be written to
try {
    $probe = Join-Path $here ('.write-test-' + [guid]::NewGuid().ToString('N') + '.tmp')
    [IO.File]::WriteAllText($probe, 'x'); Remove-Item -LiteralPath $probe -Force
    Pass 'Folder can be written to' $here
} catch { Fail 'Folder can be written to' $here; Hint 'Copy the Picture House folder somewhere you own (e.g. E:\Picture House), not Program Files or a read-only share.' }

# 10. Enough free disk space
try {
    $drv = New-Object IO.DriveInfo ([IO.Path]::GetPathRoot($here))
    $freeMb = [math]::Round($drv.AvailableFreeSpace / 1MB)
    if ($freeMb -ge 50) { Pass 'Free disk space' "$freeMb MB" } else { Fail 'Free disk space' "only $freeMb MB free - at least 50 MB is needed" }
} catch { Warn 'Free disk space' "couldn't check ($($_.Exception.Message))" }

# 11. Picture House isn't running from the old exe (it would be locked)
$running = @(Get-Process -ErrorAction SilentlyContinue | Where-Object { try { $_.Path -eq $exe } catch { $false } })
if ($running.Count) { Fail 'Picture House.exe is closed' 'it is running - close Picture House and run this again' }
else { Pass 'Picture House.exe is closed' }

# 12. PS2EXE (the tool that makes the exe)
$ps2 = Get-Module -ListAvailable -Name ps2exe | Sort-Object Version -Descending | Select-Object -First 1
if ($ps2) { Pass 'PS2EXE' "version $($ps2.Version)" }
elseif ($Script:Failures -eq 0) {
    Write-Line '  [ .. ]  PS2EXE isn''t installed - installing it for your user account (one-off)...' 'Gray'
    try {
        [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
        if (-not (Get-PackageProvider -ListAvailable -Name NuGet -ErrorAction SilentlyContinue | Where-Object { $_.Version -ge [version]'2.8.5.201' })) {
            Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Scope CurrentUser -Force | Out-Null
        }
        Install-Module -Name ps2exe -Scope CurrentUser -Repository PSGallery -Force -AllowClobber
        $ps2 = Get-Module -ListAvailable -Name ps2exe | Sort-Object Version -Descending | Select-Object -First 1
        if ($ps2) { Pass 'PS2EXE' "installed version $($ps2.Version)" } else { throw 'it did not appear after installing' }
    } catch {
        Fail 'PS2EXE' "couldn't install it: $($_.Exception.Message)"
        Hint 'This needs the internet (www.powershellgallery.com). Networks that block HTTPS, such as a work network,'
        Hint 'stop it - run the build at home instead. Or, on a PC with internet access, run:'
        Hint '    Save-Module -Name ps2exe -Path C:\Temp'
        Hint 'then copy C:\Temp\ps2exe to  Documents\WindowsPowerShell\Modules\  on this PC and run this again.'
    }
} else { Warn 'PS2EXE' 'not installed - skipped installing it until the problems above are fixed' }

Write-Line ''
if ($Script:Failures) {
    Write-Line "Can't build yet: $($Script:Failures) requirement(s) not met (see [FAIL] above)." 'Red'
    Finish 1
}
Write-Line ('All requirements met' + $(if ($Script:Warnings) { " ($($Script:Warnings) warning(s) - see [ !! ] above)" } else { '' }) + '.') 'Green'
Write-Line ''

# ---- The icon: drawn by the same code as the app's own icon, at every size Windows uses ----
Write-Line 'Making the icon' 'White'
try {
    $fn = $ast.FindAll({ param($n) $n -is [Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -eq 'New-AppIcon' }, $true) | Select-Object -First 1
    if (-not $fn) { throw 'New-AppIcon was not found in Picture-House.ps1' }
    . ([scriptblock]::Create($fn.Extent.Text))
    $sizes = 16, 20, 24, 32, 40, 48, 64, 96, 128, 256
    $pngs = foreach ($sz in $sizes) {
        $enc = New-Object Windows.Media.Imaging.PngBitmapEncoder
        [void]$enc.Frames.Add([Windows.Media.Imaging.BitmapFrame]::Create((New-AppIcon $sz)))
        $ms = New-Object IO.MemoryStream; $enc.Save($ms); $b = $ms.ToArray(); $ms.Dispose()
        , $b
    }
    $fs = [IO.File]::Create($ico); $bw = New-Object IO.BinaryWriter $fs
    try {
        $bw.Write([uint16]0); $bw.Write([uint16]1); $bw.Write([uint16]$sizes.Count)          # ICONDIR
        $offset = 6 + 16 * $sizes.Count
        for ($i = 0; $i -lt $sizes.Count; $i++) {                                                # ICONDIRENTRY per size
            $d = $(if ($sizes[$i] -ge 256) { 0 } else { $sizes[$i] })
            $bw.Write([byte]$d); $bw.Write([byte]$d); $bw.Write([byte]0); $bw.Write([byte]0)
            $bw.Write([uint16]1); $bw.Write([uint16]32); $bw.Write([uint32]$pngs[$i].Length); $bw.Write([uint32]$offset)
            $offset += $pngs[$i].Length
        }
        foreach ($p in $pngs) { $bw.Write([byte[]]$p) }
    } finally { $bw.Close() }
    Pass 'Picture House.ico' ("$($sizes.Count) sizes, 16 to 256 px - " + [math]::Round((Get-Item -LiteralPath $ico).Length / 1KB) + ' KB')
} catch {
    if (Test-Path -LiteralPath $ico) { Warn 'Picture House.ico' "couldn't redraw it ($($_.Exception.Message)) - using the one already here" }
    else { Warn 'Picture House.ico' "couldn't make it ($($_.Exception.Message)) - the exe will have the standard icon" }
}
Write-Line ''

# ---- Build ----
Write-Line "Building Picture House.exe (version $appVer)" 'White'
try {
    Import-Module ps2exe -ErrorAction Stop
    $old = $null
    if (Test-Path -LiteralPath $exe) { $old = "$exe.old"; Move-Item -LiteralPath $exe -Destination $old -Force }
    $iconArg = @{}; if (Test-Path -LiteralPath $ico) { $iconArg.iconFile = $ico }
    # -noConsole: no black window   -STA: the WPF window needs it   -noOutput/-noError: no stray pop-up boxes
    Invoke-ps2exe -inputFile $src -outputFile $exe -noConsole -STA -noOutput -noError @iconArg `
        -title 'Picture House' -description 'A film library for your NAS' -product 'Picture House' `
        -company 'Jason Rhodes' -copyright ('(c) ' + (Get-Date).Year + ' Jason Rhodes') -version $appVer | Out-Null
    if (-not (Test-Path -LiteralPath $exe)) { throw 'PS2EXE finished but no exe was made' }
    Start-Sleep -Seconds 2   # give the antivirus a moment to look at it
    if (-not (Test-Path -LiteralPath $exe)) {
        Fail 'Picture House.exe' 'it was made but then disappeared - your antivirus has probably quarantined it'
        Hint 'Programs made with PS2EXE are sometimes flagged by mistake. Restore it from the antivirus'
        Hint '(Windows Security > Protection history, or ESET > Quarantine) and add an exclusion for this folder.'
        if ($old -and (Test-Path -LiteralPath $old)) { Move-Item -LiteralPath $old -Destination $exe -Force; Hint 'Your previous Picture House.exe has been put back.' }
        Finish 1
    }
    if ($old -and (Test-Path -LiteralPath $old)) { Remove-Item -LiteralPath $old -Force -ErrorAction SilentlyContinue }
    $info = Get-Item -LiteralPath $exe
    Pass 'Picture House.exe' ("{0} KB, version {1}" -f [math]::Round($info.Length / 1KB), $info.VersionInfo.FileVersion)
} catch {
    Fail 'Picture House.exe' $_.Exception.Message
    if ($old -and (Test-Path -LiteralPath $old) -and -not (Test-Path -LiteralPath $exe)) { Move-Item -LiteralPath $old -Destination $exe -Force; Hint 'Your previous Picture House.exe has been put back.' }
    Finish 1
}

# ---- Optional desktop shortcut ----
Write-Line ''
if (-not $NoPause) {
    $ans = Read-Host 'Put a Picture House shortcut on the desktop? (Y/N)'
    if ($ans -match '^(y|yes)$') {
        try {
            $lnk = Join-Path ([Environment]::GetFolderPath('Desktop')) 'Picture House.lnk'
            $sh = New-Object -ComObject WScript.Shell
            $s = $sh.CreateShortcut($lnk)
            $s.TargetPath = $exe; $s.WorkingDirectory = $here; $s.Description = 'Picture House - your film library'
            if (Test-Path -LiteralPath $ico) { $s.IconLocation = "$ico,0" }
            $s.Save()
            Pass 'Desktop shortcut' $lnk
        } catch { Warn 'Desktop shortcut' $_.Exception.Message }
    }
}

Write-Line ''
Write-Line 'Done. Start Picture House by double-clicking "Picture House.exe" (you can pin it to Start or the taskbar).' 'Green'
Write-Line 'It uses the Data folder beside it, so your library, settings and watched history are all still there.' 'Gray'
Write-Line 'Run this again after each Picture House update.' 'Gray'
Finish 0
