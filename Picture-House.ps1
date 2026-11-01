<#
    Picture House — a film library for the NAS
    -------------------------------------------
    Version : 1.2.27 (26 Oct 2026)
    Author  : Jason Rhodes
    Needs   : Windows PowerShell 5.1 or PowerShell 7 (Windows), .NET WPF
    Launch  : Start-PictureHouse.cmd  (or: powershell -STA -ExecutionPolicy Bypass -File Picture-House.ps1)

    Everything the app writes lives in the "Data" folder beside this script, so the
    whole folder can be moved. The films themselves stay on the NAS and are only read
    (the one exception is "Move to shelf", which you confirm each time).
#>

$ErrorActionPreference = 'Continue'

# Shared dropdown look (inserted into every window's resources)
$ComboStyles = @'
    <!-- ===== Dropdowns: cream pill, teal when a filter is in use ===== -->
    <Style x:Key="PHComboToggle" TargetType="ToggleButton">
      <Setter Property="Focusable" Value="False"/>
      <Setter Property="ClickMode" Value="Press"/>
      <Setter Property="Cursor" Value="Hand"/>
      <Setter Property="Template">
        <Setter.Value><ControlTemplate TargetType="ToggleButton"><Border Background="Transparent"/></ControlTemplate></Setter.Value>
      </Setter>
    </Style>
    <Style TargetType="ComboBoxItem">
      <Setter Property="Foreground" Value="#1F1B16"/>
      <Setter Property="Cursor" Value="Hand"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="ComboBoxItem">
            <Border x:Name="b" Background="Transparent" CornerRadius="6" Padding="10,6" Margin="0,1">
              <Grid>
                <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions>
                <ContentPresenter x:Name="cp" VerticalAlignment="Center"/>
                <TextBlock x:Name="tick" Grid.Column="1" Text="✓" Foreground="#173F3E" FontWeight="Bold" Margin="12,0,0,0" VerticalAlignment="Center" Visibility="Collapsed"/>
              </Grid>
            </Border>
            <ControlTemplate.Triggers>
              <Trigger Property="IsHighlighted" Value="True"><Setter TargetName="b" Property="Background" Value="#ECE3D2"/></Trigger>
              <Trigger Property="IsSelected" Value="True">
                <Setter TargetName="b" Property="Background" Value="#E3D7C2"/>
                <Setter TargetName="tick" Property="Visibility" Value="Visible"/>
                <Setter TargetName="cp" Property="TextElement.FontWeight" Value="SemiBold"/>
              </Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>
    <Style TargetType="ComboBox">
      <Setter Property="Foreground" Value="#1F1B16"/>
      <Setter Property="Height" Value="30"/>
      <Setter Property="MinWidth" Value="90"/>
      <Setter Property="MaxDropDownHeight" Value="700"/>
      <Setter Property="SnapsToDevicePixels" Value="True"/>
      <Setter Property="ScrollViewer.HorizontalScrollBarVisibility" Value="Disabled"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="ComboBox">
            <Grid>
              <Border x:Name="box" Background="#FFFCF6" BorderBrush="#E2D9C9" BorderThickness="1" CornerRadius="15"/>
              <ContentPresenter x:Name="content" Margin="14,0,30,0" VerticalAlignment="Center" HorizontalAlignment="Left" IsHitTestVisible="False"
                                Content="{TemplateBinding SelectionBoxItem}" ContentTemplate="{TemplateBinding SelectionBoxItemTemplate}"
                                ContentTemplateSelector="{TemplateBinding ItemTemplateSelector}" ContentStringFormat="{TemplateBinding SelectionBoxItemStringFormat}"
                                TextElement.Foreground="#1F1B16"/>
              <Path x:Name="arrow" Data="M0,0 L4,4 L8,0" Stroke="#7B7266" StrokeThickness="1.6" StrokeStartLineCap="Round" StrokeEndLineCap="Round"
                    HorizontalAlignment="Right" VerticalAlignment="Center" Margin="0,1,14,0" IsHitTestVisible="False"/>
              <ToggleButton Style="{StaticResource PHComboToggle}" IsChecked="{Binding IsDropDownOpen, Mode=TwoWay, RelativeSource={RelativeSource TemplatedParent}}"/>
              <Popup x:Name="PART_Popup" Placement="Bottom" VerticalOffset="4" AllowsTransparency="True" Focusable="False" PopupAnimation="Fade"
                     IsOpen="{Binding IsDropDownOpen, RelativeSource={RelativeSource TemplatedParent}}">
                <Border Margin="0,0,12,14" MinWidth="{Binding ActualWidth, RelativeSource={RelativeSource TemplatedParent}}"
                        MaxHeight="{TemplateBinding MaxDropDownHeight}" Background="#FFFCF6" BorderBrush="#E2D9C9" BorderThickness="1" CornerRadius="10" Padding="5">
                  <Border.Effect><DropShadowEffect BlurRadius="18" ShadowDepth="4" Direction="270" Opacity="0.18"/></Border.Effect>
                  <ScrollViewer VerticalScrollBarVisibility="Auto" HorizontalScrollBarVisibility="Disabled">
                    <ItemsPresenter KeyboardNavigation.DirectionalNavigation="Contained"/>
                  </ScrollViewer>
                </Border>
              </Popup>
            </Grid>
            <ControlTemplate.Triggers>
              <Trigger Property="IsMouseOver" Value="True"><Setter TargetName="box" Property="Background" Value="#F7F1E6"/></Trigger>
              <!-- filter dropdowns (Tag="filter") turn teal when something other than the first 'Any…' choice is picked -->
              <Trigger Property="Tag" Value="filter">
                <Setter TargetName="box" Property="Background" Value="#173F3E"/>
                <Setter TargetName="box" Property="BorderBrush" Value="#173F3E"/>
                <Setter TargetName="content" Property="TextElement.Foreground" Value="#F6EBD9"/>
                <Setter TargetName="arrow" Property="Stroke" Value="#CCF6EBD9"/>
              </Trigger>
              <MultiTrigger>
                <MultiTrigger.Conditions><Condition Property="Tag" Value="filter"/><Condition Property="SelectedIndex" Value="0"/></MultiTrigger.Conditions>
                <Setter TargetName="box" Property="Background" Value="#FFFCF6"/>
                <Setter TargetName="box" Property="BorderBrush" Value="#E2D9C9"/>
                <Setter TargetName="content" Property="TextElement.Foreground" Value="#1F1B16"/>
                <Setter TargetName="arrow" Property="Stroke" Value="#7B7266"/>
              </MultiTrigger>
              <MultiTrigger>
                <MultiTrigger.Conditions><Condition Property="Tag" Value="filter"/><Condition Property="SelectedIndex" Value="-1"/></MultiTrigger.Conditions>
                <Setter TargetName="box" Property="Background" Value="#FFFCF6"/>
                <Setter TargetName="box" Property="BorderBrush" Value="#E2D9C9"/>
                <Setter TargetName="content" Property="TextElement.Foreground" Value="#1F1B16"/>
                <Setter TargetName="arrow" Property="Stroke" Value="#7B7266"/>
              </MultiTrigger>
              <Trigger Property="IsDropDownOpen" Value="True">
                <Setter TargetName="box" Property="BorderBrush" Value="#C8432B"/>
                <Setter TargetName="arrow" Property="Data" Value="M0,4 L4,0 L8,4"/>
              </Trigger>
              <Trigger Property="IsEnabled" Value="False"><Setter Property="Opacity" Value="0.5"/></Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>
    <!-- ===== Slim scrollbars: thin beige thumb, no arrows, no grey track ===== -->
    <Style x:Key="PHScrollPage" TargetType="RepeatButton">
      <Setter Property="Focusable" Value="False"/>
      <Setter Property="IsTabStop" Value="False"/>
      <Setter Property="Template">
        <Setter.Value><ControlTemplate TargetType="RepeatButton"><Border Background="Transparent"/></ControlTemplate></Setter.Value>
      </Setter>
    </Style>
    <Style x:Key="PHScrollThumb" TargetType="Thumb">
      <Setter Property="Focusable" Value="False"/>
      <Setter Property="IsTabStop" Value="False"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="Thumb">
            <Border x:Name="t" Background="#CFC4B1" CornerRadius="4"/>
            <ControlTemplate.Triggers>
              <Trigger Property="IsMouseOver" Value="True"><Setter TargetName="t" Property="Background" Value="#A89C87"/></Trigger>
              <Trigger Property="IsDragging" Value="True"><Setter TargetName="t" Property="Background" Value="#8C8070"/></Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>
    <Style TargetType="ScrollBar">
      <Setter Property="Stylus.IsFlicksEnabled" Value="False"/>
      <Setter Property="Width" Value="12"/>
      <Setter Property="MinWidth" Value="12"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="ScrollBar">
            <Grid Background="Transparent">
              <Track x:Name="PART_Track" IsDirectionReversed="True" Width="6" HorizontalAlignment="Center" Margin="0,4">
                <Track.DecreaseRepeatButton><RepeatButton Style="{StaticResource PHScrollPage}" Command="ScrollBar.PageUpCommand"/></Track.DecreaseRepeatButton>
                <Track.Thumb><Thumb Style="{StaticResource PHScrollThumb}" MinHeight="28"/></Track.Thumb>
                <Track.IncreaseRepeatButton><RepeatButton Style="{StaticResource PHScrollPage}" Command="ScrollBar.PageDownCommand"/></Track.IncreaseRepeatButton>
              </Track>
            </Grid>
            <ControlTemplate.Triggers>
              <Trigger Property="IsMouseOver" Value="True"><Setter TargetName="PART_Track" Property="Width" Value="9"/></Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
      <Style.Triggers>
        <Trigger Property="Orientation" Value="Horizontal">
          <Setter Property="Width" Value="Auto"/>
          <Setter Property="MinWidth" Value="0"/>
          <Setter Property="Height" Value="12"/>
          <Setter Property="MinHeight" Value="12"/>
          <Setter Property="Template">
            <Setter.Value>
              <ControlTemplate TargetType="ScrollBar">
                <Grid Background="Transparent">
                  <Track x:Name="PART_Track" Height="6" VerticalAlignment="Center" Margin="4,0">
                    <Track.DecreaseRepeatButton><RepeatButton Style="{StaticResource PHScrollPage}" Command="ScrollBar.PageLeftCommand"/></Track.DecreaseRepeatButton>
                    <Track.Thumb><Thumb Style="{StaticResource PHScrollThumb}" MinWidth="28"/></Track.Thumb>
                    <Track.IncreaseRepeatButton><RepeatButton Style="{StaticResource PHScrollPage}" Command="ScrollBar.PageRightCommand"/></Track.IncreaseRepeatButton>
                  </Track>
                </Grid>
                <ControlTemplate.Triggers>
                  <Trigger Property="IsMouseOver" Value="True"><Setter TargetName="PART_Track" Property="Height" Value="9"/></Trigger>
                </ControlTemplate.Triggers>
              </ControlTemplate>
            </Setter.Value>
          </Setter>
        </Trigger>
      </Style.Triggers>
    </Style>
    <!-- ===== Tooltips: dark teal card, cream text (every window) ===== -->
    <Style TargetType="ToolTip">
      <Setter Property="Foreground" Value="#F6EBD9"/>
      <Setter Property="FontFamily" Value="Segoe UI"/>
      <Setter Property="FontSize" Value="13"/>
      <Setter Property="MaxWidth" Value="460"/>
      <Setter Property="HasDropShadow" Value="False"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="ToolTip">
            <Border Background="#173F3E" BorderBrush="#2A5F5C" BorderThickness="1" CornerRadius="8" Padding="14,10" Margin="4,4,10,10">
              <Border.Effect><DropShadowEffect BlurRadius="14" ShadowDepth="3" Direction="270" Opacity="0.35"/></Border.Effect>
              <ContentPresenter>
                <ContentPresenter.Resources>
                  <Style TargetType="TextBlock"><Setter Property="TextWrapping" Value="Wrap"/><Setter Property="LineHeight" Value="19"/></Style>
                </ContentPresenter.Resources>
              </ContentPresenter>
            </Border>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>
    <!-- ===== Right-click and "More" menus: cream card, rounded, roomy rows, tan hover ===== -->
    <Style TargetType="ContextMenu">
      <Setter Property="HasDropShadow" Value="True"/>  <!-- also lets the menu's rounded corners be see-through -->
      <Setter Property="SnapsToDevicePixels" Value="True"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="ContextMenu">
            <Border Background="#FFFCF6" BorderBrush="#E2D9C9" BorderThickness="1" CornerRadius="10" Padding="6" Margin="0,4,10,12" MinWidth="220">
              <Border.Effect><DropShadowEffect BlurRadius="16" ShadowDepth="3" Direction="270" Opacity="0.22"/></Border.Effect>
              <ItemsPresenter KeyboardNavigation.DirectionalNavigation="Cycle"/>
            </Border>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>
    <Style x:Key="{x:Static MenuItem.SeparatorStyleKey}" TargetType="Separator">
      <Setter Property="Template">
        <Setter.Value><ControlTemplate TargetType="Separator"><Border Height="1" Background="#ECE3D2" Margin="10,5"/></ControlTemplate></Setter.Value>
      </Setter>
    </Style>
    <Style TargetType="MenuItem">
      <Setter Property="Foreground" Value="#1F1B16"/>
      <Setter Property="FontSize" Value="13"/>
      <Setter Property="Cursor" Value="Hand"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="MenuItem">
            <Grid>
              <Border x:Name="bg" Background="Transparent" CornerRadius="6" Padding="10,7,12,7">
                <Grid>
                  <Grid.ColumnDefinitions><ColumnDefinition Width="28"/><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions>
                  <ContentPresenter x:Name="ic" ContentSource="Icon" VerticalAlignment="Center" HorizontalAlignment="Left"/>
                  <ContentPresenter Grid.Column="1" ContentSource="Header" RecognizesAccessKey="True" VerticalAlignment="Center"/>
                  <TextBlock x:Name="arrow" Grid.Column="2" Text="›" FontSize="15" Foreground="#7B7266" Margin="14,0,0,0" VerticalAlignment="Center" Visibility="Collapsed"/>
                </Grid>
              </Border>
              <Popup x:Name="PART_Popup" Placement="Right" HorizontalOffset="2" IsOpen="{Binding IsSubmenuOpen, RelativeSource={RelativeSource TemplatedParent}}"
                     AllowsTransparency="True" Focusable="False" PopupAnimation="Fade">
                <Border Background="#FFFCF6" BorderBrush="#E2D9C9" BorderThickness="1" CornerRadius="10" Padding="6" Margin="0,0,10,12" MinWidth="200">
                  <Border.Effect><DropShadowEffect BlurRadius="16" ShadowDepth="3" Direction="270" Opacity="0.22"/></Border.Effect>
                  <ScrollViewer VerticalScrollBarVisibility="Auto" MaxHeight="520"><ItemsPresenter/></ScrollViewer>
                </Border>
              </Popup>
            </Grid>
            <ControlTemplate.Triggers>
              <Trigger Property="IsHighlighted" Value="True"><Setter TargetName="bg" Property="Background" Value="#ECE3D2"/></Trigger>
              <Trigger Property="HasItems" Value="True"><Setter TargetName="arrow" Property="Visibility" Value="Visible"/></Trigger>
              <Trigger Property="Icon" Value="{x:Null}"><Setter TargetName="ic" Property="Visibility" Value="Collapsed"/></Trigger>
              <Trigger Property="IsEnabled" Value="False"><Setter Property="Foreground" Value="#9C9385"/></Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>
'@

$AppName    = 'Picture House'
$AppVersion = '1.3.1'

# ---- WPF needs an STA thread -------------------------------------------------------
if ([Threading.Thread]::CurrentThread.GetApartmentState() -ne 'STA') {
    $exe = (Get-Process -Id $PID).Path
    Start-Process -FilePath $exe -ArgumentList @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-STA', '-File', "`"$PSCommandPath`"")
    return
}

Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase, System.Xaml, System.Windows.Forms, System.Drawing

# ---- The Picture House icon (window, taskbar, splash) — drawn here, so there's no image file to lose ----
function New-AppIcon([int]$size = 256) {
    $dv = New-Object Windows.Media.DrawingVisual
    $dc = $dv.RenderOpen()
    $s = [double]$size
    $teal = New-Object Windows.Media.SolidColorBrush ([Windows.Media.Color]::FromRgb(0x17, 0x3F, 0x3E))
    $cream = New-Object Windows.Media.SolidColorBrush ([Windows.Media.Color]::FromRgb(0xF6, 0xEB, 0xD9))
    $red = New-Object Windows.Media.SolidColorBrush ([Windows.Media.Color]::FromRgb(0xC8, 0x43, 0x2B))
    # teal tile with rounded corners
    $dc.DrawRoundedRectangle($teal, $null, (New-Object Windows.Rect 0, 0, $s, $s), ($s * 0.2), ($s * 0.2))
    # film-strip sprocket holes along the top and bottom
    $hw = $s * 0.085; $hh = $s * 0.06; $gap = ($s - 6 * $hw) / 7
    for ($i = 0; $i -lt 6; $i++) {
        $x = $gap + $i * ($hw + $gap)
        $dc.DrawRoundedRectangle($cream, $null, (New-Object Windows.Rect $x, ($s * 0.075), $hw, $hh), ($s * 0.015), ($s * 0.015))
        $dc.DrawRoundedRectangle($cream, $null, (New-Object Windows.Rect $x, ($s * 0.865), $hw, $hh), ($s * 0.015), ($s * 0.015))
    }
    # a big cream italic "P" in Georgia, like the app's title
    $tf = New-Object Windows.Media.Typeface ((New-Object Windows.Media.FontFamily 'Georgia'), [Windows.FontStyles]::Italic, [Windows.FontWeights]::Bold, [Windows.FontStretches]::Normal)
    $ft = New-Object Windows.Media.FormattedText ('P', [Globalization.CultureInfo]::InvariantCulture, [Windows.FlowDirection]::LeftToRight, $tf, ($s * 0.62), $cream)
    $dc.DrawText($ft, (New-Object Windows.Point (($s - $ft.Width) / 2 - $s * 0.02), (($s - $ft.Height) / 2)))
    # red "play" dot
    $dc.DrawEllipse($red, $null, (New-Object Windows.Point ($s * 0.74), ($s * 0.66)), ($s * 0.075), ($s * 0.075))
    $dc.Close()
    $bmp = New-Object Windows.Media.Imaging.RenderTargetBitmap $size, $size, 96, 96, ([Windows.Media.PixelFormats]::Pbgra32)
    $bmp.Render($dv); $bmp.Freeze()
    return $bmp
}
function Save-AppIcon([string]$path) {
    # a .ico holding one 256px PNG — handy for a desktop shortcut or the exe builder
    try {
        $enc = New-Object Windows.Media.Imaging.PngBitmapEncoder
        [void]$enc.Frames.Add([Windows.Media.Imaging.BitmapFrame]::Create((New-AppIcon 256)))
        $ms = New-Object IO.MemoryStream; $enc.Save($ms); $png = $ms.ToArray(); $ms.Dispose()
        $fs = [IO.File]::Create($path); $bw = New-Object IO.BinaryWriter $fs
        $bw.Write([uint16]0); $bw.Write([uint16]1); $bw.Write([uint16]1)                       # ICONDIR
        $bw.Write([byte]0); $bw.Write([byte]0); $bw.Write([byte]0); $bw.Write([byte]0)         # 256x256, no palette
        $bw.Write([uint16]1); $bw.Write([uint16]32); $bw.Write([uint32]$png.Length); $bw.Write([uint32]22)
        $bw.Write($png); $bw.Close()
    } catch {}
}
try { $Script:AppIcon = New-AppIcon 256 } catch { $Script:AppIcon = $null }

# ---- Little "opening…" card so you can see it's on its way (the main window takes a few seconds) ----
$Script:Splash = $null
try {
    $sp = New-Object Windows.Window
    $sp.WindowStyle = 'None'; $sp.ResizeMode = 'NoResize'; $sp.AllowsTransparency = $false; $sp.Topmost = $true
    $sp.Width = 380; $sp.Height = 150; $sp.WindowStartupLocation = 'CenterScreen'; $sp.Title = 'Picture House'
    $sp.Background = New-Object Windows.Media.SolidColorBrush ([Windows.Media.Color]::FromRgb(0x17, 0x3F, 0x3E))
    $cream = New-Object Windows.Media.SolidColorBrush ([Windows.Media.Color]::FromRgb(0xF6, 0xEB, 0xD9))
    $stk = New-Object Windows.Controls.StackPanel; $stk.VerticalAlignment = 'Center'; $stk.HorizontalAlignment = 'Center'
    $t1 = New-Object Windows.Controls.TextBlock; $t1.Text = 'Picture House'; $t1.FontFamily = 'Georgia'; $t1.FontStyle = [Windows.FontStyles]::Italic; $t1.FontSize = 30; $t1.Foreground = $cream; $t1.HorizontalAlignment = 'Center'
    $t2 = New-Object Windows.Controls.TextBlock; $t2.Text = 'Opening your film library…'; $t2.FontSize = 13; $t2.Margin = (New-Object Windows.Thickness 0, 8, 0, 0); $t2.Foreground = $cream; $t2.Opacity = 0.8; $t2.HorizontalAlignment = 'Center'
    [void]$stk.Children.Add($t1); [void]$stk.Children.Add($t2); $sp.Content = $stk
    if ($Script:AppIcon) { $sp.Icon = $Script:AppIcon }
    $sp.Show()
    $sp.Dispatcher.Invoke([Action]{}, [Windows.Threading.DispatcherPriority]::Background)   # let it paint now
    $Script:Splash = $sp
} catch {}
function Close-Splash { if ($Script:Splash) { try { $Script:Splash.Close() } catch {}; $Script:Splash = $null } }

# ---- Folders ------------------------------------------------------------------------
$Base = $PSScriptRoot
if (-not $Base) { $Base = Split-Path -Parent ([Diagnostics.Process]::GetCurrentProcess().MainModule.FileName) }
$DataDir  = Join-Path $Base 'Data'
$CacheDir = Join-Path $DataDir 'Cache'
foreach ($d in @($DataDir, $CacheDir, (Join-Path $CacheDir 'posters'), (Join-Path $CacheDir 'thumbs'),
                 (Join-Path $CacheDir 'backdrops'), (Join-Path $DataDir 'Exports'))) {
    if (-not (Test-Path -LiteralPath $d)) { [void](New-Item -ItemType Directory -Path $d -Force) }
}
$Files = @{
    Settings = Join-Path $DataDir 'settings.json'
    Library  = Join-Path $DataDir 'library.json'
    Meta     = Join-Path $DataDir 'metadata.json'
    User     = Join-Path $DataDir 'userdata.json'
    Colls    = Join-Path $DataDir 'collections.json'
    Log      = Join-Path $DataDir 'picture-house.log'
}

function Write-Log([string]$msg) {
    try {
        if ((Test-Path -LiteralPath $Files.Log) -and ((Get-Item -LiteralPath $Files.Log).Length -gt 1MB)) {
            Move-Item -LiteralPath $Files.Log -Destination ($Files.Log + '.old') -Force
        }
        Add-Content -LiteralPath $Files.Log -Value ((Get-Date).ToString('yyyy-MM-dd HH:mm:ss') + '  ' + $msg) -Encoding UTF8
    } catch {}
}
function Stop-Startup([string]$why) {
    # something stopped the window from being built — say so instead of vanishing
    Write-Log "Could not open: $why"
    Close-Splash
    [void][Windows.MessageBox]::Show("Picture House couldn't open.`n`n$why`n`nThe details are in Data\picture-house.log.", 'Picture House', 'OK', 'Error')
    exit 1
}
Write-Log "Opening Picture House $AppVersion (process $PID)…"
# tidy the Data folder: files older versions used, and keep the launch log short
foreach ($old in 'people-depts.json', 'console.log') { $f = Join-Path $DataDir $old; if (Test-Path -LiteralPath $f) { Remove-Item -LiteralPath $f -Force -ErrorAction SilentlyContinue } }
try { $ll = Join-Path $DataDir 'launch.log'; if (Test-Path -LiteralPath $ll) { $lines = @(Get-Content -LiteralPath $ll); if ($lines.Count -gt 200) { Set-Content -LiteralPath $ll -Value ($lines | Select-Object -Last 200) } } } catch {}
# keep only the last few launcher console logs (empty ones mean that start was fine)
try { Get-ChildItem -LiteralPath $DataDir -Filter 'console-*.log' -File -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -Skip 10 | Remove-Item -Force -ErrorAction SilentlyContinue } catch {}

# =====================================================================================
#  Shared code — loaded into the main window AND into every background worker
# =====================================================================================
# Pop-up windows share the app's look: red / cream pill buttons and a teal header band
$DialogStyles = @'
    <Style x:Key="PHDlgPrimary" TargetType="Button">
      <Setter Property="Foreground" Value="White"/><Setter Property="FontWeight" Value="SemiBold"/><Setter Property="Cursor" Value="Hand"/>
      <Setter Property="Template"><Setter.Value><ControlTemplate TargetType="Button">
        <Border x:Name="b" Background="#C8432B" CornerRadius="16" Padding="18,7"><ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/></Border>
        <ControlTemplate.Triggers>
          <Trigger Property="IsMouseOver" Value="True"><Setter TargetName="b" Property="Background" Value="#A3341F"/></Trigger>
          <Trigger Property="IsEnabled" Value="False"><Setter TargetName="b" Property="Opacity" Value="0.45"/></Trigger>
        </ControlTemplate.Triggers>
      </ControlTemplate></Setter.Value></Setter>
    </Style>
    <Style x:Key="PHDlgGhost" TargetType="Button">
      <Setter Property="Foreground" Value="#1F1B16"/><Setter Property="Cursor" Value="Hand"/>
      <Setter Property="Template"><Setter.Value><ControlTemplate TargetType="Button">
        <Border x:Name="b" Background="#FFFCF6" BorderBrush="#E2D9C9" BorderThickness="1" CornerRadius="16" Padding="18,7"><ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/></Border>
        <ControlTemplate.Triggers>
          <Trigger Property="IsMouseOver" Value="True"><Setter TargetName="b" Property="Background" Value="#ECE3D2"/></Trigger>
          <Trigger Property="IsEnabled" Value="False"><Setter TargetName="b" Property="Opacity" Value="0.45"/></Trigger>
        </ControlTemplate.Triggers>
      </ControlTemplate></Setter.Value></Setter>
    </Style>
'@
function New-DialogHeader([string]$title) {
    return '<Border DockPanel.Dock="Top" Background="#173F3E" Padding="22,14,22,16"><StackPanel>' +
           '<TextBlock Text="P I C T U R E   H O U S E" Foreground="#A6F6EBD9" FontSize="10.5"/>' +
           '<TextBlock Text="' + $title + '" FontFamily="Georgia" FontSize="22" Foreground="#F6EBD9" Margin="0,4,0,0"/></StackPanel></Border>'
}

$SharedCode = @'
try { [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12 } catch {}

$Global:PH_SkipDirs = @('extras','featurettes','behind the scenes','deleted scenes','interviews','scenes','shorts',
                       'trailers','other','others','sample','samples','subs','subtitles','artwork','metadata',
                       'extrafanart','extrathumbs','specials','bonus','bonus features','video_ts','bdmv','certificate','audio_ts')

function PH-IsSkipDir([string]$name) {
    if ([string]::IsNullOrEmpty($name)) { return $true }
    $c = $name[0]
    if ($c -eq '@' -or $c -eq '.' -or $c -eq '#' -or $c -eq '$') { return $true }
    $low = $name.ToLowerInvariant()
    if ($Global:PH_UserSkip -and ($Global:PH_UserSkip -contains $low)) { return $true }
    return ($Global:PH_SkipDirs -contains $low)
}

function PH-IsJunkToken([string]$t) {
    return ($t -match '^(?i)(2160p|1080p|1080i|720p|576p|480p|4k|uhd|bluray|blu-ray|bdrip|brrip|webrip|web-dl|webdl|hdtv|dvdrip|dvdscr|remux|x264|x265|h264|h265|hevc|avc|xvid|divx|hdr|hdr10|dovi|aac|ac3|eac3|dts|dts-hd|atmos|truehd|proper|repack|unrated|remastered|imax|10bit|8bit|internal|limited)$')
}

function PH-ParseName([string]$name) {
    $r = @{ Title = $name; Year = 0; Tmdb = 0; Imdb = ''; Edition = '' }
    $n = $name
    if ($n -match '(?i)[\[\{]tmdb(?:id)?[-=](\d+)[\]\}]') { $r.Tmdb = [int]$Matches[1] }
    if ($n -match '(?i)(tt\d{7,9})') { $r.Imdb = $Matches[1].ToLowerInvariant() }
    if ($n -match '(?i)\{edition-([^\}]+)\}') { $r.Edition = $Matches[1] }
    $n = [regex]::Replace($n, '\{[^\}]*\}', ' ')
    $n = [regex]::Replace($n, '(?i)\[(?:tmdb|imdb)[^\]]*\]', ' ')
    $t = ''
    $m = [regex]::Match($n, '[\(\[]((?:19|20)\d{2})[\)\]]')
    if ($m.Success) {
        $r.Year = [int]$m.Groups[1].Value
        $t = $n.Substring(0, $m.Index)
        if ([string]::IsNullOrWhiteSpace($t)) { $t = $n.Substring($m.Index + $m.Length) }
        if ($t.Trim() -notmatch ' ') { $t = $t -replace '[\._]', ' ' } else { $t = $t -replace '_', ' ' }
    } else {
        $tokens = @([regex]::Split($n, '[\. _]+') | Where-Object { $_ -ne '' })
        $idx = -1
        for ($i = 1; $i -lt $tokens.Count; $i++) {
            if ($tokens[$i] -match '^(19|20)\d{2}$') { $idx = $i }
            elseif (PH-IsJunkToken $tokens[$i]) { break }
        }
        if ($idx -gt 0) {
            $r.Year = [int]$tokens[$idx]
            $t = ($tokens[0..($idx - 1)] -join ' ')
        } else {
            $keep = New-Object Collections.ArrayList
            foreach ($tk in $tokens) { if (PH-IsJunkToken $tk) { break }; [void]$keep.Add($tk) }
            if ($keep.Count -gt 0) { $t = ($keep -join ' ') } else { $t = $n }
        }
    }
    $t = [regex]::Replace($t, '\[[^\]]*\]', ' ')
    $t = [regex]::Replace($t, '\s+', ' ').Trim(' ', '-', '.', '_', ',')
    if ($t -match '^(.*), (The|A|An)$') { $t = $Matches[2] + ' ' + $Matches[1] }
    if ($t) { $r.Title = $t }
    return $r
}

function PH-GetRes([string]$s) {
    if ($s -match '(?i)(2160p|\b4k\b|\buhd\b)') { return '4K' }
    if ($s -match '(?i)1080[pi]') { return '1080p' }
    if ($s -match '(?i)720p') { return '720p' }
    if ($s -match '(?i)(576p|480p|dvdrip|\bdvd\b|xvid|divx|\bsd\b)') { return 'SD' }
    return ''
}

function PH-ResFromWidth([int]$w) {
    if ($w -ge 3000) { return '4K' }
    if ($w -ge 1800) { return '1080p' }
    if ($w -ge 1200) { return '720p' }
    if ($w -gt 0) { return 'SD' }
    return ''
}

function PH-NormTitle([string]$t) {
    if (-not $t) { return '' }
    $s = $t.ToLowerInvariant().Normalize([Text.NormalizationForm]::FormD)
    $s = [regex]::Replace($s, '\p{Mn}', '')
    $s = $s.Replace('&', ' and ')
    $s = [regex]::Replace($s, '[^a-z0-9]+', ' ').Trim()
    $s = [regex]::Replace($s, '^(the|a|an) ', '')
    return $s
}

function PH-Hash([string]$s) {
    $md5 = [Security.Cryptography.MD5]::Create()
    $b = $md5.ComputeHash([Text.Encoding]::UTF8.GetBytes($s))
    $md5.Dispose()
    return ([BitConverter]::ToString($b) -replace '-', '').ToLowerInvariant()
}

function PH-MakeThumb([string]$src, [string]$destDir, [int]$width) {
    try {
        $fi = New-Object IO.FileInfo $src
        if (-not $fi.Exists) { return $null }
        $dest = Join-Path $destDir ((PH-Hash ($src.ToLowerInvariant() + '|' + $fi.LastWriteTimeUtc.Ticks + '|' + $width)) + '.jpg')
        if (Test-Path -LiteralPath $dest) { return $dest }
        Add-Type -AssemblyName System.Drawing
        $bytes = [IO.File]::ReadAllBytes($src)
        $ms = New-Object IO.MemoryStream (, $bytes)
        $img = [Drawing.Image]::FromStream($ms)
        try {
            $w2 = $width; $h = [int]([double]$img.Height * $width / [math]::Max(1.0, [double]$img.Width))
            if ($img.Width -le $width) { $w2 = $img.Width; $h = $img.Height }
            $bmp = New-Object Drawing.Bitmap $w2, $h
            $g = [Drawing.Graphics]::FromImage($bmp)
            $g.InterpolationMode = [Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
            $g.PixelOffsetMode = [Drawing.Drawing2D.PixelOffsetMode]::HighQuality
            $g.DrawImage($img, 0, 0, $w2, $h)
            $g.Dispose()
            $enc = [Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() | Where-Object { $_.MimeType -eq 'image/jpeg' } | Select-Object -First 1
            $ep = New-Object Drawing.Imaging.EncoderParameters 1
            $ep.Param[0] = New-Object Drawing.Imaging.EncoderParameter ([Drawing.Imaging.Encoder]::Quality, [long]86)
            $bmp.Save($dest, $enc, $ep)
            $bmp.Dispose()
        } finally { $img.Dispose(); $ms.Dispose() }
        return $dest
    } catch { return $null }
}

# Picture width straight from an MKV file's header (Windows itself can't read MKV details)
function PH-MkvWidth([string]$path) {
    $fs = $null
    try {
        $fs = [IO.File]::Open($path, [IO.FileMode]::Open, [IO.FileAccess]::Read, [IO.FileShare]::ReadWrite)
        $script:mkvFs = $fs
        function Read-EbmlId {
            $b = $script:mkvFs.ReadByte(); if ($b -lt 0) { return -1 }
            if ($b -band 0x80) { $len = 1 } elseif ($b -band 0x40) { $len = 2 } elseif ($b -band 0x20) { $len = 3 } elseif ($b -band 0x10) { $len = 4 } else { return -1 }
            $v = [long]$b
            for ($i = 1; $i -lt $len; $i++) { $v = ($v -shl 8) -bor $script:mkvFs.ReadByte() }
            return $v
        }
        function Read-EbmlSize {
            $b = $script:mkvFs.ReadByte(); if ($b -lt 0) { return -2 }
            $mask = 0x80; $len = 1
            while ($len -le 8 -and -not ($b -band $mask)) { $mask = $mask -shr 1; $len++ }
            if ($len -gt 8) { return -2 }
            $v = [long]($b -band ($mask - 1)); $allOnes = ($v -eq ($mask - 1))
            for ($i = 1; $i -lt $len; $i++) { $x = $script:mkvFs.ReadByte(); $v = ($v -shl 8) -bor $x; if ($x -ne 0xFF) { $allOnes = $false } }
            if ($allOnes) { return -1 }
            return $v
        }
        function Find-PixelWidth([long]$end) {
            while ($script:mkvFs.Position -lt $end) {
                $id = Read-EbmlId; $sz = Read-EbmlSize
                if ($id -lt 0 -or $sz -lt 0) { return 0 }
                if ($id -eq 0xAE -or $id -eq 0xE0) { $r = Find-PixelWidth ($script:mkvFs.Position + $sz); if ($r -gt 0) { return $r } }
                elseif ($id -eq 0xB0) { $v = [long]0; for ($i = 0; $i -lt $sz; $i++) { $v = ($v -shl 8) -bor $script:mkvFs.ReadByte() }; return $v }
                else { [void]$script:mkvFs.Seek($sz, [IO.SeekOrigin]::Current) }
            }
            return 0
        }
        if ((Read-EbmlId) -ne 0x1A45DFA3) { return 0 }
        $sz = Read-EbmlSize; if ($sz -lt 0) { return 0 }; [void]$fs.Seek($sz, [IO.SeekOrigin]::Current)
        if ((Read-EbmlId) -ne 0x18538067) { return 0 }
        $segSize = Read-EbmlSize
        $segEnd = $(if ($segSize -lt 0) { $fs.Length } else { $fs.Position + $segSize })
        for ($n = 0; $n -lt 64 -and $fs.Position -lt $segEnd; $n++) {
            $id = Read-EbmlId; $sz = Read-EbmlSize
            if ($id -lt 0 -or $sz -lt 0) { return 0 }
            if ($id -eq 0x1654AE6B) { return (Find-PixelWidth ($fs.Position + $sz)) }
            if ($id -eq 0x1F43B675) { return 0 }
            [void]$fs.Seek($sz, [IO.SeekOrigin]::Current)
        }
        return 0
    } catch { return 0 }
    finally { if ($fs) { $fs.Dispose() } }
}

function PH-X($node, [string]$xpath) {
    if ($null -eq $node) { return '' }
    $n = $node.SelectSingleNode($xpath)
    if ($n) { return $n.InnerText.Trim() }
    return ''
}

function PH-NewMeta([string]$source) {
    return @{ Source = $source; TmdbId = 0; ImdbId = ''; Title = ''; OriginalTitle = ''; Tagline = ''; Overview = '';
              Runtime = 0; Rating = 0.0; Votes = 0; Release = ''; Year = 0; Genres = @(); Directors = @(); Writers = @();
              Cast = @(); Cert = ''; CollectionId = 0; CollectionName = ''; Trailer = ''; PosterPath = ''; BackdropPath = '';
              PosterThumb = ''; Backdrop = ''; Studio = ''; Country = ''; Width = 0; Fetched = (Get-Date).ToString('s') }
}

function PH-ReadNfo([string]$path) {
    try {
        $raw = [IO.File]::ReadAllText($path)
        $i = $raw.IndexOf('<movie'); if ($i -lt 0) { return $null }
        $j = $raw.LastIndexOf('</movie>'); if ($j -lt 0) { return $null }
        $x = New-Object Xml.XmlDocument
        $x.LoadXml($raw.Substring($i, $j - $i + 8))
        $m = $x.SelectSingleNode('/movie')
        $meta = PH-NewMeta 'nfo'
        $meta.Title = PH-X $m 'title'
        $meta.OriginalTitle = PH-X $m 'originaltitle'
        $meta.Tagline = PH-X $m 'tagline'
        $meta.Overview = PH-X $m 'plot'
        if (-not $meta.Overview) { $meta.Overview = PH-X $m 'outline' }
        $rt = PH-X $m 'runtime'; if ($rt -match '(\d+)') { $meta.Runtime = [int]$Matches[1] }
        $rv = PH-X $m "ratings/rating[@default='true']/value"
        if (-not $rv) { $rv = PH-X $m 'ratings/rating/value' }
        if (-not $rv) { $rv = PH-X $m 'rating' }
        $dv = 0.0; if ([double]::TryParse($rv, [Globalization.NumberStyles]::Float, [Globalization.CultureInfo]::InvariantCulture, [ref]$dv)) { $meta.Rating = [math]::Round($dv, 1) }
        $rel = PH-X $m 'premiered'; if (-not $rel) { $rel = PH-X $m 'releasedate' }
        $meta.Release = $rel
        $yr = PH-X $m 'year'
        if ($yr -match '^\d{4}$') { $meta.Year = [int]$yr } elseif ($rel -match '^(\d{4})') { $meta.Year = [int]$Matches[1] }
        $meta.Genres = @($m.SelectNodes('genre') | ForEach-Object { $_.InnerText.Trim() } | Where-Object { $_ })
        $meta.Directors = @($m.SelectNodes('director') | ForEach-Object { @{ Id = 0; Name = $_.InnerText.Trim(); Photo = $null } } | Select-Object -First 3)
        $meta.Writers = @($m.SelectNodes('credits') | ForEach-Object { $_.InnerText.Trim() } | Select-Object -First 3)
        $cast = New-Object Collections.ArrayList
        foreach ($a in $m.SelectNodes('actor')) {
            if ($cast.Count -ge 15) { break }
            $ph = PH-X $a 'thumb'; if (-not ($ph -match '^https?://')) { $ph = $null }
            [void]$cast.Add(@{ Id = 0; Name = (PH-X $a 'name'); Role = (PH-X $a 'role'); Photo = $ph })
        }
        $meta.Cast = $cast.ToArray()
        $t = PH-X $m "uniqueid[@type='tmdb']"; if (-not $t) { $t = PH-X $m 'tmdbid' }
        if ($t -match '^\d+$') { $meta.TmdbId = [int]$t }
        $im = PH-X $m "uniqueid[@type='imdb']"; if (-not $im) { $im = PH-X $m 'imdbid' }
        if (-not $im) { $id = PH-X $m 'id'; if ($id -match '^tt\d+') { $im = $id } elseif ($id -match '^\d+$' -and -not $meta.TmdbId) { $meta.TmdbId = [int]$id } }
        $meta.ImdbId = $im
        $setNode = $m.SelectSingleNode('set')
        if ($setNode) {
            $sn = PH-X $setNode 'name'; if (-not $sn) { $sn = $setNode.InnerText.Trim() }
            $meta.CollectionName = $sn
            $cid = $setNode.GetAttribute('tmdbcolid'); if ($cid -match '^\d+$') { $meta.CollectionId = [int]$cid }
        }
        $tr = PH-X $m 'trailer'; if ($tr -match 'videoid=([A-Za-z0-9_\-]{6,})') { $meta.Trailer = $Matches[1] }
        $cert = PH-X $m 'mpaa'; if ($cert -match ':') { $cert = ($cert -split ':')[-1] }
        $meta.Cert = ($cert -replace '(?i)^rated\s+', '').Trim()
        $meta.Studio = PH-X $m 'studio'
        $meta.Country = PH-X $m 'country'
        $w = PH-X $m 'fileinfo/streamdetails/video/width'; if ($w -match '^\d+$') { $meta.Width = [int]$w }
        return $meta
    } catch { return $null }
}

function PH-Tmdb([string]$key, [string]$path, [hashtable]$q) {
    $pairs = New-Object Collections.ArrayList
    if ($q) { foreach ($k in $q.Keys) { $v = $q[$k]; if ($null -ne $v -and "$v" -ne '' -and "$v" -ne '0') { [void]$pairs.Add($k + '=' + [uri]::EscapeDataString([string]$v)) } } }
    $headers = @{ Accept = 'application/json' }
    if ($key -like 'eyJ*') { $headers['Authorization'] = 'Bearer ' + $key } else { [void]$pairs.Add('api_key=' + $key) }
    $url = 'https://api.themoviedb.org/3' + $path
    if ($pairs.Count) { $url += '?' + ($pairs -join '&') }
    for ($try = 0; $try -lt 3; $try++) {
        try { return (Invoke-RestMethod -Uri $url -Headers $headers -TimeoutSec 25 -UseBasicParsing) }
        catch {
            $code = 0; try { $code = [int]$_.Exception.Response.StatusCode } catch {}
            if ($code -eq 429) { Start-Sleep -Seconds 2; continue }
            if ($code -eq 404) { return $null }
            if ($code -eq 401) { throw 'TMDb rejected the API key (401).' }
            if ($try -eq 2) { throw }
            Start-Sleep -Milliseconds 600
        }
    }
    return $null
}

function PH-ImgUrl($p, [string]$size) {
    if ($p) { return 'https://image.tmdb.org/t/p/' + $size + $p }
    return $null
}

function PH-Download([string]$url, [string]$dest) {
    if (Test-Path -LiteralPath $dest) { return $dest }
    try {
        $wc = New-Object Net.WebClient
        $wc.DownloadFile($url, $dest + '.part')
        $wc.Dispose()
        Move-Item -LiteralPath ($dest + '.part') -Destination $dest -Force
        return $dest
    } catch { return $null }
}

function PH-TmdbSearch([string]$key, [string]$title, [int]$year, [string]$lang) {
    $res = @()
    if ($year -gt 0) {
        $r = PH-Tmdb $key '/search/movie' @{ query = $title; year = $year; language = $lang; include_adult = 'false' }
        if ($r) { $res = @($r.results) }
    }
    if ($res.Count -eq 0) {
        $r = PH-Tmdb $key '/search/movie' @{ query = $title; language = $lang; include_adult = 'false' }
        if ($r) { $res = @($r.results) }
    }
    return , $res
}

function PH-PickBest($results, [string]$title, [int]$year) {
    if (-not $results -or @($results).Count -eq 0) { return $null }
    $nt = PH-NormTitle $title
    $best = $null; $bestScore = -9999; $i = 0
    foreach ($r in $results) {
        $s = 0.0
        $ry = 0; if ($r.release_date -and ([string]$r.release_date).Length -ge 4) { $ry = [int]([string]$r.release_date).Substring(0, 4) }
        if ((PH-NormTitle $r.title) -eq $nt -or (PH-NormTitle $r.original_title) -eq $nt) { $s += 50 }
        if ($year -gt 0 -and $ry -gt 0) {
            $d = [math]::Abs($ry - $year)
            if ($d -eq 0) { $s += 40 } elseif ($d -eq 1) { $s += 25 } else { $s -= 15 }
        }
        $s -= $i * 3
        $s += [math]::Min(10.0, [math]::Log10([double]$r.vote_count + 1) * 3)
        if ($s -gt $bestScore) { $bestScore = $s; $best = $r }
        $i++
        if ($i -ge 8) { break }
    }
    return $best
}

function PH-TmdbMeta([string]$key, [int]$id, [string]$cacheDir, [string]$lang, [string]$region) {
    $d = PH-Tmdb $key "/movie/$id" @{ language = $lang; append_to_response = 'credits,release_dates,videos' }
    if (-not $d) { return $null }
    $meta = PH-NewMeta 'tmdb'
    $meta.TmdbId = [int]$d.id; $meta.ImdbId = [string]$d.imdb_id
    $meta.Title = [string]$d.title; $meta.OriginalTitle = [string]$d.original_title
    $meta.Tagline = [string]$d.tagline; $meta.Overview = [string]$d.overview
    $meta.Runtime = [int]$d.runtime; $meta.Rating = [math]::Round([double]$d.vote_average, 1); $meta.Votes = [int]$d.vote_count
    $meta.Release = [string]$d.release_date
    if ($meta.Release.Length -ge 4) { $meta.Year = [int]$meta.Release.Substring(0, 4) }
    $meta.Genres = @($d.genres | ForEach-Object { [string]$_.name })
    if ($d.belongs_to_collection) { $meta.CollectionId = [int]$d.belongs_to_collection.id; $meta.CollectionName = [string]$d.belongs_to_collection.name }
    if ($d.production_companies) { $meta.Studio = (@($d.production_companies | Select-Object -First 2 | ForEach-Object { [string]$_.name }) -join ', ') }
    if ($d.production_countries) { $meta.Country = (@($d.production_countries | Select-Object -First 2 | ForEach-Object { [string]$_.name }) -join ', ') }
    if ($d.credits) {
        $meta.Directors = @($d.credits.crew | Where-Object { $_.job -eq 'Director' } | Select-Object -First 3 | ForEach-Object {
            @{ Id = [int]$_.id; Name = [string]$_.name; Photo = (PH-ImgUrl $_.profile_path 'w185') } })
        $meta.Writers = @($d.credits.crew | Where-Object { $_.job -eq 'Screenplay' -or $_.job -eq 'Writer' -or $_.job -eq 'Novel' } |
                          ForEach-Object { [string]$_.name } | Select-Object -Unique -First 3)
        $meta.Cast = @($d.credits.cast | Sort-Object { [int]$_.order } | Select-Object -First 15 | ForEach-Object {
            @{ Id = [int]$_.id; Name = [string]$_.name; Role = [string]$_.character; Photo = (PH-ImgUrl $_.profile_path 'w185') } })
    }
    if ($d.release_dates) {
        foreach ($reg in @($region, 'US')) {
            $rr = @($d.release_dates.results | Where-Object { $_.iso_3166_1 -eq $reg })
            if ($rr.Count) {
                $c = @($rr[0].release_dates | Where-Object { $_.certification } | Select-Object -First 1)
                if ($c.Count) { $meta.Cert = [string]$c[0].certification; break }
            }
        }
    }
    if ($d.videos) {
        $v = @($d.videos.results | Where-Object { $_.site -eq 'YouTube' -and $_.type -eq 'Trailer' } | Sort-Object { -[int][bool]$_.official })
        if ($v.Count) { $meta.Trailer = [string]$v[0].key }
    }
    $meta.PosterPath = [string]$d.poster_path
    $meta.BackdropPath = [string]$d.backdrop_path
    if ($meta.PosterPath) {
        $f = Join-Path $cacheDir ('posters\tmdb' + ($meta.PosterPath -replace '[^A-Za-z0-9\.]', ''))
        $p = PH-Download ('https://image.tmdb.org/t/p/w342' + $meta.PosterPath) $f
        if ($p) { $meta.PosterThumb = $p }
    }
    if ($meta.BackdropPath) {
        $f = Join-Path $cacheDir ('backdrops\tmdb' + ($meta.BackdropPath -replace '[^A-Za-z0-9\.]', ''))
        $p = PH-Download ('https://image.tmdb.org/t/p/w1280' + $meta.BackdropPath) $f
        if ($p) { $meta.Backdrop = $p }
    }
    return $meta
}

function PH-TmdbCollection([string]$key, [int]$id, [string]$lang) {
    $c = PH-Tmdb $key "/collection/$id" @{ language = $lang }
    if (-not $c) { return $null }
    $parts = @($c.parts | Sort-Object { if ($_.release_date) { [string]$_.release_date } else { '9999' } } | ForEach-Object {
        $y = 0; if ($_.release_date -and ([string]$_.release_date).Length -ge 4) { $y = [int]([string]$_.release_date).Substring(0, 4) }
        @{ Id = [int]$_.id; Title = [string]$_.title; Release = [string]$_.release_date; Year = $y;
           Poster = (PH-ImgUrl $_.poster_path 'w342'); Overview = [string]$_.overview } })
    return @{ Id = [int]$c.id; Name = [string]$c.name; Overview = [string]$c.overview; Poster = (PH-ImgUrl $c.poster_path 'w342');
              Parts = $parts; Fetched = (Get-Date).ToString('s') }
}

function PH-PersonDetails($p) {
    # $p: @{ Key; Lang; Name; Id; Dept } — returns the TMDb person record (credits trimmed to the 80 best known)
    $id = [int]$p.Id
    if (-not $id) {
        $r = PH-Tmdb $p.Key '/search/person' @{ query = $p.Name; language = $p.Lang; include_adult = 'false' }
        $hits = @($r.results)
        if ($p.Dept) { $pref = @($hits | Where-Object { $_.known_for_department -eq $p.Dept }); if ($pref.Count) { $hits = $pref } }
        if ($hits.Count) { $id = [int]$hits[0].id }
    }
    if (-not $id) { return @{ Name = $p.Name; NotFound = $true; Asked = [int]$p.Id; Fetched = (Get-Date).ToString('s') } }
    $d = PH-Tmdb $p.Key "/person/$id" @{ language = $p.Lang; append_to_response = 'movie_credits,external_ids' }
    if (-not $d) { return @{ Name = $p.Name; NotFound = $true; Asked = [int]$p.Id; Fetched = (Get-Date).ToString('s') } }
    $bio = [string]$d.biography
    if (-not $bio -and $p.Lang -ne 'en-US') {
        $en = PH-Tmdb $p.Key "/person/$id" @{ language = 'en-US' }
        if ($en) { $bio = [string]$en.biography }
    }
    $credits = @{}
    foreach ($c in @($d.movie_credits.cast)) {
        $k = [string]$c.id; if ($credits.ContainsKey($k)) { continue }
        $y = 0; if ($c.release_date -and ([string]$c.release_date).Length -ge 4) { $y = [int]([string]$c.release_date).Substring(0, 4) }
        $credits[$k] = @{ Id = [int]$c.id; Title = [string]$c.title; Year = $y; Release = [string]$c.release_date; Role = [string]$c.character
                          Poster = (PH-ImgUrl $c.poster_path 'w342'); Popularity = [double]$c.popularity; Votes = [int]$c.vote_count }
    }
    foreach ($c in @($d.movie_credits.crew | Where-Object { $_.job -eq 'Director' })) {
        $k = [string]$c.id
        if ($credits.ContainsKey($k)) { $credits[$k].Role = 'Director' + $(if ($credits[$k].Role) { ' · ' + $credits[$k].Role } else { '' }); continue }
        $y = 0; if ($c.release_date -and ([string]$c.release_date).Length -ge 4) { $y = [int]([string]$c.release_date).Substring(0, 4) }
        $credits[$k] = @{ Id = [int]$c.id; Title = [string]$c.title; Year = $y; Release = [string]$c.release_date; Role = 'Director'
                          Poster = (PH-ImgUrl $c.poster_path 'w342'); Popularity = [double]$c.popularity; Votes = [int]$c.vote_count }
    }
    $keep = @($credits.Values | Sort-Object { [double]$_.Popularity } -Descending | Select-Object -First 80)
    # for "you have X of Y": every released film they directed, and every released film they acted in that people
    # actually saw (20+ TMDb votes) — leaving out documentaries and "Himself / Herself" appearances
    $today = (Get-Date).ToString('yyyy-MM-dd')
    $dirIds = @($d.movie_credits.crew | Where-Object { $_.job -eq 'Director' -and $_.release_date -and [string]$_.release_date -le $today -and -not $_.video -and [int]$_.vote_count -ge 5 } |
                ForEach-Object { [int]$_.id } | Select-Object -Unique)
    $actIds = @($d.movie_credits.cast | Where-Object { $_.release_date -and [string]$_.release_date -le $today -and -not $_.video -and [int]$_.vote_count -ge 20 -and
                    -not (@($_.genre_ids) -contains 99) -and -not ([string]$_.character -match '^\s*(him|her|them)?self\b|\(uncredited\)|^\s*narrator') } |
                ForEach-Object { [int]$_.id } | Select-Object -Unique)
    return @{
        DirIds = $dirIds; ActIds = $actIds;
        Asked = [int]$p.Id; Name = $p.Name; Id = $id; RealName = [string]$d.name; Bio = $bio; Birthday = [string]$d.birthday; Deathday = [string]$d.deathday
        Place = [string]$d.place_of_birth; Dept = [string]$d.known_for_department; Photo = (PH-ImgUrl $d.profile_path 'w342')
        Imdb = [string]$d.external_ids.imdb_id; Credits = $keep; Fetched = (Get-Date).ToString('s')
    }
}
'@
. ([scriptblock]::Create($SharedCode))

# =====================================================================================
#  JSON helpers (fast on PowerShell 7, safe on 5.1)
# =====================================================================================
function PH-Norm($o) {
    if ($null -eq $o) { return $null }
    if ($o -is [Collections.IDictionary]) {
        $h = @{}
        foreach ($k in @($o.Keys)) { $h[[string]$k] = PH-Norm $o[$k] }
        return $h
    }
    if ($o -is [string]) { return $o }
    if ($o -is [Collections.IEnumerable]) {
        $a = New-Object Collections.ArrayList
        foreach ($i in $o) { [void]$a.Add((PH-Norm $i)) }
        return , ($a.ToArray())
    }
    return $o
}

function PH-LoadJson([string]$path) {
    try {
        if (-not (Test-Path -LiteralPath $path)) { return $null }
        $txt = [IO.File]::ReadAllText($path, [Text.Encoding]::UTF8)
        if ([string]::IsNullOrWhiteSpace($txt)) { return $null }
        if ($PSVersionTable.PSVersion.Major -ge 6) { $o = ConvertFrom-Json -InputObject $txt -AsHashtable }
        else {
            Add-Type -AssemblyName System.Web.Extensions
            $js = New-Object Web.Script.Serialization.JavaScriptSerializer
            $js.MaxJsonLength = [int]::MaxValue; $js.RecursionLimit = 256
            $o = $js.DeserializeObject($txt)
        }
        return (PH-Norm $o)
    } catch {
        Write-Log "Could not read $path : $($_.Exception.Message)"
        return $null
    }
}

function PH-JsonStr([string]$s) {
    $s = $s.Replace('\', '\\').Replace('"', '\"').Replace("`r", '\r').Replace("`n", '\n').Replace("`t", '\t')
    $s = [regex]::Replace($s, '[\x00-\x1f]', '')
    return '"' + $s + '"'
}

function PH-ToJson($o, [Text.StringBuilder]$sb) {
    if ($null -eq $o) { [void]$sb.Append('null'); return }
    $b = $o
    if ($o -is [Management.Automation.PSObject]) { $b = $o.PSObject.BaseObject }
    if ($b -is [string]) { [void]$sb.Append((PH-JsonStr $b)); return }
    if ($b -is [bool]) { if ($b) { [void]$sb.Append('true') } else { [void]$sb.Append('false') }; return }
    if ($b -is [datetime]) { [void]$sb.Append('"' + $b.ToString('s') + '"'); return }
    if ($b -is [int] -or $b -is [long] -or $b -is [int16] -or $b -is [byte] -or $b -is [uint32] -or $b -is [uint64]) { [void]$sb.Append($b.ToString([Globalization.CultureInfo]::InvariantCulture)); return }
    if ($b -is [double] -or $b -is [single] -or $b -is [decimal]) {
        $dv = [double]$b; if ([double]::IsNaN($dv) -or [double]::IsInfinity($dv)) { $dv = 0 }
        [void]$sb.Append($dv.ToString('R', [Globalization.CultureInfo]::InvariantCulture)); return
    }
    if ($b -is [Collections.IDictionary]) {
        [void]$sb.Append('{'); $first = $true
        foreach ($k in $b.Keys) {
            if (-not $first) { [void]$sb.Append(',') }; $first = $false
            [void]$sb.Append((PH-JsonStr ([string]$k))); [void]$sb.Append(':')
            PH-ToJson $b[$k] $sb
        }
        [void]$sb.Append('}'); return
    }
    if ($b -is [Management.Automation.PSCustomObject]) {
        [void]$sb.Append('{'); $first = $true
        foreach ($p in $o.PSObject.Properties) {
            if (-not $first) { [void]$sb.Append(',') }; $first = $false
            [void]$sb.Append((PH-JsonStr $p.Name)); [void]$sb.Append(':')
            PH-ToJson $p.Value $sb
        }
        [void]$sb.Append('}'); return
    }
    if ($b -is [Collections.IEnumerable]) {
        [void]$sb.Append('['); $first = $true
        foreach ($i in $b) {
            if (-not $first) { [void]$sb.Append(',') }; $first = $false
            PH-ToJson $i $sb
        }
        [void]$sb.Append(']'); return
    }
    [void]$sb.Append((PH-JsonStr ([string]$b)))
}

function PH-ConvertToJson($obj) {
    if ($PSVersionTable.PSVersion.Major -ge 6) { return (ConvertTo-Json -InputObject $obj -Depth 12 -Compress) }
    $sb = New-Object Text.StringBuilder 65536
    PH-ToJson $obj $sb
    return $sb.ToString()
}

function PH-SaveJson($obj, [string]$path) {
    try {
        $json = PH-ConvertToJson $obj
        $tmp = $path + '.tmp'
        [IO.File]::WriteAllText($tmp, $json, (New-Object Text.UTF8Encoding $false))
        if (Test-Path -LiteralPath $path) { Copy-Item -LiteralPath $path -Destination ($path + '.bak') -Force }
        Move-Item -LiteralPath $tmp -Destination $path -Force
    } catch { Write-Log "Save failed for $path : $($_.Exception.Message)" }
}

function PH-Date($v) {
    if ($null -eq $v -or "$v" -eq '') { return [datetime]::MinValue }
    if ($v -is [datetime]) { return $v }
    $d = [datetime]::MinValue
    if ([datetime]::TryParse([string]$v, [Globalization.CultureInfo]::InvariantCulture, [Globalization.DateTimeStyles]::None, [ref]$d)) { return $d }
    return [datetime]::MinValue
}

# =====================================================================================
#  Window layout
# =====================================================================================
$XamlText = @'
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Picture House" Width="1560" Height="940" MinWidth="1180" MinHeight="680"
        WindowStartupLocation="CenterScreen" Background="#F3EEE4" FontFamily="Segoe UI" FontSize="13"
        Foreground="#1F1B16" UseLayoutRounding="True" TextOptions.TextFormattingMode="Display">
  <Window.Resources>
    <!--COMBOSTYLES-->
    <SolidColorBrush x:Key="Paper" Color="#F3EEE4"/>
    <SolidColorBrush x:Key="Card" Color="#FFFCF6"/>
    <SolidColorBrush x:Key="Ink" Color="#1F1B16"/>
    <SolidColorBrush x:Key="Muted" Color="#7B7266"/>
    <SolidColorBrush x:Key="Line" Color="#E2D9C9"/>
    <SolidColorBrush x:Key="Hover" Color="#ECE3D2"/>
    <SolidColorBrush x:Key="Accent" Color="#C8432B"/>
    <SolidColorBrush x:Key="AccentDark" Color="#A3341F"/>
    <SolidColorBrush x:Key="Teal" Color="#173F3E"/>
    <SolidColorBrush x:Key="TealLight" Color="#2A5F5C"/>
    <SolidColorBrush x:Key="Cream" Color="#F6EBD9"/>
    <SolidColorBrush x:Key="CreamDim" Color="#A6F6EBD9"/>

    <Style x:Key="BtnPrimary" TargetType="Button">
      <Setter Property="Background" Value="{StaticResource Accent}"/>
      <Setter Property="Foreground" Value="White"/>
      <Setter Property="FontWeight" Value="SemiBold"/>
      <Setter Property="Padding" Value="18,8"/>
      <Setter Property="Cursor" Value="Hand"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="Button">
            <Border x:Name="b" Background="{TemplateBinding Background}" CornerRadius="18" Padding="{TemplateBinding Padding}">
              <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
            </Border>
            <ControlTemplate.Triggers>
              <Trigger Property="IsMouseOver" Value="True"><Setter TargetName="b" Property="Background" Value="{StaticResource AccentDark}"/></Trigger>
              <Trigger Property="IsEnabled" Value="False"><Setter TargetName="b" Property="Opacity" Value="0.45"/></Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>

    <Style x:Key="BtnGhost" TargetType="Button">
      <Setter Property="Background" Value="Transparent"/>
      <Setter Property="Foreground" Value="{StaticResource Ink}"/>
      <Setter Property="BorderBrush" Value="{StaticResource Line}"/>
      <Setter Property="Padding" Value="12,6"/>
      <Setter Property="Margin" Value="0,0,6,6"/>
      <Setter Property="Cursor" Value="Hand"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="Button">
            <Border x:Name="b" Background="{TemplateBinding Background}" BorderBrush="{TemplateBinding BorderBrush}" BorderThickness="1" CornerRadius="16" Padding="{TemplateBinding Padding}">
              <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
            </Border>
            <ControlTemplate.Triggers>
              <Trigger Property="IsMouseOver" Value="True"><Setter TargetName="b" Property="Background" Value="{StaticResource Hover}"/></Trigger>
              <Trigger Property="IsEnabled" Value="False"><Setter TargetName="b" Property="Opacity" Value="0.45"/></Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>

    <Style x:Key="BtnRail" TargetType="Button">
      <Setter Property="Foreground" Value="{StaticResource Cream}"/>
      <Setter Property="HorizontalContentAlignment" Value="Left"/>
      <Setter Property="Cursor" Value="Hand"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="Button">
            <Border x:Name="b" Background="#2A5F5C" CornerRadius="8" Padding="14,9">
              <ContentPresenter HorizontalAlignment="Left" VerticalAlignment="Center"/>
            </Border>
            <ControlTemplate.Triggers>
              <Trigger Property="IsMouseOver" Value="True"><Setter TargetName="b" Property="Background" Value="#367470"/></Trigger>
              <Trigger Property="IsEnabled" Value="False"><Setter TargetName="b" Property="Opacity" Value="0.4"/></Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>

    <Style x:Key="Nav" TargetType="RadioButton">
      <Setter Property="Foreground" Value="{StaticResource Ink}"/>
      <Setter Property="Margin" Value="0,0,4,0"/>
      <Setter Property="Cursor" Value="Hand"/>
      <Setter Property="FontSize" Value="13.5"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="RadioButton">
            <Border x:Name="b" Background="Transparent" CornerRadius="17" Padding="15,7">
              <ContentPresenter x:Name="c" VerticalAlignment="Center"/>
            </Border>
            <ControlTemplate.Triggers>
              <Trigger Property="IsMouseOver" Value="True"><Setter TargetName="b" Property="Background" Value="{StaticResource Hover}"/></Trigger>
              <Trigger Property="IsChecked" Value="True">
                <Setter TargetName="b" Property="Background" Value="{StaticResource Ink}"/>
                <Setter Property="Foreground" Value="{StaticResource Cream}"/>
              </Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>

    <Style x:Key="Chip" TargetType="ToggleButton">
      <Setter Property="Foreground" Value="{StaticResource Ink}"/>
      <Setter Property="Margin" Value="0,0,6,6"/>
      <Setter Property="Cursor" Value="Hand"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="ToggleButton">
            <Border x:Name="b" Background="{StaticResource Card}" BorderBrush="{StaticResource Line}" BorderThickness="1" CornerRadius="15" Padding="12,5">
              <ContentPresenter VerticalAlignment="Center" HorizontalAlignment="Center"/>
            </Border>
            <ControlTemplate.Triggers>
              <Trigger Property="IsMouseOver" Value="True"><Setter TargetName="b" Property="Background" Value="{StaticResource Hover}"/></Trigger>
              <Trigger Property="IsChecked" Value="True">
                <Setter TargetName="b" Property="Background" Value="{StaticResource Teal}"/>
                <Setter TargetName="b" Property="BorderBrush" Value="{StaticResource Teal}"/>
                <Setter Property="Foreground" Value="{StaticResource Cream}"/>
              </Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>

    <Style x:Key="Seg" TargetType="RadioButton">
      <Setter Property="Foreground" Value="{StaticResource Ink}"/>
      <Setter Property="Cursor" Value="Hand"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="RadioButton">
            <Border x:Name="b" Background="{StaticResource Card}" BorderBrush="{StaticResource Line}" BorderThickness="1" CornerRadius="6" Padding="11,5" Margin="0,0,4,0">
              <ContentPresenter VerticalAlignment="Center"/>
            </Border>
            <ControlTemplate.Triggers>
              <Trigger Property="IsChecked" Value="True">
                <Setter TargetName="b" Property="Background" Value="{StaticResource Ink}"/>
                <Setter Property="Foreground" Value="{StaticResource Cream}"/>
              </Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>

    <Style x:Key="PickChip" TargetType="RadioButton">
      <Setter Property="Foreground" Value="{StaticResource Ink}"/>
      <Setter Property="Cursor" Value="Hand"/>
      <Setter Property="FontSize" Value="13"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="RadioButton">
            <Border x:Name="b" Background="{StaticResource Card}" BorderBrush="{StaticResource Line}" BorderThickness="1" CornerRadius="15" Padding="13,5" Margin="0,0,6,6">
              <ContentPresenter VerticalAlignment="Center"/>
            </Border>
            <ControlTemplate.Triggers>
              <Trigger Property="IsMouseOver" Value="True">
                <Setter TargetName="b" Property="Background" Value="{StaticResource Hover}"/>
              </Trigger>
              <Trigger Property="IsChecked" Value="True">
                <Setter TargetName="b" Property="Background" Value="{StaticResource Teal}"/>
                <Setter TargetName="b" Property="BorderBrush" Value="{StaticResource Teal}"/>
                <Setter Property="Foreground" Value="{StaticResource Cream}"/>
              </Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>

    <Style x:Key="Field" TargetType="TextBox">
      <Setter Property="Background" Value="{StaticResource Card}"/>
      <Setter Property="BorderBrush" Value="{StaticResource Line}"/>
      <Setter Property="Padding" Value="9,6"/>
      <Setter Property="VerticalContentAlignment" Value="Center"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="TextBox">
            <Border x:Name="b" Background="{TemplateBinding Background}" BorderBrush="{TemplateBinding BorderBrush}" BorderThickness="1" CornerRadius="7">
              <ScrollViewer x:Name="PART_ContentHost" Margin="{TemplateBinding Padding}" VerticalAlignment="{TemplateBinding VerticalContentAlignment}"/>
            </Border>
            <ControlTemplate.Triggers>
              <Trigger Property="IsKeyboardFocused" Value="True"><Setter TargetName="b" Property="BorderBrush" Value="{StaticResource Accent}"/></Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>

    <Style x:Key="H1" TargetType="TextBlock">
      <Setter Property="FontFamily" Value="Georgia"/>
      <Setter Property="FontSize" Value="30"/>
    </Style>
    <Style x:Key="H2" TargetType="TextBlock">
      <Setter Property="FontFamily" Value="Georgia"/>
      <Setter Property="FontSize" Value="19"/>
      <Setter Property="Margin" Value="0,0,0,8"/>
    </Style>
    <Style x:Key="Cap" TargetType="TextBlock">
      <Setter Property="FontSize" Value="10.5"/>
      <Setter Property="FontWeight" Value="Bold"/>
      <Setter Property="Foreground" Value="{StaticResource Muted}"/>
      <Setter Property="Margin" Value="0,16,0,6"/>
    </Style>
    <Style x:Key="RailCap" TargetType="TextBlock">
      <Setter Property="FontSize" Value="10"/>
      <Setter Property="FontWeight" Value="Bold"/>
      <Setter Property="Foreground" Value="#80F6EBD9"/>
      <Setter Property="Margin" Value="12,16,0,6"/>
    </Style>
    <Style x:Key="CardBox" TargetType="Border">
      <Setter Property="Background" Value="{StaticResource Card}"/>
      <Setter Property="BorderBrush" Value="{StaticResource Line}"/>
      <Setter Property="BorderThickness" Value="1"/>
      <Setter Property="CornerRadius" Value="10"/>
      <Setter Property="Padding" Value="18"/>
      <Setter Property="Margin" Value="0,0,14,14"/>
    </Style>

    <Style x:Key="RailItem" TargetType="ListBoxItem">
      <Setter Property="Cursor" Value="Hand"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="ListBoxItem">
            <Border x:Name="bd" Background="Transparent" CornerRadius="7" Padding="10,7" Margin="0,1">
              <ContentPresenter/>
            </Border>
            <ControlTemplate.Triggers>
              <Trigger Property="IsMouseOver" Value="True"><Setter TargetName="bd" Property="Background" Value="#1AFFFFFF"/></Trigger>
              <Trigger Property="IsSelected" Value="True"><Setter TargetName="bd" Property="Background" Value="#2A5F5C"/></Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>

    <Style x:Key="PlainItem" TargetType="ListBoxItem">
      <Setter Property="Focusable" Value="False"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="ListBoxItem"><ContentPresenter HorizontalAlignment="Stretch"/></ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>

    <Style x:Key="PickItem" TargetType="ListBoxItem">
      <Setter Property="Cursor" Value="Hand"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="ListBoxItem">
            <Border x:Name="bd" Background="Transparent" CornerRadius="7" Padding="8,6" Margin="0,1">
              <ContentPresenter/>
            </Border>
            <ControlTemplate.Triggers>
              <Trigger Property="IsMouseOver" Value="True"><Setter TargetName="bd" Property="Background" Value="{StaticResource Hover}"/></Trigger>
              <Trigger Property="IsSelected" Value="True"><Setter TargetName="bd" Property="Background" Value="#E3D7C2"/></Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>

    <Style TargetType="DataGrid">
      <Setter Property="Background" Value="{StaticResource Card}"/>
      <Setter Property="RowBackground" Value="{StaticResource Card}"/>
      <Setter Property="AlternatingRowBackground" Value="#FAF5EC"/>
      <Setter Property="BorderBrush" Value="{StaticResource Line}"/>
      <Setter Property="HorizontalGridLinesBrush" Value="{StaticResource Line}"/>
      <Setter Property="GridLinesVisibility" Value="Horizontal"/>
      <Setter Property="HeadersVisibility" Value="Column"/>
      <Setter Property="RowHeight" Value="30"/>
      <Setter Property="CanUserAddRows" Value="False"/>
      <Setter Property="CanUserDeleteRows" Value="False"/>
      <Setter Property="IsReadOnly" Value="True"/>
      <Setter Property="SelectionMode" Value="Single"/>
      <Setter Property="AutoGenerateColumns" Value="False"/>
    </Style>
    <Style TargetType="DataGridColumnHeader">
      <Setter Property="Background" Value="{StaticResource Paper}"/>
      <Setter Property="Padding" Value="8,7"/>
      <Setter Property="FontWeight" Value="SemiBold"/>
      <Setter Property="BorderBrush" Value="{StaticResource Line}"/>
      <Setter Property="BorderThickness" Value="0,0,0,1"/>
    </Style>
    <Style TargetType="DataGridCell">
      <Setter Property="BorderThickness" Value="0"/>
      <Setter Property="Padding" Value="6,0"/>
      <Style.Triggers>
        <Trigger Property="IsSelected" Value="True">
          <Setter Property="Background" Value="#E3D7C2"/>
          <Setter Property="Foreground" Value="{StaticResource Ink}"/>
        </Trigger>
      </Style.Triggers>
    </Style>

    <!-- ===== A film on the wall ===== -->
    <DataTemplate x:Key="FilmTile">
      <Border Width="150" Margin="11,8,11,16" Background="Transparent" Cursor="Hand" ToolTip="{Binding Tip}">
        <StackPanel>
          <Grid Width="150" Height="225">
            <Grid.Style>
              <Style TargetType="Grid">
                <Setter Property="RenderTransform"><Setter.Value><TranslateTransform Y="0"/></Setter.Value></Setter>
                <Style.Triggers>
                  <Trigger Property="IsMouseOver" Value="True">
                    <Setter Property="RenderTransform"><Setter.Value><TranslateTransform Y="-4"/></Setter.Value></Setter>
                  </Trigger>
                </Style.Triggers>
              </Style>
            </Grid.Style>
            <Border CornerRadius="4" Background="{Binding ShelfBrush}">
              <Border.Effect><DropShadowEffect BlurRadius="12" ShadowDepth="3" Direction="270" Opacity="0.28"/></Border.Effect>
              <TextBlock Text="{Binding Title}" FontFamily="Georgia" FontSize="17" Foreground="#F6EBD9" TextWrapping="Wrap"
                         TextAlignment="Center" VerticalAlignment="Center" Margin="12"/>
            </Border>
            <Border CornerRadius="4">
              <Border.Background><ImageBrush ImageSource="{Binding Poster}" Stretch="UniformToFill"/></Border.Background>
            </Border>
            <Border Height="4" VerticalAlignment="Bottom" CornerRadius="0,0,4,4" Background="{Binding ShelfBrush}"/>
            <Border Visibility="{Binding ResVis}" Background="#E61F1B16" CornerRadius="3" Padding="5,1" Margin="6"
                    HorizontalAlignment="Left" VerticalAlignment="Top">
              <TextBlock Text="{Binding Res}" FontSize="10" FontWeight="Bold" Foreground="#F6EBD9"/>
            </Border>
            <Border Visibility="{Binding WatchedVis}" Width="24" Height="24" CornerRadius="12" Background="#173F3E"
                    BorderBrush="#F6EBD9" BorderThickness="1.5" Margin="6" HorizontalAlignment="Right" VerticalAlignment="Top">
              <TextBlock Text="✓" Foreground="#F6EBD9" FontWeight="Bold" HorizontalAlignment="Center" VerticalAlignment="Center" FontSize="12"/>
            </Border>
            <StackPanel Orientation="Horizontal" HorizontalAlignment="Right" VerticalAlignment="Bottom" Margin="0,0,7,10">
              <Border Visibility="{Binding ListVis}" Width="24" Height="24" CornerRadius="12" Background="#F6EBD9" Margin="3,0,0,0">
                <TextBlock Text="⌚" Foreground="#173F3E" FontSize="12" HorizontalAlignment="Center" VerticalAlignment="Center"/>
              </Border>
              <Border Visibility="{Binding FavVis}" Width="24" Height="24" CornerRadius="12" Background="#F6EBD9" Margin="3,0,0,0">
                <TextBlock Text="♥" Foreground="#C8432B" FontSize="13" HorizontalAlignment="Center" VerticalAlignment="Center"/>
              </Border>
            </StackPanel>
          </Grid>
          <TextBlock Text="{Binding Title}" FontWeight="SemiBold" Margin="1,9,0,0" TextTrimming="CharacterEllipsis"/>
          <TextBlock Text="{Binding Sub}" Foreground="#5B5348" FontSize="12.5" Margin="1,2,0,0" TextTrimming="CharacterEllipsis"/>
        </StackPanel>
      </Border>
    </DataTemplate>

    <DataTemplate x:Key="ShelfItem">
      <Grid>
        <Grid.ColumnDefinitions>
          <ColumnDefinition Width="12"/><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/>
        </Grid.ColumnDefinitions>
        <Border Width="4" Height="16" CornerRadius="2" Background="{Binding Brush}" HorizontalAlignment="Left"/>
        <TextBlock Grid.Column="1" Text="{Binding Name}" Foreground="#F6EBD9" TextTrimming="CharacterEllipsis"
                   Margin="{Binding Indent}" ToolTip="{Binding Tip}" VerticalAlignment="Center"/>
        <TextBlock Grid.Column="2" Text="{Binding Count}" Foreground="#99F6EBD9" FontSize="11" VerticalAlignment="Center" Margin="6,0,0,0"/>
      </Grid>
    </DataTemplate>

    <DataTemplate x:Key="CastCard">
      <Border Width="78" Margin="0,0,6,10" Background="Transparent" Cursor="Hand" ToolTip="{Binding Tip}">
        <StackPanel>
          <Grid Width="58" Height="58">
            <Ellipse Fill="#E2D9C9"/>
            <TextBlock Text="{Binding Initials}" Foreground="#7B7266" FontWeight="SemiBold" HorizontalAlignment="Center" VerticalAlignment="Center"/>
            <Ellipse><Ellipse.Fill><ImageBrush ImageSource="{Binding Photo}" Stretch="UniformToFill"/></Ellipse.Fill></Ellipse>
          </Grid>
          <TextBlock Text="{Binding Name}" FontSize="11" FontWeight="SemiBold" TextAlignment="Center" TextWrapping="Wrap" Margin="0,5,0,0" MaxHeight="30"/>
          <TextBlock Text="{Binding Role}" FontSize="10.5" Foreground="#7B7266" TextAlignment="Center" TextTrimming="CharacterEllipsis"/>
        </StackPanel>
      </Border>
    </DataTemplate>

    <DataTemplate x:Key="BarRow">
      <Grid Margin="0,3">
        <Grid.ColumnDefinitions>
          <ColumnDefinition Width="130"/><ColumnDefinition Width="*"/><ColumnDefinition Width="44"/>
        </Grid.ColumnDefinitions>
        <TextBlock Text="{Binding Label}" TextTrimming="CharacterEllipsis" VerticalAlignment="Center" ToolTip="{Binding Label}" Margin="0,0,8,0"/>
        <!-- the bar fills its share of the space, so the number sits right after the longest bar -->
        <Grid Grid.Column="1" Height="14" VerticalAlignment="Center">
          <Grid.ColumnDefinitions><ColumnDefinition Width="{Binding BarStar}"/><ColumnDefinition Width="{Binding RestStar}"/></Grid.ColumnDefinitions>
          <Border CornerRadius="3" Background="{Binding Brush}" MinWidth="3"/>
        </Grid>
        <TextBlock Grid.Column="2" Text="{Binding ValueText}" Foreground="#7B7266" HorizontalAlignment="Right" VerticalAlignment="Center"/>
      </Grid>
    </DataTemplate>
  </Window.Resources>

  <Grid>
    <Grid.ColumnDefinitions>
      <ColumnDefinition Width="236"/>
      <ColumnDefinition Width="*"/>
      <ColumnDefinition x:Name="colDetail" Width="0"/>
    </Grid.ColumnDefinitions>
    <Grid.RowDefinitions>
      <RowDefinition Height="*"/>
      <RowDefinition Height="40"/>
    </Grid.RowDefinitions>

    <!-- ================= Rail ================= -->
    <Border Grid.Column="0" Background="{StaticResource Teal}">
      <DockPanel>
        <StackPanel DockPanel.Dock="Top" Margin="22,24,18,6">
          <TextBlock Text="Picture House" FontFamily="Georgia" FontStyle="Italic" FontSize="27" Foreground="{StaticResource Cream}"/>
          <TextBlock Text="F I L M    L I B R A R Y" FontSize="9.5" Foreground="#99F6EBD9" Margin="2,3,0,0"/>
          <Rectangle Height="2" Fill="{StaticResource Accent}" Width="44" HorizontalAlignment="Left" Margin="2,12,0,0"/>
        </StackPanel>
        <StackPanel DockPanel.Dock="Bottom" Margin="16,8,16,16">
          <Button x:Name="btnScan" Style="{StaticResource BtnRail}" Content="⟳   Rescan the NAS"/>
          <Button x:Name="btnMatchAll" Style="{StaticResource BtnRail}" Content="✦   Fetch missing film info" Margin="0,8,0,0"/>
          <TextBlock x:Name="txtLastScan" Foreground="#99F6EBD9" FontSize="11" Margin="3,10,0,0" TextWrapping="Wrap"/>
        </StackPanel>
        <ScrollViewer VerticalScrollBarVisibility="Auto">
          <StackPanel Margin="10,0,10,6">
            <TextBlock Text="BROWSE" Style="{StaticResource RailCap}"/>
            <ListBox x:Name="lbSmart" Background="Transparent" BorderThickness="0" ItemContainerStyle="{StaticResource RailItem}" ItemTemplate="{StaticResource ShelfItem}">
              <ListBox.Template><ControlTemplate TargetType="ListBox"><ItemsPresenter/></ControlTemplate></ListBox.Template>
            </ListBox>
            <TextBlock Text="SHELVES  ·  YOUR NAS FOLDERS" Style="{StaticResource RailCap}"/>
            <ListBox x:Name="lbShelves" Background="Transparent" BorderThickness="0" ItemContainerStyle="{StaticResource RailItem}" ItemTemplate="{StaticResource ShelfItem}">
              <ListBox.Template><ControlTemplate TargetType="ListBox"><ItemsPresenter/></ControlTemplate></ListBox.Template>
            </ListBox>
            <TextBlock x:Name="txtNoShelves" Foreground="#99F6EBD9" TextWrapping="Wrap" Margin="12,4,8,0" FontSize="12"
                       Text="No shelves yet. Add your NAS film folder in Settings, then press Rescan."/>
          </StackPanel>
        </ScrollViewer>
      </DockPanel>
    </Border>

    <!-- ================= Main ================= -->
    <Grid Grid.Column="1">
      <Grid.RowDefinitions>
        <RowDefinition Height="Auto"/>
        <RowDefinition Height="*"/>
      </Grid.RowDefinitions>
      <Grid Margin="24,18,20,4">
        <Grid.ColumnDefinitions>
          <ColumnDefinition Width="*"/>
          <ColumnDefinition Width="Auto"/>
        </Grid.ColumnDefinitions>
        <WrapPanel VerticalAlignment="Center">
          <RadioButton x:Name="navLibrary" GroupName="nav" Style="{StaticResource Nav}" Content="Library" IsChecked="True"/>
          <RadioButton x:Name="navCollections" GroupName="nav" Style="{StaticResource Nav}" Content="Collections"/>
          <RadioButton x:Name="navTonight" GroupName="nav" Style="{StaticResource Nav}" Content="Tonight's Pick"/>
          <RadioButton x:Name="navPeople" GroupName="nav" Style="{StaticResource Nav}" Content="People"/>
          <RadioButton x:Name="navHealth" GroupName="nav" Style="{StaticResource Nav}" Content="Health"/>
          <RadioButton x:Name="navUpgrades" GroupName="nav" Style="{StaticResource Nav}" Content="Upgrades"/>
          <RadioButton x:Name="navStats" GroupName="nav" Style="{StaticResource Nav}" Content="Stats"/>
          <RadioButton x:Name="navUtilities" GroupName="nav" Style="{StaticResource Nav}" Content="Utilities"/>
          <RadioButton x:Name="navSettings" GroupName="nav" Style="{StaticResource Nav}" Content="Settings"/>
          <Button x:Name="btnAbout" Style="{StaticResource BtnGhost}" Content="About" Margin="14,0,0,0" VerticalAlignment="Center" ToolTip="About Picture House and credits"/>
        </WrapPanel>
        <StackPanel Grid.Column="1" Orientation="Horizontal" VerticalAlignment="Center">
          <Grid Width="290">
            <TextBox x:Name="txtSearch" Style="{StaticResource Field}" Padding="15,3,5,3"/>
            <TextBlock Text="⌕" FontSize="16" Foreground="#7B7266" Margin="11,0,0,2" VerticalAlignment="Center" IsHitTestVisible="False"/>
            <TextBlock x:Name="txtSearchHint" Text="Search titles, people, genres…" Foreground="#9C9385" Margin="32,0,0,0"
                       VerticalAlignment="Center" IsHitTestVisible="False"/>
          </Grid>
          <Button x:Name="btnHelp" Style="{StaticResource BtnGhost}" Content="?" Width="34" Margin="8,0,0,0" FontWeight="Bold" ToolTip="Help"/>
          <Button x:Name="btnShowDetail" Style="{StaticResource BtnGhost}" Content="&#xE89F;" FontFamily="Segoe Fluent Icons, Segoe MDL2 Assets" FontSize="14" Width="34" Margin="4,0,0,0" ToolTip="Show / hide the film panel"/>
        </StackPanel>
      </Grid>

      <TabControl x:Name="tabs" Grid.Row="1" Background="Transparent" BorderThickness="0" Padding="0">
        <TabControl.ItemContainerStyle>
          <Style TargetType="TabItem"><Setter Property="Visibility" Value="Collapsed"/></Style>
        </TabControl.ItemContainerStyle>

        <!-- ===== Library ===== -->
        <TabItem>
          <Grid Margin="18,2,6,0">
            <Grid.RowDefinitions>
              <RowDefinition Height="Auto"/><RowDefinition Height="Auto"/><RowDefinition Height="*"/>
            </Grid.RowDefinitions>
            <Grid Margin="8,8,10,4">
              <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions>
              <StackPanel>
                <StackPanel Orientation="Horizontal">
                  <Border x:Name="bdShelfSwatch" Width="10" Height="26" CornerRadius="3" Background="{StaticResource Accent}" Margin="0,4,12,0" VerticalAlignment="Center"/>
                  <TextBlock x:Name="txtShelfTitle" Style="{StaticResource H1}" Text="All films"/>
                </StackPanel>
                <TextBlock x:Name="txtShelfSub" Foreground="{StaticResource Muted}" Margin="23,2,0,0"/>
              </StackPanel>
              <StackPanel Grid.Column="1" Orientation="Horizontal" VerticalAlignment="Bottom">
                <TextBlock Text="Sort" Foreground="{StaticResource Muted}" VerticalAlignment="Center" Margin="0,0,6,0"/>
                <ComboBox x:Name="cbSort" Width="160" VerticalContentAlignment="Center"/>
                <TextBlock Text="Group" Foreground="{StaticResource Muted}" VerticalAlignment="Center" Margin="14,0,6,0"/>
                <ComboBox x:Name="cbGroup" Width="110" Margin="0,0,14,0"/>
                <RadioButton x:Name="rbPosters" GroupName="view" Style="{StaticResource Seg}" Content="▦  Posters" IsChecked="True"/>
                <RadioButton x:Name="rbList" GroupName="view" Style="{StaticResource Seg}" Content="☰  List"/>
              </StackPanel>
            </Grid>
            <StackPanel Grid.Row="1">
            <WrapPanel Margin="8,10,0,6">
              <ToggleButton x:Name="tgUnwatched" Style="{StaticResource Chip}" Content="Unwatched"/>
              <ToggleButton x:Name="tgFavs" Style="{StaticResource Chip}" Content="♥  Favourites"/>
              <ToggleButton x:Name="tgList" Style="{StaticResource Chip}" Content="⌚  Watchlist"/>
              <ToggleButton x:Name="tgNoInfo" Style="{StaticResource Chip}" Content="Missing info"/>
              <ComboBox x:Name="cbGenre" Tag="filter" Width="140" Margin="6,0,6,6"/>
              <ComboBox x:Name="cbDecade" Tag="filter" Width="120" Margin="0,0,6,6"/>
              <ComboBox x:Name="cbRes" Tag="filter" Width="110" Margin="0,0,6,6"/>
              <Button x:Name="btnClearFilters" Style="{StaticResource BtnGhost}" Content="Clear filters"/>
            </WrapPanel>
            <Border x:Name="bdPeopleHits" Visibility="Collapsed" Margin="8,2,10,8" Background="{StaticResource Card}" BorderBrush="{StaticResource Line}" BorderThickness="1" CornerRadius="10" Padding="14,8,8,4">
              <DockPanel>
                <TextBlock DockPanel.Dock="Left" Text="PEOPLE" Style="{StaticResource Cap}" Margin="0,14,16,0" VerticalAlignment="Top"/>
                <ItemsControl x:Name="icPeopleHits">
                  <ItemsControl.ItemsPanel><ItemsPanelTemplate><WrapPanel/></ItemsPanelTemplate></ItemsControl.ItemsPanel>
                  <ItemsControl.ItemTemplate>
                    <DataTemplate>
                      <Border Tag="{Binding Tag}" Cursor="Hand" CornerRadius="24" Padding="4,4,16,4" Margin="0,0,8,4" Background="Transparent" ToolTip="Open in People">
                        <Border.Style><Style TargetType="Border"><Style.Triggers><Trigger Property="IsMouseOver" Value="True"><Setter Property="Background" Value="{StaticResource Hover}"/></Trigger></Style.Triggers></Style></Border.Style>
                        <StackPanel Orientation="Horizontal">
                          <Grid Width="40" Height="40">
                            <Ellipse Fill="#D8CCB7"/>
                            <TextBlock Text="{Binding Initials}" Foreground="#5B5348" FontSize="13" HorizontalAlignment="Center" VerticalAlignment="Center"/>
                            <Ellipse><Ellipse.Fill><ImageBrush ImageSource="{Binding Photo}" Stretch="UniformToFill"/></Ellipse.Fill></Ellipse>
                          </Grid>
                          <StackPanel Margin="10,0,0,0" VerticalAlignment="Center">
                            <TextBlock Text="{Binding Name}" FontSize="14"/>
                            <TextBlock Text="{Binding Sub}" Foreground="{StaticResource Muted}" FontSize="12"/>
                          </StackPanel>
                        </StackPanel>
                      </Border>
                    </DataTemplate>
                  </ItemsControl.ItemTemplate>
                </ItemsControl>
              </DockPanel>
            </Border>
            </StackPanel>
            <ListBox x:Name="lbWall" Grid.Row="2" Background="Transparent" BorderThickness="0" HorizontalContentAlignment="Stretch"
                     ItemContainerStyle="{StaticResource PlainItem}"
                     VirtualizingPanel.IsVirtualizing="True" VirtualizingPanel.VirtualizationMode="Recycling"
                     VirtualizingPanel.ScrollUnit="Pixel" ScrollViewer.HorizontalScrollBarVisibility="Disabled">
              <ListBox.ItemTemplate>
                <DataTemplate>
                  <StackPanel>
                    <StackPanel Orientation="Horizontal" Visibility="{Binding HeaderVis}" Margin="12,14,0,4">
                      <TextBlock Text="{Binding Header}" FontFamily="Georgia" FontSize="21"/>
                      <TextBlock Text="{Binding HeaderSub}" Foreground="#7B7266" Margin="10,0,0,3" VerticalAlignment="Bottom"/>
                    </StackPanel>
                    <ItemsControl ItemsSource="{Binding Items}" ItemTemplate="{StaticResource FilmTile}">
                      <ItemsControl.ItemsPanel><ItemsPanelTemplate><UniformGrid Rows="1" Columns="{Binding Cols}"/></ItemsPanelTemplate></ItemsControl.ItemsPanel>
                    </ItemsControl>
                  </StackPanel>
                </DataTemplate>
              </ListBox.ItemTemplate>
            </ListBox>
            <DataGrid x:Name="dgList" Grid.Row="2" Visibility="Collapsed" Margin="8,0,10,10">
              <DataGrid.Columns>
                <DataGridTextColumn Header="Title" Binding="{Binding Title}" Width="2*"/>
                <DataGridTextColumn Header="Year" Binding="{Binding YearText}" Width="60"/>
                <DataGridTextColumn Header="Shelf" Binding="{Binding Shelf}" Width="*"/>
                <DataGridTextColumn Header="Genres" Binding="{Binding GenreText}" Width="*"/>
                <DataGridTextColumn Header="Runtime" Binding="{Binding RuntimeText}" Width="75"/>
                <DataGridTextColumn Header="TMDb" Binding="{Binding RatingText}" Width="55"/>
                <DataGridTextColumn Header="Mine" Binding="{Binding MyStars}" Width="75"/>
                <DataGridTextColumn Header="Res" Binding="{Binding Res}" Width="60"/>
                <DataGridTextColumn Header="Size" Binding="{Binding SizeText}" Width="75"/>
                <DataGridTextColumn Header="Added" Binding="{Binding AddedText}" Width="95"/>
                <DataGridTextColumn Header="Seen" Binding="{Binding WatchedText}" Width="45"/>
              </DataGrid.Columns>
            </DataGrid>
            <TextBlock x:Name="txtEmpty" Grid.Row="2" Visibility="Collapsed" FontFamily="Georgia" FontStyle="Italic" FontSize="20"
                       Foreground="{StaticResource Muted}" HorizontalAlignment="Center" VerticalAlignment="Center" TextAlignment="Center" TextWrapping="Wrap" MaxWidth="460"/>
          </Grid>
        </TabItem>

        <!-- ===== Collections ===== -->
        <TabItem>
          <Grid Margin="26,10,10,10">
            <Grid.ColumnDefinitions><ColumnDefinition Width="320"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
            <DockPanel Margin="0,0,16,0">
              <StackPanel DockPanel.Dock="Top">
                <TextBlock Text="Collections" Style="{StaticResource H1}"/>
                <TextBlock x:Name="txtCollSummary" Foreground="{StaticResource Muted}" TextWrapping="Wrap" Margin="0,4,0,10"/>
                <StackPanel Orientation="Horizontal" Margin="0,0,0,8">
                  <ComboBox x:Name="cbCollFilter" Tag="filter" Width="150" Margin="0,0,8,0"/>
                  <Button x:Name="btnCollRefresh" Style="{StaticResource BtnGhost}" Content="⟳  Check TMDb" Margin="0"/>
                </StackPanel>
              </StackPanel>
              <ListBox x:Name="lbColls" Background="Transparent" BorderThickness="0" ItemContainerStyle="{StaticResource PickItem}"
                       ScrollViewer.HorizontalScrollBarVisibility="Disabled">
                <ListBox.ItemTemplate>
                  <DataTemplate>
                    <StackPanel>
                      <TextBlock Text="{Binding Name}" FontWeight="SemiBold" TextTrimming="CharacterEllipsis"/>
                      <StackPanel Orientation="Horizontal" Margin="0,4,0,0">
                        <Grid Width="150" Height="6">
                          <Border Background="#E2D9C9" CornerRadius="3"/>
                          <Border Background="{Binding Brush}" CornerRadius="3" Width="{Binding W}" HorizontalAlignment="Left"/>
                        </Grid>
                        <TextBlock Text="{Binding OwnedText}" Foreground="#7B7266" FontSize="11.5" Margin="10,-3,0,0"/>
                      </StackPanel>
                    </StackPanel>
                  </DataTemplate>
                </ListBox.ItemTemplate>
              </ListBox>
            </DockPanel>
            <Border Grid.Column="1" Style="{StaticResource CardBox}" Margin="0,0,10,0" Padding="0">
              <DockPanel>
                <StackPanel DockPanel.Dock="Top" Margin="22,20,22,4">
                  <TextBlock x:Name="txtCollName" FontFamily="Georgia" FontSize="25" TextWrapping="Wrap" Text="Pick a collection"/>
                  <TextBlock x:Name="txtCollInfo" Foreground="{StaticResource Muted}" Margin="0,4,0,0" TextWrapping="Wrap"/>
                  <TextBlock x:Name="txtCollOverview" TextWrapping="Wrap" Margin="0,10,0,0" MaxWidth="820" HorizontalAlignment="Left" Foreground="#4A433B"/>
                </StackPanel>
                <ScrollViewer VerticalScrollBarVisibility="Auto">
                  <ItemsControl x:Name="icParts" Margin="10,6,10,10">
                    <ItemsControl.ItemsPanel><ItemsPanelTemplate><WrapPanel/></ItemsPanelTemplate></ItemsControl.ItemsPanel>
                    <ItemsControl.ItemTemplate>
                      <DataTemplate>
                        <Border Width="160" Margin="12,8,6,14" Background="Transparent">
                          <StackPanel>
                            <Grid Width="160" Height="240" Cursor="Hand">
                              <Border CornerRadius="4" Background="#D8CCB7">
                                <TextBlock Text="{Binding Title}" FontFamily="Georgia" FontSize="16" Foreground="#5B5348" TextWrapping="Wrap" TextAlignment="Center" VerticalAlignment="Center" Margin="10">
                                  <TextBlock.Style><Style TargetType="TextBlock"><Setter Property="Visibility" Value="Collapsed"/>
                                    <Style.Triggers><DataTrigger Binding="{Binding Poster}" Value="{x:Null}"><Setter Property="Visibility" Value="Visible"/></DataTrigger></Style.Triggers>
                                  </Style></TextBlock.Style>
                                </TextBlock>
                              </Border>
                              <Border CornerRadius="4" Opacity="{Binding Opac}">
                                <Border.Background><ImageBrush ImageSource="{Binding Poster}" Stretch="UniformToFill"/></Border.Background>
                              </Border>
                              <Border Background="{Binding StatusBrush}" CornerRadius="3" Padding="7,2" Margin="7" HorizontalAlignment="Left" VerticalAlignment="Top">
                                <TextBlock Text="{Binding Status}" Foreground="White" FontSize="10" FontWeight="Bold"/>
                              </Border>
                            </Grid>
                            <TextBlock Text="{Binding Title}" FontWeight="SemiBold" Margin="0,8,0,0" TextTrimming="CharacterEllipsis" ToolTip="{Binding Title}"/>
                            <TextBlock Text="{Binding Sub}" Foreground="#7B7266" FontSize="11.5" TextTrimming="CharacterEllipsis"/>
                            <WrapPanel Margin="0,6,0,0">
                              <Button Style="{StaticResource BtnGhost}" Padding="7,2" FontSize="11" Margin="0,0,3,0" Content="+ Radarr" Tag="{Binding RadarrTag}" Visibility="{Binding MissingVis}"/>
                              <Button Style="{StaticResource BtnGhost}" Padding="7,2" FontSize="11" Margin="0,0,3,0" Content="Seerr" Tag="{Binding SeerrTag}" Visibility="{Binding MissingVis}"/>
                              <Button Style="{StaticResource BtnGhost}" Padding="7,2" FontSize="11" Margin="0" Content="TMDb" Tag="{Binding TmdbTag}"/>
                            </WrapPanel>
                          </StackPanel>
                        </Border>
                      </DataTemplate>
                    </ItemsControl.ItemTemplate>
                  </ItemsControl>
                </ScrollViewer>
              </DockPanel>
            </Border>
          </Grid>
        </TabItem>

        <!-- ===== Tonight's Pick ===== -->
        <TabItem>
          <Grid Margin="26,10,20,14">
            <Grid.RowDefinitions><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/><RowDefinition Height="*"/></Grid.RowDefinitions>
            <Grid>
              <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
              <StackPanel>
                <TextBlock Text="Tonight's Pick" Style="{StaticResource H1}"/>
                <TextBlock Text="Can't decide? Set the mood, then roll the dice." Foreground="{StaticResource Muted}" Margin="0,4,0,0"/>
              </StackPanel>
            </Grid>
            <Grid Grid.Row="1" Margin="0,4,0,12">
              <Grid.ColumnDefinitions><ColumnDefinition Width="Auto"/><ColumnDefinition Width="Auto" MaxWidth="1100"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
              <Grid.RowDefinitions><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/></Grid.RowDefinitions>
              <Border Grid.Column="2" Grid.RowSpan="5" VerticalAlignment="Top" HorizontalAlignment="Center" Margin="0,10,0,0"
                      Background="{StaticResource Card}" BorderBrush="{StaticResource Line}" BorderThickness="1" CornerRadius="12" Padding="34,10,34,14"
                      ToolTip="How many films match your choices">
                <StackPanel>
                  <TextBlock x:Name="txtPickPoolNum" FontFamily="Georgia" FontSize="46" Foreground="{StaticResource Accent}" HorizontalAlignment="Center"/>
                  <Border BorderBrush="{StaticResource Line}" BorderThickness="0,1,0,0" Padding="4,5,4,0" Margin="0,2,0,0">
                    <TextBlock x:Name="txtPickPool" FontSize="13" Foreground="{StaticResource Muted}" HorizontalAlignment="Center"/>
                  </Border>
                </StackPanel>
              </Border>
              <TextBlock Text="SHELF" Style="{StaticResource Cap}" Margin="0,14,18,0" VerticalAlignment="Top"/>
              <WrapPanel x:Name="wpPickShelf" Grid.Column="1" Margin="0,8,0,0"/>
              <TextBlock Grid.Row="1" Text="LENGTH" Style="{StaticResource Cap}" Margin="0,10,18,0" VerticalAlignment="Top"/>
              <WrapPanel x:Name="wpPickLen" Grid.Row="1" Grid.Column="1" Margin="0,4,0,0"><RadioButton x:Name="rbLenAny" GroupName="plen" Style="{StaticResource PickChip}" Tag="" Content="Any" IsChecked="True"/><RadioButton x:Name="rbLen100" GroupName="plen" Style="{StaticResource PickChip}" Tag="0-100" Content="Under 1h 40"/><RadioButton x:Name="rbLen120" GroupName="plen" Style="{StaticResource PickChip}" Tag="0-120" Content="Under 2h"/><RadioButton x:Name="rbLenLong" GroupName="plen" Style="{StaticResource PickChip}" Tag="121-999" Content="A long one (2h+)"/></WrapPanel>
              <TextBlock Grid.Row="2" Text="ERA" Style="{StaticResource Cap}" Margin="0,10,18,0" VerticalAlignment="Top"/>
              <WrapPanel x:Name="wpPickEra" Grid.Row="2" Grid.Column="1" Margin="0,4,0,0"><RadioButton x:Name="rbEraAny" GroupName="pera" Style="{StaticResource PickChip}" Tag="" Content="Any" IsChecked="True"/><RadioButton x:Name="rbEraClassic" GroupName="pera" Style="{StaticResource PickChip}" Tag="0-1969" Content="Classic"/><RadioButton x:Name="rbEra70" GroupName="pera" Style="{StaticResource PickChip}" Tag="1970-1979" Content="70s"/><RadioButton x:Name="rbEra80" GroupName="pera" Style="{StaticResource PickChip}" Tag="1980-1989" Content="80s"/><RadioButton x:Name="rbEra90" GroupName="pera" Style="{StaticResource PickChip}" Tag="1990-1999" Content="90s"/><RadioButton x:Name="rbEra00" GroupName="pera" Style="{StaticResource PickChip}" Tag="2000-2009" Content="2000s"/><RadioButton x:Name="rbEra10" GroupName="pera" Style="{StaticResource PickChip}" Tag="2010-2019" Content="2010s"/><RadioButton x:Name="rbEraNew" GroupName="pera" Style="{StaticResource PickChip}" Tag="2020-9999" Content="New"/></WrapPanel>
              <TextBlock Grid.Row="3" Text="FROM" Style="{StaticResource Cap}" Margin="0,10,18,0" VerticalAlignment="Top"/>
              <WrapPanel x:Name="wpPickFrom" Grid.Row="3" Grid.Column="1" Margin="0,4,0,0"><RadioButton x:Name="rbFromUnw" GroupName="pfrom" Style="{StaticResource PickChip}" Tag="unw" Content="Haven't watched" IsChecked="True"/><RadioButton x:Name="rbFromList" GroupName="pfrom" Style="{StaticResource PickChip}" Tag="list" Content="My watchlist"/><RadioButton x:Name="rbFromFav" GroupName="pfrom" Style="{StaticResource PickChip}" Tag="fav" Content="Favourites"/><RadioButton x:Name="rbFromAny" GroupName="pfrom" Style="{StaticResource PickChip}" Tag="any" Content="Anything"/></WrapPanel>
              <Button x:Name="btnPickReset" Grid.Row="4" Grid.Column="1" Style="{StaticResource BtnGhost}" Content="↺  Reset choices" HorizontalAlignment="Left" Margin="0,4,0,0" ToolTip="Back to any shelf, any length, any era, films you haven't watched"/>
            </Grid>
            <Border Grid.Row="2" Background="{StaticResource Teal}" CornerRadius="12" ClipToBounds="True">
              <Grid>
                <Image x:Name="imgPickBack" Stretch="UniformToFill" Opacity="0.16"/>
                <Grid Margin="30,24,36,24">
                  <Grid.ColumnDefinitions><ColumnDefinition Width="380"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
                  <StackPanel VerticalAlignment="Center" HorizontalAlignment="Center">
                    <Border x:Name="bdDice" Width="360" Height="360" Background="Transparent" Cursor="Hand" ToolTip="Roll the dice"/>
                    <TextBlock x:Name="txtDiceHint" Text="Click the dice to roll" Foreground="#C9F6EBD9" FontSize="17" HorizontalAlignment="Center" Margin="0,6,0,0"/>
                  </StackPanel>
                  <Grid x:Name="gdPickResult" Grid.Column="1" VerticalAlignment="Center" HorizontalAlignment="Center" Margin="10,0,20,0">
                    <Grid.RowDefinitions><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/></Grid.RowDefinitions>
                    <TextBlock x:Name="txtPickRolled" Text="T O N I G H T ' S    P I C T U R E" Foreground="#D9F6EBD9" FontSize="14"/>
                    <Grid Grid.Row="1" Margin="0,14,0,0">
                      <Grid.ColumnDefinitions><ColumnDefinition Width="Auto"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
                      <Border x:Name="bdPickPoster" Width="300" Height="450" CornerRadius="6" Background="#2A5F5C" Cursor="Hand" Margin="0,0,40,0" Visibility="Collapsed" ToolTip="Open in the film panel">
                        <Border.Effect><DropShadowEffect BlurRadius="30" ShadowDepth="8" Direction="270" Opacity="0.5"/></Border.Effect>
                        <Grid>
                          <TextBlock x:Name="txtPickPosterTitle" FontFamily="Georgia" FontSize="22" Foreground="#F6EBD9" TextWrapping="Wrap" TextAlignment="Center" VerticalAlignment="Center" Margin="18"/>
                          <Border CornerRadius="6"><Border.Background><ImageBrush x:Name="ibPickPoster" Stretch="UniformToFill"/></Border.Background></Border>
                        </Grid>
                      </Border>
                      <StackPanel Grid.Column="1" VerticalAlignment="Center" MaxWidth="760" HorizontalAlignment="Left">
                        <TextBlock x:Name="txtPickTitle" FontFamily="Georgia" FontSize="40" FontStyle="Italic" Foreground="#C9F6EBD9" TextWrapping="Wrap" Text="Roll the dice and let fate choose."/>
                        <TextBlock x:Name="txtPickMeta" Foreground="#D9F6EBD9" FontSize="15" Margin="0,8,0,0" TextWrapping="Wrap"/>
                        <TextBlock x:Name="txtPickPlot" Foreground="#E6F6EBD9" FontSize="15" Margin="0,16,0,0" TextWrapping="Wrap" LineHeight="23" MaxHeight="210" TextTrimming="WordEllipsis"/>
                        <WrapPanel x:Name="wpPickButtons" Margin="0,22,0,0" Visibility="Collapsed">
                          <Button x:Name="btnPickPlay" Style="{StaticResource BtnPrimary}" Content="▶  Play it" Margin="0,0,8,8"/>
                          <Button x:Name="btnPickList" Style="{StaticResource BtnRail}" Content="⌚  Save to watchlist" Margin="0,0,8,8"/>
                          <Button x:Name="btnPickDetail" Style="{StaticResource BtnRail}" Content="Details" Margin="0,0,8,8"/>
                        </WrapPanel>
                      </StackPanel>
                    </Grid>
                    <StackPanel x:Name="spPickAlt" Grid.Row="2" Orientation="Horizontal" Margin="0,22,0,0" Visibility="Collapsed">
                      <TextBlock Text="OR MAYBE" Foreground="#C9F6EBD9" FontSize="12" FontWeight="Bold" VerticalAlignment="Center" Margin="0,0,14,0"/>
                      <ItemsControl x:Name="icPickAlt">
                        <ItemsControl.ItemsPanel><ItemsPanelTemplate><StackPanel Orientation="Horizontal"/></ItemsPanelTemplate></ItemsControl.ItemsPanel>
                        <ItemsControl.ItemTemplate>
                          <DataTemplate>
                            <Border Width="90" Height="135" CornerRadius="4" Background="#2A5F5C" Margin="0,0,10,0" Cursor="Hand" ToolTip="{Binding Title}" Tag="{Binding Key}">
                              <Grid>
                                <TextBlock Text="{Binding Title}" FontFamily="Georgia" FontSize="11" Foreground="#F6EBD9" TextWrapping="Wrap" TextAlignment="Center" VerticalAlignment="Center" Margin="5"/>
                                <Border CornerRadius="4"><Border.Background><ImageBrush ImageSource="{Binding Poster}" Stretch="UniformToFill"/></Border.Background></Border>
                              </Grid>
                            </Border>
                          </DataTemplate>
                        </ItemsControl.ItemTemplate>
                      </ItemsControl>
                      <TextBlock Text="click one to swap it in" Foreground="#C9F6EBD9" FontSize="13" VerticalAlignment="Bottom" Margin="4,0,0,4"/>
                    </StackPanel>
                  </Grid>
                </Grid>
              </Grid>
            </Border>
          </Grid>
        </TabItem>

        <!-- ===== People ===== -->
        <TabItem>
          <Grid Margin="26,10,10,10">
            <Grid.ColumnDefinitions><ColumnDefinition Width="300"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
            <DockPanel Margin="0,0,16,0">
              <StackPanel DockPanel.Dock="Top">
                <TextBlock Text="People" Style="{StaticResource H1}"/>
                <TextBlock Text="Everyone in front of and behind the camera on your shelves." Foreground="{StaticResource Muted}" TextWrapping="Wrap" Margin="0,4,0,10"/>
                <StackPanel Orientation="Horizontal" Margin="0,0,0,8">
                  <RadioButton x:Name="rbActors" GroupName="ppl" Style="{StaticResource Seg}" Content="Actors" IsChecked="True"/>
                  <RadioButton x:Name="rbDirectors" GroupName="ppl" Style="{StaticResource Seg}" Content="Directors"/>
                </StackPanel>
                <StackPanel Orientation="Horizontal" Margin="0,0,0,8">
                  <TextBlock Text="Sort" Foreground="{StaticResource Muted}" VerticalAlignment="Center" Margin="0,0,8,0"/>
                  <RadioButton x:Name="rbPplCount" GroupName="pplsort" Style="{StaticResource Seg}" Content="Most films" IsChecked="True"/>
                  <RadioButton x:Name="rbPplDone" GroupName="pplsort" Style="{StaticResource Seg}" Content="Most complete" ToolTip="How many of their films you have"/>
                </StackPanel>
                <TextBox x:Name="txtPeopleSearch" Style="{StaticResource Field}" Margin="0,0,0,6"/>
                <CheckBox x:Name="chkPeopleMulti" IsChecked="False" Visibility="Collapsed"/>
              </StackPanel>
              <ListBox x:Name="lbPeople" Background="Transparent" BorderThickness="0" ItemContainerStyle="{StaticResource PickItem}"
                       ScrollViewer.HorizontalScrollBarVisibility="Disabled" VirtualizingPanel.IsVirtualizing="True">
                <ListBox.ItemTemplate>
                  <DataTemplate>
                    <Grid>
                      <Grid.ColumnDefinitions><ColumnDefinition Width="44"/><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions>
                      <Grid Width="34" Height="34" HorizontalAlignment="Left">
                        <Ellipse Fill="#E2D9C9"/>
                        <TextBlock Text="{Binding Initials}" FontSize="11" Foreground="#7B7266" HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        <Ellipse><Ellipse.Fill><ImageBrush ImageSource="{Binding Photo}" Stretch="UniformToFill"/></Ellipse.Fill></Ellipse>
                      </Grid>
                      <StackPanel Grid.Column="1" VerticalAlignment="Center">
                        <TextBlock Text="{Binding Name}" TextTrimming="CharacterEllipsis"/>
                        <TextBlock Text="{Binding DoneText}" Visibility="{Binding DoneVis}" FontSize="11" Foreground="#7B7266"/>
                      </StackPanel>
                      <Border Grid.Column="2" Background="#E2D9C9" CornerRadius="9" Padding="7,1" VerticalAlignment="Center">
                        <TextBlock Text="{Binding Count}" FontSize="11" FontWeight="SemiBold"/>
                      </Border>
                    </Grid>
                  </DataTemplate>
                </ListBox.ItemTemplate>
              </ListBox>
            </DockPanel>
            <ScrollViewer Grid.Column="1" VerticalScrollBarVisibility="Auto">
              <StackPanel Margin="12,6,10,16">
                <Grid>
                  <Grid.ColumnDefinitions><ColumnDefinition Width="Auto"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
                  <Border Width="140" Height="210" CornerRadius="6" Background="#E2D9C9" VerticalAlignment="Top">
                    <Border.Effect><DropShadowEffect BlurRadius="14" ShadowDepth="3" Direction="270" Opacity="0.25"/></Border.Effect>
                    <Border CornerRadius="6"><Border.Background><ImageBrush x:Name="ibPerson" Stretch="UniformToFill"/></Border.Background></Border>
                  </Border>
                  <StackPanel Grid.Column="1" Margin="22,0,0,0" MaxWidth="900" HorizontalAlignment="Left">
                    <TextBlock x:Name="txtPersonName" FontFamily="Georgia" FontSize="30" Text="Pick someone" TextWrapping="Wrap"/>
                    <TextBlock x:Name="txtPersonFacts" Foreground="#4A433B" FontSize="13.5" Margin="0,6,0,0" TextWrapping="Wrap"/>
                    <TextBlock x:Name="txtPersonInfo" Foreground="{StaticResource Muted}" Margin="0,4,0,0"/>
                    <StackPanel x:Name="bdPersonDone" Visibility="Collapsed" Margin="0,10,0,0" HorizontalAlignment="Left" Width="440">
                      <TextBlock x:Name="txtPersonDone" Foreground="{StaticResource Teal}" FontWeight="SemiBold"/>
                      <Grid Height="8" Margin="0,5,0,0">
                        <Grid.ColumnDefinitions><ColumnDefinition x:Name="cdPersonDoneA" Width="1*"/><ColumnDefinition x:Name="cdPersonDoneB" Width="1*"/></Grid.ColumnDefinitions>
                        <Border Grid.ColumnSpan="2" Background="#E2D9C9" CornerRadius="4"/>
                        <Border Background="{StaticResource Teal}" CornerRadius="4"/>
                      </Grid>
                    </StackPanel>
                    <TextBlock x:Name="txtPersonLoading" Foreground="{StaticResource Accent}" Margin="0,10,0,0" Visibility="Collapsed" Text="Getting details from TMDb…"/>
                    <TextBlock x:Name="txtPersonBio" TextWrapping="Wrap" LineHeight="20" Foreground="#2E2924" Margin="0,12,0,0" MaxHeight="120"/>
                    <WrapPanel Margin="0,8,0,0">
                      <Button x:Name="btnBioMore" Style="{StaticResource BtnGhost}" Content="Read more" Visibility="Collapsed"/>
                      <Button x:Name="btnPersonTmdb" Style="{StaticResource BtnGhost}" Content="TMDb ↗" Visibility="Collapsed"/>
                      <Button x:Name="btnPersonImdb" Style="{StaticResource BtnGhost}" Content="IMDb ↗" Visibility="Collapsed"/>
                    </WrapPanel>
                  </StackPanel>
                </Grid>
                <TextBlock x:Name="capPersonOwned" Text="ON YOUR SHELVES" Style="{StaticResource Cap}" Margin="2,22,0,4"/>
                <ItemsControl x:Name="icPeopleFilms" ItemTemplate="{StaticResource FilmTile}">
                  <ItemsControl.ItemsPanel><ItemsPanelTemplate><WrapPanel/></ItemsPanelTemplate></ItemsControl.ItemsPanel>
                </ItemsControl>
                <TextBlock x:Name="capPersonMore" Text="MORE FILMS" Style="{StaticResource Cap}" Margin="2,18,0,4" Visibility="Collapsed"/>
                <ItemsControl x:Name="icPersonMore">
                  <ItemsControl.ItemsPanel><ItemsPanelTemplate><WrapPanel/></ItemsPanelTemplate></ItemsControl.ItemsPanel>
                  <ItemsControl.ItemTemplate>
                      <DataTemplate>
                        <Border Width="160" Margin="12,8,6,14" Background="Transparent">
                          <StackPanel>
                            <Grid Width="160" Height="240" Cursor="Hand">
                              <Border CornerRadius="4" Background="#D8CCB7">
                                <TextBlock Text="{Binding Title}" FontFamily="Georgia" FontSize="16" Foreground="#5B5348" TextWrapping="Wrap" TextAlignment="Center" VerticalAlignment="Center" Margin="10">
                                  <TextBlock.Style><Style TargetType="TextBlock"><Setter Property="Visibility" Value="Collapsed"/>
                                    <Style.Triggers><DataTrigger Binding="{Binding Poster}" Value="{x:Null}"><Setter Property="Visibility" Value="Visible"/></DataTrigger></Style.Triggers>
                                  </Style></TextBlock.Style>
                                </TextBlock>
                              </Border>
                              <Border CornerRadius="4" Opacity="{Binding Opac}">
                                <Border.Background><ImageBrush ImageSource="{Binding Poster}" Stretch="UniformToFill"/></Border.Background>
                              </Border>
                              <Border Background="{Binding StatusBrush}" CornerRadius="3" Padding="7,2" Margin="7" HorizontalAlignment="Left" VerticalAlignment="Top">
                                <TextBlock Text="{Binding Status}" Foreground="White" FontSize="10" FontWeight="Bold"/>
                              </Border>
                            </Grid>
                            <TextBlock Text="{Binding Title}" FontWeight="SemiBold" Margin="0,8,0,0" TextTrimming="CharacterEllipsis" ToolTip="{Binding Title}"/>
                            <TextBlock Text="{Binding Sub}" Foreground="#7B7266" FontSize="11.5" TextTrimming="CharacterEllipsis"/>
                            <WrapPanel Margin="0,6,0,0">
                              <Button Style="{StaticResource BtnGhost}" Padding="7,2" FontSize="11" Margin="0,0,3,0" Content="+ Radarr" Tag="{Binding RadarrTag}" Visibility="{Binding MissingVis}"/>
                              <Button Style="{StaticResource BtnGhost}" Padding="7,2" FontSize="11" Margin="0,0,3,0" Content="Seerr" Tag="{Binding SeerrTag}" Visibility="{Binding MissingVis}"/>
                              <Button Style="{StaticResource BtnGhost}" Padding="7,2" FontSize="11" Margin="0" Content="TMDb" Tag="{Binding TmdbTag}"/>
                            </WrapPanel>
                          </StackPanel>
                        </Border>
                      </DataTemplate>
                    </ItemsControl.ItemTemplate>
                </ItemsControl>
              </StackPanel>
            </ScrollViewer>
          </Grid>
        </TabItem>

        <!-- ===== Health ===== -->
        <TabItem>
          <DockPanel Margin="26,10,26,14">
            <StackPanel DockPanel.Dock="Top">
              <TextBlock Text="Library health" Style="{StaticResource H1}"/>
              <TextBlock Text="Naming problems, missing artwork, duplicates, upgrade candidates — and how the NAS compares with Radarr." Foreground="{StaticResource Muted}" TextWrapping="Wrap" Margin="0,4,0,12"/>
              <WrapPanel Margin="0,0,0,10">
                <Button x:Name="btnHealthRun" Style="{StaticResource BtnPrimary}" Content="Run checks" Margin="0,0,8,6"/>
                <Button x:Name="btnHealthRadarr" Style="{StaticResource BtnGhost}" Content="Compare with Radarr"/>
                <Button x:Name="btnHealthExport" Style="{StaticResource BtnGhost}" Content="Export CSV"/>
                <Button x:Name="btnHealthHtml" Style="{StaticResource BtnGhost}" Content="Export HTML report"/>
                <TextBlock Text="Show" Foreground="{StaticResource Muted}" VerticalAlignment="Center" Margin="12,0,6,6"/>
                <ComboBox x:Name="cbHealthFilter" Tag="filter" Width="300" Margin="0,0,0,6"/>
              </WrapPanel>
              <WrapPanel x:Name="wpHealthSummary" Margin="0,0,0,8"/>
            </StackPanel>
            <DataGrid x:Name="dgHealth">
              <DataGrid.Columns>
                <DataGridTextColumn Header="Issue" Binding="{Binding Issue}" Width="190"/>
                <DataGridTextColumn Header="Film" Binding="{Binding Film}" Width="*"/>
                <DataGridTextColumn Header="Shelf" Binding="{Binding Shelf}" Width="150"/>
                <DataGridTextColumn Header="Detail" Binding="{Binding Detail}" Width="1.4*"/>
                <DataGridTextColumn Header="Path" Binding="{Binding Path}" Width="1.4*"/>
              </DataGrid.Columns>
            </DataGrid>
          </DockPanel>
        </TabItem>

        <!-- ===== Upgrades & duplicates ===== -->
        <TabItem>
          <DockPanel Margin="26,10,26,14">
            <StackPanel DockPanel.Dock="Top">
              <TextBlock Text="Upgrades &amp; duplicates" Style="{StaticResource H1}"/>
              <TextBlock Text="Copies worth replacing, and films you have more than once. Nothing changes unless you press a button — Picture House never upgrades or deletes anything by itself." Foreground="{StaticResource Muted}" TextWrapping="Wrap" Margin="0,4,0,12"/>
              <WrapPanel Margin="0,0,0,8">
                <RadioButton x:Name="rbUp1080" GroupName="upg" Style="{StaticResource Seg}" Content="Below 1080p" IsChecked="True"/>
                <RadioButton x:Name="rbUp4K" GroupName="upg" Style="{StaticResource Seg}" Content="Below 4K"/>
                <RadioButton x:Name="rbUpDupes" GroupName="upg" Style="{StaticResource Seg}" Content="Duplicates"/>
                <Button x:Name="btnUpRadarr" Style="{StaticResource BtnGhost}" Content="⟳  Check with Radarr" Margin="14,0,0,0"/>
              </WrapPanel>
              <TextBlock x:Name="txtUpSummary" Foreground="{StaticResource Muted}" TextWrapping="Wrap" Margin="2,4,0,10"/>
              <Border x:Name="bdPicks" Visibility="Collapsed" Background="#FFFCF6" BorderBrush="#E3CF8F" BorderThickness="1" CornerRadius="10" Padding="14,10" Margin="0,0,10,12">
                <StackPanel>
                  <TextBlock Text="YOUR PICKS — copies you chose, followed until Radarr swaps them in" Style="{StaticResource Cap}" Margin="0,0,0,6"/>
                  <ItemsControl x:Name="icPicks">
                    <ItemsControl.ItemTemplate>
                      <DataTemplate>
                        <Grid Margin="0,4">
                          <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions>
                          <StackPanel>
                            <TextBlock Text="{Binding Title}" FontFamily="Georgia" FontSize="15"/>
                            <TextBlock Text="{Binding StateText}" Foreground="{Binding StateBrush}" TextWrapping="Wrap"/>
                            <ProgressBar Value="{Binding Pct}" Maximum="100" Height="6" Width="320" HorizontalAlignment="Left" Margin="0,4,0,3" Visibility="{Binding PctVis}"
                                         Foreground="#2A7F7A" Background="#E2D9C9" BorderThickness="0"/>
                            <TextBlock Text="{Binding Detail}" Foreground="{StaticResource Muted}" FontSize="11.5" TextTrimming="CharacterEllipsis"/>
                          </StackPanel>
                          <StackPanel Grid.Column="1" Orientation="Horizontal" VerticalAlignment="Center" Margin="10,0,0,0">
                            <Button Style="{StaticResource BtnPrimary}" Content="Import it anyway" Tag="{Binding ImportTag}" Visibility="{Binding ImportVis}" Margin="0,0,6,0"/>
                            <Button Style="{StaticResource BtnGhost}" Content="Stop following" Tag="{Binding ForgetTag}" ToolTip="Stop tracking this pick here (nothing changes in Radarr)"/>
                          </StackPanel>
                        </Grid>
                      </DataTemplate>
                    </ItemsControl.ItemTemplate>
                  </ItemsControl>
                </StackPanel>
              </Border>
            </StackPanel>
            <Grid>
              <ListBox x:Name="lbUpgrades" Background="Transparent" BorderThickness="0" ItemContainerStyle="{StaticResource PlainItem}"
                       ScrollViewer.HorizontalScrollBarVisibility="Disabled" VirtualizingPanel.IsVirtualizing="True" VirtualizingPanel.ScrollUnit="Pixel">
                <ListBox.ItemTemplate>
                  <DataTemplate>
                    <Border Background="{StaticResource Card}" BorderBrush="{StaticResource Line}" BorderThickness="1" CornerRadius="10" Padding="12,10" Margin="0,0,10,8">
                      <Grid>
                        <Grid.ColumnDefinitions><ColumnDefinition Width="66"/><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions>
                        <Border Width="54" Height="81" CornerRadius="4" Background="#D8CCB7" HorizontalAlignment="Left">
                          <Border CornerRadius="4"><Border.Background><ImageBrush ImageSource="{Binding Poster}" Stretch="UniformToFill"/></Border.Background></Border>
                        </Border>
                        <StackPanel Grid.Column="1" VerticalAlignment="Center" Margin="4,0,12,0">
                          <StackPanel Orientation="Horizontal">
                            <Border Background="{Binding QBrush}" CornerRadius="3" Padding="7,1" Margin="0,0,10,0" VerticalAlignment="Center">
                              <TextBlock Text="{Binding Quality}" Foreground="White" FontSize="11" FontWeight="Bold"/>
                            </Border>
                            <TextBlock Text="{Binding Title}" FontFamily="Georgia" FontSize="17" VerticalAlignment="Center" TextTrimming="CharacterEllipsis"/>
                          </StackPanel>
                          <TextBlock Text="{Binding Sub}" Foreground="{StaticResource Muted}" Margin="0,5,0,0" TextTrimming="CharacterEllipsis"/>
                          <TextBlock Text="{Binding RadarrText}" Foreground="{Binding RadarrBrush}" Margin="0,3,0,0" TextWrapping="Wrap"/>
                        </StackPanel>
                        <WrapPanel Grid.Column="2" VerticalAlignment="Center" MaxWidth="430" HorizontalAlignment="Right">
                          <Button Style="{StaticResource BtnPrimary}" Content="Choose a copy…" Tag="{Binding ChooseTag}" Visibility="{Binding SearchVis}" Margin="0,0,6,6" ToolTip="See every copy your indexers have — size, quality, seeders — and pick the one to download"/>
                          <Button Style="{StaticResource BtnGhost}" Content="Add to Radarr" Tag="{Binding AddTag}" Visibility="{Binding AddVis}" Margin="0,0,6,6"/>
                          <Button Style="{StaticResource BtnGhost}" Content="Open folder" Tag="{Binding FolderTag}" Margin="0,0,6,6"/>
                          <Button Style="{StaticResource BtnGhost}" Content="Details" Tag="{Binding DetailTag}" Margin="0,0,6,6"/>
                        </WrapPanel>
                      </Grid>
                    </Border>
                  </DataTemplate>
                </ListBox.ItemTemplate>
              </ListBox>
              <TextBlock x:Name="txtUpEmpty" Visibility="Collapsed" FontFamily="Georgia" FontStyle="Italic" FontSize="20" Foreground="{StaticResource Muted}"
                         HorizontalAlignment="Center" VerticalAlignment="Center" TextAlignment="Center" TextWrapping="Wrap" MaxWidth="480"/>
            </Grid>
          </DockPanel>
        </TabItem>

        <!-- ===== Stats ===== -->
        <TabItem>
          <ScrollViewer VerticalScrollBarVisibility="Auto">
            <StackPanel x:Name="spStats" Margin="26,10,12,20">
              <StackPanel Orientation="Horizontal">
                <TextBlock x:Name="txtStatsTitle" Text="The numbers" Style="{StaticResource H1}" VerticalAlignment="Center" Margin="0,0,24,0"/>
                <RadioButton x:Name="rbStatsAll" GroupName="statmode" Style="{StaticResource Seg}" Content="All time" IsChecked="True" VerticalAlignment="Center" FontSize="14"/>
                <RadioButton x:Name="rbStatsYear" GroupName="statmode" Style="{StaticResource Seg}" Content="★  Year in review" VerticalAlignment="Center" FontSize="14"/>
              </StackPanel>
              <!-- ===== Year in review ===== -->
              <StackPanel x:Name="spYear" Visibility="Collapsed">
                <WrapPanel Margin="0,8,0,4">
                  <ComboBox x:Name="cbYear" Width="120" Margin="0,0,10,6"/>
                  <Button x:Name="btnYearExport" Style="{StaticResource BtnGhost}" Content="Export as a web page" Margin="0,0,0,6"/>
                </WrapPanel>
                <Border Background="{StaticResource Teal}" CornerRadius="12" Padding="30,24" Margin="0,8,14,16">
                  <StackPanel>
                    <TextBlock x:Name="txtYearKicker" Foreground="#A6F6EBD9" FontSize="12" Text="Y O U R   Y E A R   I N   F I L M"/>
                    <TextBlock x:Name="txtYearHero" FontFamily="Georgia" FontSize="32" Foreground="{StaticResource Cream}" TextWrapping="Wrap" Margin="0,8,0,0"/>
                    <TextBlock x:Name="txtYearHeroSub" Foreground="#D9F6EBD9" FontSize="15" TextWrapping="Wrap" Margin="0,8,0,0"/>
                  </StackPanel>
                </Border>
                <ItemsControl x:Name="icYearCards">
                  <ItemsControl.ItemsPanel><ItemsPanelTemplate><UniformGrid Columns="4"/></ItemsPanelTemplate></ItemsControl.ItemsPanel>
                  <ItemsControl.ItemTemplate>
                    <DataTemplate>
                      <Border Style="{StaticResource CardBox}">
                        <StackPanel>
                          <TextBlock Text="{Binding Label}" Foreground="#7B7266" FontSize="11" FontWeight="Bold"/>
                          <TextBlock Text="{Binding Value}" FontFamily="Georgia" FontSize="22" Foreground="{Binding Brush}" TextWrapping="Wrap" Margin="0,4,0,0"/>
                          <TextBlock Text="{Binding Sub}" Foreground="#9C9385" FontSize="12" TextWrapping="Wrap" Margin="0,2,0,0"/>
                        </StackPanel>
                      </Border>
                    </DataTemplate>
                  </ItemsControl.ItemTemplate>
                </ItemsControl>
                <ItemsControl x:Name="icYearLists">
                  <ItemsControl.ItemsPanel><ItemsPanelTemplate><UniformGrid Columns="4"/></ItemsPanelTemplate></ItemsControl.ItemsPanel>
                  <ItemsControl.ItemTemplate>
                    <DataTemplate>
                      <Border Style="{StaticResource CardBox}">
                        <StackPanel>
                          <TextBlock Text="{Binding Title}" Style="{StaticResource H2}"/>
                          <ItemsControl ItemsSource="{Binding Rows}" ItemTemplate="{StaticResource BarRow}"/>
                        </StackPanel>
                      </Border>
                    </DataTemplate>
                  </ItemsControl.ItemTemplate>
                </ItemsControl>
                <TextBlock x:Name="capYearFilms" Text="EVERYTHING YOU WATCHED" Style="{StaticResource Cap}" Margin="2,8,0,4"/>
                <ItemsControl x:Name="icYearFilms" ItemTemplate="{StaticResource FilmTile}">
                  <ItemsControl.ItemsPanel><ItemsPanelTemplate><WrapPanel/></ItemsPanelTemplate></ItemsControl.ItemsPanel>
                </ItemsControl>
                <TextBlock x:Name="txtYearEmpty" Visibility="Collapsed" FontFamily="Georgia" FontStyle="Italic" FontSize="18" Foreground="{StaticResource Muted}" TextWrapping="Wrap" Margin="2,10,0,0"/>
              </StackPanel>
              <StackPanel x:Name="spStatsAll">
              <TextBlock x:Name="txtStatsSub" Foreground="{StaticResource Muted}" Margin="0,4,0,16"/>
              <ItemsControl x:Name="icStatCards">
                <ItemsControl.ItemsPanel><ItemsPanelTemplate><UniformGrid x:Name="ugStatCards" Columns="6"/></ItemsPanelTemplate></ItemsControl.ItemsPanel>
                <ItemsControl.ItemTemplate>
                  <DataTemplate>
                    <Border Style="{StaticResource CardBox}">
                      <StackPanel>
                        <TextBlock Text="{Binding Value}" FontFamily="Georgia" FontSize="28" Foreground="{Binding Brush}"/>
                        <TextBlock Text="{Binding Label}" Foreground="#7B7266" Margin="0,2,0,0"/>
                        <TextBlock Text="{Binding Sub}" Foreground="#9C9385" FontSize="11.5" TextWrapping="Wrap"/>
                      </StackPanel>
                    </Border>
                  </DataTemplate>
                </ItemsControl.ItemTemplate>
              </ItemsControl>
              <UniformGrid x:Name="ugCharts" Columns="2" Margin="0,4,0,0"/>
              <TextBlock Text="Top lists" Style="{StaticResource H2}" Margin="0,10,0,10"/>
              <ItemsControl x:Name="icStatCharts">
                <ItemsControl.ItemsPanel><ItemsPanelTemplate><UniformGrid Columns="4"/></ItemsPanelTemplate></ItemsControl.ItemsPanel>
                <ItemsControl.ItemTemplate>
                  <DataTemplate>
                    <Border Style="{StaticResource CardBox}">
                      <StackPanel>
                        <TextBlock Text="{Binding Title}" Style="{StaticResource H2}"/>
                        <ItemsControl ItemsSource="{Binding Rows}" ItemTemplate="{StaticResource BarRow}"/>
                      </StackPanel>
                    </Border>
                  </DataTemplate>
                </ItemsControl.ItemTemplate>
              </ItemsControl>
              </StackPanel>
            </StackPanel>
          </ScrollViewer>
        </TabItem>

        <!-- ===== Utilities ===== -->
        <TabItem>
          <ScrollViewer VerticalScrollBarVisibility="Auto">
            <StackPanel Margin="26,10,26,24">
              <TextBlock Text="Utilities" Style="{StaticResource H1}"/>
              <TextBlock Text="Exports, housekeeping and your data." Foreground="{StaticResource Muted}" Margin="0,2,0,6"/>
              <TextBlock Text="EXPORT" Style="{StaticResource Cap}" Margin="2,14,0,8"/>
              <UniformGrid Columns="3">
                <Border Style="{StaticResource CardBox}">
                  <DockPanel>
                    <TextBlock DockPanel.Dock="Top" Text="Web catalogue" Style="{StaticResource H2}"/>
                    <WrapPanel DockPanel.Dock="Bottom" Margin="0,12,0,0">
                      <Button x:Name="btnExportHtml" Style="{StaticResource BtnPrimary}" Content="Export web catalogue" Margin="0,0,8,0"/>
                    </WrapPanel>
                    <TextBlock Text="A single web page of your whole library — posters, plots and search — to open on any phone, tablet or browser." Foreground="{StaticResource Muted}" TextWrapping="Wrap" LineHeight="19"/>
                  </DockPanel>
                </Border>
                <Border Style="{StaticResource CardBox}">
                  <DockPanel>
                    <TextBlock DockPanel.Dock="Top" Text="Printable list" Style="{StaticResource H2}"/>
                    <WrapPanel DockPanel.Dock="Bottom" Margin="0,12,0,0">
                      <Button x:Name="btnUtilPrint" Style="{StaticResource BtnPrimary}" Content="Make a list" Margin="0,0,8,0"/>
                    </WrapPanel>
                    <TextBlock Text="A tidy page of one shelf or your whole collection — sorted how you like, with tick boxes to mark off. Print it or save it as a PDF." Foreground="{StaticResource Muted}" TextWrapping="Wrap" LineHeight="19"/>
                  </DockPanel>
                </Border>
                <Border Style="{StaticResource CardBox}">
                  <DockPanel>
                    <TextBlock DockPanel.Dock="Top" Text="Library spreadsheet" Style="{StaticResource H2}"/>
                    <WrapPanel DockPanel.Dock="Bottom" Margin="0,12,0,0">
                      <Button x:Name="btnExportCsv" Style="{StaticResource BtnGhost}" Content="Export CSV" Margin="0,0,8,0"/>
                    </WrapPanel>
                    <TextBlock Text="Every film with its year, shelf, genres, rating, quality, size and watched status, as a CSV file for Excel." Foreground="{StaticResource Muted}" TextWrapping="Wrap" LineHeight="19"/>
                  </DockPanel>
                </Border>
              </UniformGrid>
              <TextBlock Text="LIBRARY" Style="{StaticResource Cap}" Margin="2,10,0,8"/>
              <UniformGrid Columns="3">
                <Border Style="{StaticResource CardBox}">
                  <DockPanel>
                    <TextBlock DockPanel.Dock="Top" Text="Health report" Style="{StaticResource H2}"/>
                    <WrapPanel DockPanel.Dock="Bottom" Margin="0,12,0,0">
                      <Button x:Name="btnUtilHealthHtml" Style="{StaticResource BtnGhost}" Content="Export health report" Margin="0,0,8,0"/>
                    </WrapPanel>
                    <TextBlock Text="A searchable web page of everything the Health checks found, grouped by problem — ready to print." Foreground="{StaticResource Muted}" TextWrapping="Wrap" LineHeight="19"/>
                  </DockPanel>
                </Border>
                <Border Style="{StaticResource CardBox}">
                  <DockPanel>
                    <TextBlock DockPanel.Dock="Top" Text="Refresh all film info" Style="{StaticResource H2}"/>
                    <WrapPanel DockPanel.Dock="Bottom" Margin="0,12,0,0">
                      <Button x:Name="btnUtilRefetch" Style="{StaticResource BtnGhost}" Content="Refresh all" Margin="0,0,8,0"/>
                    </WrapPanel>
                    <TextBlock Text="Fetch every film's details, posters and cast again from TMDb — useful if TMDb has corrected something. Your ratings and notes aren't touched." Foreground="{StaticResource Muted}" TextWrapping="Wrap" LineHeight="19"/>
                  </DockPanel>
                </Border>
                <Border Style="{StaticResource CardBox}">
                  <DockPanel>
                    <TextBlock DockPanel.Dock="Top" Text="Hidden shelves" Style="{StaticResource H2}"/>
                    <WrapPanel DockPanel.Dock="Bottom" Margin="0,12,0,0">
                      <Button x:Name="btnUnhide" Style="{StaticResource BtnGhost}" Content="Show all hidden shelves" Margin="0,0,8,0"/>
                    </WrapPanel>
                    <TextBlock Text="Shelves you've hidden (right-click a shelf → Hide) stay out of every list. Bring them all back here." Foreground="{StaticResource Muted}" TextWrapping="Wrap" LineHeight="19"/>
                  </DockPanel>
                </Border>
              </UniformGrid>
              <TextBlock Text="YOUR DATA" Style="{StaticResource Cap}" Margin="2,10,0,8"/>
              <UniformGrid Columns="3">
                <Border Style="{StaticResource CardBox}">
                  <DockPanel>
                    <TextBlock DockPanel.Dock="Top" Text="Back up my data" Style="{StaticResource H2}"/>
                    <WrapPanel DockPanel.Dock="Bottom" Margin="0,12,0,0">
                      <Button x:Name="btnUtilBackup" Style="{StaticResource BtnPrimary}" Content="Back up now" Margin="0,0,8,0"/>
                    </WrapPanel>
                    <TextBlock Text="Saves your watched history, ratings, notes, watchlist, settings and film info into one .zip file. Keep it somewhere safe (it includes your TMDb and Radarr keys)." Foreground="{StaticResource Muted}" TextWrapping="Wrap" LineHeight="19"/>
                  </DockPanel>
                </Border>
                <Border Style="{StaticResource CardBox}">
                  <DockPanel>
                    <TextBlock DockPanel.Dock="Top" Text="Restore from backup" Style="{StaticResource H2}"/>
                    <WrapPanel DockPanel.Dock="Bottom" Margin="0,12,0,0">
                      <Button x:Name="btnUtilRestore" Style="{StaticResource BtnGhost}" Content="Restore…" Margin="0,0,8,0"/>
                    </WrapPanel>
                    <TextBlock Text="Put a backup back. You see what is in it first, choose which parts to restore, and your data as it is now is saved before anything changes." Foreground="{StaticResource Muted}" TextWrapping="Wrap" LineHeight="19"/>
                  </DockPanel>
                </Border>
                <Border Style="{StaticResource CardBox}">
                  <DockPanel>
                    <TextBlock DockPanel.Dock="Top" Text="Move to my other PC" Style="{StaticResource H2}"/>
                    <WrapPanel DockPanel.Dock="Bottom" Margin="0,12,0,0">
                      <Button x:Name="btnUtilSend" Style="{StaticResource BtnGhost}" Content="Send to my other PC…" Margin="0,0,8,0"/>
                      <Button x:Name="btnUtilBring" Style="{StaticResource BtnGhost}" Content="Bring in…" Margin="0,0,8,0"/>
                    </WrapPanel>
                    <TextBlock Text="Take your watched history, ratings, notes and settings to Picture House on another PC. Bringing it in merges with that PC's — nothing is lost." Foreground="{StaticResource Muted}" TextWrapping="Wrap" LineHeight="19"/>
                  </DockPanel>
                </Border>
              </UniformGrid>
              <TextBlock Text="HOUSEKEEPING" Style="{StaticResource Cap}" Margin="2,10,0,8"/>
              <UniformGrid Columns="3">
                <Border Style="{StaticResource CardBox}">
                  <DockPanel>
                    <TextBlock DockPanel.Dock="Top" Text="Log file" Style="{StaticResource H2}"/>
                    <WrapPanel DockPanel.Dock="Bottom" Margin="0,12,0,0">
                      <Button x:Name="btnUtilLog" Style="{StaticResource BtnGhost}" Content="Open the log" Margin="0,0,8,0"/>
                    </WrapPanel>
                    <TextBlock Text="Picture House notes problems here — handy if something isn't working as it should." Foreground="{StaticResource Muted}" TextWrapping="Wrap" LineHeight="19"/>
                  </DockPanel>
                </Border>
                <Border Style="{StaticResource CardBox}">
                  <DockPanel>
                    <TextBlock DockPanel.Dock="Top" Text="Data folder" Style="{StaticResource H2}"/>
                    <WrapPanel DockPanel.Dock="Bottom" Margin="0,12,0,0">
                      <Button x:Name="btnOpenData" Style="{StaticResource BtnGhost}" Content="Open data folder" Margin="0,0,8,0"/>
                    </WrapPanel>
                    <TextBlock Text="Everything Picture House stores lives in the Data folder beside the app." Foreground="{StaticResource Muted}" TextWrapping="Wrap" LineHeight="19"/>
                  </DockPanel>
                </Border>
              </UniformGrid>
            </StackPanel>
          </ScrollViewer>
        </TabItem>

        <!-- ===== Settings ===== -->
        <TabItem>
          <ScrollViewer VerticalScrollBarVisibility="Auto">
            <StackPanel Margin="26,10,26,24">
              <Grid Margin="0,0,0,6">
                <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions>
                <StackPanel>
                  <TextBlock Text="Settings" Style="{StaticResource H1}"/>
                  <TextBlock Text="Changes take effect when you press Save." Foreground="{StaticResource Muted}" Margin="0,2,0,0"/>
                </StackPanel>
                <WrapPanel Grid.Column="1" VerticalAlignment="Bottom">
                  <Button x:Name="btnSaveSettings" Style="{StaticResource BtnPrimary}" Content="Save settings" Margin="0,0,8,0"/>
                  <Button x:Name="btnSaveScan" Style="{StaticResource BtnGhost}" Content="Save and rescan" Margin="0"/>
                </WrapPanel>
              </Grid>
              <TextBlock x:Name="txtWelcome" Foreground="{StaticResource Accent}" TextWrapping="Wrap" Margin="0,6,0,8" FontSize="14" Visibility="Collapsed"
                         Text="Welcome! Start by adding the NAS folder that holds your film folders (for example \\NAS\video\Films), then press Save and Rescan."/>
              <Grid x:Name="gridSettings" Margin="0,12,0,0">
                <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition x:Name="colSettings2" Width="*"/><ColumnDefinition x:Name="colSettings3" Width="*"/></Grid.ColumnDefinitions>
                <Grid.RowDefinitions><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/></Grid.RowDefinitions>
                <StackPanel x:Name="spSettingsLeft">
                  <TextBlock Text="YOUR LIBRARY" Style="{StaticResource Cap}" Margin="2,0,0,8"/>
              <Border Style="{StaticResource CardBox}" Margin="0,0,0,14">
                <StackPanel>
                  <TextBlock Text="Film folders on the NAS" Style="{StaticResource H2}"/>
                  <TextBlock Foreground="{StaticResource Muted}" TextWrapping="Wrap" Margin="0,0,0,10"
                             Text="Add the top-level folder(s). Every sub-folder becomes a shelf (Action, Comedy, Kids…). Folders inside a shelf that have no film of their own become sub-shelves. A UNC path (\\NAS\share\Films) is best — mapped drive letters work too."/>
                  <ListBox x:Name="lbRoots" Height="110" Background="{StaticResource Paper}" BorderBrush="{StaticResource Line}"/>
                  <Grid Margin="0,8,0,0">
                    <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions>
                    <TextBox x:Name="txtRootAdd" Style="{StaticResource Field}"/>
                    <StackPanel Grid.Column="1" Orientation="Horizontal" Margin="8,0,0,0">
                      <Button x:Name="btnRootAdd" Style="{StaticResource BtnGhost}" Content="Add" Margin="0,0,6,0"/>
                      <Button x:Name="btnRootBrowse" Style="{StaticResource BtnGhost}" Content="Browse…" Margin="0,0,6,0"/>
                      <Button x:Name="btnRootRemove" Style="{StaticResource BtnGhost}" Content="Remove selected" Margin="0"/>
                    </StackPanel>
                  </Grid>
                  <CheckBox x:Name="chkUseNfo" Content="Read .nfo files and local artwork (poster.jpg, fanart.jpg) when the NAS has them" Margin="0,12,0,0"/>
                  <TextBlock Text="VIDEO FILE TYPES" Style="{StaticResource Cap}"/>
                  <TextBox x:Name="txtExts" Style="{StaticResource Field}"/>
                  <TextBlock Text="FOLDERS TO IGNORE" Style="{StaticResource Cap}"/>
                  <TextBox x:Name="txtIgnore" Style="{StaticResource Field}" ToolTip="Folder names (separated by commas) that are skipped wherever they appear on the NAS — never shown as shelves or films"/>
                </StackPanel>
              </Border>

              <Border Style="{StaticResource CardBox}" Margin="0,0,0,14">
                <StackPanel>
                  <TextBlock Text="Playing films" Style="{StaticResource H2}"/>
                  <TextBlock Foreground="{StaticResource Muted}" TextWrapping="Wrap" Margin="0,0,0,8" Text="Leave blank to use whatever Windows opens video files with."/>
                  <Grid>
                    <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions>
                    <TextBox x:Name="txtPlayer" Style="{StaticResource Field}"/>
                    <StackPanel Grid.Column="1" Orientation="Horizontal" Margin="8,0,0,0">
                      <Button x:Name="btnPlayerBrowse" Style="{StaticResource BtnGhost}" Content="Browse…" Margin="0,0,6,0"/>
                      <Button x:Name="btnPlayerDetect" Style="{StaticResource BtnGhost}" Content="Find Zoom Player" Margin="0"/>
                    </StackPanel>
                  </Grid>
                  <CheckBox x:Name="chkWatchedOnPlay" Content="Mark a film as watched when I press Play" Margin="0,12,0,0"/>
                </StackPanel>
              </Border>
              <Border Style="{StaticResource CardBox}" Margin="0,0,0,14" BorderBrush="#E7B7AC">
                <StackPanel>
                  <TextBlock Text="Start again" Style="{StaticResource H2}"/>
                  <TextBlock Foreground="{StaticResource Muted}" TextWrapping="Wrap" LineHeight="19" Margin="0,0,0,10"
                             Text="Two separate resets. Neither touches the NAS — no films or folders are ever deleted."/>
                  <Grid Margin="0,0,0,10">
                    <Grid.ColumnDefinitions><ColumnDefinition Width="150"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
                    <Button x:Name="btnClearAll" Style="{StaticResource BtnPrimary}" Content="Clear all data…" HorizontalAlignment="Left" VerticalAlignment="Top"/>
                    <TextBlock Grid.Column="1" Foreground="{StaticResource Muted}" TextWrapping="Wrap" LineHeight="18" VerticalAlignment="Center"
                               Text="Film list, film info, posters, collections, people, and your watched history, ratings and notes — as if no scan had been done. Settings are kept. Offers a backup first."/>
                  </Grid>
                  <Grid>
                    <Grid.ColumnDefinitions><ColumnDefinition Width="150"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
                    <Button x:Name="btnClearSettings" Style="{StaticResource BtnPrimary}" Content="Clear settings…" HorizontalAlignment="Left" VerticalAlignment="Top"/>
                    <TextBlock Grid.Column="1" Foreground="{StaticResource Muted}" TextWrapping="Wrap" LineHeight="18" VerticalAlignment="Center"
                               Text="NAS folders, API keys and addresses, player, folders to ignore, hidden shelves — back to first-run. Your films, info and watched history are kept."/>
                  </Grid>
                </StackPanel>
              </Border>
                </StackPanel>
                <StackPanel x:Name="spSettingsRight" Grid.Column="1">
                  <TextBlock Text="ONLINE SERVICES" Style="{StaticResource Cap}" Margin="2,0,0,8"/>
              <Border Style="{StaticResource CardBox}" Margin="0,0,0,14">
                <StackPanel>
                  <TextBlock Text="TMDb (film info and posters)" Style="{StaticResource H2}"/>
                  <TextBlock Foreground="{StaticResource Muted}" TextWrapping="Wrap" Margin="0,0,0,8"
                             Text="Paste either your v3 API key or the v4 read access token from themoviedb.org → Settings → API."/>
                  <Grid>
                    <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions>
                    <PasswordBox x:Name="pwTmdb" Padding="8,6" BorderBrush="{StaticResource Line}" Background="{StaticResource Card}"/>
                    <StackPanel Grid.Column="1" Orientation="Horizontal" Margin="8,0,0,0">
                      <Button x:Name="btnTmdbTest" Style="{StaticResource BtnGhost}" Content="Test" Margin="0,0,6,0"/>
                      <Button x:Name="btnTmdbGetKey" Style="{StaticResource BtnGhost}" Content="Get a free API key ↗" Margin="0"
                              ToolTip="Opens themoviedb.org. Sign in (or create a free account), then copy the API Key or API Read Access Token."/>
                    </StackPanel>
                  </Grid>
                  <StackPanel Orientation="Horizontal" Margin="0,10,0,0">
                    <TextBlock Text="Language" VerticalAlignment="Center" Margin="0,0,8,0"/>
                    <TextBox x:Name="txtLang" Style="{StaticResource Field}" Width="90"/>
                    <TextBlock Text="Certificate region" VerticalAlignment="Center" Margin="18,0,8,0"/>
                    <TextBox x:Name="txtRegion" Style="{StaticResource Field}" Width="60"/>
                  </StackPanel>
                  <CheckBox x:Name="chkAutoFetch" Content="After a rescan, fetch info for new films automatically" Margin="0,12,0,0"/>
                </StackPanel>
              </Border>
              <Border Style="{StaticResource CardBox}" Margin="0,0,0,14">
                <StackPanel>
                  <TextBlock Text="Radarr and Seerr" Style="{StaticResource H2}"/>
                  <TextBlock Foreground="{StaticResource Muted}" TextWrapping="Wrap" Margin="0,0,0,8"
                             Text="Optional. Lets you send missing collection films to Radarr or Seerr, and compare Radarr with what is really on the NAS. Seerr's API key (Seerr → Settings → General) lets Picture House send requests directly."/>
                  <Grid>
                    <Grid.ColumnDefinitions><ColumnDefinition Width="110"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
                    <Grid.RowDefinitions><RowDefinition/><RowDefinition/><RowDefinition/><RowDefinition/><RowDefinition/><RowDefinition/></Grid.RowDefinitions>
                    <TextBlock Text="Radarr URL" VerticalAlignment="Center"/>
                    <TextBox x:Name="txtRadarrUrl" Grid.Column="1" Style="{StaticResource Field}" Margin="0,0,0,6"/>
                    <TextBlock Grid.Row="1" Text="API key" VerticalAlignment="Center"/>
                    <Grid Grid.Row="1" Grid.Column="1" Margin="0,0,0,6">
                      <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions>
                      <PasswordBox x:Name="pwRadarr" Padding="8,6" BorderBrush="{StaticResource Line}" Background="{StaticResource Card}"/>
                      <StackPanel Grid.Column="1" Orientation="Horizontal" Margin="8,0,0,0">
                        <Button x:Name="btnRadarrTest" Style="{StaticResource BtnGhost}" Content="Test Radarr" Margin="0,0,6,0"/>
                        <Button x:Name="btnRadarrLoad" Style="{StaticResource BtnGhost}" Content="Load quality profiles" Margin="0"/>
                      </StackPanel>
                    </Grid>
                    <TextBlock Grid.Row="2" Text="Quality profile" VerticalAlignment="Center"/>
                    <ComboBox x:Name="cbRadarrProfile" Grid.Row="2" Grid.Column="1" Margin="0,0,0,6" DisplayMemberPath="Name"/>
                    <TextBlock Grid.Row="4" Text="Seerr URL" VerticalAlignment="Center" Margin="0,2,0,0"/>
                    <TextBox x:Name="txtSeerrUrl" Grid.Row="4" Grid.Column="1" Style="{StaticResource Field}" Margin="0,8,0,6"/>
                    <TextBlock Grid.Row="5" Text="Seerr API key" VerticalAlignment="Center"/>
                    <Grid Grid.Row="5" Grid.Column="1">
                      <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions>
                      <PasswordBox x:Name="pwSeerr" Padding="8,6" BorderBrush="{StaticResource Line}" Background="{StaticResource Card}" ToolTip="Optional — Seerr → Settings → General → API Key"/>
                      <Button x:Name="btnSeerrTest" Grid.Column="1" Style="{StaticResource BtnGhost}" Content="Test Seerr" Margin="8,0,0,0"/>
                    </Grid>
                  </Grid>
                </StackPanel>
              </Border>
                </StackPanel>
                <StackPanel x:Name="spSettingsAbout" Grid.Column="2">
                  <TextBlock Text="VERSION HISTORY" Style="{StaticResource Cap}" Margin="2,0,0,8"/>
              <Border Style="{StaticResource CardBox}" Margin="0,0,0,14">
                <StackPanel>
                  <TextBlock Text="Version history" Style="{StaticResource H2}"/>
                  <TextBlock x:Name="txtAbout" TextWrapping="Wrap" LineHeight="20"/>
                </StackPanel>
              </Border>
                </StackPanel>
              </Grid>
            </StackPanel>
          </ScrollViewer>
        </TabItem>
      </TabControl>
    </Grid>

    <!-- ================= Film panel ================= -->
    <Border Grid.Column="2" Background="{StaticResource Card}" BorderBrush="{StaticResource Line}" BorderThickness="1,0,0,0">
      <Grid>
        <StackPanel x:Name="pnlNoSel" Visibility="Collapsed"/>
        <ScrollViewer x:Name="svDetail" Visibility="Collapsed" VerticalScrollBarVisibility="Auto">
          <StackPanel>
            <Grid Height="220">
              <Border x:Name="bdBackFallback" Background="{StaticResource Teal}"/>
              <Image x:Name="imgBackdrop" Stretch="UniformToFill"/>
              <Rectangle>
                <Rectangle.Fill>
                  <LinearGradientBrush StartPoint="0,0" EndPoint="0,1">
                    <GradientStop Color="#00FFFCF6" Offset="0.35"/>
                    <GradientStop Color="#FFFFFCF6" Offset="1"/>
                  </LinearGradientBrush>
                </Rectangle.Fill>
              </Rectangle>
              <Button x:Name="btnCloseDetail" Content="✕" Width="30" Height="30" HorizontalAlignment="Right" VerticalAlignment="Top" Margin="10" Cursor="Hand"
                      Background="#B31F1B16" Foreground="White" BorderThickness="0" ToolTip="Hide panel"/>
            </Grid>
            <Grid Margin="22,-110,22,0">
              <Grid.ColumnDefinitions><ColumnDefinition Width="124"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
              <Border x:Name="bdDetailPoster" Width="124" Height="186" CornerRadius="5" Background="{StaticResource TealLight}" VerticalAlignment="Top" Cursor="Hand" ToolTip="Click for a bigger poster">
                <Border.Effect><DropShadowEffect BlurRadius="16" ShadowDepth="4" Direction="270" Opacity="0.35"/></Border.Effect>
                <Border CornerRadius="5"><Border.Background><ImageBrush x:Name="ibDetailPoster" Stretch="UniformToFill"/></Border.Background></Border>
              </Border>
              <StackPanel Grid.Column="1" Margin="16,112,0,0">
                <Border x:Name="bdDetailShelf" CornerRadius="9" Padding="9,2" HorizontalAlignment="Left" Cursor="Hand" ToolTip="Open this shelf">
                  <TextBlock x:Name="txtDetailShelf" Foreground="White" FontSize="11" FontWeight="SemiBold"/>
                </Border>
                <TextBlock x:Name="txtDetailYear" Foreground="{StaticResource Muted}" Margin="0,8,0,0" FontSize="13"/>
              </StackPanel>
            </Grid>
            <StackPanel Margin="22,12,22,24">
              <TextBlock x:Name="txtDetailTitle" FontFamily="Georgia" FontSize="27" TextWrapping="Wrap"/>
              <TextBlock x:Name="txtDetailTagline" FontFamily="Georgia" FontStyle="Italic" Foreground="{StaticResource Muted}" TextWrapping="Wrap" Margin="0,4,0,0"/>
              <Border x:Name="bdDetailAwards" Visibility="Collapsed" Background="#F7EDD0" BorderBrush="#E3CF8F" BorderThickness="1" CornerRadius="6" Padding="10,7" Margin="0,10,0,0">
                <TextBlock x:Name="txtDetailAwards" Foreground="#6B5413" TextWrapping="Wrap" LineHeight="19" FontSize="12.5"/>
              </Border>
              <TextBlock x:Name="txtDetailMeta" Foreground="#4A433B" TextWrapping="Wrap" Margin="0,10,0,0"/>
              <WrapPanel x:Name="wpGenres" Margin="0,10,0,0"/>

              <Grid Margin="0,12,0,0">
                <Grid.ColumnDefinitions><ColumnDefinition Width="Auto"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
                <StackPanel Orientation="Horizontal" VerticalAlignment="Center" Margin="0,0,22,0">
                  <TextBlock x:Name="txtDetailRating" FontFamily="Georgia" FontSize="26" Foreground="{StaticResource Teal}"/>
                  <TextBlock Text=" / 10 TMDb" Foreground="{StaticResource Muted}" VerticalAlignment="Bottom" Margin="2,0,0,5"/>
                </StackPanel>
                <StackPanel Grid.Column="1" VerticalAlignment="Center">
                  <TextBlock Text="MY RATING" Style="{StaticResource Cap}" Margin="0,0,0,0"/>
                  <StackPanel x:Name="spStars" Orientation="Horizontal" Cursor="Hand">
                    <TextBlock x:Name="star1" Tag="1" Text="☆" FontSize="22" Margin="0,0,2,0"/>
                    <TextBlock x:Name="star2" Tag="2" Text="☆" FontSize="22" Margin="0,0,2,0"/>
                    <TextBlock x:Name="star3" Tag="3" Text="☆" FontSize="22" Margin="0,0,2,0"/>
                    <TextBlock x:Name="star4" Tag="4" Text="☆" FontSize="22" Margin="0,0,2,0"/>
                    <TextBlock x:Name="star5" Tag="5" Text="☆" FontSize="22"/>
                  </StackPanel>
                </StackPanel>
              </Grid>

              <WrapPanel Margin="0,16,0,0">
                <Button x:Name="btnPlay" Style="{StaticResource BtnPrimary}" Content="▶   Play" Margin="0,0,8,8" FontSize="14" Padding="22,9"/>
                <ToggleButton x:Name="tgWatched" Style="{StaticResource Chip}" Content="✓  Watched" Margin="0,0,6,8"/>
                <ToggleButton x:Name="tgFav" Style="{StaticResource Chip}" Content="♥  Favourite" Margin="0,0,6,8"/>
                <ToggleButton x:Name="tgWatchlist" Style="{StaticResource Chip}" Content="⌚  Watchlist" Margin="0,0,6,8"/>
                <Button x:Name="btnMore" Style="{StaticResource BtnGhost}" Content="More  ▾" Margin="0,0,6,8" ToolTip="Trailer, open folder, TMDb / IMDb, refresh info, fix match, move to shelf"/>
              </WrapPanel>
              <!-- these live in the More menu now; kept (hidden) so everything that updates them still works -->
              <WrapPanel x:Name="wpDetailExtras" Margin="0,2,0,0" Visibility="Collapsed">
                <Button x:Name="btnFolder" Style="{StaticResource BtnGhost}" Content="Open folder"/>
                <Button x:Name="btnTrailer" Style="{StaticResource BtnGhost}" Content="Trailer"/>
                <Button x:Name="btnTmdb" Style="{StaticResource BtnGhost}" Content="TMDb"/>
                <Button x:Name="btnImdb" Style="{StaticResource BtnGhost}" Content="IMDb"/>
                <Button x:Name="btnFetchOne" Style="{StaticResource BtnGhost}" Content="Refresh info"/>
                <Button x:Name="btnFixMatch" Style="{StaticResource BtnGhost}" Content="Fix match…"/>
                <Button x:Name="btnMove" Style="{StaticResource BtnGhost}" Content="Move to shelf ▾"/>
              </WrapPanel>

              <Border x:Name="bdCollection" Background="#EFE6D6" CornerRadius="8" Padding="14,10" Margin="0,12,0,0" Cursor="Hand" Visibility="Collapsed">
                <StackPanel>
                  <TextBlock x:Name="txtCollTitle" FontWeight="SemiBold" TextWrapping="Wrap"/>
                  <TextBlock x:Name="txtCollOwned" Foreground="{StaticResource Muted}" FontSize="12" Margin="0,2,0,0"/>
                </StackPanel>
              </Border>

              <TextBlock Text="STORY" Style="{StaticResource Cap}"/>
              <TextBlock x:Name="txtDetailPlot" TextWrapping="Wrap" LineHeight="20" Foreground="#2E2924"/>

              <TextBlock x:Name="capCrew" Text="DIRECTED BY" Style="{StaticResource Cap}"/>
              <WrapPanel x:Name="wpDirectors"/>
              <TextBlock x:Name="txtWriters" Foreground="{StaticResource Muted}" TextWrapping="Wrap" Margin="0,4,0,0"/>

              <TextBlock x:Name="capCast" Text="CAST" Style="{StaticResource Cap}"/>
              <ItemsControl x:Name="icCast" ItemTemplate="{StaticResource CastCard}">
                <ItemsControl.ItemsPanel><ItemsPanelTemplate><WrapPanel/></ItemsPanelTemplate></ItemsControl.ItemsPanel>
              </ItemsControl>

              <TextBlock Text="MY NOTES" Style="{StaticResource Cap}"/>
              <TextBox x:Name="txtNotes" Style="{StaticResource Field}" AcceptsReturn="True" TextWrapping="Wrap" MinHeight="60" VerticalContentAlignment="Top"/>
              <TextBlock x:Name="txtHistory" Foreground="{StaticResource Muted}" FontSize="12" Margin="0,6,0,0" TextWrapping="Wrap"/>

              <TextBlock Text="ON THE NAS" Style="{StaticResource Cap}"/>
              <TextBox x:Name="txtFile" IsReadOnly="True" TextWrapping="Wrap" BorderThickness="0" Background="Transparent" Foreground="#4A433B" FontFamily="Consolas" FontSize="11.5"/>
              <TextBlock x:Name="txtFileInfo" Foreground="{StaticResource Muted}" TextWrapping="Wrap" Margin="0,4,0,0"/>
            </StackPanel>
          </StackPanel>
        </ScrollViewer>
      </Grid>
    </Border>

    <!-- ================= Status bar ================= -->
    <Border Grid.Row="1" Grid.ColumnSpan="3" Background="#1F1B16">
      <Grid Margin="14,0">
        <Grid.ColumnDefinitions>
          <ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/><ColumnDefinition Width="Auto"/>
        </Grid.ColumnDefinitions>
        <TextBlock x:Name="txtStatus" Foreground="#F6EBD9" FontSize="12" VerticalAlignment="Center" TextTrimming="CharacterEllipsis" Margin="0,0,16,0"/>
        <!-- busy pill: what's running, a proper progress bar, percentage and Cancel -->
        <Border x:Name="bdBusy" Grid.Column="1" Visibility="Collapsed" Background="#3A322B" CornerRadius="14" Padding="14,4,5,4" VerticalAlignment="Center">
          <StackPanel Orientation="Horizontal">
            <Ellipse Width="8" Height="8" Fill="#C8432B" VerticalAlignment="Center" Margin="0,0,9,0">
              <Ellipse.Triggers>
                <EventTrigger RoutedEvent="Loaded">
                  <BeginStoryboard><Storyboard RepeatBehavior="Forever" AutoReverse="True">
                    <DoubleAnimation Storyboard.TargetProperty="Opacity" From="1" To="0.25" Duration="0:0:0.7"/>
                  </Storyboard></BeginStoryboard>
                </EventTrigger>
              </Ellipse.Triggers>
            </Ellipse>
            <TextBlock x:Name="txtBusyLabel" Foreground="#F6EBD9" FontWeight="SemiBold" FontSize="12.5" VerticalAlignment="Center" Margin="0,0,12,0"/>
            <ProgressBar x:Name="pbBusy" Width="300" Height="10" Minimum="0" Maximum="100" VerticalAlignment="Center">
              <ProgressBar.Template>
                <ControlTemplate TargetType="ProgressBar">
                  <Border x:Name="PART_Track" CornerRadius="5" Background="#5A5047" ClipToBounds="True">
                    <Grid ClipToBounds="True">
                      <Border x:Name="PART_Indicator" CornerRadius="5" Background="#C8432B" HorizontalAlignment="Left"/>
                      <Border x:Name="sweep" Width="90" CornerRadius="5" Background="#C8432B" HorizontalAlignment="Left" Visibility="Collapsed">
                        <Border.RenderTransform><TranslateTransform X="-90"/></Border.RenderTransform>
                      </Border>
                    </Grid>
                  </Border>
                  <ControlTemplate.Triggers>
                    <Trigger Property="IsIndeterminate" Value="True">
                      <Setter TargetName="sweep" Property="Visibility" Value="Visible"/>
                      <Setter TargetName="PART_Indicator" Property="Visibility" Value="Collapsed"/>
                      <Trigger.EnterActions>
                        <BeginStoryboard x:Name="sbSweep"><Storyboard RepeatBehavior="Forever">
                          <DoubleAnimation Storyboard.TargetName="sweep" Storyboard.TargetProperty="(UIElement.RenderTransform).(TranslateTransform.X)" From="-90" To="300" Duration="0:0:1.4"/>
                        </Storyboard></BeginStoryboard>
                      </Trigger.EnterActions>
                      <Trigger.ExitActions><StopStoryboard BeginStoryboardName="sbSweep"/></Trigger.ExitActions>
                    </Trigger>
                  </ControlTemplate.Triggers>
                </ControlTemplate>
              </ProgressBar.Template>
            </ProgressBar>
            <TextBlock x:Name="txtBusyPct" Foreground="#F6EBD9" FontSize="12" FontWeight="SemiBold" Margin="10,0,0,0" MinWidth="34" VerticalAlignment="Center"/>
            <Button x:Name="btnCancel" Content="Cancel" Margin="4,0,0,0" Padding="12,3" FontSize="12" Cursor="Hand" Foreground="#F6EBD9">
              <Button.Template>
                <ControlTemplate TargetType="Button">
                  <Border x:Name="b" Background="#4A423A" CornerRadius="11" Padding="{TemplateBinding Padding}">
                    <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                  </Border>
                  <ControlTemplate.Triggers>
                    <Trigger Property="IsMouseOver" Value="True"><Setter TargetName="b" Property="Background" Value="#C8432B"/></Trigger>
                  </ControlTemplate.Triggers>
                </ControlTemplate>
              </Button.Template>
            </Button>
          </StackPanel>
        </Border>
        <TextBlock x:Name="txtTotals" Grid.Column="2" Foreground="#AAF6EBD9" FontSize="12" Margin="18,0,0,0" VerticalAlignment="Center"/>
      </Grid>
    </Border>

    <!-- ================= Notifications (bottom-right) ================= -->
    <StackPanel x:Name="spToasts" Grid.Row="0" Grid.Column="1" Grid.ColumnSpan="2" HorizontalAlignment="Right" VerticalAlignment="Bottom"
                Margin="0,0,24,18" Panel.ZIndex="50" Width="400"/>

    <!-- ================= Big poster viewer ================= -->
    <Grid x:Name="gridBigPoster" Grid.RowSpan="2" Grid.ColumnSpan="3" Visibility="Collapsed" Background="#E61F1B16" Cursor="Hand">
      <Grid Margin="60,40,60,36">
        <Grid.RowDefinitions><RowDefinition Height="*"/><RowDefinition Height="Auto"/></Grid.RowDefinitions>
        <Image x:Name="imgBigPoster" Stretch="Uniform" StretchDirection="Both" RenderOptions.BitmapScalingMode="HighQuality">
          <Image.Effect><DropShadowEffect BlurRadius="40" ShadowDepth="10" Direction="270" Opacity="0.6"/></Image.Effect>
        </Image>
        <StackPanel Grid.Row="1" HorizontalAlignment="Center" Margin="0,18,0,0">
          <TextBlock x:Name="txtBigPosterTitle" FontFamily="Georgia" FontSize="24" Foreground="#F6EBD9" HorizontalAlignment="Center" TextAlignment="Center"/>
          <TextBlock x:Name="txtBigPosterNote" Foreground="#99F6EBD9" FontSize="12" HorizontalAlignment="Center" Margin="0,4,0,0" Text="Click anywhere or press Esc to close"/>
        </StackPanel>
      </Grid>
      <Border Width="36" Height="36" CornerRadius="18" Background="#33F6EBD9" HorizontalAlignment="Right" VerticalAlignment="Top" Margin="0,16,20,0">
        <TextBlock Text="✕" Foreground="#F6EBD9" FontSize="16" HorizontalAlignment="Center" VerticalAlignment="Center"/>
      </Border>
    </Grid>
  </Grid>
</Window>
'@
[xml]$Xaml = $XamlText.Replace('<!--COMBOSTYLES-->', $ComboStyles)

# =====================================================================================
#  Build the window
# =====================================================================================
$reader = New-Object System.Xml.XmlNodeReader $Xaml
try { $Window = [Windows.Markup.XamlReader]::Load($reader) }
catch { $ex = $_.Exception; while ($ex.InnerException) { $ex = $ex.InnerException }; Stop-Startup ("The window layout failed to load: " + $ex.Message) }
if (-not $Window) { Stop-Startup 'The window layout failed to load.' }
$UI = @{}
foreach ($n in $Xaml.SelectNodes('//*[@*[local-name()="Name"]]')) {
    $name = $n.GetAttribute('Name', 'http://schemas.microsoft.com/winfx/2006/xaml')
    if ($name) { $el = $Window.FindName($name); if ($el) { $UI[$name] = $el } }
}
$Window.Title = "$AppName  ·  v$AppVersion"
if ($Script:AppIcon) { $Window.Icon = $Script:AppIcon }   # taskbar and title-bar icon instead of PowerShell's
$icoPath = Join-Path $Base 'Picture House.ico'
if (-not (Test-Path -LiteralPath $icoPath)) { Save-AppIcon $icoPath }

$Window.Dispatcher.Add_UnhandledException({
    param($s, $e)
    Write-Log ("UI error: " + $e.Exception.ToString())
    $e.Handled = $true
    try { $UI.txtStatus.Text = 'Something went wrong — details are in Data\picture-house.log' } catch {}
})

# =====================================================================================
#  Settings & data
# =====================================================================================
function New-DefaultSettings {
    return @{
        Roots = @(); PlayerPath = ''; TmdbKey = ''; Language = 'en-GB'; Region = 'GB'
        RadarrUrl = ''; RadarrKey = ''; RadarrProfileId = 0; RadarrProfileName = ''; RadarrProfileList = @(); RadarrRoot = ''
        SeerrUrl = ''; SeerrKey = ''; UseNfo = $true; AutoFetch = $false; WatchedOnPlay = $false
        HiddenShelves = @(); Sort = 'Title A–Z'; Group = 'None'; View = 'Posters'
        IgnoreFolders = 'Intros, Seerr'
        Extensions = '.mkv .mp4 .avi .m4v .mov .wmv .ts .m2ts .iso .mpg .mpeg .vob .webm .divx'
        LastScan = ''; WinW2 = 0; WinH2 = 0; WinMax2 = $false; WinCustom = $false; UiZoom = 100; DetailOpen = $true
    }
}

$Settings = New-DefaultSettings
$loaded = PH-LoadJson $Files.Settings
if ($loaded) { foreach ($k in @($loaded.Keys)) { $Settings[$k] = $loaded[$k] } }
$Settings.Roots = @($Settings.Roots | Where-Object { $_ })
$Settings.HiddenShelves = @($Settings.HiddenShelves | Where-Object { $_ })

function Save-Settings { PH-SaveJson $Settings $Files.Settings }
# quality profiles fetched from Radarr last time
$Script:RadarrProfiles = @(@($Settings.RadarrProfileList) | Where-Object { $_ -and $_['Name'] } | ForEach-Object { [pscustomobject]@{ Id = [int]$_['Id']; Name = [string]$_['Name'] } })

$Script:Lib = @{}; $Script:Shelves = @(); $Script:ScanErrors = @()
$j = PH-LoadJson $Files.Library
if ($j) {
    foreach ($f in @($j['Films'])) { if ($f -and $f['Key']) { $Script:Lib[[string]$f['Key']] = $f } }
    $Script:Shelves = @($j['Shelves'] | Where-Object { $_ })
    $Script:ScanErrors = @($j['Errors'] | Where-Object { $_ })
}
$Script:Meta = @{}; $Script:MatchFail = @{}
$j = PH-LoadJson $Files.Meta
if ($j) {
    if ($j['Films']) { foreach ($k in @($j['Films'].Keys)) { $Script:Meta[$k] = $j['Films'][$k] } }
    if ($j['Fails']) { foreach ($k in @($j['Fails'].Keys)) { $Script:MatchFail[$k] = $j['Fails'][$k] } }
}
$Script:User = @{}
$j = PH-LoadJson $Files.User
if ($j) { foreach ($k in @($j.Keys)) { $Script:User[$k] = $j[$k] } }
$Script:Colls = @{}
$j = PH-LoadJson $Files.Colls
if ($j) { foreach ($k in @($j.Keys)) { $Script:Colls[$k] = $j[$k] } }
Remove-Variable j, loaded -ErrorAction SilentlyContinue

# ---- folders to ignore (e.g. Intros) --------------------------------------------------
function Get-IgnoreNames { return @(([string]$Settings.IgnoreFolders) -split '[,;]' | ForEach-Object { $_.Trim().ToLowerInvariant() } | Where-Object { $_ }) }
function Set-IgnoreNames { $Global:PH_UserSkip = @(Get-IgnoreNames) }
function Test-IgnoredPath([string]$p) {
    if (-not $p) { return $false }
    $names = $Global:PH_UserSkip; if (-not $names -or $names.Count -eq 0) { return $false }
    foreach ($seg in ($p -split '[\\/]')) { if ($seg -and ($names -contains $seg.ToLowerInvariant())) { return $true } }
    return $false
}
# drop anything already stored that lives under an ignored folder
function Remove-IgnoredFromLibrary {
    Set-IgnoreNames
    $gone = 0
    foreach ($k in @($Script:Lib.Keys)) { if (Test-IgnoredPath ([string]$Script:Lib[$k]['Path'])) { $Script:Lib.Remove($k); $gone++ } }
    $before = @($Script:Shelves).Count + @($Script:ScanErrors).Count
    $Script:Shelves = @($Script:Shelves | Where-Object { -not (Test-IgnoredPath ([string]$_['Path'])) -and -not (@(([string]$_['Name']) -split ' › ' | Where-Object { $Global:PH_UserSkip -contains $_.ToLowerInvariant() }).Count) })
    $Script:ScanErrors = @($Script:ScanErrors | Where-Object { -not (Test-IgnoredPath ([string]$_['Path'])) })
    if ($gone -or $before -ne (@($Script:Shelves).Count + @($Script:ScanErrors).Count)) { Save-Lib }
    return $gone
}
if (-not $Settings.SeerrIgnoreAdded) {
    $names = @(([string]$Settings.IgnoreFolders) -split '[,;]' | ForEach-Object { $_.Trim() } | Where-Object { $_ })
    if (-not ($names | Where-Object { $_ -ieq 'Seerr' })) { $names += 'Seerr' }
    $Settings.IgnoreFolders = ($names -join ', ')
    $Settings.SeerrIgnoreAdded = $true
    Save-Settings
}
[void](Remove-IgnoredFromLibrary)

function Save-Lib { PH-SaveJson @{ Version = 1; Films = @($Script:Lib.Values); Shelves = @($Script:Shelves); Errors = @($Script:ScanErrors) } $Files.Library }
function Save-Meta { PH-SaveJson @{ Version = 1; Films = $Script:Meta; Fails = $Script:MatchFail } $Files.Meta }
function Save-User { PH-SaveJson $Script:User $Files.User }
function Save-Colls { PH-SaveJson $Script:Colls $Files.Colls }

function Get-User([string]$key, [switch]$Create) {
    $u = $Script:User[$key]
    if (-not $u -and $Create) {
        $u = @{ Watched = $false; WatchedOn = ''; Fav = $false; Watchlist = $false; ListAdded = ''; MyRating = 0; Notes = ''; LastPlayed = ''; PlayCount = 0 }
        $Script:User[$key] = $u
    }
    return $u
}

# =====================================================================================
#  Small helpers
# =====================================================================================
$Palette = @('#C8432B', '#2A7F7A', '#D9902F', '#5B6FB0', '#8E4C8F', '#3E8E4F', '#B5576B', '#3F86B0', '#9C7A3C', '#6B5B95', '#D06A3A', '#2F6F8F', '#7A8B2E', '#A0522D')
# Fixed colours for Jason's genre shelves (any other folder name gets the next unused palette colour)
$ShelfColours = @{
    'action'      = '#C8432B'   # red
    'animated'    = '#E08A2E'   # orange
    'comedy'      = '#D4A72C'   # mustard
    'comic book'  = '#7B4FA6'   # purple
    'documentary' = '#2A7F7A'   # teal
    'drama'       = '#3F6FB0'   # blue
    'fantasy'     = '#3E8E4F'   # green
    'horror'      = '#7A1F2B'   # blood red
    'mum'         = '#C9608A'   # rose
    'mystery'     = '#4A5568'   # slate
    'sci-fi'      = '#1F9BB5'   # cyan
}
$Script:ShelfColourCache = @{}
function Get-ShelfColor([string]$name) {
    if (-not $name) { return '#7B7266' }
    $top = (($name -split ' › ')[0]).Trim().ToLowerInvariant()
    if ($ShelfColours.ContainsKey($top)) { return $ShelfColours[$top] }
    if ($Script:ShelfColourCache.ContainsKey($top)) { return $Script:ShelfColourCache[$top] }
    # unknown shelf: take a palette colour nobody else is using, so shelves never share a colour
    $used = @($ShelfColours.Values) + @($Script:ShelfColourCache.Values)
    $free = @($Palette | Where-Object { $used -notcontains $_ })
    if ($free.Count -eq 0) { $free = $Palette }
    $h = 0
    foreach ($c in $top.ToCharArray()) { $h = ($h * 31 + [int]$c) % 1000003 }
    $pick = $free[$h % $free.Count]
    $Script:ShelfColourCache[$top] = $pick
    return $pick
}
function Format-Runtime([int]$m) { if ($m -le 0) { return '' }; $h = [math]::Floor($m / 60); $mm = $m % 60; if ($h -gt 0) { return "{0}h {1:00}m" -f $h, $mm }; return "$($m)m" }
function Format-Size([double]$b) {
    if ($b -ge 1TB) { return ('{0:N2} TB' -f ($b / 1TB)) }
    if ($b -ge 1GB) { return ('{0:N1} GB' -f ($b / 1GB)) }
    if ($b -ge 1MB) { return ('{0:N0} MB' -f ($b / 1MB)) }
    return ''
}
function Get-Initials([string]$n) { if (-not $n) { return '' }; $p = @($n -split '\s+' | Where-Object { $_ }); if ($p.Count -ge 2) { return ($p[0][0].ToString() + $p[-1][0].ToString()).ToUpper() }; return $n.Substring(0, [math]::Min(2, $n.Length)).ToUpper() }
function Get-SortTitle([string]$t) { if (-not $t) { return '' }; return ([regex]::Replace($t, '^(?i)(the|a|an)\s+', '')).ToLowerInvariant() }
function Status([string]$t) { $UI.txtStatus.Text = $t }
function Ask([string]$msg) { return ([Windows.MessageBox]::Show($Window, $msg, $AppName, 'YesNo', 'Question') -eq 'Yes') }
function Tell([string]$msg, [string]$icon = 'Information') { [void][Windows.MessageBox]::Show($Window, $msg, $AppName, 'OK', $icon) }
function Open-Url([string]$u) { try { Start-Process $u } catch { Tell "Couldn't open $u" 'Warning' } }

function Load-Bitmap([string]$path, [int]$w = 0) {
    if (-not $path) { return $null }
    try {
        $isWeb = $path -match '^https?://'
        if (-not $isWeb -and -not (Test-Path -LiteralPath $path)) { return $null }
        $bi = New-Object Windows.Media.Imaging.BitmapImage
        $bi.BeginInit()
        if (-not $isWeb) { $bi.CacheOption = [Windows.Media.Imaging.BitmapCacheOption]::OnLoad }
        $bi.CreateOptions = [Windows.Media.Imaging.BitmapCreateOptions]::IgnoreColorProfile
        $bi.UriSource = New-Object Uri $path
        if ($w -gt 0) { $bi.DecodePixelWidth = $w }
        $bi.EndInit()
        return $bi
    } catch { return $null }
}

function Get-FromSource($src, [string]$flag) {
    $el = $src
    $guard = 0
    while ($el -and $guard -lt 60) {
        $guard++
        if ($el -is [Windows.FrameworkElement] -or $el -is [Windows.FrameworkContentElement]) {
            $dc = $el.DataContext
            if ($null -ne $dc -and $dc.PSObject.Properties[$flag] -and $dc.$flag) { return $dc }
        }
        if ($el -is [Windows.Media.Visual]) { $el = [Windows.Media.VisualTreeHelper]::GetParent($el) }
        elseif ($el -is [Windows.FrameworkContentElement]) { $el = $el.Parent }
        else { $el = $null }
    }
    return $null
}

# =====================================================================================
#  Film "view" objects — what the UI binds to
# =====================================================================================
function New-FilmView($rec) {
    $k = [string]$rec['Key']
    $m = $Script:Meta[$k]
    $u = $Script:User[$k]
    $title = [string]$rec['Title']; $year = [int]$rec['Year']
    $runtime = 0; $genres = @(); $rating = 0.0; $overview = ''; $dirs = @(); $cast = @(); $tmdb = [int]$rec['TmdbHint']; $imdb = [string]$rec['ImdbHint']
    $collId = 0; $collName = ''; $cert = ''; $tagline = ''; $poster = $null; $res = [string]$rec['Res']
    if ($rec['LocalThumb'] -and (Test-Path -LiteralPath $rec['LocalThumb'])) { $poster = [string]$rec['LocalThumb'] }
    $hasInfo = $false; $orig = ''
    if ($m) {
        if ($m['Title']) { $title = [string]$m['Title'] }
        if ([int]$m['Year'] -gt 0) { $year = [int]$m['Year'] }
        $runtime = [int]$m['Runtime']; $rating = [double]$m['Rating']; $overview = [string]$m['Overview']; $tagline = [string]$m['Tagline']
        $genres = @($m['Genres'] | Where-Object { $_ })
        $dirs = @($m['Directors'] | Where-Object { $_ }); $cast = @($m['Cast'] | Where-Object { $_ })
        if ([int]$m['TmdbId'] -gt 0) { $tmdb = [int]$m['TmdbId'] }
        if ($m['ImdbId']) { $imdb = [string]$m['ImdbId'] }
        $collId = [int]$m['CollectionId']; $collName = [string]$m['CollectionName']; $cert = [string]$m['Cert']
        if (-not $poster -and $m['PosterThumb'] -and (Test-Path -LiteralPath $m['PosterThumb'])) { $poster = [string]$m['PosterThumb'] }
        if ($m['Source'] -eq 'tmdb' -and $m['PosterThumb'] -and (Test-Path -LiteralPath $m['PosterThumb'])) { $poster = [string]$m['PosterThumb'] }
        if (-not $res -and [int]$m['Width'] -gt 0) { $res = PH-ResFromWidth ([int]$m['Width']) }
        $hasInfo = ([bool]$overview) -or ($m['Source'] -eq 'tmdb')
        $orig = [string]$m['OriginalTitle']
    }
    $watched = $false; $fav = $false; $list = $false; $my = 0; $lastPlayed = [datetime]::MinValue; $listAdded = [datetime]::MinValue
    if ($u) { $watched = [bool]$u['Watched']; $fav = [bool]$u['Fav']; $list = [bool]$u['Watchlist']; $my = [int]$u['MyRating']; $lastPlayed = PH-Date $u['LastPlayed']; $listAdded = PH-Date $u['ListAdded'] }
    $added = PH-Date $rec['Added']
    $shelf = [string]$rec['Shelf']
    $sub = @()
    if ($year -gt 0) { $sub += [string]$year }
    if ($runtime -gt 0) { $sub += (Format-Runtime $runtime) }
    if ($rating -gt 0) { $sub += ('★ {0:0.0}' -f $rating) }
    $dirNames = @($dirs | ForEach-Object { [string]$_['Name'] })
    $castNames = @($cast | ForEach-Object { [string]$_['Name'] })
    $search = (($title, $rec['Title'], $year, $shelf, ($genres -join ' '), ($dirNames -join ' '), ($castNames -join ' '), $collName, $orig) -join ' | ').ToLowerInvariant()
    $decade = 0; if ($year -gt 0) { $decade = [int]([math]::Floor($year / 10) * 10) }
    $stars = ''; if ($my -gt 0) { $stars = ('★' * $my) }
    $tip = $title; if ($year) { $tip += " ($year)" }; $tip += "`n$shelf"; if ($genres.Count) { $tip += "  ·  " + ($genres -join ', ') }
    return [pscustomobject]@{
        IsFilm = $true; Key = $k; Title = $title; SortTitle = (Get-SortTitle $title); Year = $year; YearText = $(if ($year) { [string]$year } else { '' })
        Shelf = $shelf; ShelfBrush = (Get-ShelfColor $shelf); Poster = $poster; Sub = ($sub -join '  ·  ')
        Runtime = $runtime; RuntimeText = (Format-Runtime $runtime); Genres = $genres; GenreText = ($genres -join ', ')
        Rating = $rating; RatingText = $(if ($rating -gt 0) { '{0:0.0}' -f $rating } else { '' })
        Res = $res; ResVis = 'Collapsed'   # quality tag not shown on posters (still used by filters, Stats and Health)
        Size = [double]$rec['Size']; SizeText = (Format-Size ([double]$rec['Size']))
        Added = $added; AddedText = $(if ($added -gt [datetime]::MinValue) { $added.ToString('dd MMM yyyy') } else { '' })
        Watched = $watched; WatchedText = $(if ($watched) { '✓' } else { '' }); WatchedVis = $(if ($watched) { 'Visible' } else { 'Collapsed' })
        Fav = $fav; FavVis = $(if ($fav) { 'Visible' } else { 'Collapsed' })
        Watchlist = $list; ListVis = $(if ($list) { 'Visible' } else { 'Collapsed' }); ListAdded = $listAdded
        MyRating = $my; MyStars = $stars; LastPlayed = $lastPlayed
        Overview = $overview; Tagline = $tagline; Cert = $cert; Directors = $dirs; DirectorNames = $dirNames; Cast = $cast; CastNames = $castNames
        TmdbId = $tmdb; ImdbId = $imdb; CollectionId = $collId; CollectionName = $collName
        HasInfo = $hasInfo; File = [string]$rec['File']; Path = [string]$rec['Path']; IsFolder = [bool]$rec['IsFolder']
        Decade = $decade; SearchText = $search; Tip = $tip
    }
}

$Script:AllViews = New-Object Collections.Generic.List[object]
$Script:ViewByKey = @{}
$Script:Filtered = New-Object Collections.Generic.List[object]
$Script:Rows = $null
$Script:RowIndex = @{}
$Script:PerRow = 0
$Script:Loading = $false
$Script:CurShelf = @{ Kind = 'smart'; Id = 'all' }
$Script:CurKey = $null
$Script:CtxKey = $null
$Script:Dirty = @{ Collections = $true; People = $true; Stats = $true; Health = $true }

function Rebuild-Views {
    $Script:AllViews = New-Object Collections.Generic.List[object]
    $Script:ViewByKey = @{}
    foreach ($rec in $Script:Lib.Values) {
        try { $v = New-FilmView $rec; $Script:AllViews.Add($v); $Script:ViewByKey[$v.Key] = $v }
        catch { Write-Log "View failed for $($rec['Key']): $($_.Exception.Message)" }
    }
    foreach ($k in @($Script:Dirty.Keys)) { $Script:Dirty[$k] = $true }
    Build-UpcomingViews
}

function Get-HiddenSet {
    $h = New-Object 'Collections.Generic.HashSet[string]' ([StringComparer]::OrdinalIgnoreCase)
    foreach ($s in @($Settings.HiddenShelves)) { [void]$h.Add([string]$s) }
    return , $h
}
function Test-Hidden([string]$shelf, $set) {
    if ($set.Count -eq 0) { return $false }
    if ($set.Contains($shelf)) { return $true }
    foreach ($h in $set) { if ($shelf.StartsWith($h + ' › ', [StringComparison]::OrdinalIgnoreCase)) { return $true } }
    return $false
}
function Get-VisibleViews {
    $set = Get-HiddenSet
    $out = New-Object Collections.Generic.List[object]
    foreach ($v in $Script:AllViews) { if (-not (Test-Hidden $v.Shelf $set)) { $out.Add($v) } }
    return , $out
}

# Replace one film's view everywhere it is shown, without resetting the scroll position
function Update-Film([string]$key) {
    $rec = $Script:Lib[$key]; if (-not $rec) { return }
    $v = New-FilmView $rec
    $old = $Script:ViewByKey[$key]
    $Script:ViewByKey[$key] = $v
    if ($old) {
        $i = $Script:AllViews.IndexOf($old); if ($i -ge 0) { $Script:AllViews[$i] = $v }
        $i = $Script:Filtered.IndexOf($old); if ($i -ge 0) { $Script:Filtered[$i] = $v }
    } else { $Script:AllViews.Add($v) }
    if ($Script:Rows -and $Script:RowIndex.ContainsKey($key)) {
        $ri = $Script:RowIndex[$key]
        if ($ri -lt $Script:Rows.Count) {
            $row = $Script:Rows[$ri]
            $items = @($row.Items | ForEach-Object { if ($_.Key -eq $key) { $v } else { $_ } })
            $Script:Rows[$ri] = [pscustomobject]@{ Header = $row.Header; HeaderSub = $row.HeaderSub; HeaderVis = $row.HeaderVis; Items = $items; Cols = $row.Cols }
        }
    }
    if ($UI.dgList.Visibility -eq 'Visible') { $UI.dgList.Items.Refresh() }
    if ($UI.icPeopleFilms.ItemsSource) {
        $src = @($UI.icPeopleFilms.ItemsSource)
        if (@($src | Where-Object { $_.Key -eq $key }).Count) { $UI.icPeopleFilms.ItemsSource = @($src | ForEach-Object { if ($_.Key -eq $key) { $v } else { $_ } }) }
    }
    foreach ($d in @('Stats', 'People', 'Collections', 'Health')) { $Script:Dirty[$d] = $true }
    if ($Script:CurKey -eq $key) { Show-Detail $key }
}

# =====================================================================================
#  Background workers (scans and downloads never freeze the window)
# =====================================================================================
$Script:Jobs = New-Object Collections.ArrayList
$Script:JobTimer = New-Object Windows.Threading.DispatcherTimer
$Script:JobTimer.Interval = [TimeSpan]::FromMilliseconds(250)

function Start-BgJob([string]$Name, [scriptblock]$Work, [hashtable]$Params, [scriptblock]$OnItem, [scriptblock]$OnDone) {
    $sync = [hashtable]::Synchronized(@{ Status = "$Name…"; Pct = -1; Done = $false; Error = $null; Cancel = $false; Result = $null })
    $sync.Queue = New-Object 'System.Collections.Concurrent.ConcurrentQueue[object]'
    $rs = [runspacefactory]::CreateRunspace()
    $rs.ApartmentState = 'STA'; $rs.ThreadOptions = 'ReuseThread'
    $rs.Open()
    $ps = [PowerShell]::Create(); $ps.Runspace = $rs
    $runner = 'param($sync, $p, $shared, $work)
        try { . ([scriptblock]::Create($shared)); & ([scriptblock]::Create($work)) $sync $p }
        catch { $sync.Error = $_.Exception.Message }
        finally { $sync.Done = $true }'
    [void]$ps.AddScript($runner).AddArgument($sync).AddArgument($Params).AddArgument($SharedCode).AddArgument($Work.ToString())
    $job = @{ Name = $Name; Sync = $sync; PS = $ps; RS = $rs; Handle = $ps.BeginInvoke(); OnItem = $OnItem; OnDone = $OnDone }
    [void]$Script:Jobs.Add($job)
    Update-BusyUi
    if (-not $Script:JobTimer.IsEnabled) { $Script:JobTimer.Start() }
    return $job
}

function Pump-Jobs {
    foreach ($job in @($Script:Jobs)) {
        $item = $null; $n = 0
        while ($n -lt 100 -and $job.Sync.Queue.TryDequeue([ref]$item)) {
            $n++
            if ($job.OnItem) { try { & $job.OnItem $item } catch { Write-Log "OnItem ($($job.Name)): $($_.Exception.Message)" } }
        }
        if ($job.Sync.Done -and $job.Sync.Queue.IsEmpty) {
            try { [void]$job.PS.EndInvoke($job.Handle) } catch {}
            try { $job.PS.Dispose(); $job.RS.Close(); $job.RS.Dispose() } catch {}
            $Script:Jobs.Remove($job)
            if ($job.Sync.Error) { Write-Log "$($job.Name): $($job.Sync.Error)" }
            if ($UI.txtStatus.Text.StartsWith([string]$job.Sync.Status)) { $UI.txtStatus.Text = '' }   # don't leave 'Getting…' behind
            if ($job.OnDone) { try { & $job.OnDone $job.Sync } catch { Write-Log "OnDone ($($job.Name)): $($_.Exception.ToString())"; Status "$($job.Name) hit a problem — see the log." } }
        }
    }
    Update-BusyUi
    if ($Script:Jobs.Count -eq 0) { $Script:JobTimer.Stop() }
}
$Script:JobTimer.Add_Tick({ Pump-Jobs })

# ---- Notifications: a card in the bottom-right that says what happened (click to close) ----
function Show-Toast([string]$title, [string]$text = '', [string]$kind = 'ok', [int]$seconds = 9, [string]$actionText = '', [scriptblock]$action = $null, $actionArg = $null) {
    # seconds 0 = stays until you click it; actionText/action add a button (e.g. "Import it anyway")
    try {
        $bg = switch ($kind) { 'warn' { '#8E2F1F' } 'wait' { '#2A4A6B' } default { '#173F3E' } }
        $icon = switch ($kind) { 'warn' { '!' } 'wait' { '…' } default { '✓' } }
        $bc = New-Object Windows.Media.BrushConverter
        $cream = $bc.ConvertFromString('#F6EBD9')
        $b = New-Object Windows.Controls.Border
        $b.Background = $bc.ConvertFromString($bg); $b.CornerRadius = New-Object Windows.CornerRadius 10
        $b.Padding = New-Object Windows.Thickness 16, 12, 16, 14; $b.Margin = New-Object Windows.Thickness 0, 10, 0, 0; $b.Cursor = [Windows.Input.Cursors]::Hand
        $b.Effect = New-Object Windows.Media.Effects.DropShadowEffect -Property @{ BlurRadius = 18; ShadowDepth = 4; Direction = 270; Opacity = 0.35 }
        $g = New-Object Windows.Controls.Grid
        $c0 = New-Object Windows.Controls.ColumnDefinition; $c0.Width = New-Object Windows.GridLength 34
        [void]$g.ColumnDefinitions.Add($c0); [void]$g.ColumnDefinitions.Add((New-Object Windows.Controls.ColumnDefinition))
        $ic = New-Object Windows.Controls.TextBlock; $ic.Text = $icon; $ic.FontSize = 20; $ic.FontWeight = [Windows.FontWeights]::Bold; $ic.Foreground = $cream; $ic.VerticalAlignment = 'Top'
        $sp = New-Object Windows.Controls.StackPanel; [Windows.Controls.Grid]::SetColumn($sp, 1)
        $t1 = New-Object Windows.Controls.TextBlock; $t1.Text = $title; $t1.FontFamily = 'Georgia'; $t1.FontSize = 16; $t1.Foreground = $cream; $t1.TextWrapping = 'Wrap'
        [void]$sp.Children.Add($t1)
        if ($text) { $t2 = New-Object Windows.Controls.TextBlock; $t2.Text = $text; $t2.FontSize = 12.5; $t2.Foreground = $cream; $t2.Opacity = 0.85; $t2.TextWrapping = 'Wrap'; $t2.Margin = New-Object Windows.Thickness 0, 4, 0, 0; [void]$sp.Children.Add($t2) }
        if ($actionText -and $action) {
            $btn = New-Object Windows.Controls.Button
            $btn.Content = $actionText; $btn.Margin = New-Object Windows.Thickness 0, 10, 0, 0; $btn.Padding = New-Object Windows.Thickness 14, 5, 14, 5
            $btn.HorizontalAlignment = 'Left'; $btn.Cursor = [Windows.Input.Cursors]::Hand; $btn.BorderThickness = New-Object Windows.Thickness 0
            $btn.Background = $bc.ConvertFromString('#F6EBD9'); $btn.Foreground = $bc.ConvertFromString('#1F1B16'); $btn.FontWeight = [Windows.FontWeights]::SemiBold
            $btn.Tag = @{ Action = $action; Arg = $actionArg }
            $btn.Add_Click({ $t = $this.Tag; try { & $t.Action $t.Arg } catch { Write-Log "Toast action: $($_.Exception.Message)" } })
            [void]$sp.Children.Add($btn)
        }
        [void]$g.Children.Add($ic); [void]$g.Children.Add($sp); $b.Child = $g
        $b.Add_MouseLeftButtonUp({ $UI.spToasts.Children.Remove($this) })
        [void]$UI.spToasts.Children.Add($b)
        while ($UI.spToasts.Children.Count -gt 4) { $UI.spToasts.Children.RemoveAt(0) }
        if ($seconds -gt 0) {
            $tm = New-Object Windows.Threading.DispatcherTimer; $tm.Interval = [TimeSpan]::FromSeconds([math]::Max(3, $seconds)); $tm.Tag = $b
            $tm.Add_Tick({ $this.Stop(); $UI.spToasts.Children.Remove($this.Tag) })
            $tm.Start()
        }
        Status ($title + $(if ($text) { ' — ' + $text } else { '' }))
    } catch { Status $title }
}

function Test-Busy([string]$name) { return (@($Script:Jobs | Where-Object { $_.Name -eq $name }).Count -gt 0) }

function Update-BusyUi {
    if ($Script:Jobs.Count -gt 0) {
        $j = $Script:Jobs[0]
        $fg = @($Script:Jobs | Where-Object { $_.Name -notin @('People', 'Awards', 'Depts', 'Picks') }); if ($fg.Count) { $j = $fg[0] }   # long background people job shows last
        $UI.bdBusy.Visibility = 'Visible'
        $label = switch ($j.Name) { 'Scan' { 'Scanning the NAS' } 'Fetch' { 'Fetching film info' } 'Collections' { 'Checking collections' } 'Upcoming' { 'Checking Radarr' } 'Person' { 'Getting person details' } 'People' { 'Getting cast & crew details' } 'Depts' { 'Sorting actors from producers' } 'Awards' { 'Checking awards' } 'RadarrWatch' { 'Waiting on Radarr' } 'RadarrList' { 'Asking Radarr' } 'Releases' { 'Asking your indexers' } 'Talking' { 'Talking to Radarr / Seerr' } 'Picks' { 'Checking your Radarr picks' } default { [string]$j.Name } }
        if ($Script:Jobs.Count -gt 1) { $label += "  (+$($Script:Jobs.Count - 1))" }
        $UI.txtBusyLabel.Text = $label
        $pct = [int]$j.Sync.Pct
        if ($pct -lt 0) { $UI.pbBusy.IsIndeterminate = $true; $UI.txtBusyPct.Text = '' }
        else { $UI.pbBusy.IsIndeterminate = $false; $UI.pbBusy.Value = [double]$pct; $UI.txtBusyPct.Text = "$pct%" }
        $extra = ''; if ($Script:Jobs.Count -gt 1) { $extra = "   (+$($Script:Jobs.Count - 1) more)" }
        Status ([string]$j.Sync.Status + $extra)
    } else {
        $UI.bdBusy.Visibility = 'Collapsed'
    }
    $UI.btnScan.IsEnabled = -not (Test-Busy 'Scan')
    $UI.btnMatchAll.IsEnabled = -not (Test-Busy 'Fetch')
}

# =====================================================================================
#  Talk to Radarr / Seerr in the background so the window never freezes while they answer.
#  Invoke-Async runs a script block on a worker (with Invoke-Radarr / Invoke-Seerr available),
#  then calls OnOk with whatever it returned, or OnFail with the error.
# =====================================================================================
$Script:AsyncFuncNames = @('Normalize-ServiceUrl', 'Get-HttpErrorDetail', 'Expand-JsonList', 'Invoke-Radarr', 'Invoke-Seerr',
                           'PH-JsonStr', 'PH-ToJson', 'PH-ConvertToJson')
$AsyncWork = {
    param($sync, $p)
    . ([scriptblock]::Create($p.Funcs))
    $Settings = $p.Settings
    $sync.Status = $p.Label
    $work = [scriptblock]::Create($p.Work)
    try { $sync.Result = @{ Value = (& $work $p.Vars) } }
    catch { $sync.Code = $_.Exception.Data['Code']; throw }
}
function Invoke-Async([string]$label, [scriptblock]$work, [hashtable]$vars, [scriptblock]$onOk, [scriptblock]$onFail) {
    if (-not $Script:AsyncFuncs) {
        $Script:AsyncFuncs = (@($Script:AsyncFuncNames | ForEach-Object { "function $_ {`n" + (Get-Item "function:$_").Definition + "`n}" }) -join "`n")
    }
    $snap = @{ RadarrUrl = $Settings.RadarrUrl; RadarrKey = $Settings.RadarrKey; SeerrUrl = $Settings.SeerrUrl; SeerrKey = $Settings.SeerrKey }
    $job = Start-BgJob 'Talking' $AsyncWork @{ Funcs = $Script:AsyncFuncs; Settings = $snap; Label = $label; Work = $work.ToString(); Vars = $(if ($vars) { $vars } else { @{} }) } $null ${function:On-AsyncDone}
    # callbacks get (result, vars) — PowerShell script blocks don't remember the caller's variables, so pass what they need in $vars
    $job.Sync.OnOk = $onOk; $job.Sync.OnFail = $onFail; $job.Sync.Vars = $(if ($vars) { $vars } else { @{} })
}
function On-AsyncDone($sync) {
    if ($sync.Error) {
        if ($sync.OnFail) { try { & $sync.OnFail ([string]$sync.Error) $sync.Vars $sync.Code } catch { Write-Log "Async fail handler: $($_.Exception.Message)" } }
        else { Tell ([string]$sync.Error) 'Warning' }
        return
    }
    if ($sync.OnOk) {
        $v = $null; if ($sync.Result) { $v = $sync.Result.Value }
        try { & $sync.OnOk $v $sync.Vars } catch { Write-Log "Async result handler: $($_.Exception.Message)"; Tell ("Something went wrong:`n" + $_.Exception.Message) 'Warning' }
    }
}

# =====================================================================================
#  Scanning the NAS
# =====================================================================================
$ScanWork = {
    param($sync, $p)
    $exts = @($p.Exts)
    $Global:PH_UserSkip = @($p.Ignore)
    $thumbDir = $p.ThumbDir
    $useNfo = [bool]$p.UseNfo
    $films = New-Object Collections.ArrayList
    $shelves = New-Object Collections.ArrayList
    $shelfSeen = @{}
    $errors = New-Object Collections.ArrayList
    $nfoMeta = @{}
    $failedRoots = New-Object Collections.ArrayList

    function Add-Shelf([string]$name, [string]$path, [string]$root, [int]$depth) {
        if ($shelfSeen.ContainsKey($name)) { return }
        $shelfSeen[$name] = $true
        [void]$shelves.Add(@{ Name = $name; Path = $path; Root = $root; Depth = $depth })
    }
    function Get-Files($di) { try { return , @($di.GetFiles()) } catch { [void]$errors.Add(@{ Type = 'Unreadable folder'; Path = $di.FullName; Shelf = ''; Detail = $_.Exception.Message }); return , @() } }
    function Get-Dirs($di) { try { return , @($di.GetDirectories() | Where-Object { -not (PH-IsSkipDir $_.Name) -and -not ($_.Attributes -band [IO.FileAttributes]::Hidden) }) } catch { return , @() } }
    function Test-Video($f) { return ($exts -contains $f.Extension.ToLowerInvariant()) }
    function Get-Videos($files) {
        return , @($files | Where-Object { (Test-Video $_) -and -not ($_.BaseName -match '(?i)(^|[\.\-_ ])sample([\.\-_ ]|$)' -and $_.Length -lt 500MB) -and -not ($_.BaseName -match '(?i)-(trailer|featurette|behindthescenes|deleted|interview|scene|short|other)$') })
    }
    function Get-PartGroups($vids) {
        $groups = @{}
        foreach ($v in $vids) {
            $b = $v.BaseName; $part = 1
            $m = [regex]::Match($b, '(?i)[ _\.\-\(\[]*(?:cd|dvd|part|pt|disc|disk)[ _\.\-]*([1-9])[\)\]]?$')
            if ($m.Success) { $part = [int]$m.Groups[1].Value; $b = $b.Substring(0, $m.Index) }
            $gk = $b.Trim().ToLowerInvariant()
            if (-not $groups.ContainsKey($gk)) { $groups[$gk] = @{ Base = $b.Trim(); Files = (New-Object Collections.ArrayList); Size = [long]0 } }
            [void]$groups[$gk].Files.Add(@{ Part = $part; File = $v })
            $groups[$gk].Size += $v.Length
        }
        $out = New-Object Collections.ArrayList
        foreach ($g in $groups.Values) {
            $sorted = @($g.Files | Sort-Object { $_.Part } | ForEach-Object { $_.File })
            [void]$out.Add(@{ Base = $g.Base; Files = $sorted; Size = $g.Size })
        }
        return , @($out | Sort-Object { $_.Size } -Descending)
    }
    function Find-Art($files, [string[]]$names) {
        foreach ($n in $names) {
            $hit = @($files | Where-Object { $_.Name -ieq $n } | Select-Object -First 1)
            if ($hit.Count) { return $hit[0].FullName }
        }
        return $null
    }
    # ---- real picture size, read from the file's own details (what Explorer shows under Properties > Details)
    $knownRes = $p.KnownRes; if (-not $knownRes) { $knownRes = @{} }
    $script:shell = $null; $script:nsCache = @{}; $script:probed = 0
    function Get-VideoRes([string]$file, [long]$size) {
        $k = $file.ToLowerInvariant() + '|' + $size
        if ($knownRes.ContainsKey($k)) { return [string]$knownRes[$k] }
        $res = ''
        if ($file -match '(?i)\.(mkv|webm|mk3d)$') {
            $mw = PH-MkvWidth $file
            if ($mw -gt 0) { $res = PH-ResFromWidth ([int]$mw); $knownRes[$k] = $res; return $res }
        }
        try {
            if (-not $script:shell) { $script:shell = New-Object -ComObject Shell.Application }
            $dir = [IO.Path]::GetDirectoryName($file)
            $ns = $script:nsCache[$dir]
            if (-not $ns) { $ns = $script:shell.Namespace($dir); $script:nsCache[$dir] = $ns }
            if ($ns) {
                $item = $ns.ParseName([IO.Path]::GetFileName($file))
                if ($item) {
                    $w = 0; $h = 0
                    try { $w = [int]$item.ExtendedProperty('System.Video.FrameWidth') } catch {}
                    try { $h = [int]$item.ExtendedProperty('System.Video.FrameHeight') } catch {}
                    if ($w -gt 0) { $res = PH-ResFromWidth $w }
                    elseif ($h -gt 0) { $res = $(if ($h -ge 1600) { '4K' } elseif ($h -ge 1000) { '1080p' } elseif ($h -ge 700) { '720p' } else { 'SD' }) }
                }
            }
        } catch {}
        $script:probed++
        if ($res) { $knownRes[$k] = $res }   # blanks aren't remembered, so they're tried again next scan
        return $res
    }

    function Add-Record($rec, [string]$nfoPath, [string]$poster, [string]$fanart) {
        $rec.LocalPoster = $poster; $rec.LocalFanart = $fanart; $rec.Nfo = $nfoPath
        if ($poster) { $t = PH-MakeThumb $poster $thumbDir 260; if ($t) { $rec.LocalThumb = $t } }
        if ($useNfo -and $nfoPath) {
            $nm = PH-ReadNfo $nfoPath
            if ($nm) {
                if (-not $rec.Res -and $nm.Width -gt 0) { $rec.Res = PH-ResFromWidth $nm.Width }
                if (-not $rec.TmdbHint -and $nm.TmdbId) { $rec.TmdbHint = $nm.TmdbId }
                if (-not $rec.ImdbHint -and $nm.ImdbId) { $rec.ImdbHint = $nm.ImdbId }
                $nfoMeta[$rec.Key] = $nm
            }
        }
        if (-not $rec.Res -and -not $rec.Disc -and $rec.File) {
            $sync.Status = "Reading picture quality — $($rec.Title)"
            $r2 = Get-VideoRes ([string]$rec.File) ([long]$rec.Size)
            if ($r2) { $rec.Res = $r2; $rec.ResFrom = 'file' }
        }
        [void]$films.Add($rec)
        $sync.Status = "Scanning the NAS — $($films.Count) films found  ·  $($rec.Shelf)"
    }
    function New-Rec([string]$key, [string]$shelf, [string]$root) {
        return @{ Key = $key; Title = ''; Year = 0; Shelf = $shelf; Root = $root; Path = ''; File = ''; IsFolder = $false; Size = [long]0;
                  Added = ''; Ext = ''; Res = ''; Edition = ''; TmdbHint = 0; ImdbHint = ''; Parts = 1; PartFiles = @(); Disc = '';
                  LocalPoster = $null; LocalFanart = $null; LocalThumb = $null; Nfo = $null; Scanned = (Get-Date).ToString('s') }
    }

    function Add-FileFilm($group, $dirFiles, [string]$shelf, [string]$root) {
        $main = $group.Files[0]
        $rec = New-Rec $main.FullName.ToLowerInvariant() $shelf $root
        $pn = PH-ParseName $group.Base
        $rec.Title = $pn.Title; $rec.Year = $pn.Year; $rec.TmdbHint = $pn.Tmdb; $rec.ImdbHint = $pn.Imdb; $rec.Edition = $pn.Edition
        $rec.Path = $main.FullName; $rec.File = $main.FullName; $rec.Size = $group.Size
        $rec.Added = $main.CreationTime.ToString('s'); $rec.Ext = $main.Extension.TrimStart('.').ToUpperInvariant()
        $rec.Res = PH-GetRes $main.Name; $rec.Parts = $group.Files.Count; $rec.PartFiles = @($group.Files | ForEach-Object { $_.FullName })
        if ($main.Extension -ieq '.iso') { $rec.Disc = 'ISO' }
        $b = $group.Base; $mb = $main.BaseName
        $poster = Find-Art $dirFiles @("$mb-poster.jpg", "$b-poster.jpg", "$mb.jpg", "$b.jpg", "$mb-poster.png", "$mb.png", "$mb.tbn")
        $fanart = Find-Art $dirFiles @("$mb-fanart.jpg", "$b-fanart.jpg", "$mb-backdrop.jpg")
        $nfo = Find-Art $dirFiles @("$mb.nfo", "$b.nfo")
        Add-Record $rec $nfo $poster $fanart
    }

    function Add-FolderFilm($di, $files, $group, [string]$shelf, [string]$root, [string]$disc) {
        $rec = New-Rec $di.FullName.ToLowerInvariant() $shelf $root
        $pn = PH-ParseName $di.Name
        $rec.Path = $di.FullName; $rec.IsFolder = $true
        if ($disc) {
            $rec.Disc = $disc
            if ($disc -eq 'DVD') { $vt = Join-Path $di.FullName 'VIDEO_TS'; $rec.File = Join-Path $vt 'VIDEO_TS.IFO'; $rec.Res = 'SD'; $sub = $vt }
            else { $bd = Join-Path $di.FullName 'BDMV'; $rec.File = Join-Path $bd 'index.bdmv'; $rec.Res = '1080p'; $sub = $bd }
            $sz = [long]0
            try { foreach ($f in [IO.Directory]::EnumerateFiles($sub, '*', [IO.SearchOption]::AllDirectories)) { $sz += (New-Object IO.FileInfo $f).Length } } catch {}
            $rec.Size = $sz; $rec.Ext = $disc; $rec.Added = $di.CreationTime.ToString('s')
            if ($di.Name -match '(?i)(2160p|4k|uhd)') { $rec.Res = '4K' }
        } else {
            $main = $group.Files[0]
            $rec.File = $main.FullName; $rec.Size = $group.Size; $rec.Parts = $group.Files.Count
            $rec.PartFiles = @($group.Files | ForEach-Object { $_.FullName })
            $rec.Added = $main.CreationTime.ToString('s'); $rec.Ext = $main.Extension.TrimStart('.').ToUpperInvariant()
            $rec.Res = PH-GetRes ($di.Name + ' ' + $main.Name)
            if ($main.Extension -ieq '.iso') { $rec.Disc = 'ISO' }
            $pf = PH-ParseName $group.Base
            if (-not $pn.Year -and $pf.Year) { $pn.Year = $pf.Year }
            if (-not $pn.Tmdb -and $pf.Tmdb) { $pn.Tmdb = $pf.Tmdb }
            if (-not $pn.Imdb -and $pf.Imdb) { $pn.Imdb = $pf.Imdb }
            if (-not $pn.Edition -and $pf.Edition) { $pn.Edition = $pf.Edition }
        }
        $rec.Title = $pn.Title; $rec.Year = $pn.Year; $rec.TmdbHint = $pn.Tmdb; $rec.ImdbHint = $pn.Imdb; $rec.Edition = $pn.Edition
        $mb = ''; if ($group) { $mb = $group.Files[0].BaseName }
        $poster = Find-Art $files @('poster.jpg', 'poster.png', 'folder.jpg', 'folder.png', 'cover.jpg', 'movie.jpg', "$mb-poster.jpg", "$mb.jpg", "$mb-poster.png")
        if (-not $poster) { $hit = @($files | Where-Object { $_.Name -match '(?i)poster\.(jpe?g|png)$' } | Select-Object -First 1); if ($hit.Count) { $poster = $hit[0].FullName } }
        $fanart = Find-Art $files @('fanart.jpg', 'backdrop.jpg', 'background.jpg', 'fanart.png', "$mb-fanart.jpg", "$mb-backdrop.jpg")
        $nfo = Find-Art $files @('movie.nfo', "$mb.nfo")
        if (-not $nfo) { $hit = @($files | Where-Object { $_.Extension -ieq '.nfo' } | Select-Object -First 1); if ($hit.Count) { $nfo = $hit[0].FullName } }
        Add-Record $rec $nfo $poster $fanart
    }

    function Scan-Container($di, [string]$shelf, [int]$depth, [string]$root) {
        if ($sync.Cancel) { return }
        $files = Get-Files $di
        $loose = Get-PartGroups (Get-Videos $files)
        if ($loose.Count) { Add-Shelf $shelf $di.FullName $root ([math]::Max(0, $depth - 1)) }
        foreach ($g in $loose) { if ($sync.Cancel) { return }; Add-FileFilm $g $files $shelf $root }
        foreach ($sub in (Get-Dirs $di)) {
            if ($sync.Cancel) { return }
            $subName = $sub.Name
            $childName = $subName; if ($depth -gt 0) { $childName = "$shelf › $subName" }
            # DVD / Blu-ray folder rips
            $raw = @(); try { $raw = @($sub.GetDirectories()) } catch {}
            if (@($raw | Where-Object { $_.Name -ieq 'VIDEO_TS' }).Count) { Add-FolderFilm $sub (Get-Files $sub) $null $shelf $root 'DVD'; continue }
            if (@($raw | Where-Object { $_.Name -ieq 'BDMV' }).Count) { Add-FolderFilm $sub (Get-Files $sub) $null $shelf $root 'Blu-ray'; continue }
            $sf = Get-Files $sub
            $groups = Get-PartGroups (Get-Videos $sf)
            $hasYear = ($subName -match '[\(\[](19|20)\d{2}[\)\]]') -or ($subName -match '[\. ](19|20)\d{2}([\. ]|$)')
            if ($groups.Count -ge 1) {
                $isFilm = $hasYear -or $groups.Count -eq 1
                if (-not $isFilm -and $groups.Count -ge 2) {
                    $rest = [long]0; for ($i = 1; $i -lt $groups.Count; $i++) { $rest += $groups[$i].Size }
                    if ($groups[0].Size -gt (4 * $rest)) { $isFilm = $true }
                }
                if ($isFilm -and $depth -lt 6) { Add-FolderFilm $sub $sf $groups[0] $shelf $root ''; continue }
                Add-Shelf $childName $sub.FullName $root $depth
                Scan-Container $sub $childName ($depth + 1) $root
                continue
            }
            $subDirs = Get-Dirs $sub
            if ($subDirs.Count -eq 0) {
                if ($depth -eq 0) { Add-Shelf $childName $sub.FullName $root $depth }
                else { [void]$errors.Add(@{ Type = 'Folder with no film'; Path = $sub.FullName; Shelf = $shelf; Detail = 'No video files found' }) }
                continue
            }
            if ($hasYear) {
                # a film whose video sits one level down (e.g. "Film (2001)\1080p\film.mkv")
                $found = $false
                foreach ($sd in $subDirs) {
                    $g2 = Get-PartGroups (Get-Videos (Get-Files $sd))
                    if ($g2.Count) { Add-FolderFilm $sub $sf $g2[0] $shelf $root ''; $found = $true; break }
                }
                if ($found) { continue }
            }
            if ($depth -lt 6) { Add-Shelf $childName $sub.FullName $root $depth; Scan-Container $sub $childName ($depth + 1) $root }
        }
    }

    foreach ($root in @($p.Roots)) {
        if ($sync.Cancel) { break }
        $sync.Status = "Opening $root …"
        $di = New-Object IO.DirectoryInfo $root
        $ok = $false
        try { $ok = $di.Exists } catch {}
        if (-not $ok) { [void]$failedRoots.Add($root); [void]$errors.Add(@{ Type = 'NAS folder not reachable'; Path = $root; Shelf = ''; Detail = 'Is the NAS on and the share available?' }); continue }
        $leaf = $di.Name; if (-not $leaf) { $leaf = $root }
        Scan-Container $di $leaf 0 $root
    }
    $sync.Result = @{ KnownRes = $knownRes; Films = $films.ToArray(); Shelves = $shelves.ToArray(); Errors = $errors.ToArray(); NfoMeta = $nfoMeta; FailedRoots = $failedRoots.ToArray(); Cancelled = [bool]$sync.Cancel }
}

$Files.ResCache = Join-Path $DataDir 'resolutions.json'
function Get-KnownRes {
    $h = @{}
    $j = PH-LoadJson $Files.ResCache
    if ($j) { foreach ($k in @($j.Keys)) { $h[$k] = [string]$j[$k] } }
    return $h
}

function Start-Scan {
    if (Test-Busy 'Scan') { return }
    if (@($Settings.Roots).Count -eq 0) { Tell 'Add your NAS film folder in Settings first.'; Select-Tab 'Settings'; return }
    $exts = @(([string]$Settings.Extensions) -split '[\s,;]+' | Where-Object { $_ } | ForEach-Object { $e = $_.ToLowerInvariant(); if (-not $e.StartsWith('.')) { $e = '.' + $e }; $e })
    [void](Start-BgJob 'Scan' $ScanWork @{ Roots = @($Settings.Roots); Exts = $exts; ThumbDir = (Join-Path $CacheDir 'thumbs'); UseNfo = [bool]$Settings.UseNfo; Ignore = @(Get-IgnoreNames); KnownRes = (Get-KnownRes) } $null ${function:On-ScanDone})
}

function Move-UserKey([string]$from, [string]$to) {
    if ($from -eq $to) { return }
    if ($Script:Meta.ContainsKey($from)) { $Script:Meta[$to] = $Script:Meta[$from]; $Script:Meta.Remove($from) }
    if ($Script:User.ContainsKey($from)) { $Script:User[$to] = $Script:User[$from]; $Script:User.Remove($from) }
    if ($Script:MatchFail.ContainsKey($from)) { $Script:MatchFail.Remove($from) }
}

function On-ScanDone($sync) {
    $r = $sync.Result
    if (-not $r) { Status ('Scan failed: ' + $sync.Error); Tell ("The scan stopped:`n`n" + $sync.Error) 'Warning'; return }
    if ($r.Cancelled) { Status 'Scan cancelled — the library was not changed.'; return }
    $old = $Script:Lib
    $new = @{}
    foreach ($f in $r.Films) { $new[[string]$f.Key] = $f }
    # keep films from NAS folders that could not be reached this time
    $failed = @($r.FailedRoots)
    if ($failed.Count) { foreach ($k in @($old.Keys)) { if ($failed -contains [string]$old[$k]['Root'] -and -not $new.ContainsKey($k)) { $new[$k] = $old[$k] } } }
    # carry info/ratings across for films that were moved or renamed outside the app
    $gone = @($old.Keys | Where-Object { -not $new.ContainsKey($_) })
    $added = @($new.Keys | Where-Object { -not $old.ContainsKey($_) })
    $moved = 0
    if ($gone.Count -and $added.Count) {
        $byLeaf = @{}
        foreach ($g in $gone) { $leaf = ([IO.Path]::GetFileName([string]$old[$g]['Path'])).ToLowerInvariant(); if ($leaf) { $byLeaf[$leaf] = $g } }
        foreach ($a in $added) {
            $leaf = ([IO.Path]::GetFileName([string]$new[$a]['Path'])).ToLowerInvariant()
            if ($byLeaf.ContainsKey($leaf)) { Move-UserKey $byLeaf[$leaf] $a; $byLeaf.Remove($leaf); $moved++ }
        }
    }
    foreach ($k in @($r.NfoMeta.Keys)) {
        $cur = $Script:Meta[$k]
        if (-not $cur -or $cur['Source'] -ne 'tmdb') { $Script:Meta[$k] = $r.NfoMeta[$k] }
    }
    $oldShelves = @($Script:Shelves)
    $Script:Lib = $new
    $Script:Shelves = @($r.Shelves)
    if ($failed.Count) { $Script:Shelves += @($oldShelves | Where-Object { $failed -contains [string]$_['Root'] }) }
    $Script:ScanErrors = @($r.Errors)
    if ($r.KnownRes) { PH-SaveJson $r.KnownRes $Files.ResCache }
    $Settings.LastScan = (Get-Date).ToString('s')
    Save-Lib; Save-Meta; Save-User; Save-Settings
    Refresh-Everything
    $newCount = @($added).Count - $moved; $goneCount = @($gone).Count - $moved
    $msg = "Scan complete — $($new.Count) films"
    if ($old.Count -gt 0) { $msg += " ($newCount new, $goneCount gone" + $(if ($moved) { ", $moved moved" } else { '' }) + ')' }
    if ($failed.Count) { $msg += "   ·   ⚠ couldn't reach: " + ($failed -join ', ') }
    Status $msg
    Start-UpcomingFetch
    if ($Settings.AutoFetch -and $Settings.TmdbKey) { Start-Fetch -OnlyMissing -Quiet }
}


# =====================================================================================
#  Fetching film info from TMDb
# =====================================================================================
$FetchWork = {
    param($sync, $p)
    $key = $p.ApiKey; $cache = $p.CacheDir; $lang = $p.Lang; $region = $p.Region
    $items = @($p.Items); $n = $items.Count; $i = 0
    foreach ($it in $items) {
        if ($sync.Cancel) { break }
        $i++
        $sync.Status = "Fetching film info $i of $n  ·  $($it.Title)"
        $sync.Pct = [int](100 * $i / [math]::Max(1, $n))
        try {
            $id = [int]$it.TmdbId
            if (-not $id -and $it.ImdbId) {
                $f = PH-Tmdb $key "/find/$($it.ImdbId)" @{ external_source = 'imdb_id' }
                if ($f -and @($f.movie_results).Count) { $id = [int]@($f.movie_results)[0].id }
            }
            if (-not $id) {
                $res = PH-TmdbSearch $key $it.Title ([int]$it.Year) $lang
                $best = PH-PickBest $res $it.Title ([int]$it.Year)
                if ($best) { $id = [int]$best.id }
            }
            if ($id) {
                $m = PH-TmdbMeta $key $id $cache $lang $region
                if ($m) { $sync.Queue.Enqueue(@{ Key = $it.Key; Meta = $m }) } else { $sync.Queue.Enqueue(@{ Key = $it.Key; Fail = "TMDb id $id not found" }) }
            } else { $sync.Queue.Enqueue(@{ Key = $it.Key; Fail = 'No match on TMDb' }) }
        } catch {
            $msg = $_.Exception.Message
            if ($msg -match '401') { $sync.Error = 'TMDb rejected the API key. Check it in Settings.'; break }
            $sync.Queue.Enqueue(@{ Key = $it.Key; Fail = $msg })
        }
    }
}

$Script:FetchStats = @{ Ok = 0; Fail = 0; SinceSave = 0 }
function Start-Fetch([string[]]$Keys, [switch]$OnlyMissing, [switch]$Quiet, [hashtable]$ForceIds) {
    if (-not $Settings.TmdbKey) { if (-not $Quiet) { Tell 'Add your TMDb API key in Settings first.' }; Select-Tab 'Settings'; return }
    if (Test-Busy 'Fetch') { if (-not $Quiet) { Tell 'Already fetching film info — give it a moment.' }; return }
    $items = New-Object Collections.ArrayList
    $src = @(); if ($Keys) { $src = $Keys } else { $src = @($Script:Lib.Keys) }
    foreach ($k in $src) {
        $rec = $Script:Lib[$k]; if (-not $rec) { continue }
        $m = $Script:Meta[$k]
        if ($OnlyMissing) {
            if ($m -and $m['Source'] -eq 'tmdb') { continue }
            if ($Script:MatchFail.ContainsKey($k) -and -not $Keys) { continue }
        }
        $tid = [int]$rec['TmdbHint']; $imdb = [string]$rec['ImdbHint']
        if ($m) { if ([int]$m['TmdbId'] -gt 0) { $tid = [int]$m['TmdbId'] }; if (-not $imdb -and $m['ImdbId']) { $imdb = [string]$m['ImdbId'] } }
        if ($ForceIds -and $ForceIds.ContainsKey($k)) { $tid = [int]$ForceIds[$k]; $imdb = '' }
        [void]$items.Add(@{ Key = $k; Title = [string]$rec['Title']; Year = [int]$rec['Year']; TmdbId = $tid; ImdbId = $imdb })
    }
    if ($items.Count -eq 0) { if (-not $Quiet) { Status 'Every film already has its info. (Use “Refresh info” on a film to re-fetch it.)' }; return }
    $Script:FetchStats = @{ Ok = 0; Fail = 0; SinceSave = 0 }
    [void](Start-BgJob 'Fetch' $FetchWork @{ ApiKey = $Settings.TmdbKey; CacheDir = $CacheDir; Lang = $Settings.Language; Region = $Settings.Region; Items = $items.ToArray() } ${function:On-FetchItem} ${function:On-FetchDone})
}

function On-FetchItem($item) {
    $k = [string]$item.Key
    if ($item.Meta) {
        $Script:Meta[$k] = $item.Meta
        if ($Script:MatchFail.ContainsKey($k)) { $Script:MatchFail.Remove($k) }
        $Script:FetchStats.Ok++
    } else {
        $Script:MatchFail[$k] = [string]$item.Fail
        $Script:FetchStats.Fail++
    }
    $Script:FetchStats.SinceSave++
    if ($Script:ViewByKey.ContainsKey($k)) { Update-Film $k }
    if ($Script:FetchStats.SinceSave -ge 60) { Save-Meta; $Script:FetchStats.SinceSave = 0 }
}

function On-FetchDone($sync) {
    Save-Meta
    Refresh-Rail; Refresh-FilterCombos; Apply-Filter
    $msg = "Film info: $($Script:FetchStats.Ok) updated"
    if ($Script:FetchStats.Fail) { $msg += ", $($Script:FetchStats.Fail) couldn't be matched (see Health, or use Fix match)" }
    if ($sync.Cancel) { $msg += '  ·  stopped early' }
    if ($sync.Error) { $msg = $sync.Error; Tell $sync.Error 'Warning' }
    Status $msg
    if ($UI.navCollections.IsChecked) { Refresh-Collections }
    if ($Script:FetchStats.Ok -gt 0 -and -not $sync.Error) { Start-CollFetch -Auto }   # pick up any new franchises
    if (-not $sync.Error) { Start-PeopleAuto; Start-AwardsFetch -Auto }   # and details for any new cast & crew, and their awards
}

# =====================================================================================
#  Collections from TMDb
# =====================================================================================
$CollWork = {
    param($sync, $p)
    $ids = @($p.Ids); $n = $ids.Count; $i = 0
    foreach ($id in $ids) {
        if ($sync.Cancel) { break }
        $i++
        $sync.Status = "Checking collections on TMDb  ·  $i of $n"
        $sync.Pct = [int](100 * $i / [math]::Max(1, $n))
        try { $c = PH-TmdbCollection $p.ApiKey ([int]$id) $p.Lang; if ($c) { $sync.Queue.Enqueue($c) } }
        catch { if ($_.Exception.Message -match '401') { $sync.Error = 'TMDb rejected the API key.'; break } }
    }
}
function Start-CollFetch([switch]$Auto) {
    # -Auto: quiet background check of collections never checked, or not checked for a week
    if (-not $Settings.TmdbKey) { if (-not $Auto) { Tell 'Add your TMDb API key in Settings first.' }; return }
    if (Test-Busy 'Collections') { return }
    $ids = @($Script:AllViews | Where-Object { $_.CollectionId -gt 0 } | ForEach-Object { $_.CollectionId } | Select-Object -Unique)
    if ($Auto) {
        $weekAgo = (Get-Date).AddDays(-7)
        $ids = @($ids | Where-Object { $c = $Script:Colls[[string]$_]; -not $c -or (PH-Date $c['Fetched']) -lt $weekAgo })
        if ($ids.Count -eq 0) { return }
    }
    $Script:CollAuto = [bool]$Auto
    if ($ids.Count -eq 0) { Tell "None of your films are linked to a collection yet.`n`nFetch film info first (rail button: ‘Fetch missing film info’)."; return }
    [void](Start-BgJob 'Collections' $CollWork @{ ApiKey = $Settings.TmdbKey; Lang = $Settings.Language; Ids = $ids } ${function:On-CollItem} ${function:On-CollDone})
}
function On-CollItem($c) { $Script:Colls[[string]$c.Id] = $c }
function On-CollDone($sync) {
    Save-Colls
    $Script:Dirty.Collections = $true
    if ($UI.navCollections.IsChecked) { Refresh-Collections }
    if ($sync.Error) { if ($Script:CollAuto) { Write-Log "Collections: $($sync.Error)" } else { Tell $sync.Error 'Warning' } }
    Status "Collections checked — $($Script:Colls.Count) known."
    if ($Script:CurKey) { Show-Detail $Script:CurKey }
}

# =====================================================================================
#  Coming soon — films Radarr is waiting for, with their release dates
# =====================================================================================
$Files.Upcoming = Join-Path $DataDir 'radarr-upcoming.json'
$Script:Upcoming = @()
$Script:UpcomingViews = @()
$Script:UpcomingChecked = ''
$j = PH-LoadJson $Files.Upcoming
if ($j) { $Script:Upcoming = @($j['Films'] | Where-Object { $_ }); $Script:UpcomingChecked = [string]$j['Checked'] }
Remove-Variable j -ErrorAction SilentlyContinue

$UpcomingWork = {
    param($sync, $p)
    $sync.Status = 'Checking Radarr for films that are on their way…'
    function D($v) {
        if ($null -eq $v -or "$v" -eq '') { return $null }
        if ($v -is [datetime]) { return $v.ToString('s') }
        $d = [datetime]::MinValue
        if ([datetime]::TryParse([string]$v, [Globalization.CultureInfo]::InvariantCulture, [Globalization.DateTimeStyles]::AdjustToUniversal, [ref]$d)) { return $d.ToString('s') }
        return $null
    }
    $h = @{ 'X-Api-Key' = $p.Key; Accept = 'application/json' }
    $r = Invoke-RestMethod -Uri ($p.Url + '/api/v3/movie') -Headers $h -TimeoutSec 120 -UseBasicParsing
    $out = New-Object Collections.ArrayList
    foreach ($m in $r) {
        if ($m.hasFile -or -not $m.monitored) { continue }
        $poster = $null
        $img = @($m.images | Where-Object { $_.coverType -eq 'poster' } | Select-Object -First 1)
        if ($img.Count) { $poster = [string]$img[0].remoteUrl; if (-not $poster) { $poster = $null } }
        [void]$out.Add(@{
            TmdbId = [int]$m.tmdbId; Title = [string]$m.title; Year = [int]$m.year; Path = [string]$m.path; TitleSlug = [string]$m.titleSlug
            Status = [string]$m.status; Available = [bool]$m.isAvailable; MinAvailability = [string]$m.minimumAvailability
            InCinemas = (D $m.inCinemas); Digital = (D $m.digitalRelease); Physical = (D $m.physicalRelease)
            Poster = $poster; Overview = [string]$m.overview; Runtime = [int]$m.runtime; Genres = @($m.genres | ForEach-Object { [string]$_ }); Studio = [string]$m.studio
        })
    }
    $sync.Result = $out.ToArray()
}

function Start-UpcomingFetch([switch]$Quiet) {
    if (-not $Settings.RadarrUrl -or -not $Settings.RadarrKey) { return }
    if (Test-Busy 'Upcoming') { return }
    [void](Start-BgJob 'Upcoming' $UpcomingWork @{ Url = (Normalize-ServiceUrl $Settings.RadarrUrl); Key = ([string]$Settings.RadarrKey).Trim() } $null ${function:On-UpcomingDone})
}

function On-UpcomingDone($sync) {
    if ($sync.Error -or $null -eq $sync.Result) { Write-Log "Upcoming check failed: $($sync.Error)"; return }
    $Script:Upcoming = @($sync.Result)
    $Script:UpcomingChecked = (Get-Date).ToString('s')
    PH-SaveJson @{ Checked = $Script:UpcomingChecked; Films = $Script:Upcoming } $Files.Upcoming
    Build-UpcomingViews
    Refresh-Rail
    if ($Script:CurShelf.Kind -eq 'smart' -and $Script:CurShelf.Id -eq 'soon') { Apply-Filter }
    $Script:Dirty.Health = $true
    $n = @($Script:UpcomingViews).Count
    if ($n) { Status ("Radarr: $n film$(if ($n -ne 1) { 's' }) coming soon" + $(if ($Script:UpcomingViews[0].NextText) { " — next up: $($Script:UpcomingViews[0].Title), $($Script:UpcomingViews[0].NextText)" } else { '' })) }
}

function Get-ShelfForRadarrPath([string]$path) {
    $parts = @($path -split '[\\/]' | Where-Object { $_ })
    if ($parts.Count -lt 2) { return '' }
    $parent = $parts[-2]
    $hit = @(Get-ShelfList | Where-Object { (([string]$_['Name']) -split ' › ')[-1] -ieq $parent } | Select-Object -First 1)
    if ($hit.Count) { return [string]$hit[0]['Name'] }
    return $parent
}

# The date that matters for a film you will watch at home: the earliest digital/disc date, else the cinema date
function Get-ReleaseInfo($u) {
    $today = (Get-Date).Date
    $cin = PH-Date $u['InCinemas']; $dig = PH-Date $u['Digital']; $phy = PH-Date $u['Physical']
    $homeDates = @(@($dig, $phy) | Where-Object { $_ -gt [datetime]::MinValue } | Sort-Object)
    $homeDate = $(if ($homeDates.Count) { $homeDates[0] } else { [datetime]::MinValue })
    $homeKind = $(if ($homeDate -eq [datetime]::MinValue) { '' } elseif ($homeDate -eq $dig) { 'Digital' } else { 'Disc' })
    $out = @{ Cinema = $cin; Home = $homeDate; HomeKind = $homeKind; Next = [datetime]::MaxValue; NextLabel = ''; Stage = 'announced'; Released = $false }
    if ($homeDate -gt [datetime]::MinValue -and $homeDate.Date -le $today) { $out.Stage = 'out'; $out.Released = $true; $out.Next = $homeDate; $out.NextLabel = "$homeKind release" }
    elseif ($cin -gt [datetime]::MinValue -and $cin.Date -le $today) { $out.Stage = 'cinemas'; $out.Next = $(if ($homeDate -gt [datetime]::MinValue) { $homeDate } else { [datetime]::MaxValue }); $out.NextLabel = $(if ($homeDate -gt [datetime]::MinValue) { "$homeKind release" } else { 'Home release date not set' }) }
    elseif ($cin -gt [datetime]::MinValue) { $out.Stage = 'soon'; $out.Next = $cin; $out.NextLabel = 'In cinemas' }
    elseif ($homeDate -gt [datetime]::MinValue) { $out.Stage = 'soon'; $out.Next = $homeDate; $out.NextLabel = "$homeKind release" }
    # no dates at all: trust Radarr's own 'available' flag
    if ($out.Stage -eq 'announced' -and [bool]$u['Available']) { $out.Released = $true }
    return $out
}

function Format-Countdown([datetime]$d) {
    if ($d -eq [datetime]::MaxValue -or $d -eq [datetime]::MinValue) { return 'date not announced' }
    $days = [int]($d.Date - (Get-Date).Date).TotalDays
    if ($days -eq 0) { return 'today' }
    if ($days -eq 1) { return 'tomorrow' }
    if ($days -lt 0) { return "$(-$days) days ago" }
    if ($days -lt 60) { return "in $days days" }
    return ('in {0} months' -f [math]::Round($days / 30.4))
}

# A tidy card for the Coming soon tooltip: title, release dates, shelf, story
function New-UpcomingTip($u, $ri, [string]$shelf) {
    $cream = $Window.FindResource('Cream'); $dim = New-Object Windows.Media.SolidColorBrush ([Windows.Media.Color]::FromArgb(0xA6, 0xF6, 0xEB, 0xD9))
    $sp = New-Object Windows.Controls.StackPanel; $sp.MaxWidth = 420
    $t = New-Object Windows.Controls.TextBlock; $t.Text = [string]$u['Title']; $t.FontFamily = 'Georgia'; $t.FontSize = 19; $t.Foreground = $cream
    [void]$sp.Children.Add($t)
    if ($u['Year']) { $y = New-Object Windows.Controls.TextBlock; $y.Text = [string]$u['Year'] + $(if (@($u['Genres']).Count) { '   ·   ' + (@($u['Genres'] | Select-Object -First 3) -join ', ') } else { '' }); $y.Foreground = $dim; $y.FontSize = 12; $y.Margin = New-Object Windows.Thickness 0, 2, 0, 0; [void]$sp.Children.Add($y) }
    $g = New-Object Windows.Controls.Grid; $g.Margin = New-Object Windows.Thickness 0, 10, 0, 0
    $c0 = New-Object Windows.Controls.ColumnDefinition; $c0.Width = New-Object Windows.GridLength 104
    [void]$g.ColumnDefinitions.Add($c0); [void]$g.ColumnDefinitions.Add((New-Object Windows.Controls.ColumnDefinition))
    $rows = New-Object Collections.ArrayList
    if ($ri.Cinema -gt [datetime]::MinValue) { [void]$rows.Add(@('IN CINEMAS', $ri.Cinema)) }
    $dg = PH-Date $u['Digital']; if ($dg -gt [datetime]::MinValue) { [void]$rows.Add(@('DIGITAL', $dg)) }
    $ds = PH-Date $u['Physical']; if ($ds -gt [datetime]::MinValue) { [void]$rows.Add(@('DISC', $ds)) }
    if ($rows.Count -eq 0) { [void]$rows.Add(@('RELEASE', 'not announced yet')) }
    [void]$rows.Add(@('LANDS ON', $shelf))
    $today = (Get-Date).Date; $i = 0
    foreach ($r in $rows) {
        [void]$g.RowDefinitions.Add((New-Object Windows.Controls.RowDefinition))
        $l = New-Object Windows.Controls.TextBlock; $l.Text = $r[0]; $l.FontSize = 10.5; $l.FontWeight = [Windows.FontWeights]::Bold; $l.Foreground = $dim; $l.VerticalAlignment = 'Center'; $l.Margin = New-Object Windows.Thickness 0, 3, 0, 3
        $v = New-Object Windows.Controls.TextBlock; $v.Foreground = $cream; $v.FontSize = 13.5; $v.Margin = New-Object Windows.Thickness 0, 3, 0, 3
        if ($r[1] -is [datetime]) {
            $v.Text = $r[1].ToString('d MMM yyyy')
            if ($r[1].Date -le $today) { $v.Text += '   (out)'; $v.Opacity = 0.7 }
        } else { $v.Text = [string]$r[1] }
        [Windows.Controls.Grid]::SetRow($l, $i); [Windows.Controls.Grid]::SetRow($v, $i); [Windows.Controls.Grid]::SetColumn($v, 1)
        [void]$g.Children.Add($l); [void]$g.Children.Add($v); $i++
    }
    [void]$sp.Children.Add($g)
    if ($u['Overview']) {
        $ln = New-Object Windows.Controls.Border; $ln.Height = 1; $ln.Background = New-Object Windows.Media.SolidColorBrush ([Windows.Media.Color]::FromRgb(0x2A, 0x5F, 0x5C)); $ln.Margin = New-Object Windows.Thickness 0, 10, 0, 10
        [void]$sp.Children.Add($ln)
        $ov = [string]$u['Overview']; if ($ov.Length -gt 320) { $ov = $ov.Substring(0, 320).TrimEnd() + '…' }
        $o = New-Object Windows.Controls.TextBlock; $o.Text = $ov; $o.TextWrapping = 'Wrap'; $o.FontSize = 13; $o.LineHeight = 19; $o.Foreground = $cream; $o.Opacity = 0.9
        [void]$sp.Children.Add($o)
    }
    $h = New-Object Windows.Controls.TextBlock; $h.Text = 'Double-click to open in Radarr'; $h.FontSize = 11.5; $h.FontStyle = [Windows.FontStyles]::Italic; $h.Foreground = $dim; $h.Margin = New-Object Windows.Thickness 0, 10, 0, 0
    [void]$sp.Children.Add($h)
    return , $sp
}

function Build-UpcomingViews {
    $views = foreach ($u in @($Script:Upcoming)) {
        if (Test-IgnoredPath ([string]$u['Path'])) { continue }
        $ri = Get-ReleaseInfo $u
        if ($ri.Released) { continue }      # out already — that's a Health item, not "coming soon"
        $shelf = Get-ShelfForRadarrPath ([string]$u['Path'])
        $badge = ''   # no label over the posters — the page is already 'Coming soon' and the dates are under each one
        $nextText = ''
        if ($ri.Next -ne [datetime]::MaxValue) { $nextText = $ri.Next.ToString('d MMM yyyy') + ' · ' + (Format-Countdown $ri.Next) } else { $nextText = 'date not announced yet' }
        $tip = [Windows.Controls.StackPanel](New-UpcomingTip $u $ri $shelf)   # unwrap it, or WPF just shows the type name
        $month = $(if ($ri.Next -ne [datetime]::MaxValue) { $ri.Next.ToString('MMMM yyyy') } else { 'Date not announced' })
        $genres = @($u['Genres'] | Where-Object { $_ })
        [pscustomobject]@{
            IsFilm = $false; IsUpcoming = $true; Key = 'soon|' + $u['TmdbId']; TmdbId = [int]$u['TmdbId']; TitleSlug = [string]$u['TitleSlug']
            Title = [string]$u['Title']; Year = [int]$u['Year']; YearText = [string]$u['Year']; Shelf = $shelf; ShelfBrush = (Get-ShelfColor $shelf)
            Poster = $u['Poster']; Res = $badge; ResVis = $(if ($badge) { 'Visible' } else { 'Collapsed' }); WatchedVis = 'Collapsed'; FavVis = 'Collapsed'; ListVis = 'Collapsed'
            Sub = $(if ($ri.NextLabel -and $ri.Next -ne [datetime]::MaxValue) { "$($ri.NextLabel) " + $ri.Next.ToString('d MMM') + ' · ' + (Format-Countdown $ri.Next) } else { $nextText })
            NextText = $nextText; NextDate = $ri.Next; MonthKey = $month; Tip = $tip; Path = [string]$u['Path']
            GenreText = ($genres -join ', '); RuntimeText = (Format-Runtime ([int]$u['Runtime'])); RatingText = ''; MyStars = ''; SizeText = ''; WatchedText = ''
            AddedText = $(if ($ri.Next -ne [datetime]::MaxValue) { $ri.Next.ToString('dd MMM yyyy') } else { '' })
            Size = 0.0; Runtime = [int]$u['Runtime']; Watched = $false
            SearchText = (([string]$u['Title'], [string]$u['Year'], $shelf, ($genres -join ' '), [string]$u['Studio']) -join ' | ').ToLowerInvariant()
        }
    }
    $Script:UpcomingViews = @($views | Sort-Object NextDate, Title)
}

# Films Radarr is still waiting for although their release date has passed
function Get-OverdueRadarr {
    return @(foreach ($u in @($Script:Upcoming)) { $ri = Get-ReleaseInfo $u; if ($ri.Released) { @{ U = $u; R = $ri } } })
}

# NAS folder ↔ Radarr path match on the last two parts ("Horror\Film (2027)")
function Get-PathTail([string]$p) {
    $parts = @($p -split '[\\/]' | Where-Object { $_ })
    if ($parts.Count -ge 2) { return ($parts[-2] + '/' + $parts[-1]).ToLowerInvariant() }
    if ($parts.Count -eq 1) { return $parts[0].ToLowerInvariant() }
    return ''
}

function Open-InRadarr($v) {
    if (-not $Settings.RadarrUrl) { return }
    $slug = $v.TitleSlug; if (-not $slug) { $slug = [string]$v.TmdbId }
    Open-Url ((Normalize-ServiceUrl $Settings.RadarrUrl) + '/movie/' + $slug)
}


# =====================================================================================
#  Awards — Oscars, BAFTAs and Golden Globes from Wikidata (free, no key), matched by TMDb id
# =====================================================================================
$Files.Awards = Join-Path $DataDir 'awards.json'
$Script:Awards = @{ Checked = ''; Ids = @(); Films = @{}; Lists = @{} }
$j = PH-LoadJson $Files.Awards
if ($j) { foreach ($k in 'Checked', 'Ids', 'Films', 'Lists') { if ($null -ne $j[$k]) { $Script:Awards[$k] = $j[$k] } } }
Remove-Variable j -ErrorAction SilentlyContinue

$AwardsWork = {
    param($sync, $p)
    function Ask-Wikidata([string]$q) {
        $h = @{ Accept = 'application/sparql-results+json'; 'User-Agent' = 'PictureHouse/1.3 (personal film library app; PowerShell)' }
        $r = Invoke-RestMethod -Method Post -Uri 'https://query.wikidata.org/sparql' -Headers $h -Body @{ query = $q } -ContentType 'application/x-www-form-urlencoded' -TimeoutSec 90 -UseBasicParsing
        return @($r.results.bindings)
    }
    $films = @{}
    $ids = @($p.Ids)
    # 1) awards and nominations for the films you own (the film itself, or a person "for" that film)
    $batch = 40; $ok = 0; $lastErr = ''
    for ($i = 0; $i -lt $ids.Count; $i += $batch) {
        if ($sync.Cancel) { return }
        $hi = [math]::Min($ids.Count, $i + $batch)
        $sync.Status = "Checking awards on Wikidata  ·  $hi of $($ids.Count) films"
        $vals = (@($ids[$i..($hi - 1)]) | ForEach-Object { '"' + $_ + '"' }) -join ' '
        # optimizer "None" makes Wikidata run the steps in the order written: your films first, then their awards —
        # without it the server can try to scan every award statement and time out (HTTP 504)
        $q = @"
SELECT DISTINCT ?tmdb ?awardLabel ?kind ?year WHERE {
  hint:Query hint:optimizer "None" .
  VALUES ?tmdb { $vals }
  ?film wdt:P4947 ?tmdb .
  {
    { ?film p:P166 ?st . ?st ps:P166 ?award . BIND("won" AS ?kind) }
    UNION { ?film p:P1411 ?st . ?st ps:P1411 ?award . BIND("nom" AS ?kind) }
    UNION { ?st pq:P1686 ?film . ?st ps:P166 ?award . BIND("won" AS ?kind) }
    UNION { ?st pq:P1686 ?film . ?st ps:P1411 ?award . BIND("nom" AS ?kind) }
  }
  ?award rdfs:label ?awardLabel . FILTER(LANG(?awardLabel) = "en")
  FILTER(STRSTARTS(?awardLabel, "Academy Award for") || STRSTARTS(?awardLabel, "BAFTA Award for") || STRSTARTS(?awardLabel, "Golden Globe Award for"))
  OPTIONAL { ?st pq:P585 ?date . BIND(YEAR(?date) AS ?year) }
}
"@
        $rows = $null
        for ($try = 1; $try -le 2 -and $null -eq $rows; $try++) {
            try { $rows = @(Ask-Wikidata $q) } catch { $lastErr = $_.Exception.Message; Start-Sleep -Seconds 3 }
        }
        if ($null -eq $rows) { continue }
        $ok++
        foreach ($b in $rows) {
            $t = [string]$b.tmdb.value; $a = [string]$b.awardLabel.value; $k = [string]$b.kind.value
            $y = 0; if ($b.year) { [void][int]::TryParse([string]$b.year.value, [ref]$y) }
            if (-not $films.ContainsKey($t)) { $films[$t] = @{} }
            $prev = $films[$t][$a]
            if (-not $prev -or ($prev.K -eq 'nom' -and $k -eq 'won')) { $films[$t][$a] = @{ A = $a; K = $k; Y = $y } }
        }
        Start-Sleep -Milliseconds 400
    }
    if ($ok -eq 0) { throw "Wikidata didn't answer: $lastErr" }
    $outFilms = @{}
    foreach ($t in $films.Keys) { $outFilms[$t] = @($films[$t].Values) }

    # 2) every Best Picture (Oscar) and Best Film (BAFTA) winner, for the "what am I missing" lists
    $sync.Status = 'Fetching the Best Picture winners…'
    $q2 = @'
SELECT DISTINCT ?which ?tmdb ?filmLabel ?year WHERE {
  hint:Query hint:optimizer "None" .
  VALUES (?which ?lbl) { ("oscar" "Academy Award for Best Picture"@en) ("bafta" "BAFTA Award for Best Film"@en) }
  ?award rdfs:label ?lbl .
  ?st ps:P166 ?award .
  ?film p:P166 ?st .
  ?film wdt:P4947 ?tmdb .
  OPTIONAL { ?st pq:P585 ?d . BIND(YEAR(?d) AS ?year) }
  OPTIONAL { ?film rdfs:label ?filmLabel . FILTER(LANG(?filmLabel) = "en") }
}
'@
    $lists = @{ oscar = @{}; bafta = @{} }
    $winners = @(); try { $winners = @(Ask-Wikidata $q2) } catch { $sync.Note = 'Best Picture list: ' + $_.Exception.Message }
    foreach ($b in $winners) {
        $w = [string]$b.which.value; $t = [string]$b.tmdb.value
        if (-not $lists.ContainsKey($w) -or $t -notmatch '^\d+$') { continue }
        $y = 0; if ($b.year) { [void][int]::TryParse([string]$b.year.value, [ref]$y) }
        if (-not $lists[$w].ContainsKey($t)) { $lists[$w][$t] = @{ Id = [int]$t; Title = [string]$b.filmLabel.value; AwardYear = $y; Year = 0; Release = ''; Poster = '' } }
    }
    # posters and release dates from TMDb (only for films not looked up before)
    $known = $p.Known
    $todo = @(); foreach ($w in $lists.Keys) { foreach ($t in $lists[$w].Keys) { $todo += , @($w, $t) } }
    $n = 0
    foreach ($x in $todo) {
        if ($sync.Cancel) { break }
        $w = $x[0]; $t = $x[1]; $e = $lists[$w][$t]; $n++
        $k = $known[$t]
        if ($k) { $e.Title = [string]$k['Title']; $e.Year = [int]$k['Year']; $e.Release = [string]$k['Release']; $e.Poster = [string]$k['Poster']; continue }
        if (-not $p.Key) { continue }
        $sync.Status = "Fetching posters for the award winners  ·  $n of $($todo.Count)"
        try {
            $m = PH-Tmdb $p.Key "/movie/$t" @{ language = $p.Lang }
            if ($m) {
                if ($m.title) { $e.Title = [string]$m.title }
                $e.Release = [string]$m.release_date
                if ($e.Release.Length -ge 4) { $e.Year = [int]$e.Release.Substring(0, 4) }
                $e.Poster = PH-ImgUrl $m.poster_path 'w342'
                $known[$t] = @{ Title = $e.Title; Year = $e.Year; Release = $e.Release; Poster = $e.Poster }
            }
        } catch { if ($_.Exception.Message -match '401') { $p.Key = '' } }
        Start-Sleep -Milliseconds 60
    }
    $outLists = @{}
    foreach ($w in $lists.Keys) { $outLists[$w] = @($lists[$w].Values | Sort-Object { $_.AwardYear } -Descending) }
    $sync.Result = @{ Films = $outFilms; Lists = $outLists; Partial = ($ok * $batch -lt $ids.Count) }
}

function Start-AwardsFetch([switch]$Auto) {
    if (Test-Busy 'Awards') { return }
    $ids = @($Script:AllViews | Where-Object { $_.TmdbId -gt 0 } | ForEach-Object { [string]$_.TmdbId } | Select-Object -Unique | Sort-Object)
    if ($ids.Count -eq 0) { if (-not $Auto) { Tell 'Fetch film info first — awards are matched by TMDb id.' }; return }
    if ($Auto) {
        $last = PH-Date $Script:Awards.Checked
        $seen = New-Object 'Collections.Generic.HashSet[string]'; foreach ($x in @($Script:Awards.Ids)) { [void]$seen.Add([string]$x) }
        $new = @($ids | Where-Object { -not $seen.Contains($_) }).Count
        if ($last -gt (Get-Date).AddDays(-14) -and $new -eq 0) { return }
    }
    # reuse posters already looked up
    $known = [hashtable]::Synchronized(@{})
    foreach ($w in @($Script:Awards.Lists.Keys)) { foreach ($e in @($Script:Awards.Lists[$w])) { if ($e -and $e['Poster']) { $known[[string]$e['Id']] = @{ Title = $e['Title']; Year = $e['Year']; Release = $e['Release']; Poster = $e['Poster'] } } } }
    $Script:AwardsIds = $ids
    $Script:AwardsAuto = [bool]$Auto
    [void](Start-BgJob 'Awards' $AwardsWork @{ Ids = $ids; Key = $Settings.TmdbKey; Lang = $Settings.Language; Known = $known } $null ${function:On-AwardsDone})
}

function On-AwardsDone($sync) {
    if ($sync.Error -or -not $sync.Result) {
        Write-Log "Awards check failed: $($sync.Error)"
        if (-not $Script:AwardsAuto) { Tell ("Couldn't check awards on Wikidata.`n`n" + $sync.Error) 'Warning' }
        return
    }
    if ($sync.Note) { Write-Log "Awards: $($sync.Note)" }
    $lists = $sync.Result.Lists
    if (-not @($lists.Values | Where-Object { @($_).Count }).Count -and $Script:Awards.Lists) { $lists = $Script:Awards.Lists }   # keep the last good winners lists
    $Script:Awards = @{ Checked = (Get-Date).ToString('s'); Ids = $Script:AwardsIds; Films = $sync.Result.Films; Lists = $lists }
    PH-SaveJson $Script:Awards $Files.Awards
    $won = @($Script:Awards.Films.Keys | Where-Object { @($Script:Awards.Films[$_] | Where-Object { $_.K -eq 'won' -or $_['K'] -eq 'won' }).Count }).Count
    Write-Log "Awards: $($Script:Awards.Films.Count) of your films have Oscar/BAFTA/Golden Globe wins or nominations ($won winners)."
    Status "Awards checked — $($Script:Awards.Films.Count) of your films are award winners or nominees."
    Refresh-Rail
    $Script:Dirty.Collections = $true
    if ($UI.navCollections.IsChecked) { Refresh-Collections }
    if ($Script:CurShelf.Kind -eq 'smart' -and $Script:CurShelf.Id -eq 'awards') { Apply-Filter }
    if ($Script:CurKey) { Show-Detail $Script:CurKey }
}

# ---- helpers used by the shelf, the film panel and Collections ----
function Get-FilmAwards($v) {
    if (-not $v -or $v.TmdbId -le 0 -or -not $Script:Awards.Films) { return @() }
    return @($Script:Awards.Films[[string]$v.TmdbId] | Where-Object { $_ })
}
function Split-AwardName([string]$label) {
    # "Academy Award for Best Picture" -> Oscar / Best Picture
    if ($label -match '^Academy Award for (.+)$') { return @{ Org = 'Oscar'; Order = 1; What = $Matches[1] } }
    if ($label -match '^BAFTA Award for (.+)$') { return @{ Org = 'BAFTA'; Order = 2; What = $Matches[1] } }
    if ($label -match '^Golden Globe Award for (.+)$') { return @{ Org = 'Golden Globe'; Order = 3; What = $Matches[1] } }
    return @{ Org = 'Award'; Order = 9; What = $label }
}
function Get-AwardTier($v) {
    $best = $null
    foreach ($a in (Get-FilmAwards $v)) {
        $s = Split-AwardName ([string]$a['A'])
        $rank = $s.Order + $(if ($a['K'] -eq 'won') { 0 } else { 10 })
        if (-not $best -or $rank -lt $best.Rank) { $best = @{ Rank = $rank; Org = $s.Org; Won = ($a['K'] -eq 'won') } }
    }
    if (-not $best) { return '' }
    return ('{0:00}|{1} {2}' -f $best.Rank, $best.Org, $(if ($best.Won) { 'winners' } else { 'nominees' }))
}
function Format-FilmAwards($v) {
    # one line per organisation: "Oscars — won Best Picture, Best Director · nominated Best Actor"
    $by = @{}
    foreach ($a in (Get-FilmAwards $v)) {
        $s = Split-AwardName ([string]$a['A'])
        if (-not $by.ContainsKey($s.Org)) { $by[$s.Org] = @{ Order = $s.Order; Won = (New-Object Collections.ArrayList); Nom = (New-Object Collections.ArrayList) } }
        if ($a['K'] -eq 'won') { [void]$by[$s.Org].Won.Add($s.What) } else { [void]$by[$s.Org].Nom.Add($s.What) }
    }
    $lines = foreach ($org in @($by.Keys | Sort-Object { $by[$_].Order })) {
        $e = $by[$org]; $bits = @()
        if ($e.Won.Count) { $bits += ('won ' + (@($e.Won | Sort-Object -Unique) -join ', ')) }
        if ($e.Nom.Count) { $bits += ('nominated for ' + (@($e.Nom | Sort-Object -Unique) -join ', ')) }
        $plural = $(if ($org -eq 'Oscar') { 'Oscars' } elseif ($org -eq 'Golden Globe') { 'Golden Globes' } else { 'BAFTAs' })
        "★  $plural — " + ($bits -join '  ·  ')
    }
    return (@($lines) -join "`n")
}

# Oscar Best Picture and BAFTA Best Film winners, shown in Collections like a franchise
$AwardLists = @(
    @{ Id = -1; Key = 'oscar'; Name = '★ Oscar — Best Picture winners'; Overview = 'Every film that won the Academy Award for Best Picture. The ones on your shelves are in full colour; the rest you can send to Radarr or Seerr.' },
    @{ Id = -2; Key = 'bafta'; Name = '★ BAFTA — Best Film winners'; Overview = 'Every winner of the BAFTA Award for Best Film. The ones on your shelves are in full colour; the rest you can send to Radarr or Seerr.' }
)
function Get-AwardCollection([int]$id) {
    $d = @($AwardLists | Where-Object { $_.Id -eq $id }); if (-not $d.Count) { return $null }
    $parts = @($Script:Awards.Lists[$d[0].Key] | Where-Object { $_ })
    if (-not $parts.Count) { return $null }
    return @{ Name = $d[0].Name; Overview = $d[0].Overview
              Parts = @($parts | ForEach-Object {
                  $rel = [string]$_['Release']; if (-not $rel -and [int]$_['AwardYear'] -gt 1900) { $rel = '{0}-06-01' -f ([int]$_['AwardYear'] - 1) }
                  $yr = [int]$_['Year']; if (-not $yr -and [int]$_['AwardYear'] -gt 1900) { $yr = [int]$_['AwardYear'] - 1 }
                  @{ Id = [int]$_['Id']; Title = [string]$_['Title']; Year = $yr; Release = $rel; Poster = $(if ($_['Poster']) { [string]$_['Poster'] } else { $null }); AwardYear = [int]$_['AwardYear'] } }) }
}

# =====================================================================================
#  Rail (smart lists + shelves)
# =====================================================================================
$SmartDefs = @(
    @{ Id = 'all';     Name = 'All films';        Brush = '#F6EBD9' },
    @{ Id = 'recent';  Name = 'Recently added';   Brush = '#D9902F' },
    @{ Id = 'list';    Name = 'Watchlist';        Brush = '#3F86B0' },
    @{ Id = 'fav';     Name = 'Favourites';       Brush = '#C8432B' },
    @{ Id = 'unseen';  Name = 'Not watched yet';  Brush = '#3E8E4F' },
    @{ Id = 'played';  Name = 'Recently played';  Brush = '#8E4C8F' },
    @{ Id = 'awards';  Name = 'Award winners';    Brush = '#C9A227' },
    @{ Id = 'nomatch'; Name = 'Needs film info';  Brush = '#7B7266' },
    @{ Id = 'soon';    Name = 'Coming soon';      Brush = '#1F9BB5' }
)

function Test-Smart([string]$id, $v) {
    switch ($id) {
        'all'     { return $true }
        'recent'  { return ($v.Added -gt (Get-Date).AddDays(-60)) }
        'list'    { return $v.Watchlist }
        'fav'     { return $v.Fav }
        'unseen'  { return (-not $v.Watched) }
        'played'  { return ($v.LastPlayed -gt [datetime]::MinValue) }
        'nomatch' { return (-not $v.HasInfo) }
        'awards'  { return ($v.TmdbId -gt 0 -and $Script:Awards.Films -and $Script:Awards.Films.ContainsKey([string]$v.TmdbId)) }
        'soon'    { return $false }
    }
    return $true
}

function Get-ShelfList {
    # every shelf from the scan plus any shelf a film says it is on
    $map = @{}
    foreach ($s in @($Script:Shelves)) { if ($s -and $s['Name']) { $map[[string]$s['Name']] = $s } }
    foreach ($v in $Script:AllViews) { if ($v.Shelf -and -not $map.ContainsKey($v.Shelf)) { $map[$v.Shelf] = @{ Name = $v.Shelf; Path = ''; Root = ''; Depth = 0 } } }
    return @($map.Values | Sort-Object { ([string]$_['Name']).Replace(' › ', [string][char]1).ToLowerInvariant() })
}

function Refresh-Rail {
    $Script:Loading = $true
    try {
        $vis = Get-VisibleViews
        $smart = foreach ($d in $SmartDefs) {
            $c = 0
            if ($d.Id -eq 'soon') { $c = @($Script:UpcomingViews).Count } else { foreach ($v in $vis) { if (Test-Smart $d.Id $v) { $c++ } } }
            if ($d.Id -in @('played', 'nomatch', 'list', 'fav', 'soon', 'awards') -and $c -eq 0) { continue }
            [pscustomobject]@{ Kind = 'smart'; Id = $d.Id; Name = $d.Name; Count = $c; Brush = $d.Brush; Indent = '0'; Tip = $d.Name; Path = '' }
        }
        $UI.lbSmart.ItemsSource = @($smart)
        $set = Get-HiddenSet
        $exact = @{}
        foreach ($v in $vis) { if ($exact.ContainsKey($v.Shelf)) { $exact[$v.Shelf]++ } else { $exact[$v.Shelf] = 1 } }
        $shelves = foreach ($s in (Get-ShelfList)) {
            $name = [string]$s['Name']
            if (Test-Hidden $name $set) { continue }
            $c = 0; foreach ($k in $exact.Keys) { if ($k -eq $name -or $k.StartsWith($name + ' › ')) { $c += $exact[$k] } }
            $parts = $name -split ' › '
            $tip = $name; if ($s['Path']) { $tip += "`n" + $s['Path'] }
            [pscustomobject]@{ Kind = 'shelf'; Id = $name; Name = $parts[-1]; Count = $c; Brush = (Get-ShelfColor $name); Indent = ('{0},0,0,0' -f (14 * ($parts.Count - 1))); Tip = $tip; Path = [string]$s['Path'] }
        }
        $UI.lbShelves.ItemsSource = @($shelves)
        $UI.txtNoShelves.Visibility = $(if (@($shelves).Count) { 'Collapsed' } else { 'Visible' })
        # re-select
        $UI.lbSmart.SelectedIndex = -1; $UI.lbShelves.SelectedIndex = -1
        if ($Script:CurShelf.Kind -eq 'smart') {
            $hit = @($UI.lbSmart.Items | Where-Object { $_.Id -eq $Script:CurShelf.Id })
            if ($hit.Count) { $UI.lbSmart.SelectedItem = $hit[0] } else { $Script:CurShelf = @{ Kind = 'smart'; Id = 'all' }; $UI.lbSmart.SelectedIndex = 0 }
        } else {
            $hit = @($UI.lbShelves.Items | Where-Object { $_.Id -eq $Script:CurShelf.Id })
            if ($hit.Count) { $UI.lbShelves.SelectedItem = $hit[0] } else { $Script:CurShelf = @{ Kind = 'smart'; Id = 'all' }; $UI.lbSmart.SelectedIndex = 0 }
        }
        $last = PH-Date $Settings.LastScan
        if ($last -gt [datetime]::MinValue) { $UI.txtLastScan.Text = 'Last scanned ' + $last.ToString('ddd d MMM, HH:mm') } else { $UI.txtLastScan.Text = 'Not scanned yet' }
    } finally { $Script:Loading = $false }
}

function Refresh-Totals {
    $vis = Get-VisibleViews
    $size = 0.0; foreach ($v in $vis) { $size += $v.Size }
    $shelfCount = @($UI.lbShelves.Items).Count
    $UI.txtTotals.Text = ('{0:N0} films  ·  {1} shelves  ·  {2}' -f $vis.Count, $shelfCount, (Format-Size $size))
}

# =====================================================================================
#  Filters, sorting, the poster wall
# =====================================================================================
$SortNames = @('Title A–Z', 'Year — newest', 'Year — oldest', 'Recently added', 'TMDb rating', 'My rating', 'Shortest first', 'Longest first', 'Largest file', 'Recently played', 'Added to watchlist')
$GroupNames = @('None', 'Shelf', 'Decade', 'Letter', 'Genre')

function Fill-Combo($cb, $items, $selected) {
    $Script:Loading = $true
    try {
        $cb.ItemsSource = @($items)
        if ($null -ne $selected -and @($items) -contains $selected) { $cb.SelectedItem = $selected } else { $cb.SelectedIndex = 0 }
    } finally { $Script:Loading = $false }
}

function Refresh-FilterCombos {
    $genres = @($Script:AllViews | ForEach-Object { $_.Genres } | Where-Object { $_ } | Sort-Object -Unique)
    $decades = @($Script:AllViews | Where-Object { $_.Decade -gt 0 } | ForEach-Object { $_.Decade } | Sort-Object -Unique -Descending | ForEach-Object { "$($_)s" })
    Fill-Combo $UI.cbGenre (@('Any genre') + $genres) $UI.cbGenre.SelectedItem
    Fill-Combo $UI.cbDecade (@('Any decade') + $decades) $UI.cbDecade.SelectedItem
    Fill-Combo $UI.cbRes @('Any quality', '4K', '1080p', '720p', 'SD', 'Unknown') $UI.cbRes.SelectedItem
    Fill-PickShelves
}

function Get-SortedViews($list, [string]$sort) {
    switch ($sort) {
        'Year — newest'      { return @($list | Sort-Object @{ e = { $_.Year }; d = $true }, SortTitle) }
        'Year — oldest'      { return @($list | Sort-Object @{ e = { if ($_.Year) { $_.Year } else { 9999 } } }, SortTitle) }
        'Recently added'     { return @($list | Sort-Object @{ e = { $_.Added }; d = $true }, SortTitle) }
        'TMDb rating'        { return @($list | Sort-Object @{ e = { $_.Rating }; d = $true }, SortTitle) }
        'My rating'          { return @($list | Sort-Object @{ e = { $_.MyRating }; d = $true }, @{ e = { $_.Rating }; d = $true }) }
        'Shortest first'     { return @($list | Sort-Object @{ e = { if ($_.Runtime) { $_.Runtime } else { 9999 } } }, SortTitle) }
        'Longest first'      { return @($list | Sort-Object @{ e = { $_.Runtime }; d = $true }, SortTitle) }
        'Largest file'       { return @($list | Sort-Object @{ e = { $_.Size }; d = $true }) }
        'Recently played'    { return @($list | Sort-Object @{ e = { $_.LastPlayed }; d = $true }, SortTitle) }
        'Added to watchlist' { return @($list | Sort-Object @{ e = { $_.ListAdded }; d = $true }, SortTitle) }
        default              { return @($list | Sort-Object SortTitle, Year) }
    }
}

function Apply-Filter {
    if ($Script:Loading) { return }
    $q = $UI.txtSearch.Text.Trim().ToLowerInvariant()
    $terms = @($q -split '\s+' | Where-Object { $_ })
    $genre = [string]$UI.cbGenre.SelectedItem; if ($genre -eq 'Any genre') { $genre = '' }
    $dec = [string]$UI.cbDecade.SelectedItem; $decN = 0; if ($dec -match '^(\d{4})s$') { $decN = [int]$Matches[1] }
    $res = [string]$UI.cbRes.SelectedItem; if ($res -eq 'Any quality') { $res = '' }
    $unw = [bool]$UI.tgUnwatched.IsChecked; $favs = [bool]$UI.tgFavs.IsChecked; $lst = [bool]$UI.tgList.IsChecked; $noinfo = [bool]$UI.tgNoInfo.IsChecked
    $cs = $Script:CurShelf
    $list = New-Object Collections.Generic.List[object]
    foreach ($v in (Get-VisibleViews)) {
        if ($cs.Kind -eq 'smart') { if (-not (Test-Smart $cs.Id $v)) { continue } }
        elseif (-not ($v.Shelf -eq $cs.Id -or $v.Shelf.StartsWith($cs.Id + ' › '))) { continue }
        if ($unw -and $v.Watched) { continue }
        if ($favs -and -not $v.Fav) { continue }
        if ($lst -and -not $v.Watchlist) { continue }
        if ($noinfo -and $v.HasInfo) { continue }
        if ($genre -and -not ($v.Genres -contains $genre)) { continue }
        if ($decN -and $v.Decade -ne $decN) { continue }
        if ($res) { if ($res -eq 'Unknown') { if ($v.Res) { continue } } elseif ($v.Res -ne $res) { continue } }
        $ok = $true
        foreach ($t in $terms) { if ($v.SearchText.IndexOf($t) -lt 0) { $ok = $false; break } }
        if (-not $ok) { continue }
        $list.Add($v)
    }
    $isSoon = ($cs.Kind -eq 'smart' -and $cs.Id -eq 'soon')
    if ($isSoon) {
        $sorted = @(foreach ($u in $Script:UpcomingViews) { $ok = $true; foreach ($t in $terms) { if ($u.SearchText.IndexOf($t) -lt 0) { $ok = $false; break } }; if ($ok) { $u } })
    } else { $sorted = Get-SortedViews $list ([string]$UI.cbSort.SelectedItem) }
    $Script:Filtered = New-Object Collections.Generic.List[object]
    foreach ($v in $sorted) { $Script:Filtered.Add($v) }

    # header
    if ($cs.Kind -eq 'smart') {
        $title = ($SmartDefs | Where-Object { $_.Id -eq $cs.Id } | Select-Object -First 1).Name
        $UI.bdShelfSwatch.Background = (New-Object Windows.Media.BrushConverter).ConvertFromString('#C8432B')
    } else {
        $title = ($cs.Id -split ' › ')[-1]
        $UI.bdShelfSwatch.Background = (New-Object Windows.Media.BrushConverter).ConvertFromString((Get-ShelfColor $cs.Id))
    }
    $UI.txtShelfTitle.Text = $title
    $size = 0.0; $mins = 0; $seen = 0
    $timed = 0
    foreach ($v in $Script:Filtered) { $size += $v.Size; $mins += $v.Runtime; if ($v.Runtime -gt 0) { $timed++ }; if ($v.Watched) { $seen++ } }
    $sub = '{0:N0} film{1}' -f $Script:Filtered.Count, $(if ($Script:Filtered.Count -eq 1) { '' } else { 's' })
    if ($size -gt 0) { $sub += '  ·  ' + (Format-Size $size) }
    if ($timed -gt 0 -and $timed -ge $Script:Filtered.Count * 0.8) {
        $hrs = [math]::Round($mins / 60.0)
        if ($hrs -ge 1) { $sub += ('  ·  {0:N0} hour{1} of film' -f $hrs, $(if ($hrs -eq 1) { '' } else { 's' })) }
    }
    if ($Script:Filtered.Count -gt 0 -and $seen -gt 0) { $sub += ('  ·  {0} watched' -f $seen) }
    if ($cs.Kind -eq 'shelf') { $sh = @(Get-ShelfList | Where-Object { $_['Name'] -eq $cs.Id }); if ($sh.Count -and $sh[0]['Path']) { $sub += '  ·  ' + $sh[0]['Path'] } }
    if ($isSoon) {
        $sub = '{0} film{1} Radarr is waiting for' -f $Script:Filtered.Count, $(if ($Script:Filtered.Count -eq 1) { '' } else { 's' })
        if ($Script:Filtered.Count) { $sub += '  ·  next: ' + $Script:Filtered[0].Title + ', ' + $Script:Filtered[0].NextText }
        $chk = PH-Date $Script:UpcomingChecked; if ($chk -gt [datetime]::MinValue) { $sub += '  ·  checked ' + $chk.ToString('HH:mm') }
    }
    if ($terms.Count) { $sub += "  ·  matching ‘$q’" }
    $UI.txtShelfSub.Text = $sub
    Update-PeopleHits $q

    if ($Script:Filtered.Count -eq 0) {
        $UI.txtEmpty.Visibility = 'Visible'
        if ($Script:Lib.Count -eq 0) { $UI.txtEmpty.Text = "Your shelves are empty.`nAdd the NAS film folder in Settings, then press ‘Rescan the NAS’." }
        elseif ($isSoon) { $UI.txtEmpty.Text = 'Radarr isn''t waiting for any unreleased films.' }
        else { $UI.txtEmpty.Text = 'Nothing here matches those filters.' }
    } else { $UI.txtEmpty.Visibility = 'Collapsed' }

    if ($UI.rbList.IsChecked) {
        $UI.lbWall.Visibility = 'Collapsed'; $UI.dgList.Visibility = 'Visible'
        $UI.dgList.ItemsSource = $Script:Filtered
    } else {
        $UI.dgList.Visibility = 'Collapsed'; $UI.lbWall.Visibility = 'Visible'
        Render-Wall
    }
}

# People whose name matches the search box, shown as a strip above the films
function Update-PeopleHits([string]$q) {
    $q = $q.Trim()
    if ($q.Length -lt 2) { $UI.bdPeopleHits.Visibility = 'Collapsed'; $UI.icPeopleHits.ItemsSource = $null; return }
    if ($Script:Dirty.People -or -not $Script:PeopleIndex) { Build-PeopleIndex }
    Load-PersonDepts
    $terms = @($q.ToLowerInvariant() -split '\s+' | Where-Object { $_ })
    $hits = @{}
    foreach ($kind in 'Directors', 'Actors') {
        foreach ($p in $Script:PeopleIndex[$kind].Values) {
            $n = $p.Name.ToLowerInvariant(); $ok = $true
            foreach ($t in $terms) { if ($n.IndexOf($t) -lt 0) { $ok = $false; break } }
            if (-not $ok) { continue }
            if ($kind -eq 'Actors' -and -not (Test-ActorOrDirector $p)) { continue }
            if ($hits.ContainsKey($p.Name)) { $hits[$p.Name].Kinds += $kind; $hits[$p.Name].Count = [math]::Max($hits[$p.Name].Count, $p.Films.Count); continue }
            $hits[$p.Name] = @{ Name = $p.Name; Photo = $p.Photo; Kinds = @($kind); Count = $p.Films.Count }
        }
    }
    $rows = @($hits.Values | Sort-Object @{ e = { $_.Count }; d = $true }, @{ e = { $_.Name } } | Select-Object -First 10 | ForEach-Object {
        $isDir = $_.Kinds -contains 'Directors'; $isAct = $_.Kinds -contains 'Actors'
        $role = $(if ($isDir -and $isAct) { 'Director & actor' } elseif ($isDir) { 'Director' } else { 'Actor' })
        $ph = $_.Photo; if (-not $ph) { $ph = $null }
        [pscustomobject]@{ Name = $_.Name; Photo = $ph; Initials = (Get-Initials $_.Name)
            Sub = ('{0}  ·  {1} film{2}' -f $role, $_.Count, $(if ($_.Count -eq 1) { '' } else { 's' }))
            Tag = $(if ($isDir) { 'Directors' } else { 'Actors' }) + '|' + $_.Name }
    })
    $UI.icPeopleHits.ItemsSource = $rows
    $UI.bdPeopleHits.Visibility = $(if ($rows.Count) { 'Visible' } else { 'Collapsed' })
}

function Get-GroupKey($v, [string]$mode) {
    switch ($mode) {
        'Shelf'  { return ($v.Shelf -split ' › ')[0] }
        'Decade' { if ($v.Decade) { return "$($v.Decade)s" } else { return 'Year unknown' } }
        'Letter' { $c = $v.SortTitle.Substring(0, [math]::Min(1, $v.SortTitle.Length)).ToUpperInvariant(); if ($c -match '[A-Z]') { return $c } else { return '#' } }
        'Genre'  { if ($v.Genres.Count) { return [string]$v.Genres[0] } else { return 'No genre yet' } }
        'Month'  { return [string]$v.MonthKey }
        'Award'  { $t = Get-AwardTier $v; if ($t) { return $t } else { return '99|Other' } }
    }
    return ''
}

function Render-Wall {
    $w = $UI.lbWall.ActualWidth
    if ($w -lt 200) { $w = [math]::Max(800, $Window.ActualWidth - 700) }
    $per = [int][math]::Max(1, [math]::Floor(($w - 28) / 172))
    $Script:PerRow = $per
    $mode = [string]$UI.cbGroup.SelectedItem
    if ($Script:CurShelf.Kind -eq 'smart' -and $Script:CurShelf.Id -eq 'soon') { $mode = 'Month' }
    if ($Script:CurShelf.Kind -eq 'smart' -and $Script:CurShelf.Id -eq 'awards') { $mode = 'Award' }
    $groups = New-Object Collections.Specialized.OrderedDictionary
    foreach ($v in $Script:Filtered) {
        $g = Get-GroupKey $v $mode
        if (-not $groups.Contains($g)) { $groups[$g] = New-Object Collections.Generic.List[object] }
        $groups[$g].Add($v)
    }
    $keys = @($groups.Keys)
    if ($mode -eq 'Shelf' -or $mode -eq 'Letter' -or $mode -eq 'Genre') { $keys = @($keys | Sort-Object) }
    if ($mode -eq 'Decade') { $keys = @($keys | Sort-Object -Descending) }
    if ($mode -eq 'Award') { $keys = @($keys | Sort-Object) }   # "01|Oscar winners", "02|BAFTA winners"… — the number is only for order
    $rows = New-Object 'Collections.ObjectModel.ObservableCollection[object]'
    $Script:RowIndex = @{}
    foreach ($g in $keys) {
        $items = $groups[$g]
        $first = $true
        for ($i = 0; $i -lt $items.Count; $i += $per) {
            $n = [math]::Min($per, $items.Count - $i)
            $chunk = $items.GetRange($i, $n).ToArray()
            $hdr = ''; $hvis = 'Collapsed'; $hsub = ''
            if ($first -and $mode -ne 'None') { $hdr = $(if ($mode -eq 'Award') { ($g -split '\|', 2)[-1] } else { $g }); $hvis = 'Visible'; $hsub = '{0} film{1}' -f $items.Count, $(if ($items.Count -eq 1) { '' } else { 's' }) }
            $first = $false
            foreach ($c in $chunk) { $Script:RowIndex[$c.Key] = $rows.Count }
            $rows.Add([pscustomobject]@{ Header = $hdr; HeaderSub = $hsub; HeaderVis = $hvis; Items = $chunk; Cols = $per })
        }
    }
    $Script:Rows = $rows
    $UI.lbWall.ItemsSource = $rows
}

# =====================================================================================
#  The film panel
# =====================================================================================
function Set-DetailOpen([bool]$open) {
    if ($open) { $UI.colDetail.Width = New-Object Windows.GridLength 420 } else { $UI.colDetail.Width = New-Object Windows.GridLength 0 }
    $Settings.DetailOpen = $open
}

function New-Chip([string]$text, [string]$tag, [string]$bg = '#EFE6D6', [string]$fg = '#1F1B16') {
    $bc = New-Object Windows.Media.BrushConverter
    $b = New-Object Windows.Controls.Border
    $b.Background = $bc.ConvertFromString($bg); $b.CornerRadius = New-Object Windows.CornerRadius 11
    $b.Padding = New-Object Windows.Thickness 10, 3, 10, 3; $b.Margin = New-Object Windows.Thickness 0, 0, 6, 6
    $b.Cursor = [Windows.Input.Cursors]::Hand; $b.Tag = $tag
    $t = New-Object Windows.Controls.TextBlock
    $t.Text = $text; $t.FontSize = 12; $t.Foreground = $bc.ConvertFromString($fg)
    $b.Child = $t
    return $b
}

function Show-Detail([string]$key) {
    $v = $Script:ViewByKey[$key]; $rec = $Script:Lib[$key]
    if (-not $v -or -not $rec) { $UI.svDetail.Visibility = 'Collapsed'; $Script:CurKey = $null; Set-DetailOpen $false; return }
    $Script:CurKey = $key
    $Script:Loading = $true
    try {
        if ($UI.colDetail.Width.Value -lt 10) { Set-DetailOpen $true }
        $UI.pnlNoSel.Visibility = 'Collapsed'; $UI.svDetail.Visibility = 'Visible'
        $m = $Script:Meta[$key]; $u = $Script:User[$key]
        $bc = New-Object Windows.Media.BrushConverter
        # images
        $back = $null
        if ($m -and $m['Backdrop']) { $back = Load-Bitmap ([string]$m['Backdrop']) 900 }
        if (-not $back -and $rec['LocalFanart']) { $back = Load-Bitmap ([string]$rec['LocalFanart']) 900 }
        $UI.imgBackdrop.Source = $back
        $UI.bdBackFallback.Background = $bc.ConvertFromString($v.ShelfBrush)
        $UI.ibDetailPoster.ImageSource = Load-Bitmap $v.Poster 260
        $UI.bdDetailPoster.Background = $bc.ConvertFromString($v.ShelfBrush)
        $UI.bdDetailShelf.Background = $bc.ConvertFromString($v.ShelfBrush)
        $UI.txtDetailShelf.Text = $v.Shelf
        $yearBits = @(); if ($v.Year) { $yearBits += [string]$v.Year }; if ($v.Cert) { $yearBits += $v.Cert }; if ($v.RuntimeText) { $yearBits += $v.RuntimeText }
        $UI.txtDetailYear.Text = ($yearBits -join '   ·   ')
        $UI.txtDetailTitle.Text = $v.Title
        $UI.txtDetailTagline.Text = $v.Tagline
        $UI.txtDetailTagline.Visibility = $(if ($v.Tagline) { 'Visible' } else { 'Collapsed' })
        $aw = Format-FilmAwards $v
        $UI.txtDetailAwards.Text = $aw
        $UI.bdDetailAwards.Visibility = $(if ($aw) { 'Visible' } else { 'Collapsed' })
        $metaBits = @()
        if ($m -and $m['OriginalTitle'] -and $m['OriginalTitle'] -ne $v.Title) { $metaBits += ('Original title: ' + $m['OriginalTitle']) }
        if ($m -and $m['Country']) { $metaBits += [string]$m['Country'] }
        if ($m -and $m['Studio']) { $metaBits += [string]$m['Studio'] }
        $UI.txtDetailMeta.Text = ($metaBits -join '  ·  ')
        $UI.txtDetailMeta.Visibility = $(if ($metaBits.Count) { 'Visible' } else { 'Collapsed' })
        $UI.wpGenres.Children.Clear()
        foreach ($g in $v.Genres) { $c = New-Chip $g ("genre|" + $g); $c.Add_MouseLeftButtonUp($Script:ChipClick); [void]$UI.wpGenres.Children.Add($c) }
        if ($v.Res) { [void]$UI.wpGenres.Children.Add((New-Chip $v.Res '' '#1F1B16' '#F6EBD9')) }
        if ($rec['Disc']) { [void]$UI.wpGenres.Children.Add((New-Chip ([string]$rec['Disc']) '' '#1F1B16' '#F6EBD9')) }
        if ($rec['Edition']) { [void]$UI.wpGenres.Children.Add((New-Chip ([string]$rec['Edition']) '' '#173F3E' '#F6EBD9')) }
        $UI.txtDetailRating.Text = $(if ($v.Rating -gt 0) { '{0:0.0}' -f $v.Rating } else { '–' })
        Set-Stars $v.MyRating
        $UI.tgWatched.IsChecked = $v.Watched; $UI.tgFav.IsChecked = $v.Fav; $UI.tgWatchlist.IsChecked = $v.Watchlist
        $UI.txtDetailPlot.Text = $(if ($v.Overview) { $v.Overview } else { 'No story yet — press “Refresh info” to fetch it from TMDb.' })
        # crew & cast
        $UI.wpDirectors.Children.Clear()
        foreach ($d in $v.Directors) { $c = New-Chip ([string]$d['Name']) ('person|' + [string]$d['Name']) '#E2D9C9'; $c.Add_MouseLeftButtonUp($Script:ChipClick); [void]$UI.wpDirectors.Children.Add($c) }
        $UI.capCrew.Visibility = $(if (@($v.Directors).Count) { 'Visible' } else { 'Collapsed' })
        $wr = @(); if ($m) { $wr = @($m['Writers'] | Where-Object { $_ }) }
        $UI.txtWriters.Text = $(if ($wr.Count) { 'Written by ' + ($wr -join ', ') } else { '' })
        $UI.txtWriters.Visibility = $(if ($wr.Count) { 'Visible' } else { 'Collapsed' })
        $cast = @($v.Cast | Select-Object -First 12 | ForEach-Object {
            $ph = $_['Photo']; if (-not $ph) { $ph = $null }
            [pscustomobject]@{ IsPerson = $true; Name = [string]$_['Name']; Role = [string]$_['Role']; Photo = $ph; Initials = (Get-Initials ([string]$_['Name'])); Tip = ([string]$_['Name'] + $(if ($_['Role']) { ' as ' + $_['Role'] } else { '' })) } })
        $UI.icCast.ItemsSource = $cast
        $UI.capCast.Visibility = $(if ($cast.Count) { 'Visible' } else { 'Collapsed' })
        # collection banner
        if ($v.CollectionId -gt 0 -or $v.CollectionName) {
            $owned = @($Script:AllViews | Where-Object { ($v.CollectionId -gt 0 -and $_.CollectionId -eq $v.CollectionId) -or ($v.CollectionId -eq 0 -and $_.CollectionName -eq $v.CollectionName) }).Count
            $c = $Script:Colls[[string]$v.CollectionId]
            $UI.txtCollTitle.Text = 'Part of ' + $v.CollectionName + '   →'
            if ($c) {
                $rel = @($c['Parts'] | Where-Object { $d = PH-Date $_['Release']; $d -gt [datetime]::MinValue -and $d -le (Get-Date) }).Count
                $UI.txtCollOwned.Text = "You have $owned of $rel released films in this collection"
            } else { $UI.txtCollOwned.Text = "You have $owned film(s) from it — open Collections to see what's missing" }
            $UI.bdCollection.Visibility = 'Visible'
        } else { $UI.bdCollection.Visibility = 'Collapsed' }
        # personal
        $UI.txtNotes.Text = $(if ($u) { [string]$u['Notes'] } else { '' })
        $hist = @()
        if ($u) {
            $wo = PH-Date $u['WatchedOn']; if ($u['Watched'] -and $wo -gt [datetime]::MinValue) { $hist += ('Watched ' + $wo.ToString('d MMM yyyy')) }
            if ([int]$u['PlayCount'] -gt 0) { $hist += ('played {0} time{1}' -f $u['PlayCount'], $(if ([int]$u['PlayCount'] -eq 1) { '' } else { 's' })) }
            $lp = PH-Date $u['LastPlayed']; if ($lp -gt [datetime]::MinValue) { $hist += ('last played ' + $lp.ToString('d MMM yyyy, HH:mm')) }
        }
        $UI.txtHistory.Text = ($hist -join '  ·  ')
        # file
        $UI.txtFile.Text = $(if ($rec['IsFolder']) { [string]$rec['File'] } else { [string]$rec['Path'] })
        $fi = @()
        if ($v.AddedText) { $fi += ('Added ' + $v.AddedText) }
        if ($v.SizeText) { $fi += $v.SizeText }
        if ($rec['Ext']) { $fi += [string]$rec['Ext'] }
        if ([int]$rec['Parts'] -gt 1) { $fi += ('{0} parts' -f $rec['Parts']) }
        if ($m) { $fi += ('info from ' + $(if ($m['Source'] -eq 'tmdb') { 'TMDb' } else { '.nfo file' })) }
        if ($Script:MatchFail.ContainsKey($key)) { $fi += ('TMDb: ' + $Script:MatchFail[$key]) }
        $UI.txtFileInfo.Text = ($fi -join '  ·  ')
        $UI.btnTrailer.Content = $(if ($m -and $m['Trailer']) { '▶ Trailer' } else { 'Find trailer' })
        $UI.svDetail.ScrollToTop()
    } finally { $Script:Loading = $false }
}

# ---- Big poster: sharpest copy available (NAS original → TMDb high-res → cached thumbnail)
function Show-BigPoster([string]$key) {
    $v = $Script:ViewByKey[$key]; $rec = $Script:Lib[$key]; if (-not $v -or -not $rec) { return }
    $m = $Script:Meta[$key]
    $UI.txtBigPosterTitle.Text = $v.Title + $(if ($v.Year) { "  ($($v.Year))" } else { '' })
    $UI.imgBigPoster.Source = Load-Bitmap $v.Poster      # instant, low-res
    $hi = $null
    # enlarge the same artwork that's on screen: the TMDb poster if that's what the panel shows, otherwise the folder's own poster
    $showingTmdb = ($m -and $m['PosterThumb'] -and [string]$v.Poster -eq [string]$m['PosterThumb'])
    if (-not $showingTmdb -and $rec['LocalPoster'] -and (Test-Path -LiteralPath ([string]$rec['LocalPoster']))) { $hi = Load-Bitmap ([string]$rec['LocalPoster']) 1400 }
    elseif ($m -and $m['PosterPath']) {
        try {
            $bi = New-Object Windows.Media.Imaging.BitmapImage
            $bi.BeginInit(); $bi.UriSource = New-Object Uri ('https://image.tmdb.org/t/p/original' + $m['PosterPath']); $bi.EndInit()
            $Script:BigPosterKey = $key; $Script:BigPosterUri = [string]$bi.UriSource
            if ($bi.IsDownloading) {
                # only swap in if this is still the poster being shown
                $bi.Add_DownloadCompleted({ if ($UI.gridBigPoster.Visibility -eq 'Visible' -and [string]$this.UriSource -eq $Script:BigPosterUri) { $UI.imgBigPoster.Source = $this } })
            } else { $hi = $bi }
        } catch {}
    }
    if ($hi) { $UI.imgBigPoster.Source = $hi }
    if (-not $UI.imgBigPoster.Source) { return }
    $UI.gridBigPoster.Visibility = 'Visible'
}
function Hide-BigPoster { $UI.gridBigPoster.Visibility = 'Collapsed'; $Script:BigPosterKey = $null; $UI.imgBigPoster.Source = $null }

function Set-Stars([int]$n) {
    $bc = New-Object Windows.Media.BrushConverter
    for ($i = 1; $i -le 5; $i++) {
        $s = $UI["star$i"]
        if ($i -le $n) { $s.Text = '★'; $s.Foreground = $bc.ConvertFromString('#C8432B') } else { $s.Text = '☆'; $s.Foreground = $bc.ConvertFromString('#9C9385') }
    }
}

# =====================================================================================
#  Film actions
# =====================================================================================
function Set-UserFlag([string]$key, [string]$flag, $value) {
    $u = Get-User $key -Create
    $u[$flag] = $value
    if ($flag -eq 'Watched') { if ($value) { $u['WatchedOn'] = (Get-Date).ToString('s') } else { $u['WatchedOn'] = '' } }
    if ($flag -eq 'Watchlist') { if ($value) { $u['ListAdded'] = (Get-Date).ToString('s') } else { $u['ListAdded'] = '' } }
    Save-User
    Update-Film $key
    Refresh-Rail
}

function Invoke-Play([string]$key) {
    $rec = $Script:Lib[$key]; if (-not $rec) { return }
    $file = [string]$rec['File']
    if (-not (Test-Path -LiteralPath $file)) { Tell "I can't reach this film right now:`n$file`n`nIs the NAS on and the share connected?" 'Warning'; return }
    $player = [string]$Settings.PlayerPath
    $parts = @($rec['PartFiles'] | Where-Object { $_ })
    try {
        if ($player -and (Test-Path -LiteralPath $player)) {
            $argList = @(); if ($parts.Count -gt 1) { $argList = @($parts | ForEach-Object { '"' + $_ + '"' }) } else { $argList = @('"' + $file + '"') }
            Start-Process -FilePath $player -ArgumentList $argList
        } elseif ($parts.Count -gt 1) {
            $m3u = Join-Path $CacheDir 'now-playing.m3u'
            [IO.File]::WriteAllLines($m3u, [string[]]$parts, (New-Object Text.UTF8Encoding $false))
            Start-Process -FilePath $m3u
        } else { Start-Process -FilePath $file }
    } catch { Tell ("Couldn't start playback:`n" + $_.Exception.Message) 'Warning'; return }
    $u = Get-User $key -Create
    $u['LastPlayed'] = (Get-Date).ToString('s'); $u['PlayCount'] = [int]$u['PlayCount'] + 1
    if ($Settings.WatchedOnPlay -and -not $u['Watched']) { $u['Watched'] = $true; $u['WatchedOn'] = (Get-Date).ToString('s') }
    Save-User; Update-Film $key
    Status ('Playing ' + $Script:ViewByKey[$key].Title)
}

function Open-FilmFolder([string]$key) {
    $rec = $Script:Lib[$key]; if (-not $rec) { return }
    try {
        if ($rec['IsFolder']) { Start-Process explorer.exe -ArgumentList ('"' + $rec['Path'] + '"') }
        else { Start-Process explorer.exe -ArgumentList ('/select,"' + $rec['Path'] + '"') }
    } catch { Tell "Couldn't open the folder — is the NAS reachable?" 'Warning' }
}

function Open-Trailer([string]$key) {
    $v = $Script:ViewByKey[$key]; $m = $Script:Meta[$key]
    if ($m -and $m['Trailer']) { Open-Url ('https://www.youtube.com/watch?v=' + $m['Trailer']) }
    else { Open-Url ('https://www.youtube.com/results?search_query=' + [uri]::EscapeDataString("$($v.Title) $($v.Year) trailer")) }
}
function Open-Tmdb([string]$key) {
    $v = $Script:ViewByKey[$key]
    if ($v.TmdbId -gt 0) { Open-Url "https://www.themoviedb.org/movie/$($v.TmdbId)" } else { Open-Url ('https://www.themoviedb.org/search/movie?query=' + [uri]::EscapeDataString($v.Title)) }
}
function Open-Imdb([string]$key) {
    $v = $Script:ViewByKey[$key]
    if ($v.ImdbId) { Open-Url "https://www.imdb.com/title/$($v.ImdbId)/" } else { Open-Url ('https://www.imdb.com/find/?q=' + [uri]::EscapeDataString("$($v.Title) $($v.Year)")) }
}

function Replace-PathPrefix($value, [string]$old, [string]$new) {
    if ($null -eq $value) { return $null }
    $s = [string]$value
    if ($s.StartsWith($old, [StringComparison]::OrdinalIgnoreCase)) { return $new + $s.Substring($old.Length) }
    return $s
}

function Move-FilmToShelf([string]$key, $shelf) {
    $rec = $Script:Lib[$key]; if (-not $rec) { return }
    $target = [string]$shelf['Path']
    if (-not $target) { Tell "I don't know where that shelf lives on the NAS yet — rescan first."; return }
    if ([string]$rec['Root'] -and [string]$shelf['Root'] -and [string]$rec['Root'] -ne [string]$shelf['Root']) {
        Tell ("That shelf is in a different NAS folder:`n" + $shelf['Root'] + "`n`nMoving between shares would copy the whole film through this PC, so I'll leave that to Synology File Station.") 'Information'
        return
    }
    $v = $Script:ViewByKey[$key]
    if (-not (Ask ("Move ‘$($v.Title)’ from $($rec['Shelf']) to $($shelf['Name'])?`n`nFrom: $($rec['Path'])`nTo:   $target"))) { return }
    try {
        if ($rec['IsFolder']) {
            $oldDir = [string]$rec['Path']
            $dest = Join-Path $target ([IO.Path]::GetFileName($oldDir.TrimEnd('\')))
            if (Test-Path -LiteralPath $dest) { Tell "There's already a folder called that on the $($shelf['Name']) shelf." 'Warning'; return }
            [IO.Directory]::Move($oldDir, $dest)
            $oldPrefix = $oldDir; $newPrefix = $dest
        } else {
            $oldFile = [string]$rec['Path']; $dir = [IO.Path]::GetDirectoryName($oldFile)
            $base = [IO.Path]::GetFileNameWithoutExtension($oldFile)
            $parts = @($rec['PartFiles'] | Where-Object { $_ })
            $sidecars = @(Get-ChildItem -LiteralPath $dir -File -ErrorAction SilentlyContinue | Where-Object { $_.BaseName -eq $base -or $_.Name.StartsWith($base + '.') -or $_.Name.StartsWith($base + '-') } | ForEach-Object { $_.FullName })
            $all = @(($parts + $sidecars + $oldFile) | Where-Object { $_ } | Select-Object -Unique)
            foreach ($f in $all) { if (Test-Path -LiteralPath (Join-Path $target ([IO.Path]::GetFileName($f)))) { Tell "A file called $([IO.Path]::GetFileName($f)) is already on that shelf." 'Warning'; return } }
            foreach ($f in $all) { [IO.File]::Move($f, (Join-Path $target ([IO.Path]::GetFileName($f)))) }
            $oldPrefix = $dir; $newPrefix = $target
        }
    } catch { Tell ("The move didn't work:`n" + $_.Exception.Message) 'Warning'; return }
    $nr = @{}; foreach ($k in @($rec.Keys)) { $nr[$k] = $rec[$k] }
    foreach ($f in @('Path', 'File', 'LocalPoster', 'LocalFanart', 'Nfo')) { $nr[$f] = Replace-PathPrefix $rec[$f] $oldPrefix $newPrefix }
    $nr['PartFiles'] = @($rec['PartFiles'] | ForEach-Object { Replace-PathPrefix $_ $oldPrefix $newPrefix })
    $nr['Shelf'] = [string]$shelf['Name']
    $nr['Key'] = ([string]$nr['Path']).ToLowerInvariant()
    $Script:Lib.Remove($key)
    $Script:Lib[$nr['Key']] = $nr
    Move-UserKey $key $nr['Key']
    Save-Lib; Save-Meta; Save-User
    Refresh-Everything
    Show-Detail $nr['Key']
    Status "Moved ‘$($v.Title)’ to $($shelf['Name'])"
}

function Get-MoveTargets([string]$key) {
    $rec = $Script:Lib[$key]
    return @(Get-ShelfList | Where-Object { $_['Path'] -and $_['Name'] -ne $rec['Shelf'] -and ((-not $rec['Root']) -or ([string]$_['Root'] -eq [string]$rec['Root'])) })
}

function Show-MoveMenu([string]$key, $placement) {
    $cm = New-Object Windows.Controls.ContextMenu
    foreach ($s in (Get-MoveTargets $key)) {
        $mi = New-Object Windows.Controls.MenuItem
        $depth = @(([string]$s['Name']) -split ' › ').Count - 1
        $mi.Header = ('    ' * $depth) + (([string]$s['Name']) -split ' › ')[-1]
        $mi.Tag = 'move|' + [string]$s['Name']
        $mi.Add_Click($Script:MenuClick)
        [void]$cm.Items.Add($mi)
    }
    if ($cm.Items.Count -eq 0) { $mi = New-Object Windows.Controls.MenuItem; $mi.Header = 'No other shelves in this NAS folder'; $mi.IsEnabled = $false; [void]$cm.Items.Add($mi) }
    $Script:CtxKey = $key
    $cm.PlacementTarget = $placement; $cm.IsOpen = $true
}

function Build-FilmMenu([string]$key) {
    $v = $Script:ViewByKey[$key]
    $cm = New-Object Windows.Controls.ContextMenu
    $add = {
        param($header, $tag)
        if ($header -eq '-') { [void]$cm.Items.Add((New-Object Windows.Controls.Separator)); return }
        $mi = New-Object Windows.Controls.MenuItem; $mi.Header = $header; $mi.Tag = $tag; $mi.Add_Click($Script:MenuClick); [void]$cm.Items.Add($mi); $mi
    }
    [void](& $add '▶  Play' 'play')
    [void](& $add 'Show details' 'details')
    [void](& $add '-' '')
    [void](& $add $(if ($v.Watched) { 'Mark as not watched' } else { '✓  Mark as watched' }) 'watched')
    [void](& $add $(if ($v.Fav) { 'Remove from favourites' } else { '♥  Add to favourites' }) 'fav')
    [void](& $add $(if ($v.Watchlist) { 'Remove from watchlist' } else { '⌚  Add to watchlist' }) 'watchlist')
    [void](& $add '-' '')
    [void](& $add 'Open folder' 'folder')
    [void](& $add 'Copy path' 'copy')
    [void](& $add 'Trailer' 'trailer')
    [void](& $add '-' '')
    [void](& $add 'Refresh info from TMDb' 'fetch')
    [void](& $add 'Fix match…' 'fix')
    $mv = New-Object Windows.Controls.MenuItem; $mv.Header = 'Move to shelf'
    foreach ($s in (Get-MoveTargets $key)) {
        $mi = New-Object Windows.Controls.MenuItem; $mi.Header = [string]$s['Name']; $mi.Tag = 'move|' + [string]$s['Name']; $mi.Add_Click($Script:MenuClick); [void]$mv.Items.Add($mi)
    }
    if ($mv.Items.Count -eq 0) { $mv.IsEnabled = $false }
    [void]$cm.Items.Add($mv)
    return $cm
}

function Invoke-FilmAction([string]$action, [string]$key) {
    if (-not $key -or -not $Script:Lib.ContainsKey($key)) { return }
    $v = $Script:ViewByKey[$key]
    switch -Regex ($action) {
        '^play$'      { Invoke-Play $key }
        '^details$'   { Show-Detail $key }
        '^watched$'   { Set-UserFlag $key 'Watched' (-not $v.Watched) }
        '^fav$'       { Set-UserFlag $key 'Fav' (-not $v.Fav) }
        '^watchlist$' { Set-UserFlag $key 'Watchlist' (-not $v.Watchlist) }
        '^folder$'    { Open-FilmFolder $key }
        '^copy$'      { [Windows.Clipboard]::SetText([string]$Script:Lib[$key]['Path']); Status 'Path copied.' }
        '^trailer$'   { Open-Trailer $key }
        '^fetch$'     { Start-Fetch -Keys @($key) }
        '^fix$'       { Show-FixMatch $key }
        '^move\|'     { $name = $action.Substring(5); $s = @(Get-ShelfList | Where-Object { $_['Name'] -eq $name }); if ($s.Count) { Move-FilmToShelf $key $s[0] } }
    }
}

$Script:MenuClick = { Invoke-FilmAction ([string]$this.Tag) $Script:CtxKey }
$Script:ChipClick = {
    $t = [string]$this.Tag
    if ($t -like 'genre|*') {
        $g = $t.Substring(6)
        Select-Tab 'Library'
        $Script:CurShelf = @{ Kind = 'smart'; Id = 'all' }
        Refresh-Rail
        $UI.cbGenre.SelectedItem = $g
    } elseif ($t -like 'person|*') { Show-Person $t.Substring(7) 'Directors' }
}

# =====================================================================================
#  Fix match dialog
# =====================================================================================
function Show-FixMatch([string]$key) {
    if (-not $Settings.TmdbKey) { Tell 'Add your TMDb API key in Settings first.'; return }
    $rec = $Script:Lib[$key]; $v = $Script:ViewByKey[$key]
    $fixText = @'
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Fix match" Width="760" Height="680" WindowStartupLocation="CenterOwner" Background="#F3EEE4" FontFamily="Segoe UI" FontSize="13">
  <Window.Resources><!--COMBOSTYLES--></Window.Resources>
  <DockPanel>
  <!--HEADER-->
  <Grid Margin="20,12,20,18">
    <Grid.RowDefinitions><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/><RowDefinition Height="*"/><RowDefinition Height="Auto"/></Grid.RowDefinitions>
    <TextBlock Text="Search TMDb and pick the right film." Foreground="#7B7266"/>
    <TextBlock x:Name="dPath" Grid.Row="1" Foreground="#7B7266" TextWrapping="Wrap" Margin="0,4,0,10" FontFamily="Consolas" FontSize="11.5"/>
    <Grid Grid.Row="2" Margin="0,0,0,10">
      <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="80"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions>
      <TextBox x:Name="dQuery" Padding="7,5"/>
      <TextBox x:Name="dYear" Grid.Column="1" Padding="7,5" Margin="8,0,0,0" ToolTip="Year (optional)"/>
      <Button x:Name="dGo" Grid.Column="2" Content="Search TMDb" Style="{StaticResource PHDlgGhost}" Margin="8,0,0,0" IsDefault="True"/>
    </Grid>
    <ListBox x:Name="dList" Grid.Row="3" Background="#FFFCF6" BorderBrush="#E2D9C9" ScrollViewer.HorizontalScrollBarVisibility="Disabled">
      <ListBox.ItemTemplate>
        <DataTemplate>
          <Grid Margin="2,4">
            <Grid.ColumnDefinitions><ColumnDefinition Width="58"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
            <Border Width="46" Height="69" Background="#E2D9C9" CornerRadius="3" HorizontalAlignment="Left">
              <Border CornerRadius="3"><Border.Background><ImageBrush ImageSource="{Binding Poster}" Stretch="UniformToFill"/></Border.Background></Border>
            </Border>
            <StackPanel Grid.Column="1">
              <TextBlock Text="{Binding Label}" FontWeight="SemiBold" FontSize="14"/>
              <TextBlock Text="{Binding Overview}" Foreground="#5B5348" TextWrapping="Wrap" MaxHeight="38" TextTrimming="WordEllipsis"/>
            </StackPanel>
          </Grid>
        </DataTemplate>
      </ListBox.ItemTemplate>
    </ListBox>
    <Grid Grid.Row="4" Margin="0,12,0,0">
      <StackPanel Orientation="Horizontal">
        <TextBlock Text="…or type a TMDb ID / IMDb tt-number:" VerticalAlignment="Center" Margin="0,0,8,0" Foreground="#5B5348"/>
        <TextBox x:Name="dId" Width="130" Padding="6,4"/>
      </StackPanel>
      <StackPanel Orientation="Horizontal" HorizontalAlignment="Right">
        <Button x:Name="dCancel" Content="Cancel" Style="{StaticResource PHDlgGhost}" Margin="0,0,8,0" IsCancel="True"/>
        <Button x:Name="dOk" Content="Use this film" Style="{StaticResource PHDlgPrimary}"/>
      </StackPanel>
    </Grid>
  </Grid>
  </DockPanel>
</Window>
'@
    [xml]$dx = $fixText.Replace('<!--COMBOSTYLES-->', $ComboStyles + $DialogStyles).Replace('<!--HEADER-->', (New-DialogHeader 'Which film is this?'))
    $dw = [Windows.Markup.XamlReader]::Load((New-Object System.Xml.XmlNodeReader $dx))
    $dw.Owner = $Window
    $Script:Dlg = @{ Win = $dw; Result = $null; Query = $dw.FindName('dQuery'); Year = $dw.FindName('dYear'); List = $dw.FindName('dList'); Id = $dw.FindName('dId') }
    $dw.FindName('dPath').Text = [string]$rec['Path']
    $Script:Dlg.Query.Text = [string]$rec['Title']
    if ([int]$rec['Year'] -gt 0) { $Script:Dlg.Year.Text = [string]$rec['Year'] }
    $search = {
        $d = $Script:Dlg
        $d.Win.Cursor = [Windows.Input.Cursors]::Wait
        try {
            $y = 0; [void][int]::TryParse($d.Year.Text, [ref]$y)
            $res = PH-TmdbSearch $Settings.TmdbKey $d.Query.Text.Trim() $y $Settings.Language
            $d.List.ItemsSource = @($res | Select-Object -First 20 | ForEach-Object {
                $yy = ''; if ($_.release_date -and ([string]$_.release_date).Length -ge 4) { $yy = ([string]$_.release_date).Substring(0, 4) }
                [pscustomobject]@{ Id = [int]$_.id; Label = ([string]$_.title + $(if ($yy) { " ($yy)" } else { '' })); Overview = [string]$_.overview; Poster = (PH-ImgUrl $_.poster_path 'w92') } })
            if (@($d.List.Items).Count) { $d.List.SelectedIndex = 0 }
        } catch { [void][Windows.MessageBox]::Show($d.Win, ('TMDb search failed: ' + $_.Exception.Message), $AppName) }
        finally { $d.Win.Cursor = $null }
    }
    $Script:Dlg.Search = $search
    $dw.FindName('dGo').Add_Click({ & $Script:Dlg.Search })
    $dw.FindName('dOk').Add_Click({
        $d = $Script:Dlg; $idText = $d.Id.Text.Trim()
        if ($idText -match '^\d+$') { $d.Result = @{ Tmdb = [int]$idText } }
        elseif ($idText -match '^(tt\d+)$') {
            try { $f = PH-Tmdb $Settings.TmdbKey "/find/$idText" @{ external_source = 'imdb_id' }; if ($f -and @($f.movie_results).Count) { $d.Result = @{ Tmdb = [int]@($f.movie_results)[0].id } } } catch {}
            if (-not $d.Result) { [void][Windows.MessageBox]::Show($d.Win, "TMDb doesn't know $idText.", $AppName); return }
        }
        elseif ($d.List.SelectedItem) { $d.Result = @{ Tmdb = [int]$d.List.SelectedItem.Id } }
        else { return }
        $d.Win.DialogResult = $true
    })
    $dw.FindName('dList').Add_MouseDoubleClick({ $d = $Script:Dlg; if ($d.List.SelectedItem) { $d.Result = @{ Tmdb = [int]$d.List.SelectedItem.Id }; $d.Win.DialogResult = $true } })
    $dw.Add_ContentRendered({ & $Script:Dlg.Search })
    [void]$dw.ShowDialog()
    $r = $Script:Dlg.Result
    $Script:Dlg = $null
    if ($r -and $r.Tmdb) {
        if ($Script:MatchFail.ContainsKey($key)) { $Script:MatchFail.Remove($key) }
        Start-Fetch -Keys @($key) -ForceIds @{ $key = $r.Tmdb }
    }
}

# =====================================================================================
#  Collections
# =====================================================================================
function Get-CollectionRows {
    $bc = '#2A7F7A'
    $groups = @{}
    foreach ($v in (Get-VisibleViews)) {
        if ($v.CollectionId -le 0) { continue }
        $id = [string]$v.CollectionId
        if (-not $groups.ContainsKey($id)) { $groups[$id] = @{ Id = $v.CollectionId; Name = $v.CollectionName; Films = (New-Object Collections.ArrayList) } }
        [void]$groups[$id].Films.Add($v)
    }
    $today = Get-Date
    $rows = foreach ($g in $groups.Values) {
        $c = $Script:Colls[[string]$g.Id]
        $owned = $g.Films.Count; $total = 0; $state = 'unknown'
        $name = [string]$g.Name; if ($c -and $c['Name']) { $name = [string]$c['Name'] }
        if ($c) {
            $ownedIds = @($g.Films | ForEach-Object { $_.TmdbId })
            $released = @($c['Parts'] | Where-Object { $d = PH-Date $_['Release']; $d -gt [datetime]::MinValue -and $d -le $today })
            $total = $released.Count
            $have = @($released | Where-Object { $ownedIds -contains [int]$_['Id'] }).Count
            if ($have -ge $total) { $state = 'complete' } else { $state = 'incomplete' }
            $owned = $have
        }
        $w = 0; if ($total -gt 0) { $w = [math]::Round(150 * [math]::Min(1.0, $owned / $total)) } else { $w = 0 }
        $txt = $(if ($total -gt 0) { "$owned of $total" } else { "$($g.Films.Count) owned · not checked" })
        [pscustomobject]@{ Id = [int]$g.Id; Name = $name; Owned = $owned; Total = $total; State = $state; W = $w; OwnedText = $txt
                           Brush = $(if ($state -eq 'complete') { '#2A7F7A' } else { '#C8432B' }); Missing = [math]::Max(0, $total - $owned) }
    }
    # the award "collections" (Oscar Best Picture, BAFTA Best Film) go at the top
    $ownedIds = New-Object 'Collections.Generic.HashSet[int]'; foreach ($v in (Get-VisibleViews)) { if ($v.TmdbId -gt 0) { [void]$ownedIds.Add([int]$v.TmdbId) } }
    $award = foreach ($d in $AwardLists) {
        $c = Get-AwardCollection $d.Id; if (-not $c) { continue }
        $released = @($c.Parts | Where-Object { $r = PH-Date $_['Release']; $r -gt [datetime]::MinValue -and $r -le $today })
        $total = $released.Count; $have = @($released | Where-Object { $ownedIds.Contains([int]$_['Id']) }).Count
        $state = $(if ($have -ge $total) { 'complete' } else { 'incomplete' })
        $w = 0; if ($total -gt 0) { $w = [math]::Round(150 * [math]::Min(1.0, $have / $total)) }
        [pscustomobject]@{ Id = $d.Id; Name = $d.Name; Owned = $have; Total = $total; State = $state; W = $w; OwnedText = "$have of $total"
                           Brush = '#C9A227'; Missing = [math]::Max(0, $total - $have) }
    }
    return @(@($award) + @($rows | Sort-Object Name))
}

function Refresh-Collections {
    $Script:Dirty.Collections = $false
    $all = Get-CollectionRows
    $f = [string]$UI.cbCollFilter.SelectedItem
    $rows = switch ($f) {
        'Incomplete'        { @($all | Where-Object { $_.State -eq 'incomplete' } | Sort-Object Missing -Descending) }
        'Complete'          { @($all | Where-Object { $_.State -eq 'complete' }) }
        'Not checked yet'   { @($all | Where-Object { $_.State -eq 'unknown' }) }
        default             { $all }
    }
    $sel = $UI.lbColls.SelectedItem
    $UI.lbColls.ItemsSource = @($rows)
    if ($sel) { $hit = @($UI.lbColls.Items | Where-Object { $_.Id -eq $sel.Id }); if ($hit.Count) { $UI.lbColls.SelectedItem = $hit[0] } }
    $missing = 0; $inc = 0; $comp = 0; $unk = 0
    foreach ($r in $all) { $missing += $r.Missing; if ($r.State -eq 'incomplete') { $inc++ } elseif ($r.State -eq 'complete') { $comp++ } else { $unk++ } }
    $s = "$($all.Count) collections on your shelves"
    if ($comp + $inc -gt 0) { $s += " · $comp complete · $inc with gaps ($missing released films missing)" }
    if ($unk) { $s += " · $unk being checked…" }
    $UI.txtCollSummary.Text = $s
    if (-not $UI.lbColls.SelectedItem) { Show-Collection $null }
}

function Show-Collection($row) {
    if (-not $row) {
        $UI.txtCollName.Text = 'Pick a collection'; $UI.txtCollInfo.Text = 'Franchises and series your films belong to, with the gaps highlighted.'
        $UI.txtCollOverview.Text = ''; $UI.icParts.ItemsSource = $null; return
    }
    if ($row.Id -lt 0) {
        $c = Get-AwardCollection $row.Id
        $ids = New-Object 'Collections.Generic.HashSet[int]'; if ($c) { foreach ($p in $c.Parts) { [void]$ids.Add([int]$p['Id']) } }
        $owned = @($Script:AllViews | Where-Object { $_.TmdbId -gt 0 -and $ids.Contains([int]$_.TmdbId) })
    } else {
        $c = $Script:Colls[[string]$row.Id]
        $owned = @($Script:AllViews | Where-Object { $_.CollectionId -eq $row.Id })
    }
    $UI.txtCollName.Text = $row.Name
    $today = Get-Date
    $items = New-Object Collections.ArrayList
    if ($c) {
        $UI.txtCollOverview.Text = [string]$c['Overview']
        foreach ($p in @($c['Parts'])) {
            $partId = [int]$p['Id']
            $mine = @($owned | Where-Object { $_.TmdbId -eq $partId } | Select-Object -First 1)
            $rel = PH-Date $p['Release']
            $sub = $(if ($p['Year']) { [string]$p['Year'] } else { 'Date unknown' })
            if ($p['AwardYear']) { $sub = "won $($p['AwardYear'])" }
            if ($mine.Count) {
                $f = $mine[0]
                [void]$items.Add([pscustomobject]@{ IsFilm = $true; Key = $f.Key; Title = $f.Title; Sub = "$sub  ·  $($f.Shelf)"; Poster = $(if ($f.Poster) { $f.Poster } else { $p['Poster'] }); Opac = 1.0
                    Status = 'ON YOUR SHELF'; StatusBrush = '#2A7F7A'; MissingVis = 'Collapsed'; RadarrTag = ''; SeerrTag = ''; TmdbTag = "tmdb|$partId" })
            } else {
                $coming = ($rel -eq [datetime]::MinValue -or $rel -gt $today)
                [void]$items.Add([pscustomobject]@{ IsFilm = $false; Key = ''; Title = [string]$p['Title']; Sub = $(if ($coming) { "$sub  ·  not out yet" } else { $sub }); Poster = $p['Poster']; Opac = 0.42
                    Status = $(if ($coming) { 'COMING' } else { 'MISSING' }); StatusBrush = $(if ($coming) { '#7B7266' } else { '#C8432B' })
                    MissingVis = $(if ($coming) { 'Collapsed' } else { 'Visible' }); RadarrTag = "radarr|$partId|$([string]$p['Title'])|$([int]$p['Year'])"; SeerrTag = "seerr|$partId|$([string]$p['Title'])"; TmdbTag = "tmdb|$partId" })
            }
        }
        $UI.txtCollInfo.Text = "You have $($row.Owned) of $($row.Total) released films"
    } else {
        $UI.txtCollOverview.Text = 'Press “Check TMDb” to see the full collection and what you are missing.'
        foreach ($f in $owned) {
            [void]$items.Add([pscustomobject]@{ IsFilm = $true; Key = $f.Key; Title = $f.Title; Sub = "$($f.YearText)  ·  $($f.Shelf)"; Poster = $f.Poster; Opac = 1.0
                Status = 'ON YOUR SHELF'; StatusBrush = '#2A7F7A'; MissingVis = 'Collapsed'; RadarrTag = ''; SeerrTag = ''; TmdbTag = "tmdb|$($f.TmdbId)" })
        }
        $UI.txtCollInfo.Text = "$($owned.Count) on your shelves"
    }
    $UI.icParts.ItemsSource = $items.ToArray()
}

function Invoke-PartButton([string]$tag) {
    $bits = $tag -split '\|'
    switch ($bits[0]) {
        'tmdb'   { Open-Url "https://www.themoviedb.org/movie/$($bits[1])" }
        'seerr'  { Request-InSeerr ([int]$bits[1]) $(if ($bits.Count -gt 2) { $bits[2] } else { '' }) }
        'radarr' { Show-RadarrAdd ([int]$bits[1]) $bits[2] ([int]$bits[3]) }
    }
}

# =====================================================================================
#  Radarr
# =====================================================================================
function Normalize-ServiceUrl([string]$u) {
    # Tidy whatever was pasted: add https://, drop UI paths (/settings, /movie/…, /#…) and any /api/… suffix
    $u = ([string]$u).Trim().Trim('"')
    if (-not $u) { return '' }
    $u = $u.TrimEnd('/')
    if ($u -notmatch '^(?i)https?://') {
        # bare IP addresses and host:port are almost always plain http on a home network
        if ($u -match '^[\d\.]+(:\d+)?(/|$)' -or $u -match '^[^/]+:\d+') { $u = 'http://' + $u } else { $u = 'https://' + $u }
    }
    $u = [regex]::Replace($u, '^(?i)(https?://)([^/]+)', { param($m) $m.Groups[1].Value + ($m.Groups[2].Value -replace '\.{2,}', '.') })
    $u = $u -replace '#.*$', '' -replace '\?.*$', ''
    $u = [regex]::Replace($u, '(?i)/(api(/v\d+)?|settings|movie|movies|add|calendar|activity|wanted|system|discover|login)(/.*)?$', '')
    if ($u -match '^(?i)http://([^/:]+):443(/.*)?$') { $u = 'https://' + $Matches[1] + $Matches[2] }
    return $u.TrimEnd('/')
}

function Get-HttpErrorDetail($err) {
    $code = 0; $body = ''
    try { $code = [int]$err.Exception.Response.StatusCode } catch {}
    try { if ($err.ErrorDetails -and $err.ErrorDetails.Message) { $body = [string]$err.ErrorDetails.Message } } catch {}
    if (-not $body) { try { $sr = New-Object IO.StreamReader ($err.Exception.Response.GetResponseStream()); $body = $sr.ReadToEnd(); $sr.Dispose() } catch {} }
    $body = [regex]::Replace($body, '<[^>]+>', ' ')
    $body = [regex]::Replace($body, '\s+', ' ').Trim()
    if ($body.Length -gt 300) { $body = $body.Substring(0, 300) + '…' }
    return @{ Code = $code; Body = $body; Message = $err.Exception.Message }
}

# Windows PowerShell 5.1 returns a JSON list as ONE object; send each item down the pipeline separately
function Expand-JsonList($r) {
    if ($null -eq $r) { return }
    if ($r -is [Array]) { foreach ($x in $r) { $x } } else { $r }
}

function Invoke-Radarr([string]$method, [string]$path, $body) {
    $baseUrl = Normalize-ServiceUrl $Settings.RadarrUrl
    $key = ([string]$Settings.RadarrKey).Trim()
    $url = $baseUrl + '/api/v3' + $path
    $args2 = @{ Method = $method; Uri = $url; Headers = @{ 'X-Api-Key' = $key; Accept = 'application/json' }; TimeoutSec = 60; UseBasicParsing = $true }
    if ($null -ne $body) { $args2.Body = [Text.Encoding]::UTF8.GetBytes((PH-ConvertToJson $body)); $args2.ContentType = 'application/json' }
    try { $r = Invoke-RestMethod @args2; return (Expand-JsonList $r) }
    catch {
        $d = Get-HttpErrorDetail $_
        # some reverse proxies mangle custom headers — try the key as a query parameter once
        if ($d.Code -eq 400 -or $d.Code -eq 401) {
            $sep = $(if ($url.Contains('?')) { '&' } else { '?' })
            $args2.Uri = $url + $sep + 'apikey=' + [uri]::EscapeDataString($key)
            $args2.Headers = @{ Accept = 'application/json' }
            try { $r = Invoke-RestMethod @args2; return (Expand-JsonList $r) } catch { $d = Get-HttpErrorDetail $_ }
        }
        $hint = switch ($d.Code) {
            400 { "The server didn't like the request — usually the address. It should look like https://radarr.example.org with no port and nothing after it. If Radarr has a URL Base set (Settings → General), add it, e.g. https://example.org/radarr." }
            401 { 'Radarr rejected the API key. Copy it again from Radarr → Settings → General → API Key.' }
            403 { 'Access was refused — the reverse proxy may be asking for a login or blocking this PC.' }
            404 { 'Nothing found at that address. If Radarr has a URL Base set (Settings → General), include it in the address.' }
            { $_ -ge 500 } { 'The reverse proxy answered but Radarr itself did not — is the Radarr container running?' }
            default { 'No answer at all — check the address, and that this PC can reach it (try it in a browser).' }
        }
        if ($baseUrl -match ':(8112|8080|8090|9091|8989|9696|5055|8096|32400)(/|$)') {
            $other = @{ '8112' = 'Deluge'; '8080' = 'SABnzbd or qBittorrent'; '8090' = 'a download client'; '9091' = 'Transmission'; '8989' = 'Sonarr'; '9696' = 'Prowlarr'; '5055' = 'Seerr'; '8096' = 'Jellyfin'; '32400' = 'Plex' }[$Matches[1]]
            $hint = "(Port $($Matches[1]) is often used by $other — if Radarr really runs on that port, ignore this.)`n`n" + $hint
        }
        $hint += "`n`nQuick test: open $baseUrl/api/v3/system/status?apikey=YOUR-KEY in a browser. If it shows text containing ""appName"": ""Radarr"", the address and key are right."
        $msg = "Address tried: $baseUrl/api/v3$path`n"
        if ($d.Code) { $msg += "Reply: HTTP $($d.Code)" } else { $msg += "Error: $($d.Message)" }
        if ($d.Body) { $msg += "`nRadarr/proxy said: $($d.Body)" }
        throw ($msg + "`n`n" + $hint)
    }
}

function Test-Radarr {
    if (-not $Settings.RadarrUrl -or -not $Settings.RadarrKey) { Tell 'Enter the Radarr URL and API key first.'; return }
    $Window.Cursor = [Windows.Input.Cursors]::Wait
    try {
        $st = Invoke-Radarr 'GET' '/system/status' $null
        $app = [string]$st.appName
        if ($app -and $app -ne 'Radarr') { Tell "Something answered at that address, but it says it is $app, not Radarr." 'Warning'; return }
        $msg = "Radarr is answering at $(Normalize-ServiceUrl $Settings.RadarrUrl) and the API key is accepted."
        if ($st.version) { $msg += "`nVersion $($st.version)" + $(if ($st.branch) { " ($($st.branch) branch)" } else { '' }) }
        try {
            $roots = @(Invoke-Radarr 'GET' '/rootfolder' $null)
            if ($roots.Count) {
                $msg += "`n`nRoot folders:"
                foreach ($r in $roots) {
                    $free = ''; if ($r.freeSpace) { $free = '  —  ' + (Format-Size ([double]$r.freeSpace)) + ' free' }
                    $msg += "`n•  $($r.path)$free" + $(if ($r.accessible -eq $false) { '  (not accessible!)' } else { '' })
                }
            }
        } catch {}
        try {
            $h = @(Invoke-Radarr 'GET' '/health' $null | Where-Object { $_.type -eq 'error' -or $_.type -eq 'warning' })
            if ($h.Count) { $msg += "`n`nRadarr is reporting:"; foreach ($x in ($h | Select-Object -First 5)) { $msg += "`n•  [$($x.type)] $($x.message)" } }
        } catch {}
        Tell $msg
        Status "Radarr connection OK$(if ($st.version) { ' — version ' + $st.version })."
    } catch { Tell ("Couldn't connect to Radarr.`n`n" + $_.Exception.Message) 'Warning' }
    finally { $Window.Cursor = $null }
}

function Load-RadarrOptions([switch]$Quiet) {
    if (-not $Settings.RadarrUrl -or -not $Settings.RadarrKey) { if (-not $Quiet) { Tell 'Enter the Radarr URL and API key first.' }; return $false }
    $Window.Cursor = [Windows.Input.Cursors]::Wait
    try {
        $st = Invoke-Radarr 'GET' '/system/status' $null
        $ver = [string]$st.version
        $profiles = @(Invoke-Radarr 'GET' '/qualityprofile' $null | ForEach-Object { [pscustomobject]@{ Id = [int]$_.id; Name = [string]$_.name } })
        $UI.cbRadarrProfile.ItemsSource = $profiles
        $p = @($profiles | Where-Object { $_.Id -eq [int]$Settings.RadarrProfileId }); if ($p.Count) { $UI.cbRadarrProfile.SelectedItem = $p[0] } elseif ($profiles.Count) { $UI.cbRadarrProfile.SelectedIndex = 0 }
        $Script:RadarrProfiles = $profiles
        $Settings.RadarrProfileList = @($profiles | ForEach-Object { @{ Id = $_.Id; Name = $_.Name } }); Save-Settings
        if (-not $Quiet) { Status "Connected to Radarr $ver — $($profiles.Count) quality profiles." }
        return $true
    } catch {
        if (-not $Quiet) { Tell ("Couldn't connect to Radarr.`n`n" + $_.Exception.Message) 'Warning' }
        return $false
    } finally { $Window.Cursor = $null }
}

function Show-RadarrAdd([int]$tmdbId, [string]$title, [int]$year) {
    if (-not $Settings.RadarrUrl -or -not $Settings.RadarrKey) { Tell 'Add your Radarr address and API key in Settings first.'; Select-Tab 'Settings'; return }
    if (-not $Script:RadarrProfiles) { if (-not (Load-RadarrOptions)) { return } }
    # Radarr's folders, fetched fresh each time (in the background) so new genre folders show up straight away
    Invoke-Async "Getting Radarr's folders…" { param($v) @(Invoke-Radarr 'GET' '/rootfolder' $null) } @{ TmdbId = $tmdbId; Title = $title; Year = $year } {
        param($r, $v)
        $roots = @(@($r) | Where-Object { $_ } | ForEach-Object {
            $path = [string]$_.path
            $leaf = @($path -split '[\\/]' | Where-Object { $_ })[-1]
            $free = ''; if ($_.freeSpace) { $free = '  ·  ' + (Format-Size ([double]$_.freeSpace)) + ' free' }
            [pscustomobject]@{ Name = $path; Label = "$leaf      $path$free" }
        } | Sort-Object Label)
        Show-RadarrAddDialog $v.TmdbId $v.Title $v.Year $roots
    } { param($err) Tell ("Couldn't get Radarr's folders.`n`n" + $err) 'Warning' }
}
function Show-RadarrAddDialog([int]$tmdbId, [string]$title, [int]$year, $roots) {
    $roots = @($roots)
    if ($roots.Count -eq 0) { Tell "Radarr hasn't got any root folders set up yet (Radarr → Settings → Media Management)." 'Warning'; return }
    $dxText = @'
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Add to Radarr" Width="520" SizeToContent="Height" WindowStartupLocation="CenterOwner" Background="#F3EEE4" FontFamily="Segoe UI" FontSize="13" ResizeMode="NoResize">
  <Window.Resources><!--COMBOSTYLES--></Window.Resources>
  <DockPanel>
  <!--HEADER-->
  <StackPanel Margin="22,16,22,22">
    <TextBlock x:Name="rTitle" FontWeight="SemiBold" FontSize="15" Margin="0,0,0,14" TextWrapping="Wrap"/>
    <TextBlock Text="Which folder should it go in?" Foreground="#7B7266"/>
    <ComboBox x:Name="rRoot" DisplayMemberPath="Label" Margin="0,4,0,2"/>
    <TextBlock x:Name="rHint" Text="Choose the genre folder (shelf) for this film." Foreground="#C8432B" FontSize="12" Margin="0,0,0,10"/>
    <TextBlock Text="Quality profile" Foreground="#7B7266"/>
    <ComboBox x:Name="rProfile" DisplayMemberPath="Name" Margin="0,4,0,10"/>
    <TextBlock Text="Then" Foreground="#7B7266"/>
    <RadioButton x:Name="rChoose" GroupName="how" Content="Let me choose which copy to download (size, quality, seeders)" IsChecked="True" Margin="0,4,0,0"/>
    <RadioButton x:Name="rSearch" GroupName="how" Content="Let Radarr pick and download the best copy it finds" Margin="0,4,0,0"/>
    <RadioButton x:Name="rWait" GroupName="how" Content="Don't search yet — just keep an eye out for it" Margin="0,4,0,0"/>
    <StackPanel Orientation="Horizontal" HorizontalAlignment="Right" Margin="0,18,0,0">
      <Button Content="Cancel" Style="{StaticResource PHDlgGhost}" Margin="0,0,8,0" IsCancel="True"/>
      <Button x:Name="rOk" Content="Add to Radarr" Style="{StaticResource PHDlgPrimary}" IsDefault="True" IsEnabled="False"/>
    </StackPanel>
  </StackPanel>
  </DockPanel>
</Window>
'@
    [xml]$dx = $dxText.Replace('<!--COMBOSTYLES-->', $ComboStyles + $DialogStyles).Replace('<!--HEADER-->', (New-DialogHeader 'Send to Radarr'))
    $dw = [Windows.Markup.XamlReader]::Load((New-Object System.Xml.XmlNodeReader $dx))
    $dw.Owner = $Window
    $dw.FindName('rTitle').Text = $title + $(if ($year) { " ($year)" } else { '' })
    $rr = $dw.FindName('rRoot'); $rp = $dw.FindName('rProfile')
    $rr.ItemsSource = $roots; $rp.ItemsSource = $Script:RadarrProfiles
    $rr.SelectedIndex = -1          # no default — you choose the folder every time
    $x = @($Script:RadarrProfiles | Where-Object { $_.Id -eq [int]$Settings.RadarrProfileId }); if ($x.Count) { $rp.SelectedItem = $x[0] } else { $rp.SelectedIndex = 0 }
    $Script:Dlg = @{ Win = $dw; Ok = $dw.FindName('rOk'); Hint = $dw.FindName('rHint'); Root = $rr }
    $rr.Add_SelectionChanged({ $d = $Script:Dlg; $has = ($null -ne $d.Root.SelectedItem); $d.Ok.IsEnabled = $has; $d.Hint.Visibility = $(if ($has) { 'Collapsed' } else { 'Visible' }) })
    $dw.FindName('rOk').Add_Click({ if ($Script:Dlg.Root.SelectedItem) { $Script:Dlg.Win.DialogResult = $true } })
    $ok = $dw.ShowDialog()
    $root = $rr.SelectedItem; $prof = $rp.SelectedItem; $doSearch = [bool]$dw.FindName('rSearch').IsChecked; $doChoose = [bool]$dw.FindName('rChoose').IsChecked
    $Script:Dlg = $null
    if (-not $ok -or -not $root -or -not $prof) { return }
    Show-Toast "Adding $title to Radarr…" '' 'wait' 4
    $vars = @{ TmdbId = $tmdbId; Title = $title; Year = $year; Root = [string]$root.Name; ProfId = [int]$prof.Id; ProfName = [string]$prof.Name; Search = $doSearch; Choose = $doChoose }
    Invoke-Async "Adding $title to Radarr…" {
        param($v)
        $existing = @(Invoke-Radarr 'GET' "/movie?tmdbId=$($v.TmdbId)" $null)
        if ($existing.Count -and $existing[0].id) { return @{ State = 'exists' } }
        $look = Invoke-Radarr 'GET' "/movie/lookup/tmdb?tmdbId=$($v.TmdbId)" $null
        if (-not $look) { return @{ State = 'notfound' } }
        $body = @{ title = [string]$look.title; tmdbId = $v.TmdbId; year = [int]$look.year; titleSlug = [string]$look.titleSlug
                   qualityProfileId = $v.ProfId; rootFolderPath = $v.Root; monitored = $true; minimumAvailability = 'released'
                   images = @($look.images | ForEach-Object { @{ coverType = [string]$_.coverType; url = [string]$_.url; remoteUrl = [string]$_.remoteUrl } })
                   addOptions = @{ searchForMovie = $v.Search; monitor = 'movieOnly' } }
        $added = @(Invoke-Radarr 'POST' '/movie' $body) | Select-Object -First 1
        return @{ State = 'added'; Id = [int]$added.id }
    } $vars { param($r, $v) On-RadarrAdded $r $v } { param($err) Tell ("Radarr said no:`n" + $err) 'Warning' }
}
function On-RadarrAdded($r, $v) {
    $title = $v.Title; $tmdbId = $v.TmdbId; $year = $v.Year; $doSearch = $v.Search; $doChoose = $v.Choose
    $root = @{ Name = $v.Root }; $prof = @{ Name = $v.ProfName }
    if ($r.State -eq 'exists') { Show-Toast "Radarr already has $title" 'Nothing was changed.' 'wait'; return }
    if ($r.State -eq 'notfound') { Tell "Radarr couldn't find TMDb film $tmdbId." 'Warning'; return }
    $added = @{ id = $r.Id }
    try {
        Write-Log "Radarr: added $title (TMDb $tmdbId) to $($root.Name)$(if ($doSearch) { ' with a search' })."
        if ($doChoose -and $added -and $added.id) {
            Show-Toast "Added $title to Radarr" "Folder: $($root.Name)  ·  profile: $($prof.Name)`nNow pick which copy to download." 'ok' 8
            Show-ReleasePicker ([int]$added.id) ($title + $(if ($year) { " ($year)" } else { '' })) "Not on your shelves yet" $tmdbId
        } elseif ($doSearch) {
            Show-Toast "Added $title to Radarr" "Folder: $($root.Name)  ·  profile: $($prof.Name)`nRadarr is searching for it now — I'll tell you what it finds." 'ok' 10
            if ($added -and $added.id) { Start-RadarrWatch ([int]$added.id) 0 $title $tmdbId }
        } else {
            Show-Toast "Added $title to Radarr" "Folder: $($root.Name)  ·  profile: $($prof.Name)`nIt's monitored, so Radarr will fetch it when a release turns up." 'ok' 10
        }
        Start-RadarrMoviesFetch -Quiet
    } catch { Tell ("Something went wrong after adding:`n" + $_.Exception.Message) 'Warning' }
}

# =====================================================================================
#  Seerr
# =====================================================================================
function Invoke-Seerr([string]$method, [string]$path, $body, [switch]$NoKey) {
    $baseUrl = Normalize-ServiceUrl $Settings.SeerrUrl
    $url = $baseUrl + '/api/v1' + $path
    $h = @{ Accept = 'application/json' }
    if (-not $NoKey -and $Settings.SeerrKey) { $h['X-Api-Key'] = ([string]$Settings.SeerrKey).Trim() }
    $a = @{ Method = $method; Uri = $url; Headers = $h; TimeoutSec = 30; UseBasicParsing = $true }
    if ($null -ne $body) { $a.Body = [Text.Encoding]::UTF8.GetBytes((PH-ConvertToJson $body)); $a.ContentType = 'application/json' }
    try { $r = Invoke-RestMethod @a; return (Expand-JsonList $r) }
    catch {
        $d = Get-HttpErrorDetail $_
        $hint = switch ($d.Code) {
            400 { "Seerr didn't like the request. If the reply mentions an invalid hostname, add this address to the allowed hosts, or use the proxy address." }
            401 { 'The Seerr API key was rejected. Copy it again from Seerr → Settings → General → API Key.' }
            403 { 'Seerr refused — usually the API key is wrong (copy it again from Seerr → Settings → General), or that Seerr user is not allowed to request films.' }
            404 { 'Nothing found at that address — check the Seerr URL (and any URL base).' }
            409 { 'Seerr says this film has already been requested.' }
            { $_ -ge 500 } { 'The proxy answered but Seerr did not — is the Seerr container running?' }
            default { 'No answer — check the address, and that this PC can reach it (try it in a browser).' }
        }
        $msg = "Address tried: $baseUrl/api/v1$path`n"
        if ($d.Code) { $msg += "Reply: HTTP $($d.Code)" } else { $msg += "Error: $($d.Message)" }
        if ($d.Body) { $msg += "`nSeerr said: $($d.Body)" }
        $ex = New-Object Exception ($msg + "`n`n" + $hint)
        $ex.Data['Code'] = $d.Code
        throw $ex
    }
}

function Test-Seerr {
    if (-not $Settings.SeerrUrl) { Tell 'Enter the Seerr URL first.'; return }
    $Window.Cursor = [Windows.Input.Cursors]::Wait
    try {
        $st = Invoke-Seerr 'GET' '/status' $null -NoKey
        $msg = "Seerr is answering at $(Normalize-ServiceUrl $Settings.SeerrUrl)"
        if ($st.version) { $msg += " (version $($st.version))" }
        $msg += '.'
        if ($Settings.SeerrKey) {
            try {
                $me = Invoke-Seerr 'GET' '/auth/me' $null
                $who = [string]$me.displayName; if (-not $who) { $who = [string]$me.username }; if (-not $who) { $who = [string]$me.email }
                $msg += "`n`nAPI key accepted" + $(if ($who) { " — requests will be made as $who" } else { '' }) + ".`nThe Seerr button on missing collection films will now request them straight away."
            } catch { $msg += "`n`nBut the API key didn't work:`n" + $_.Exception.Message; Tell $msg 'Warning'; return }
        } else {
            $msg += "`n`nNo API key entered, so the Seerr button will open the film's page in your browser. Add the key (Seerr → Settings → General) to request films directly from Picture House."
        }
        Tell $msg
        Status 'Seerr connection OK.'
    } catch { Tell ("Couldn't connect to Seerr.`n`n" + $_.Exception.Message) 'Warning' }
    finally { $Window.Cursor = $null }
}

function Request-InSeerr([int]$tmdbId, [string]$title) {
    if (-not $Settings.SeerrUrl) { Tell 'Add your Seerr address in Settings first.'; Select-Tab 'Settings'; return }
    $page = (Normalize-ServiceUrl $Settings.SeerrUrl) + "/movie/$tmdbId"
    if (-not $Settings.SeerrKey) { Open-Url $page; return }
    $label = $(if ($title) { "‘$title’" } else { "TMDb film $tmdbId" })
    if (-not (Ask "Request $label in Seerr?")) { return }
    Invoke-Async "Requesting $label in Seerr…" { param($v) [void](Invoke-Seerr 'POST' '/request' @{ mediaType = 'movie'; mediaId = $v.TmdbId }); $true } @{ TmdbId = $tmdbId; Label = $label } {
        param($r, $v) Show-Toast "Requested $($v.Label) in Seerr" 'Seerr will pass it to Radarr (straight away, or once it''s approved).' 'ok'
    } {
        param($err, $v, $code)
        if ($code -eq 409 -or $err -match 'HTTP 409') { Show-Toast "$($v.Label) is already requested in Seerr" 'Nothing was changed.' 'wait' }
        else { Tell ("Seerr couldn't take the request.`n`n" + $err) 'Warning' }
    }
}

# =====================================================================================
#  Tonight's Pick
# =====================================================================================
function Get-ChipTag($panel) {
    foreach ($c in $panel.Children) { if ($c -is [Windows.Controls.RadioButton] -and $c.IsChecked) { return [string]$c.Tag } }
    return ''
}
function Get-ChipRange($panel) {
    $t = Get-ChipTag $panel
    if ($t -match '^(\d+)-(\d+)$') { return @([int]$Matches[1], [int]$Matches[2]) }
    return $null
}

function Get-PickPool {
    $shelf = Get-ChipTag $UI.wpPickShelf
    $len = Get-ChipRange $UI.wpPickLen
    $era = Get-ChipRange $UI.wpPickEra
    $from = Get-ChipTag $UI.wpPickFrom
    $pool = New-Object Collections.Generic.List[object]
    foreach ($v in (Get-VisibleViews)) {
        if ($shelf -and -not ($v.Shelf -eq $shelf -or $v.Shelf.StartsWith($shelf + ' › '))) { continue }
        if ($len -and ($v.Runtime -le 0 -or $v.Runtime -lt $len[0] -or $v.Runtime -gt $len[1])) { continue }
        if ($era -and ($v.Year -le 0 -or $v.Year -lt $era[0] -or $v.Year -gt $era[1])) { continue }
        if ($from -eq 'unw' -and $v.Watched) { continue }
        if ($from -eq 'list' -and -not $v.Watchlist) { continue }
        if ($from -eq 'fav' -and -not $v.Fav) { continue }
        if ($Script:PickSkip -contains $v.Key) { continue }
        $pool.Add($v)
    }
    return , $pool
}
$Script:PickSkip = @()
$Script:PickAlts = @()
$Script:Rng = New-Object Random

function Update-PickPoolText {
    $pool = Get-PickPool
    $n = $pool.Count + @($Script:PickSkip).Count
    $UI.txtPickPoolNum.Text = '{0:N0}' -f $n
    $words = $(if ($n -eq 1) { 'FILM IN THE HAT' } else { 'FILMS IN THE HAT' })
    $UI.txtPickPool.Text = (($words -split ' ') | ForEach-Object { $_.ToCharArray() -join ' ' }) -join '     '   # spaced-out capitals
}

function Reset-PickChoices {
    $Script:Loading = $true
    try {
        foreach ($wp in @($UI.wpPickShelf, $UI.wpPickLen, $UI.wpPickEra)) { if ($wp.Children.Count) { $wp.Children[0].IsChecked = $true } }
        $UI.rbFromUnw.IsChecked = $true
    } finally { $Script:Loading = $false }
    $Script:PickSkip = @()
    Update-PickPoolText
}

function On-PickFilterChanged { if ($Script:Loading) { return }; $Script:PickSkip = @(); Update-PickPoolText }

function Fill-PickShelves([string]$want) {
    if (-not $want) { $want = Get-ChipTag $UI.wpPickShelf }
    $names = @(Get-ShelfList | ForEach-Object { [string]$_['Name'] } | Where-Object { $_ -and $_ -notmatch ' › ' -and -not (Test-Hidden $_ (Get-HiddenSet)) })
    if ($want -and $names -notcontains $want) { $names += $want }   # a sub-shelf picked from the rail
    $Script:Loading = $true
    try {
        $UI.wpPickShelf.Children.Clear()
        foreach ($n in @('') + $names) {
            $rb = New-Object Windows.Controls.RadioButton
            $rb.GroupName = 'pshelf'; $rb.Style = $Window.FindResource('PickChip'); $rb.Tag = $n
            $rb.Content = $(if ($n) { $n } else { 'Any' })
            $rb.IsChecked = ($n -eq $want)
            $rb.Add_Checked({ On-PickFilterChanged })
            [void]$UI.wpPickShelf.Children.Add($rb)
        }
    } finally { $Script:Loading = $false }
}

function Get-PickWeighted($pool, [int]$count) {
    # watchlist, favourite and well-rated films get a few more tickets
    $left = New-Object Collections.Generic.List[object]; foreach ($v in $pool) { $left.Add($v) }
    $out = @()
    while ($out.Count -lt $count -and $left.Count -gt 0) {
        $total = 0.0; $w = New-Object 'Collections.Generic.List[double]'
        foreach ($v in $left) { $x = 1.0; if ($v.Watchlist) { $x += 2.0 }; if ($v.Fav) { $x += 0.5 }; $x += [math]::Max([double]0, [double]$v.Rating - 5.0) / 2.0; $w.Add($x); $total += $x }
        $r = $Script:Rng.NextDouble() * $total; $acc = 0.0; $idx = $left.Count - 1
        for ($i = 0; $i -lt $left.Count; $i++) { $acc += $w[$i]; if ($acc -ge $r) { $idx = $i; break } }
        $out += $left[$idx]; $left.RemoveAt($idx)
    }
    return , $out
}

function Show-PickCard($v) {
    $UI.bdPickPoster.Visibility = 'Visible'
    $UI.ibPickPoster.ImageSource = Load-Bitmap $v.Poster 450
    $UI.txtPickPosterTitle.Text = $v.Title
    $UI.txtPickTitle.Text = $v.Title; $UI.txtPickTitle.FontStyle = [Windows.FontStyles]::Normal; $UI.txtPickTitle.Foreground = $Window.FindResource('Cream')
    $bits = @(); if ($v.Year) { $bits += [string]$v.Year }; if ($v.RuntimeText) { $bits += $v.RuntimeText }; if ($v.GenreText) { $bits += $v.GenreText }; if ($v.Rating -gt 0) { $bits += ('★ {0:0.0}' -f $v.Rating) }; $bits += $v.Shelf
    $UI.txtPickMeta.Text = ($bits -join '   ·   ')
    $UI.txtPickPlot.Text = $v.Overview
    $m = $Script:Meta[$v.Key]; $back = $null
    if ($m -and $m['Backdrop']) { $back = Load-Bitmap ([string]$m['Backdrop']) 1200 }
    $UI.imgPickBack.Source = $back
    $UI.wpPickButtons.Visibility = 'Visible'
    $UI.btnPickList.Content = $(if ($v.Watchlist) { '⌚  On your watchlist' } else { '⌚  Save to watchlist' })
    $Script:PickKey = $v.Key
    $UI.icPickAlt.ItemsSource = @($Script:PickAlts)
    $UI.spPickAlt.Visibility = $(if (@($Script:PickAlts).Count) { 'Visible' } else { 'Collapsed' })
}

function Reset-PickCard([string]$msg = 'Roll the dice and let fate choose.') {
    $UI.bdPickPoster.Visibility = 'Collapsed'; $UI.ibPickPoster.ImageSource = $null; $UI.imgPickBack.Source = $null
    $UI.txtPickRolled.Text = "T O N I G H T ' S    P I C T U R E"
    $UI.txtPickTitle.Text = $msg; $UI.txtPickTitle.FontStyle = [Windows.FontStyles]::Italic; $UI.txtPickTitle.Foreground = (New-Object Windows.Media.SolidColorBrush ([Windows.Media.Color]::FromArgb(0xC9, 0xF6, 0xEB, 0xD9)))
    $UI.txtPickMeta.Text = ''; $UI.txtPickPlot.Text = ''; $UI.wpPickButtons.Visibility = 'Collapsed'
    $UI.icPickAlt.ItemsSource = $null; $UI.spPickAlt.Visibility = 'Collapsed'
    $UI.txtDiceHint.Text = 'Click the dice to roll'
    $Script:PickKey = $null; $Script:PickAlts = @()
}

function Swap-PickAlt([string]$key) {
    $alt = @($Script:PickAlts | Where-Object { $_.Key -eq $key }); if (-not $alt.Count) { return }
    $cur = $Script:ViewByKey[$Script:PickKey]
    $Script:PickAlts = @($Script:PickAlts | ForEach-Object { if ($_.Key -eq $key) { if ($cur) { $cur } } else { $_ } })
    Show-PickCard $alt[0]
    $UI.txtPickRolled.Text = "T O N I G H T ' S    P I C T U R E"
}

# ---------- the dice: a real 3D cube (Viewport3D) that tumbles and lands on a face ----------
function New-DiceFace([int]$n) {
    $sz = 256
    $dv = New-Object Windows.Media.DrawingVisual
    $dc = $dv.RenderOpen()
    $edge = New-Object Windows.Media.SolidColorBrush ([Windows.Media.Color]::FromRgb(0xD9, 0xC8, 0xA8))
    $face = New-Object Windows.Media.SolidColorBrush ([Windows.Media.Color]::FromRgb(0xF8, 0xEF, 0xDF))
    $pip = New-Object Windows.Media.SolidColorBrush ([Windows.Media.Color]::FromRgb(0xC8, 0x43, 0x2B))
    $dc.DrawRectangle($edge, $null, (New-Object Windows.Rect 0, 0, $sz, $sz))
    $dc.DrawRoundedRectangle($face, $null, (New-Object Windows.Rect 7, 7, ($sz - 14), ($sz - 14)), 38, 38)
    $g = @(66.0, 128.0, 190.0)
    $pat = @{ 1 = '11'; 2 = '00 22'; 3 = '00 11 22'; 4 = '00 20 02 22'; 5 = '00 20 11 02 22'; 6 = '00 01 02 20 21 22' }
    foreach ($p in ($pat[$n] -split ' ')) {
        $cx = $g[[int]::Parse($p.Substring(0, 1))]; $cy = $g[[int]::Parse($p.Substring(1, 1))]
        $dc.DrawEllipse($pip, $null, (New-Object Windows.Point $cx, $cy), 23.0, 23.0)
    }
    $dc.Close()
    $bmp = New-Object Windows.Media.Imaging.RenderTargetBitmap $sz, $sz, 96, 96, ([Windows.Media.PixelFormats]::Pbgra32)
    $bmp.Render($dv); $bmp.Freeze()
    $br = New-Object Windows.Media.ImageBrush $bmp; $br.Freeze()
    return $br
}

function New-V3([double]$x, [double]$y, [double]$z) { return (New-Object Windows.Media.Media3D.Vector3D $x, $y, $z) }
function Get-UnitV3($v) {
    $l = [math]::Sqrt($v.X * $v.X + $v.Y * $v.Y + $v.Z * $v.Z)
    if ($l -lt 0.0001) { return (New-V3 0.6 0.8 0) }
    return (New-V3 ($v.X / $l) ($v.Y / $l) ($v.Z / $l))
}
function New-Fade([double]$from, [double]$to, [int]$ms) {
    $a = New-Object Windows.Media.Animation.DoubleAnimation
    if ($from -ge 0) { $a.From = $from }
    $a.To = $to; $a.Duration = New-Object Windows.Duration ([TimeSpan]::FromMilliseconds($ms))
    return $a
}

function Init-Dice {
    $vp = New-Object Windows.Controls.Viewport3D
    $cam = New-Object Windows.Media.Media3D.PerspectiveCamera
    $cam.Position = New-Object Windows.Media.Media3D.Point3D 0, 0, 8.6
    $cam.LookDirection = New-V3 0 0 -1; $cam.UpDirection = New-V3 0 1 0; $cam.FieldOfView = 26
    $vp.Camera = $cam
    $grp = New-Object Windows.Media.Media3D.Model3DGroup
    [void]$grp.Children.Add((New-Object Windows.Media.Media3D.AmbientLight ([Windows.Media.Color]::FromRgb(0x9A, 0x9A, 0x9A))))
    [void]$grp.Children.Add((New-Object Windows.Media.Media3D.DirectionalLight ([Windows.Media.Color]::FromRgb(0x80, 0x80, 0x80)), (New-V3 -0.4 -0.6 -1)))
    # face number -> normal, right, up (right x up = normal); opposite faces add up to 7
    $faces = @(
        @(1, (New-V3 0 0 1), (New-V3 1 0 0), (New-V3 0 1 0)),
        @(6, (New-V3 0 0 -1), (New-V3 -1 0 0), (New-V3 0 1 0)),
        @(2, (New-V3 1 0 0), (New-V3 0 0 -1), (New-V3 0 1 0)),
        @(5, (New-V3 -1 0 0), (New-V3 0 0 1), (New-V3 0 1 0)),
        @(3, (New-V3 0 1 0), (New-V3 1 0 0), (New-V3 0 0 -1)),
        @(4, (New-V3 0 -1 0), (New-V3 1 0 0), (New-V3 0 0 1)))
    foreach ($f in $faces) {
        $nrm = $f[1]; $r = $f[2]; $u = $f[3]
        $m = New-Object Windows.Media.Media3D.MeshGeometry3D
        foreach ($c in @(@(-1, -1), @(1, -1), @(1, 1), @(-1, 1))) {
            $v = $nrm + ($r * [double]$c[0]) + ($u * [double]$c[1])
            [void]$m.Positions.Add((New-Object Windows.Media.Media3D.Point3D $v.X, $v.Y, $v.Z))
        }
        foreach ($t in @(@(0, 1), @(1, 1), @(1, 0), @(0, 0))) { [void]$m.TextureCoordinates.Add((New-Object Windows.Point $t[0], $t[1])) }
        foreach ($i in 0, 1, 2, 0, 2, 3) { [void]$m.TriangleIndices.Add($i) }
        $mat = New-Object Windows.Media.Media3D.DiffuseMaterial (New-DiceFace $f[0])
        [void]$grp.Children.Add((New-Object Windows.Media.Media3D.GeometryModel3D $m, $mat))
    }
    $Script:DiceRot = New-Object Windows.Media.Media3D.QuaternionRotation3D ([Windows.Media.Media3D.Quaternion]::Identity)
    $Script:DiceLift = New-Object Windows.Media.Media3D.TranslateTransform3D 0, 0, 0
    $tg = New-Object Windows.Media.Media3D.Transform3DGroup
    [void]$tg.Children.Add((New-Object Windows.Media.Media3D.RotateTransform3D $Script:DiceRot))
    [void]$tg.Children.Add((New-Object Windows.Media.Media3D.RotateTransform3D (New-Object Windows.Media.Media3D.AxisAngleRotation3D (New-V3 1 0 0), 22)))
    [void]$tg.Children.Add((New-Object Windows.Media.Media3D.RotateTransform3D (New-Object Windows.Media.Media3D.AxisAngleRotation3D (New-V3 0 1 0), -28)))
    [void]$tg.Children.Add($Script:DiceLift)
    $grp.Transform = $tg
    $mv = New-Object Windows.Media.Media3D.ModelVisual3D; $mv.Content = $grp
    [void]$vp.Children.Add($mv)
    $UI.bdDice.Child = $vp
    # which way to turn the cube so a face ends up at the front
    $Q = { param($ax, $deg) New-Object Windows.Media.Media3D.Quaternion $ax, ([double]$deg) }
    $Script:DiceTargets = @{
        1 = [Windows.Media.Media3D.Quaternion]::Identity
        6 = (& $Q (New-V3 0 1 0) 180); 2 = (& $Q (New-V3 0 1 0) -90); 5 = (& $Q (New-V3 0 1 0) 90)
        3 = (& $Q (New-V3 1 0 0) 90); 4 = (& $Q (New-V3 1 0 0) -90)
    }
    $Script:DiceRot.Quaternion = $Script:DiceTargets[5]
}

$Script:DiceTimer = New-Object Windows.Threading.DispatcherTimer
$Script:DiceTimer.Interval = [TimeSpan]::FromMilliseconds(15)
$Script:Dice = $null
$Script:DiceTimer.Add_Tick({
    $d = $Script:Dice; if (-not $d) { $Script:DiceTimer.Stop(); return }
    $t = $d.Clock.Elapsed.TotalSeconds
    $dt = $t - $d.Last; $d.Last = $t
    $spinEnd = 1.0; $total = 1.6
    if ($t -lt $spinEnd) {
        $speed = 1150.0 * (1.0 - $t / 1.25)
        $d.Axis = Get-UnitV3 (New-V3 ($d.Axis.X + ($Script:Rng.NextDouble() - 0.5) * 0.08) ($d.Axis.Y + ($Script:Rng.NextDouble() - 0.5) * 0.08) $d.Axis.Z)
        $step = New-Object Windows.Media.Media3D.Quaternion $d.Axis, ($speed * $dt)
        $Script:DiceRot.Quaternion = [Windows.Media.Media3D.Quaternion]::Multiply($step, $Script:DiceRot.Quaternion)
        $d.From = $Script:DiceRot.Quaternion
    } elseif ($t -lt $total) {
        $s = ($t - $spinEnd) / ($total - $spinEnd); $e = 1.0 - [math]::Pow(1.0 - $s, 3.0)
        $Script:DiceRot.Quaternion = [Windows.Media.Media3D.Quaternion]::Slerp($d.From, $d.Target, $e)
    }
    # a little hop off the table and back down
    $hop = [math]::Max([double]0, [math]::Sin([math]::PI * [math]::Min([double]1, $t / 1.25)))
    $Script:DiceLift.OffsetZ = 0.9 * $hop
    if ($t -ge $total) {
        $Script:DiceTimer.Stop()
        $Script:DiceRot.Quaternion = $d.Target; $Script:DiceLift.OffsetZ = 0
        $Script:Dice = $null
        Finish-Roll $d
    }
})

function Start-Spin {
    if ($Script:DiceTimer.IsEnabled) { return }
    if (-not $Script:DiceRot) { Init-Dice }
    if ($Script:PickKey) { $Script:PickSkip += $Script:PickKey }   # rolling again means "not that one tonight"
    $pool = Get-PickPool
    if ($pool.Count -eq 0 -and @($Script:PickSkip).Count) { $Script:PickSkip = @(); $pool = Get-PickPool }
    if ($pool.Count -eq 0) { Reset-PickCard 'Nothing fits — loosen the filters a little.'; return }
    $picks = Get-PickWeighted $pool 4
    $n = $Script:Rng.Next(1, 7)
    $ax = Get-UnitV3 (New-V3 ($Script:Rng.NextDouble() - 0.5) ($Script:Rng.NextDouble() - 0.5) ($Script:Rng.NextDouble() - 0.5))
    $Script:Dice = @{ Clock = [Diagnostics.Stopwatch]::StartNew(); Last = 0.0; Axis = $ax; From = $Script:DiceRot.Quaternion; Target = $Script:DiceTargets[$n]; Number = $n; Picks = $picks }
    $UI.txtDiceHint.Text = 'Rolling…'
    $UI.gdPickResult.BeginAnimation([Windows.UIElement]::OpacityProperty, (New-Fade -1 0.15 250))
    $Script:DiceTimer.Start()
}

function Finish-Roll($d) {
    $picks = @($d.Picks)
    $Script:PickAlts = @($picks | Select-Object -Skip 1)
    Show-PickCard $picks[0]
    $UI.txtPickRolled.Text = "YOU ROLLED A $($d.Number)   ·   TONIGHT'S PICTURE"
    $UI.txtDiceHint.Text = 'Not tonight? Roll again'
    $UI.gdPickResult.BeginAnimation([Windows.UIElement]::OpacityProperty, (New-Fade 0.15 1.0 380))
}

# =====================================================================================
#  People
# =====================================================================================
$Script:PeopleIndex = $null
function Build-PeopleIndex {
    $actors = @{}; $dirs = @{}
    foreach ($v in (Get-VisibleViews)) {
        foreach ($c in $v.Cast) {
            $n = [string]$c['Name']; if (-not $n) { continue }
            if (-not $actors.ContainsKey($n)) { $actors[$n] = @{ Name = $n; Photo = $c['Photo']; Id = 0; Films = (New-Object Collections.ArrayList) } }
            if (-not $actors[$n].Photo -and $c['Photo']) { $actors[$n].Photo = $c['Photo'] }
            if (-not $actors[$n].Id -and [int]$c['Id'] -gt 0) { $actors[$n].Id = [int]$c['Id'] }
            [void]$actors[$n].Films.Add($v.Key)
        }
        foreach ($d in $v.Directors) {
            $n = [string]$d['Name']; if (-not $n) { continue }
            if (-not $dirs.ContainsKey($n)) { $dirs[$n] = @{ Name = $n; Photo = $d['Photo']; Id = 0; Films = (New-Object Collections.ArrayList) } }
            if (-not $dirs[$n].Photo -and $d['Photo']) { $dirs[$n].Photo = $d['Photo'] }
            if (-not $dirs[$n].Id -and [int]$d['Id'] -gt 0) { $dirs[$n].Id = [int]$d['Id'] }
            [void]$dirs[$n].Films.Add($v.Key)
        }
    }
    $Script:PeopleIndex = @{ Actors = $actors; Directors = $dirs }
    $Script:Dirty.People = $false
}

function Refresh-People {
    if ($Script:Dirty.People -or -not $Script:PeopleIndex) { Build-PeopleIndex }
    $src = $(if ($UI.rbDirectors.IsChecked) { $Script:PeopleIndex.Directors } else { $Script:PeopleIndex.Actors })
    $q = $UI.txtPeopleSearch.Text.Trim().ToLowerInvariant()
    $min = 1   # everyone is listed — actors and directors alike
    $actorsTab = -not $UI.rbDirectors.IsChecked
    $kind = $(if ($actorsTab) { 'Actors' } else { 'Directors' })
    Load-PersonDepts
    $Script:PeopleHidden = 0
    $rows = foreach ($p in $src.Values) {
        if ($p.Films.Count -lt $min) { continue }
        if ($actorsTab -and -not (Test-ActorOrDirector $p)) { $Script:PeopleHidden++; continue }   # producers, writers, crew who turn up in a cast list
        if ($q -and $p.Name.ToLowerInvariant().IndexOf($q) -lt 0) { continue }
        $ph = $p.Photo; if (-not $ph) { $ph = $null }
        $c = Get-PersonCompletion $p $kind
        $done = ''; $pct = -1; $tot = 0
        if ($c) { $done = "$($c.Have) of $($c.Total)  ·  $($c.Pct)%"; $pct = $c.Pct; $tot = $c.Total }
        [pscustomobject]@{ IsPerson = $true; Name = $p.Name; Count = $p.Films.Count; Photo = $ph; Initials = (Get-Initials $p.Name)
                           DoneText = $done; DoneVis = $(if ($done) { 'Visible' } else { 'Collapsed' }); Pct = $pct; Total = $tot }
    }
    if ($UI.rbPplDone.IsChecked) {
        # most complete first — only people with 3+ films count, so a single film doesn't read as "100%"
        $UI.lbPeople.ItemsSource = @($rows | Sort-Object @{ e = { if ($_.Total -ge 3) { $_.Pct } else { -1 } }; d = $true }, @{ e = { $_.Total }; d = $true }, Name)
    } else {
        $UI.lbPeople.ItemsSource = @($rows | Sort-Object @{ e = { $_.Count }; d = $true }, Name)
    }
}

function Show-Person([string]$name, [string]$kind = '') {
    if ($Script:Dirty.People -or -not $Script:PeopleIndex) { Build-PeopleIndex }
    if (-not $kind) { if ($Script:PeopleIndex.Actors.ContainsKey($name)) { $kind = 'Actors' } else { $kind = 'Directors' } }
    if ($kind -eq 'Directors' -and -not $Script:PeopleIndex.Directors.ContainsKey($name) -and $Script:PeopleIndex.Actors.ContainsKey($name)) { $kind = 'Actors' }
    $p = $Script:PeopleIndex[$kind][$name]
    if (-not $UI.navPeople.IsChecked) { Select-Tab 'People' }
    $Script:Loading = $true
    try {
        if ($kind -eq 'Directors') { $UI.rbDirectors.IsChecked = $true } else { $UI.rbActors.IsChecked = $true }
    } finally { $Script:Loading = $false }
    Refresh-People
    $hit = @($UI.lbPeople.Items | Where-Object { $_.Name -eq $name })
    if ($hit.Count) { $Script:Loading = $true; $UI.lbPeople.SelectedItem = $hit[0]; $UI.lbPeople.ScrollIntoView($hit[0]); $Script:Loading = $false }
    $Script:CurPerson = @{ Name = $name; Kind = $kind }
    Reset-PersonDetails
    if (-not $p) { $UI.txtPersonName.Text = $name; $UI.txtPersonInfo.Text = 'Not on any visible shelf'; $UI.icPeopleFilms.ItemsSource = $null; Request-PersonDetails $name 0 $kind; return }
    $films = @($p.Films | ForEach-Object { $Script:ViewByKey[$_] } | Where-Object { $_ } | Sort-Object Year)
    $UI.txtPersonName.Text = $name
    $role = $(if ($kind -eq 'Directors') { 'directed' } else { 'appears in' })
    $seen = @($films | Where-Object { $_.Watched }).Count
    $UI.txtPersonInfo.Text = "$role $($films.Count) of your films  ·  you've watched $seen"
    $UI.ibPerson.ImageSource = $(if ($p.Photo) { Load-Bitmap ([string]$p.Photo) 280 } else { $null })
    $UI.icPeopleFilms.ItemsSource = $films
    Update-PersonCompletion
    Request-PersonDetails $name ([int]$p.Id) $kind
}

# =====================================================================================
#  Person details from TMDb (photo, biography, other films) — cached in Data\people.json
# =====================================================================================
$Files.People = Join-Path $DataDir 'people.json'
$Script:PeopleCache = @{}
$j = PH-LoadJson $Files.People
if ($j) { foreach ($k in @($j.Keys)) { $Script:PeopleCache[$k] = $j[$k] } }
Remove-Variable j -ErrorAction SilentlyContinue

$PersonWork = {
    param($sync, $p)
    $sync.Status = "Getting details for $($p.Name) from TMDb…"
    $sync.Result = PH-PersonDetails $p
}

# Background: fetch details for everyone in your films, most-seen first, so People opens instantly
$PeopleAutoWork = {
    param($sync, $p)
    $list = @($p.List); $n = $list.Count; $i = 0
    foreach ($x in $list) {
        if ($sync.Cancel) { break }
        $i++
        $sync.Status = "Getting cast & crew details from TMDb  ·  $i of $n"
        $sync.Pct = [int](100 * $i / [math]::Max(1, $n))
        try {
            $r = PH-PersonDetails @{ Key = $p.Key; Lang = $p.Lang; Name = $x.Name; Id = [int]$x.Id; Dept = $x.Dept }
            if ($r) { $sync.Queue.Enqueue($r) }
        } catch { if ($_.Exception.Message -match '401') { $sync.Error = 'TMDb rejected the API key.'; break } }
        Start-Sleep -Milliseconds 80   # be gentle with TMDb
    }
}

$PeopleDir = Join-Path $CacheDir 'people'
if (-not (Test-Path -LiteralPath $PeopleDir)) { [void](New-Item -ItemType Directory -Path $PeopleDir -Force) }

function Get-PersonSlug([string]$name, [int]$id) {
    if ($id -gt 0) { return [string]$id }
    $s = [regex]::Replace($name.ToLowerInvariant().Trim(), '[\\/:*?"<>|\s.]+', '_').Trim('_')
    if (-not $s) { $s = [string]([Math]::Abs($name.GetHashCode())) }
    return 'n_' + $s
}

function Get-PersonCache([string]$name, [int]$id) {
    $ck = $(if ($id) { "id:$id" } else { "name:$($name.ToLowerInvariant())" })
    $c = $Script:PeopleCache[$ck]
    if (-not $c) {
        $c = PH-LoadJson (Join-Path $PeopleDir ((Get-PersonSlug $name $id) + '.json'))
        if ($c -and $c['Alias']) { $c = PH-LoadJson (Join-Path $PeopleDir ([string]$c['Alias'] + '.json')) }
        if ($c) { $Script:PeopleCache[$ck] = $c }
    }
    return $c
}

function Save-PersonCache($r) {
    if (-not $r) { return }
    try {
        $utf8 = New-Object Text.UTF8Encoding $false
        $nameFile = Join-Path $PeopleDir ((Get-PersonSlug ([string]$r.Name) 0) + '.json')
        if ($r.NotFound) {
            [IO.File]::WriteAllText($nameFile, (PH-ConvertToJson $r), $utf8)
            $Script:PeopleCache["name:$(([string]$r.Name).ToLowerInvariant())"] = $r
            return
        }
        [IO.File]::WriteAllText((Join-Path $PeopleDir ("$([int]$r.Id).json")), (PH-ConvertToJson $r), $utf8)
        Load-PersonDepts
        $pid2 = [string]([int]$r.Id)
        if ($r.Dept) { $Script:PersonDept[$pid2] = [string]$r.Dept }
        if ($null -ne $r.DirIds -or $null -ne $r.ActIds) { $Script:PersonWorks[$pid2] = @{ D = @($r.DirIds); A = @($r.ActIds) } }
        $Script:DeptsDirty = $true
        if (-not [int]$r.Asked) { [IO.File]::WriteAllText($nameFile, (PH-ConvertToJson @{ Alias = [int]$r.Id; Fetched = $r.Fetched }), $utf8) }
        $Script:PeopleCache["id:$($r.Id)"] = $r
        $Script:PeopleCache["name:$(([string]$r.Name).ToLowerInvariant())"] = $r
    } catch { Write-Log "Could not save person $($r.Name): $($_.Exception.Message)" }
}

# What TMDb says each person is mainly known for (Acting, Directing, Production, Writing…), read from the cached files
$Script:PersonDept = $null     # TMDb id -> what they're mainly known for (Acting, Directing, Production…)
$Script:PersonWorks = $null    # TMDb id -> @{ D = films they directed; A = films they acted in } (for "you have X of Y")
$Script:DeptsDirty = $false
$Files.Depts = Join-Path $DataDir 'people-index.json'
$DeptWork = {
    param($sync, $p)
    $sync.Status = 'Sorting actors from producers…'
    $d = @{}; $w = @{}
    $today = (Get-Date).ToString('yyyy-MM-dd')
    $files = [IO.Directory]::GetFiles($p.Dir, '*.json'); $n = $files.Count; $i = 0
    foreach ($f in $files) {
        if ($sync.Cancel) { break }
        $i++; if ($i % 50 -eq 0) { $sync.Pct = [int](100 * $i / [math]::Max(1, $n)) }
        $id = [IO.Path]::GetFileNameWithoutExtension($f)
        if ($id -notmatch '^\d+$') { continue }
        try {
            $j = [IO.File]::ReadAllText($f) | ConvertFrom-Json
            if ($j.Dept) { $d[$id] = [string]$j.Dept }
            if ($null -ne $j.DirIds -or $null -ne $j.ActIds) { $w[$id] = @{ D = @($j.DirIds | ForEach-Object { [int]$_ }); A = @($j.ActIds | ForEach-Object { [int]$_ }) } }
            else {
                # older files: work it out from the saved credits
                $cr = @($j.Credits | Where-Object { $_.Release -and [string]$_.Release -le $today })
                $w[$id] = @{ D = @($cr | Where-Object { ([string]$_.Role).StartsWith('Director') -and [int]$_.Votes -ge 5 } | ForEach-Object { [int]$_.Id })
                             A = @($cr | Where-Object { [string]$_.Role -ne 'Director' -and [int]$_.Votes -ge 20 -and -not ([string]$_.Role -match '(him|her)self') } | ForEach-Object { [int]$_.Id }) }
            }
        } catch {}
    }
    $sync.Result = @{ Depts = $d; Works = $w }
}
function Load-PersonDepts {
    # one small index file, loaded instantly; if it's missing it's rebuilt in the background (never freezes the window)
    if ($null -ne $Script:PersonDept) { return }
    $j = PH-LoadJson $Files.Depts
    if ($j -and $j['Depts']) {
        $Script:PersonDept = $j['Depts']; $Script:PersonWorks = $j['Works']; if (-not $Script:PersonWorks) { $Script:PersonWorks = @{} }
        return
    }
    $Script:PersonDept = @{}; $Script:PersonWorks = @{}
    foreach ($k in @($Script:PeopleCache.Keys)) {
        $c = $Script:PeopleCache[$k]
        if ($k -like 'id:*' -and $c -and $c['Dept']) { $Script:PersonDept[$k.Substring(3)] = [string]$c['Dept'] }
    }
    if (-not (Test-Busy 'Depts')) { [void](Start-BgJob 'Depts' $DeptWork @{ Dir = $PeopleDir } $null ${function:On-DeptsDone}) }
}
function On-DeptsDone($sync) {
    $r = $sync.Result; if (-not $r) { return }
    foreach ($k in @($r.Depts.Keys)) { if (-not $Script:PersonDept.ContainsKey($k)) { $Script:PersonDept[$k] = $r.Depts[$k] } }
    foreach ($k in @($r.Works.Keys)) { if (-not $Script:PersonWorks.ContainsKey($k)) { $Script:PersonWorks[$k] = $r.Works[$k] } }
    Save-PersonDepts -Force
    if ($UI.navPeople.IsChecked) { Refresh-People; if ($Script:CurPerson) { Update-PersonCompletion } }
}
function Save-PersonDepts([switch]$Force) {
    if ($null -eq $Script:PersonDept -or -not ($Force -or $Script:DeptsDirty)) { return }
    PH-SaveJson @{ Depts = $Script:PersonDept; Works = $Script:PersonWorks } $Files.Depts
    $Script:DeptsDirty = $false
}

# "You have 6 of the 14 films they directed"
function Get-PersonCompletion($p, [string]$kind) {
    if (-not $p -or [int]$p.Id -le 0 -or -not $Script:PersonWorks) { return $null }
    $w = $Script:PersonWorks[[string]([int]$p.Id)]; if (-not $w) { return $null }
    $elig = @($(if ($kind -eq 'Directors') { $w['D'] } else { $w['A'] }))
    $set = New-Object 'Collections.Generic.HashSet[int]'
    foreach ($x in $elig) { [void]$set.Add([int]$x) }
    $have = 0
    foreach ($k in $p.Films) { $v = $Script:ViewByKey[$k]; if ($v -and $v.TmdbId -gt 0) { $have++; [void]$set.Add([int]$v.TmdbId) } }
    $total = $set.Count
    if ($total -le 0) { return $null }
    return @{ Have = $have; Total = $total; Pct = [int][math]::Round(100.0 * $have / $total) }
}
function Update-PersonCompletion {
    $UI.bdPersonDone.Visibility = 'Collapsed'
    if (-not $Script:CurPerson -or -not $Script:PeopleIndex) { return }
    Load-PersonDepts
    $kind = $Script:CurPerson.Kind
    $p = $Script:PeopleIndex[$kind][$Script:CurPerson.Name]
    $c = Get-PersonCompletion $p $kind
    if (-not $c) { return }
    $what = $(if ($kind -eq 'Directors') { "of the $($c.Total) films they directed" } else { "of their $($c.Total) better-known films" })
    $UI.txtPersonDone.Text = "You have $($c.Have) $what  ·  $($c.Pct)%"
    $UI.cdPersonDoneA.Width = New-Object Windows.GridLength ([double][math]::Max(0.001, $c.Pct)), ([Windows.GridUnitType]::Star)
    $UI.cdPersonDoneB.Width = New-Object Windows.GridLength ([double][math]::Max(0.001, 100 - $c.Pct)), ([Windows.GridUnitType]::Star)
    $UI.bdPersonDone.Visibility = 'Visible'
}
function Test-ActorOrDirector($p) {
    if ([int]$p.Id -le 0) { return $true }   # no TMDb id (from an .nfo) — nothing to check against
    $dept = $Script:PersonDept[[string]([int]$p.Id)]
    return (-not $dept -or $dept -eq 'Acting' -or $dept -eq 'Directing')
}

function Start-PeopleAuto {
    if (-not $Settings.TmdbKey -or $Script:Lib.Count -eq 0) { return }
    if ((Test-Busy 'People') -or (Test-Busy 'Scan') -or (Test-Busy 'Fetch')) { return }
    if ($Script:Dirty.People -or -not $Script:PeopleIndex) { Build-PeopleIndex }
    $fresh = (Get-Date).AddDays(-90)
    $have = New-Object 'Collections.Generic.HashSet[string]'
    foreach ($f in @(Get-ChildItem -LiteralPath $PeopleDir -Filter '*.json' -File -ErrorAction SilentlyContinue)) { if ($f.LastWriteTime -gt $fresh) { [void]$have.Add($f.BaseName) } }
    foreach ($k in @($Script:PeopleCache.Keys)) {
        $c = $Script:PeopleCache[$k]; if (-not $c -or (PH-Date $c['Fetched']) -lt $fresh) { continue }
        if ($k -like 'id:*') { [void]$have.Add($k.Substring(3)) } elseif ($k -like 'name:*') { [void]$have.Add((Get-PersonSlug $k.Substring(5) 0)) }
    }
    $todo = New-Object Collections.ArrayList
    foreach ($kind in 'Directors', 'Actors') {
        foreach ($p in $Script:PeopleIndex[$kind].Values) {
            $slug = Get-PersonSlug ([string]$p.Name) ([int]$p.Id)
            if ($have.Contains($slug)) { continue }
            if ([int]$p.Id -le 0 -and $have.Contains((Get-PersonSlug ([string]$p.Name) 0))) { continue }
            [void]$have.Add($slug)
            [void]$todo.Add(@{ Name = [string]$p.Name; Id = [int]$p.Id; Count = $p.Films.Count; Dept = $(if ($kind -eq 'Directors') { 'Directing' } else { 'Acting' }) })
        }
    }
    if ($todo.Count -eq 0) { return }
    $list = @($todo | Sort-Object @{ e = { $_.Count }; d = $true }, @{ e = { $_.Name } })
    $Script:PeopleAutoDone = 0
    Write-Log "People: fetching TMDb details for $($list.Count) people in the background."
    [void](Start-BgJob 'People' $PeopleAutoWork @{ Key = $Settings.TmdbKey; Lang = $Settings.Language; List = $list } ${function:On-PeopleAutoItem} ${function:On-PeopleAutoDone})
}

function On-PeopleAutoItem($r) {
    Save-PersonCache $r
    if (-not $r.NotFound) { $Script:PeopleAutoDone++ }
    if ($Script:CurPerson -and $Script:CurPerson.Name -eq $r.Name -and $UI.navPeople.IsChecked) {
        $UI.txtPersonLoading.Visibility = 'Collapsed'
        if ($r.NotFound) { $UI.txtPersonFacts.Text = "TMDb doesn't have a profile for $($r.Name)." } else { Show-PersonDetails $r }
    }
}

function On-PeopleAutoDone($sync) {
    if ($sync.Error) { Write-Log "People: $($sync.Error)" }
    if ($Script:PeopleAutoDone -gt 0) { Status "Cast & crew details ready for $($Script:PeopleAutoDone) people." }
    Save-PersonDepts
    if ($UI.navPeople.IsChecked -and $UI.rbActors.IsChecked) { Refresh-People }   # newly known producers etc. drop off the Actors list
}

function Reset-PersonDetails {
    $UI.txtPersonFacts.Text = ''; $UI.txtPersonBio.Text = ''; $UI.txtPersonBio.MaxHeight = 120
    $UI.btnBioMore.Visibility = 'Collapsed'; $UI.btnPersonTmdb.Visibility = 'Collapsed'; $UI.btnPersonImdb.Visibility = 'Collapsed'
    $UI.capPersonMore.Visibility = 'Collapsed'; $UI.icPersonMore.ItemsSource = $null; $UI.txtPersonLoading.Visibility = 'Collapsed'
    $UI.bdPersonDone.Visibility = 'Collapsed'
}

function Request-PersonDetails([string]$name, [int]$id, [string]$kind) {
    $ck = $(if ($id) { "id:$id" } else { "name:$($name.ToLowerInvariant())" })
    $c = Get-PersonCache $name $id
    if ($c -and (PH-Date $c['Fetched']) -gt (Get-Date).AddDays(-90)) {
        if ($c['NotFound']) { $UI.txtPersonFacts.Text = "TMDb doesn't have a profile for $name." } else { Show-PersonDetails $c }
        return
    }
    if ($c -and $c['NotFound']) { $c = $null }
    if (-not $Settings.TmdbKey) { return }
    $UI.txtPersonLoading.Visibility = 'Visible'
    $Script:PersonCacheKey = $ck
    [void](Start-BgJob 'Person' $PersonWork @{ Key = $Settings.TmdbKey; Lang = $Settings.Language; Name = $name; Id = $id; Dept = $(if ($kind -eq 'Directors') { 'Directing' } else { 'Acting' }) } $null ${function:On-PersonDone})
    if ($c) { Show-PersonDetails $c }
}

function On-PersonDone($sync) {
    $r = $sync.Result
    if (-not $r) { $UI.txtPersonLoading.Visibility = 'Collapsed'; if ($sync.Error) { Write-Log "Person: $($sync.Error)" }; return }
    Save-PersonCache $r
    if ($Script:CurPerson -and $Script:CurPerson.Name -eq $r.Name) {
        $UI.txtPersonLoading.Visibility = 'Collapsed'
        if ($r.NotFound) { $UI.txtPersonFacts.Text = "TMDb doesn't have a profile for $($r.Name)." } else { Show-PersonDetails $r }
    }
}

function Show-PersonDetails($d) {
    if (-not $d) { return }
    $facts = @()
    $dept = [string]$d['Dept']
    if ($dept) { $facts += $(switch ($dept) { 'Acting' { 'Actor' } 'Directing' { 'Director' } 'Writing' { 'Writer' } 'Production' { 'Producer' } default { $dept } }) }
    $born = PH-Date $d['Birthday']; $died = PH-Date $d['Deathday']
    if ($born -gt [datetime]::MinValue) {
        $end = $(if ($died -gt [datetime]::MinValue) { $died } else { Get-Date })
        $age = $end.Year - $born.Year; if ($end.DayOfYear -lt $born.DayOfYear) { $age-- }
        $b = 'Born ' + $born.ToString('d MMMM yyyy'); if ($d['Place']) { $b += ' in ' + $d['Place'] }
        if ($died -le [datetime]::MinValue) { $b += " (age $age)" }
        $facts += $b
        if ($died -gt [datetime]::MinValue) { $facts += ('Died ' + $died.ToString('d MMMM yyyy') + " (aged $age)") }
    } elseif ($d['Place']) { $facts += ('From ' + $d['Place']) }
    $UI.txtPersonFacts.Text = ($facts -join '   ·   ')
    if ($d['Photo'] -and -not $UI.ibPerson.ImageSource) { $UI.ibPerson.ImageSource = Load-Bitmap ([string]$d['Photo']) 280 }
    elseif ($d['Photo']) { $UI.ibPerson.ImageSource = Load-Bitmap ([string]$d['Photo']) 280 }
    $bio = [string]$d['Bio']
    # drop Wikipedia-style pronunciation guides, e.g. "(/ˈtʃuːətəl …/ CHOO-ə-tel …; born 10 July 1977)"
    $bio = [regex]::Replace($bio, '\s*\((?=[^)]*/[^/)]{2,}/)[^)]*\)', '', 'None', [TimeSpan]::FromSeconds(1))
    $bio = [regex]::Replace($bio, '\s+([,.;])', '$1')
    $UI.txtPersonBio.Text = $(if ($bio) { $bio } else { 'No biography on TMDb yet.' })
    $UI.txtPersonBio.MaxHeight = 120
    $UI.btnBioMore.Content = 'Read more'
    $UI.btnBioMore.Visibility = $(if ($bio.Length -gt 420) { 'Visible' } else { 'Collapsed' })
    $Script:PersonLinks = @{ Tmdb = [int]$d['Id']; Imdb = [string]$d['Imdb'] }
    $UI.btnPersonTmdb.Visibility = $(if ([int]$d['Id'] -gt 0) { 'Visible' } else { 'Collapsed' })
    $UI.btnPersonImdb.Visibility = $(if ($d['Imdb']) { 'Visible' } else { 'Collapsed' })
    # other films you don't have
    $owned = New-Object 'Collections.Generic.HashSet[int]'
    foreach ($v in $Script:AllViews) { if ($v.TmdbId -gt 0) { [void]$owned.Add([int]$v.TmdbId) } }
    $today = Get-Date
    $more = @(@($d['Credits']) | Where-Object { $_ -and -not $owned.Contains([int]$_['Id']) -and ([int]$_['Votes'] -ge 5 -or (PH-Date $_['Release']) -gt $today) } |
              Sort-Object { [double]$_['Popularity'] } -Descending | Select-Object -First 36 | Sort-Object { if ([int]$_['Year']) { -[int]$_['Year'] } else { -9999 } })
    $items = foreach ($c in $more) {
        $rel = PH-Date $c['Release']; $coming = ($rel -eq [datetime]::MinValue -or $rel -gt $today)
        $sub = $(if ([int]$c['Year']) { [string]$c['Year'] } else { 'Date unknown' }); if ($c['Role']) { $sub += '  ·  ' + $c['Role'] }
        [pscustomobject]@{ IsFilm = $false; Key = ''; Title = [string]$c['Title']; Sub = $sub; Poster = $c['Poster']; Opac = 1.0
            Status = $(if ($coming) { 'COMING' } else { '' }); StatusBrush = $(if ($coming) { '#7B7266' } else { 'Transparent' })
            MissingVis = 'Visible'; RadarrTag = "radarr|$([int]$c['Id'])|$([string]$c['Title'])|$([int]$c['Year'])"; SeerrTag = "seerr|$([int]$c['Id'])|$([string]$c['Title'])"; TmdbTag = "tmdb|$([int]$c['Id'])" }
    }
    $UI.icPersonMore.ItemsSource = @($items)
    $UI.capPersonMore.Text = 'MORE FILMS  ·  ' + @($items).Count + ' you don''t have'
    $UI.capPersonMore.Visibility = $(if (@($items).Count) { 'Visible' } else { 'Collapsed' })
    Update-PersonCompletion
}

# =====================================================================================
#  Health
# =====================================================================================
$Script:HealthRows = @()
function Add-HealthRow($list, [string]$issue, $v, [string]$detail, [string]$path = '') {
    $film = ''; $shelf = ''; $key = ''
    if ($v) { $film = $v.Title + $(if ($v.Year) { " ($($v.Year))" } else { '' }); $shelf = $v.Shelf; $key = $v.Key; if (-not $path) { $path = $v.Path } }
    [void]$list.Add([pscustomobject]@{ Issue = $issue; Film = $film; Shelf = $shelf; Detail = $detail; Path = $path; Key = $key })
}

function Run-Health {
    $list = New-Object Collections.ArrayList
    # empty folders Radarr made for films that aren't out yet are not problems
    $waiting = @{}; foreach ($u in @($Script:Upcoming)) { $waiting[(Get-PathTail ([string]$u['Path']))] = $u }
    foreach ($e in @($Script:ScanErrors)) {
        $ep = [string]$e['Path']; $u = $waiting[(Get-PathTail $ep)]
        if ($u) {
            $ri = Get-ReleaseInfo $u
            if (-not $ri.Released) { continue }
            $when = $(if ($ri.Home -gt [datetime]::MinValue) { "$($ri.HomeKind) release was " + $ri.Home.ToString('d MMM yyyy') + " ($(Format-Countdown $ri.Home))" } else { 'Radarr says it is available now' })
            Add-HealthRow $list 'Released — still missing' $null "$($u['Title']) ($($u['Year'])): $when, but the folder is empty" $ep
            continue
        }
        Add-HealthRow $list ([string]$e['Type']) $null ([string]$e['Detail']) $ep
    }
    $byTmdb = @{}; $byName = @{}
    foreach ($v in $Script:AllViews) {
        $rec = $Script:Lib[$v.Key]; $m = $Script:Meta[$v.Key]
        if (-not $v.HasInfo) {
            $why = 'No film info yet'; if ($Script:MatchFail.ContainsKey($v.Key)) { $why = 'TMDb: ' + $Script:MatchFail[$v.Key] }
            Add-HealthRow $list 'Needs film info' $v $why
        }
        if (-not $v.Poster) { Add-HealthRow $list 'No poster' $v 'Fetch info, or add poster.jpg to the folder' }
        if ([int]$rec['Year'] -eq 0) { Add-HealthRow $list 'No year in the name' $v ('Rename to “' + $v.Title + $(if ($v.Year) { " ($($v.Year))" } else { ' (Year)' }) + '”') }
        if ($m -and $m['Source'] -eq 'tmdb') {
            $py = [int]$rec['Year']; $my = [int]$m['Year']
            if ($py -gt 0 -and $my -gt 0 -and [math]::Abs($py - $my) -gt 1) { Add-HealthRow $list 'Year differs from TMDb' $v "Name says $py, TMDb says $my — maybe the wrong match?" }
            $pn = PH-NormTitle ([string]$rec['Title'])
            if ($pn -and $pn -ne (PH-NormTitle ([string]$m['Title'])) -and $pn -ne (PH-NormTitle ([string]$m['OriginalTitle']))) {
                Add-HealthRow $list 'Name differs from TMDb' $v ('On the NAS: “' + $rec['Title'] + '”   ·   TMDb: “' + $m['Title'] + '”')
            }
        }
        if ($v.TmdbId -gt 0) { $k = [string]$v.TmdbId; if (-not $byTmdb.ContainsKey($k)) { $byTmdb[$k] = New-Object Collections.ArrayList }; [void]$byTmdb[$k].Add($v) }
        else { $k = (PH-NormTitle $v.Title) + '|' + $v.Year; if (-not $byName.ContainsKey($k)) { $byName[$k] = New-Object Collections.ArrayList }; [void]$byName[$k].Add($v) }
        if ($v.Res -eq 'SD' -and -not $rec['Disc']) { Add-HealthRow $list 'Standard definition' $v 'See the Upgrades tab to choose a better copy' }
        if ([int]$rec['Parts'] -gt 1) { Add-HealthRow $list 'Split into parts' $v ("$($rec['Parts']) files (CD1/CD2…) — plays as a playlist") }
        if (-not $rec['IsFolder']) { Add-HealthRow $list 'Not in its own folder' $v 'Radarr, Plex and Jellyfin prefer one folder per film' }
        elseif (-not $rec['Disc']) {
            $fn = PH-NormTitle ([IO.Path]::GetFileNameWithoutExtension([string]$rec['File']))
            $dn = PH-NormTitle ([IO.Path]::GetFileName([string]$rec['Path']))
            $dnNoYear = PH-NormTitle (PH-ParseName ([IO.Path]::GetFileName([string]$rec['Path']))).Title
            if ($fn -and $dnNoYear -and -not $fn.StartsWith($dnNoYear)) { Add-HealthRow $list 'File name ≠ folder name' $v ([IO.Path]::GetFileName([string]$rec['File'])) }
        }
    }
    foreach ($g in @($byTmdb.Values) + @($byName.Values)) {
        if ($g.Count -gt 1) { foreach ($v in $g) { Add-HealthRow $list 'Possible duplicate' $v ("$($g.Count) copies: " + (@($g | ForEach-Object { $_.Shelf + ' / ' + $_.Res }) -join '; ') + '  ·  see Upgrades → Duplicates') } }
    }
    foreach ($r in @($Script:RadarrRows)) { [void]$list.Add($r) }
    $Script:HealthRows = @($list | Sort-Object Issue, Film)
    $Script:Dirty.Health = $false
    Refresh-HealthFilter
}

function Refresh-HealthFilter {
    $counts = @($Script:HealthRows | Group-Object Issue | Sort-Object Name)
    $items = @("Everything ($($Script:HealthRows.Count))") + @($counts | ForEach-Object { "$($_.Name) ($($_.Count))" })
    $prev = [string]$UI.cbHealthFilter.SelectedItem
    $prevName = $prev -replace ' \(\d+\)$', ''
    $Script:Loading = $true
    $UI.cbHealthFilter.ItemsSource = $items
    $hit = @($items | Where-Object { ($_ -replace ' \(\d+\)$', '') -eq $prevName })
    if ($hit.Count) { $UI.cbHealthFilter.SelectedItem = $hit[0] } else { $UI.cbHealthFilter.SelectedIndex = 0 }
    $Script:Loading = $false
    Apply-HealthFilter
    $UI.wpHealthSummary.Children.Clear()
    foreach ($c in ($counts | Sort-Object Count -Descending | Select-Object -First 8)) {
        $chip = New-Chip ("$($c.Name)  $($c.Count)") ("health|" + $c.Name) '#FFFCF6'
        $chip.BorderBrush = (New-Object Windows.Media.BrushConverter).ConvertFromString('#E2D9C9'); $chip.BorderThickness = New-Object Windows.Thickness 1
        $chip.Add_MouseLeftButtonUp({ $n = ([string]$this.Tag).Substring(7); $hit = @($UI.cbHealthFilter.Items | Where-Object { ($_ -replace ' \(\d+\)$', '') -eq $n }); if ($hit.Count) { $UI.cbHealthFilter.SelectedItem = $hit[0] } })
        [void]$UI.wpHealthSummary.Children.Add($chip)
    }
}
function Apply-HealthFilter {
    $sel = ([string]$UI.cbHealthFilter.SelectedItem) -replace ' \(\d+\)$', ''
    if (-not $sel -or $sel -eq 'Everything') { $UI.dgHealth.ItemsSource = $Script:HealthRows }
    else { $UI.dgHealth.ItemsSource = @($Script:HealthRows | Where-Object { $_.Issue -eq $sel }) }
}

$Script:RadarrRows = @()
function Compare-Radarr {
    if (-not $Settings.RadarrUrl -or -not $Settings.RadarrKey) { Tell 'Add your Radarr address and API key in Settings first.'; return }
    Invoke-Async 'Asking Radarr for its film list…' { param($v) @(Invoke-Radarr 'GET' '/movie' $null) } @{} { param($r) Compare-RadarrDone @($r | Where-Object { $_ }) } { param($err) Tell ("Couldn't connect to Radarr.`n`n" + $err) 'Warning' }
}
function Compare-RadarrDone($movies) {
    $mine = @{}; foreach ($v in $Script:AllViews) { if ($v.TmdbId -gt 0) { $mine[[string]$v.TmdbId] = $v } }
    $theirs = @{}; foreach ($m in $movies) { $theirs[[string]$m.tmdbId] = $m }
    $list = New-Object Collections.ArrayList
    $notOut = 0
    foreach ($m in $movies) {
        $k = [string]$m.tmdbId
        $label = [string]$m.title + $(if ($m.year) { " ($($m.year))" } else { '' })
        if ($m.hasFile -and -not $mine.ContainsKey($k)) {
            [void]$list.Add([pscustomobject]@{ Issue = 'Radarr: has file, not found in scan'; Film = $label; Shelf = ''; Detail = 'Path differs, hidden shelf, or not matched here yet'; Path = [string]$m.path; Key = '' })
        } elseif (-not $m.hasFile -and $m.monitored -and -not $mine.ContainsKey($k)) {
            $ri = Get-ReleaseInfo @{ InCinemas = $m.inCinemas; Digital = $m.digitalRelease; Physical = $m.physicalRelease; Available = [bool]$m.isAvailable }
            if (-not $ri.Released) { $notOut++; continue }
            $when = $(if ($ri.Home -gt [datetime]::MinValue) { "$($ri.HomeKind) release was " + $ri.Home.ToString('d MMM yyyy') + " ($(Format-Countdown $ri.Home))" } else { 'Radarr says it is available now' })
            [void]$list.Add([pscustomobject]@{ Issue = 'Released — still missing'; Film = $label; Shelf = (Get-ShelfForRadarrPath ([string]$m.path)); Detail = "$when — check Radarr's queue/indexers"; Path = [string]$m.path; Key = '' })
        } elseif (-not $m.hasFile -and $m.monitored) {
            $hereToo = $mine.ContainsKey($k)
            [void]$list.Add([pscustomobject]@{ Issue = $(if ($hereToo) { 'Radarr: thinks it is missing' } else { 'Radarr: wanted (no file yet)' }); Film = $label; Shelf = $(if ($hereToo) { $mine[$k].Shelf } else { '' })
                Detail = $(if ($hereToo) { "It's on your NAS — Radarr may need a rescan of that folder" } else { 'Monitored, waiting for a download' }); Path = [string]$m.path; Key = $(if ($hereToo) { $mine[$k].Key } else { '' }) })
        }
    }
    foreach ($k in $mine.Keys) {
        if (-not $theirs.ContainsKey($k)) { $v = $mine[$k]; Add-HealthRow $list 'Not in Radarr' $v 'Radarr is not tracking this film' }
    }
    $Script:RadarrRows = $list.ToArray()
    Run-Health
    Status "Compared with Radarr: $($movies.Count) films in Radarr, $($list.Count) differences$(if ($notOut) { ", $notOut not released yet (see Coming soon)" })."
    Start-UpcomingFetch
}

# =====================================================================================
#  Upgrades & duplicates — a list to decide from; Radarr only searches when you press the button
# =====================================================================================
$Script:RadarrMovies = $null   # tmdb id -> what Radarr knows (its id, profile, whether the profile wants better)
$RadarrListWork = {
    param($sync, $p)
    $sync.Status = 'Asking Radarr about your films…'
    $h = @{ 'X-Api-Key' = $p.Key; Accept = 'application/json' }
    $profiles = @{}
    try { foreach ($q in (Invoke-RestMethod -Uri ($p.Url + '/api/v3/qualityprofile') -Headers $h -TimeoutSec 60 -UseBasicParsing)) { $profiles[[string]$q.id] = [string]$q.name } } catch {}
    $r = Invoke-RestMethod -Uri ($p.Url + '/api/v3/movie') -Headers $h -TimeoutSec 120 -UseBasicParsing
    $out = @{}
    foreach ($m in $r) {
        if (-not $m.tmdbId) { continue }
        $q = ''; $cut = $false
        if ($m.movieFile) { $q = [string]$m.movieFile.quality.quality.name; $cut = [bool]$m.movieFile.qualityCutoffNotMet }
        $out[[string]$m.tmdbId] = @{ Id = [int]$m.id; HasFile = [bool]$m.hasFile; CutoffNotMet = $cut; FileQuality = $q
                                     Profile = [string]$profiles[[string]$m.qualityProfileId]; Monitored = [bool]$m.monitored }
    }
    $sync.Result = $out
}
function Start-RadarrMoviesFetch([switch]$Quiet) {
    if (-not $Settings.RadarrUrl -or -not $Settings.RadarrKey) { if (-not $Quiet) { Tell 'Add your Radarr address and API key in Settings first.' }; return }
    if (Test-Busy 'RadarrList') { return }
    $Script:RadarrListQuiet = [bool]$Quiet
    [void](Start-BgJob 'RadarrList' $RadarrListWork @{ Url = (Normalize-ServiceUrl $Settings.RadarrUrl); Key = ([string]$Settings.RadarrKey).Trim() } $null ${function:On-RadarrMoviesDone})
}
function On-RadarrMoviesDone($sync) {
    if ($sync.Error -or -not $sync.Result) {
        Write-Log "Radarr film list: $($sync.Error)"
        if (-not $Script:RadarrListQuiet) { Tell ("Couldn't get the film list from Radarr.`n`n" + $sync.Error) 'Warning' }
        return
    }
    $Script:RadarrMovies = $sync.Result
    Status "Radarr knows $($Script:RadarrMovies.Count) films."
    if ($UI.navUpgrades.IsChecked) { Refresh-Upgrades }
}

# ---- After asking Radarr to do something, keep an eye on it and say what happened ----
$Script:RadarrActivity = @{}   # tmdb id -> latest news, shown on the Upgrades page
$RadarrWatchWork = {
    param($sync, $p)
    $h = @{ 'X-Api-Key' = $p.Key; Accept = 'application/json' }
    $base = $p.Url + '/api/v3'
    $since = [datetime]::UtcNow.AddMinutes(-1)
    $msg = ''; $state = ''
    if ($p.CmdId) {
        # 1) wait for the search command to finish (up to 4 minutes)
        $t0 = Get-Date
        while (((Get-Date) - $t0).TotalSeconds -lt 240 -and -not $sync.Cancel) {
            $sync.Status = "Radarr is searching for $($p.Title)…" + $(if ($state) { "  ($state)" } else { '' })
            try { $c = Invoke-RestMethod -Uri "$base/command/$($p.CmdId)" -Headers $h -TimeoutSec 20 -UseBasicParsing; $state = [string]$c.status; $msg = [string]$c.message } catch {}
            if ($state -in @('completed', 'failed', 'aborted', 'cancelled', 'orphaned')) { break }
            Start-Sleep -Seconds 3
        }
    }
    # 2) did it grab anything? check the download queue (several times if the film was only just added)
    $tries = $(if ($p.CmdId) { 3 } elseif ($p.Mode -eq 'grab') { 8 } else { 18 })
    $grab = $null
    for ($i = 0; $i -lt $tries -and -not $grab -and -not $sync.Cancel; $i++) {
        $sync.Status = "Checking Radarr's downloads for $($p.Title)…"
        try {
            foreach ($q in (Invoke-RestMethod -Uri "$base/queue/details?movieId=$($p.MovieId)" -Headers $h -TimeoutSec 20 -UseBasicParsing)) {
                if ($q -and $q.title) { $grab = @{ Release = [string]$q.title; Quality = [string]$q.quality.quality.name; Size = [double]$q.size; Client = [string]$q.downloadClient; State = [string]$q.status }; break }
            }
        } catch {}
        if (-not $grab) {
            try {
                foreach ($e in (Invoke-RestMethod -Uri "$base/history/movie?movieId=$($p.MovieId)&eventType=1" -Headers $h -TimeoutSec 20 -UseBasicParsing)) {
                    if (-not $e) { continue }
                    $d = [datetime]::MinValue
                    if ($e.date -is [datetime]) { $d = $e.date.ToUniversalTime() } else { [void][datetime]::TryParse([string]$e.date, [Globalization.CultureInfo]::InvariantCulture, [Globalization.DateTimeStyles]::AdjustToUniversal, [ref]$d) }
                    if ($d -ge $since) { $grab = @{ Release = [string]$e.sourceTitle; Quality = [string]$e.quality.quality.name; Size = 0; Client = ''; State = 'grabbed' }; break }
                }
            } catch {}
        }
        if (-not $grab -and $i -lt $tries - 1) { Start-Sleep -Seconds 5 }
    }
    $sync.Result = @{ Title = $p.Title; TmdbId = $p.TmdbId; State = $state; Message = $msg; Grab = $grab; Added = ($p.Mode -eq 'add'); Picked = ($p.Mode -eq 'grab') }
}
function Start-RadarrWatch([int]$movieId, [int]$cmdId, [string]$title, [int]$tmdbId, [string]$mode = '') {
    # mode: '' = after a search command, 'add' = just added with a search, 'grab' = you picked a copy
    if ($movieId -le 0) { return }
    if (-not $mode) { $mode = $(if ($cmdId) { 'search' } else { 'add' }) }
    [void](Start-BgJob 'RadarrWatch' $RadarrWatchWork @{ Url = (Normalize-ServiceUrl $Settings.RadarrUrl); Key = ([string]$Settings.RadarrKey).Trim()
        MovieId = $movieId; CmdId = $cmdId; Title = $title; TmdbId = $tmdbId; Mode = $mode } $null ${function:On-RadarrWatchDone})
}
function On-RadarrWatchDone($sync) {
    $r = $sync.Result
    if (-not $r) { Show-Toast "Couldn't hear back from Radarr" ([string]$sync.Error) 'warn'; return }
    $news = ''
    if ($r.Picked) {
        if ($r.Grab) {
            $g = $r.Grab
            Show-Toast "$($r.Title) is downloading" ("Your pick reached $(if ($g.Client) { $g.Client } else { 'the download client' }): $($g.Release)`nRadarr swaps it in when it finishes.") 'ok' 14
            $news = "Downloading the $($g.Quality) copy you picked"
        } else {
            Show-Toast "Radarr took your pick for $($r.Title)" 'It isn''t showing in the download queue yet — look in Radarr → Activity → Queue in a minute.' 'wait' 14
        }
    } elseif ($r.Grab) {
        $g = $r.Grab
        $what = $(if ($g.Quality) { "a $($g.Quality) copy" } else { 'a copy' })
        $size = $(if ($g.Size -gt 0) { '  ·  ' + (Format-Size $g.Size) } else { '' })
        $how = $(if ($g.Client) { "Downloading with $($g.Client)$size." } else { "Sent to your download client$size." })
        Show-Toast "Radarr found $what of $($r.Title)" ("$how`n$($g.Release)`nRadarr swaps it in when the download finishes.") 'ok' 15
        $news = "Radarr grabbed $what — downloading now"
    } elseif ($r.State -eq 'failed') {
        Show-Toast "Radarr's search for $($r.Title) failed" ($(if ($r.Message) { $r.Message } else { 'Check Radarr → System → Logs.' })) 'warn' 15
        $news = 'The last search failed — see Radarr''s logs'
    } elseif ($r.Added) {
        Show-Toast "$($r.Title) is in Radarr" 'Radarr is looking for it but hasn''t grabbed anything yet. It keeps checking by itself and it will show in Radarr''s Activity when it does.' 'ok' 12
    } else {
        Show-Toast "Radarr searched for $($r.Title) — nothing better yet" ('Nothing on your indexers beat what its quality profile wants right now.' + $(if ($r.Message) { "`nRadarr said: $($r.Message)" } else { '' })) 'wait' 15
        $news = 'Searched ' + (Get-Date).ToString('HH:mm') + ' — nothing better found yet'
    }
    Write-Log ("Radarr: " + $(if ($r.Grab) { "grabbed $($r.Grab.Release) for $($r.Title)" } else { "nothing grabbed for $($r.Title) (command $($r.State): $($r.Message))" }))
    if ($r.TmdbId -and $news) { $Script:RadarrActivity[[string]$r.TmdbId] = $news }
    if ($UI.navUpgrades.IsChecked) { Refresh-Upgrades }
}

$QualityBrush = @{ 'SD' = '#C8432B'; '720p' = '#D9902F'; '1080p' = '#3F86B0'; '4K' = '#3E8E4F' }
$QualityRank = @{ 'SD' = 1; '720p' = 2; '1080p' = 3; '4K' = 4 }
function Refresh-Upgrades {
    $vis = (Get-VisibleViews).ToArray()   # it returns a List — @() would wrap the whole List as one item
    $rows = New-Object Collections.ArrayList
    $mode = $(if ($UI.rbUpDupes.IsChecked) { 'dupes' } elseif ($UI.rbUp4K.IsChecked) { '4k' } else { '1080' })
    $pick = @()
    if ($mode -eq 'dupes') {
        $groups = @{}
        foreach ($v in $vis) {
            $k = $(if ($v.TmdbId -gt 0) { 't' + $v.TmdbId } else { 'n' + (PH-NormTitle $v.Title) + '|' + $v.Year })
            if (-not $groups.ContainsKey($k)) { $groups[$k] = New-Object Collections.ArrayList }
            [void]$groups[$k].Add($v)
        }
        foreach ($g in @($groups.Values | Where-Object { $_.Count -gt 1 } | Sort-Object { $_[0].SortTitle })) {
            $i = 0
            foreach ($v in @($g | Sort-Object { - [int]$QualityRank[[string]$_.Res] }, { - [double]$_.Size })) {
                $i++
                $others = @($g | Where-Object { $_.Key -ne $v.Key } | ForEach-Object { "$(if ($_.Res) { $_.Res } else { '?' }) on $($_.Shelf)" }) -join ', '
                $pick += , @($v, "Copy $i of $($g.Count)  ·  also: $others")
            }
        }
    } else {
        $limit = $(if ($mode -eq '4k') { 4 } else { 3 })
        foreach ($v in @($vis | Where-Object { $_.Res -and [int]$QualityRank[[string]$_.Res] -gt 0 -and [int]$QualityRank[[string]$_.Res] -lt $limit } |
                         Sort-Object { [int]$QualityRank[[string]$_.Res] }, SortTitle)) { $pick += , @($v, '') }
    }
    $inRadarr = 0; $wants = 0
    foreach ($x in $pick) {
        $v = $x[0]; $extra = $x[1]
        $rec = $Script:Lib[$v.Key]
        $bits = @(); if ($v.Year) { $bits += [string]$v.Year }; $bits += $v.Shelf; if ($v.Size -gt 0) { $bits += (Format-Size $v.Size) }
        if ($rec -and $rec['Disc']) { $bits += 'DVD / Blu-ray folder' }
        if ($extra) { $bits += $extra }
        $rm = $null; if ($Script:RadarrMovies -and $v.TmdbId -gt 0) { $rm = $Script:RadarrMovies[[string]$v.TmdbId] }
        if (-not $Script:RadarrMovies) { $rt = 'Press “Check with Radarr” to see what Radarr thinks of this copy.'; $rb = '#7B7266' }
        elseif (-not $rm) { $rt = 'Not in Radarr — add it there first if you want Radarr to find a better copy.'; $rb = '#7B7266' }
        else {
            $inRadarr++
            $prof = $(if ($rm['Profile']) { "‘$($rm['Profile'])’" } else { 'its quality profile' })
            $have = $(if ($rm['FileQuality']) { " (Radarr sees $($rm['FileQuality']))" } else { '' })
            if (-not $rm['HasFile']) { $rt = "In Radarr, but Radarr doesn't see the file — it may need a rescan of that folder."; $rb = '#D9902F' }
            elseif ($rm['CutoffNotMet']) { $wants++; $rt = "In Radarr  ·  $prof would upgrade this$have"; $rb = '#2A7F7A' }
            else { $rt = "In Radarr  ·  $prof is happy with this copy$have — a search won't replace it unless you change the profile in Radarr."; $rb = '#7B7266' }
        }
        $act = $Script:RadarrActivity[[string]$v.TmdbId]
        if ($act) { $rt = "$act   ·   $rt"; $rb = '#173F3E' }
        $q = $(if ($v.Res) { $v.Res } else { '?' })
        [void]$rows.Add([pscustomobject]@{
            Key = $v.Key; Title = $v.Title; Sub = ($bits -join '   ·   '); Poster = $(if ($v.Poster) { $v.Poster } else { $null })
            Quality = $q; QBrush = $(if ($QualityBrush[$q]) { $QualityBrush[$q] } else { '#7B7266' })
            RadarrText = $rt; RadarrBrush = $rb
            SearchTag = "search|$($v.Key)"; ChooseTag = "choose|$($v.Key)"; SearchVis = $(if ($rm -and $rm['HasFile']) { 'Visible' } else { 'Collapsed' })
            AddTag = "add|$($v.Key)"; AddVis = $(if ($Script:RadarrMovies -and -not $rm -and $v.TmdbId -gt 0) { 'Visible' } else { 'Collapsed' })
            FolderTag = "folder|$($v.Key)"; DetailTag = "detail|$($v.Key)" })
    }
    $UI.lbUpgrades.ItemsSource = $rows.ToArray()
    $n = $rows.Count
    switch ($mode) {
        '1080' { $s = "$n film$(if ($n -ne 1) { 's' }) below 1080p (SD and 720p)" }
        '4k'   { $s = "$n film$(if ($n -ne 1) { 's' }) below 4K" }
        'dupes' { $s = "$n cop$(if ($n -ne 1) { 'ies' } else { 'y' }) of films you have more than once — best quality listed first. Nothing is deleted; open the folders and decide." }
    }
    if ($mode -ne 'dupes' -and $Script:RadarrMovies) { $s += "  ·  $inRadarr in Radarr, $wants of them below what their Radarr profile wants" }
    $UI.txtUpSummary.Text = $s
    $UI.txtUpEmpty.Text = $(switch ($mode) { 'dupes' { 'No duplicates — every film is on your shelves once.' } '4k' { 'Everything is already 4K.' } default { 'Nothing below 1080p. Nice.' } })
    $UI.txtUpEmpty.Visibility = $(if ($n) { 'Collapsed' } else { 'Visible' })
}

function Invoke-UpgradeButton([string]$tag) {
    $bits = $tag.Split([char]'|', 2); $key = $bits[1]
    $v = $Script:ViewByKey[$key]; if (-not $v) { return }
    switch ($bits[0]) {
        'folder' { Open-FilmFolder $key }
        'detail' { Show-Detail $key }
        'add'    { Show-RadarrAdd ([int]$v.TmdbId) $v.Title ([int]$v.Year); Start-RadarrMoviesFetch -Quiet }
        'choose' {
            $rm = $Script:RadarrMovies[[string]$v.TmdbId]; if (-not $rm) { return }
            $label = $v.Title + $(if ($v.Year) { " ($($v.Year))" } else { '' })
            $cur = "Your copy: $(if ($v.Res) { $v.Res } else { 'quality unknown' })$(if ($v.Size -gt 0) { '  ·  ' + (Format-Size $v.Size) })$(if ($rm['FileQuality']) { "  (Radarr sees $($rm['FileQuality']))" })"
            Show-ReleasePicker ([int]$rm['Id']) $label $cur ([int]$v.TmdbId)
        }
        'search' {
            $rm = $Script:RadarrMovies[[string]$v.TmdbId]; if (-not $rm) { return }
            $prof = $(if ($rm['Profile']) { "‘$($rm['Profile'])’" } else { 'its quality profile' })
            $label = $v.Title + $(if ($v.Year) { " ($($v.Year))" } else { '' })
            $msg = "Ask Radarr to search for a better copy of ${label}?`n`n" +
                   "Your copy: $(if ($v.Res) { $v.Res } else { 'quality unknown' })$(if ($rm['FileQuality']) { " (Radarr sees $($rm['FileQuality']))" })`n`n" +
                   "Radarr will look on your indexers now. If it finds a release that $prof prefers, it will download it and replace this copy. "
            if ($rm['CutoffNotMet']) { $msg += "$prof says this copy can be improved, so an upgrade is likely if one is out there." }
            else { $msg += "Heads up: $prof is already happy with this copy, so Radarr probably won't grab anything unless you raise the profile in Radarr first." }
            $msg += "`n`nNo other film is touched."
            if (-not (Ask $msg)) { return }
            try {
                $cmd = @(Invoke-Radarr 'POST' '/command' @{ name = 'MoviesSearch'; movieIds = @([int]$rm['Id']) }) | Select-Object -First 1
                Write-Log "Upgrades: asked Radarr to search for $label (Radarr id $($rm['Id']), command $($cmd.id))."
                Show-Toast "Radarr is searching for $label" "I'll let you know here what it finds — usually within a minute." 'wait' 8
                $Script:RadarrActivity[[string]$v.TmdbId] = 'Searching now…'
                Refresh-Upgrades
                Start-RadarrWatch ([int]$rm['Id']) ([int]$cmd.id) $label ([int]$v.TmdbId)
            } catch { Tell ("Radarr didn't accept the search.`n`n" + $_.Exception.Message) 'Warning' }
        }
    }
}

# =====================================================================================
#  Stats
# =====================================================================================
function New-Bars($pairs, [string]$color, [int]$max = 12, [string]$fmt = '{0:N0}') {
    $arr = @($pairs | Select-Object -First $max)
    $top = 1.0; foreach ($p in $arr) { if ([double]$p.Value -gt $top) { $top = [double]$p.Value } }
    return @($arr | ForEach-Object {
        $c = $color; if ($_.Color) { $c = $_.Color }
        $frac = [math]::Max(0.01, [math]::Min(1.0, [double]$_.Value / $top))
        [pscustomobject]@{ Label = [string]$_.Label; Brush = $c; ValueText = ($fmt -f [double]$_.Value)
                           BarStar = ($frac.ToString('0.####', [Globalization.CultureInfo]::InvariantCulture) + '*')
                           RestStar = (([math]::Max(0.0001, 1.0 - $frac)).ToString('0.####', [Globalization.CultureInfo]::InvariantCulture) + '*') } })
}

function Refresh-Stats {
    $Script:Dirty.Stats = $false
    $vis = Get-VisibleViews
    $n = $vis.Count
    $size = 0.0; $mins = 0; $seen = 0; $seenYear = 0; $rated = 0; $rsum = 0.0
    $yr = (Get-Date).Year
    foreach ($v in $vis) {
        $size += $v.Size; $mins += $v.Runtime
        if ($v.Watched) { $seen++; $u = $Script:User[$v.Key]; if ($u -and (PH-Date $u['WatchedOn']).Year -eq $yr) { $seenYear++ } }
        if ($v.Rating -gt 0) { $rated++; $rsum += $v.Rating }
    }
    $colls = @(Get-CollectionRows | Where-Object { $_.Id -gt 0 })
    $complete = @($colls | Where-Object { $_.State -eq 'complete' }).Count
    $UI.txtStatsSub.Text = $(if ($Settings.LastScan) { 'As of the last scan, ' + (PH-Date $Settings.LastScan).ToString('d MMMM yyyy, HH:mm') } else { '' })
    $UI.icStatCards.ItemsSource = @(
        [pscustomobject]@{ Value = ('{0:N0}' -f $n); Label = 'films'; Sub = ('{0} shelves' -f @($UI.lbShelves.Items).Count); Brush = '#C8432B' },
        [pscustomobject]@{ Value = (Format-Size $size); Label = 'on the NAS'; Sub = $(if ($n) { 'avg ' + (Format-Size ($size / $n)) + ' a film' } else { '' }); Brush = '#173F3E' },
        [pscustomobject]@{ Value = ('{0:N0} h' -f ($mins / 60)); Label = 'of running time'; Sub = ('{0:N1} days back to back' -f ($mins / 1440)); Brush = '#D9902F' },
        [pscustomobject]@{ Value = $(if ($n) { '{0:0}%' -f (100 * $seen / $n) } else { '0%' }); Label = 'watched'; Sub = "$seen films · $seenYear this year"; Brush = '#3E8E4F' },
        [pscustomobject]@{ Value = $(if ($rated) { '{0:0.0}' -f ($rsum / $rated) } else { '–' }); Label = 'average TMDb rating'; Sub = "$rated rated films"; Brush = '#5B6FB0' },
        [pscustomobject]@{ Value = "$complete / $(@($colls).Count)"; Label = 'complete collections'; Sub = 'see the Collections tab'; Brush = '#8E4C8F' }
    )
    $genrePairs = @($vis | ForEach-Object { $_.Genres } | Where-Object { $_ } | Group-Object | Sort-Object Count -Descending | ForEach-Object { @{ Label = $_.Name; Value = $_.Count } })
    $dirPairs = @($vis | ForEach-Object { $_.DirectorNames } | Where-Object { $_ } | Group-Object | Where-Object { $_.Count -gt 1 } | Sort-Object Count -Descending | ForEach-Object { @{ Label = $_.Name; Value = $_.Count } })
    $actPairs = @($vis | ForEach-Object { @($_.CastNames | Select-Object -First 8) } | Where-Object { $_ } | Group-Object | Where-Object { $_.Count -gt 1 } | Sort-Object Count -Descending | ForEach-Object { @{ Label = $_.Name; Value = $_.Count } })
    $sizePairs = @($vis | Group-Object { ($_.Shelf -split ' › ')[0] } | ForEach-Object { $s = 0.0; foreach ($x in $_.Group) { $s += $x.Size }; @{ Label = $_.Name; Value = ($s / 1GB); Color = (Get-ShelfColor $_.Name) } } | Sort-Object { $_.Value } -Descending)
    try { Build-StatCharts $vis } catch { Write-Log ("Charts: " + $_.Exception.Message + "`n" + $_.InvocationInfo.PositionMessage + "`n" + $_.ScriptStackTrace) }
    $UI.icStatCharts.ItemsSource = @(
        [pscustomobject]@{ Title = 'Top genres'; Rows = (New-Bars $genrePairs '#5B6FB0' 12) },
        [pscustomobject]@{ Title = 'Space per shelf (GB)'; Rows = (New-Bars $sizePairs '#173F3E' 14 '{0:N0}') },
        [pscustomobject]@{ Title = 'Most collected directors'; Rows = (New-Bars $dirPairs '#B5576B' 10) },
        [pscustomobject]@{ Title = 'Most seen faces'; Rows = (New-Bars $actPairs '#3E8E4F' 10) }
    )
}

# =====================================================================================
#  Year in review
# =====================================================================================
function Get-WatchedOn($v) { $u = $Script:User[$v.Key]; if ($u -and $u['Watched']) { return (PH-Date $u['WatchedOn']) }; return [datetime]::MinValue }

function Get-YearOptions {
    $years = New-Object 'Collections.Generic.SortedSet[int]'
    foreach ($v in (Get-VisibleViews)) {
        $w = Get-WatchedOn $v; if ($w -gt [datetime]::MinValue) { [void]$years.Add($w.Year) }
        if ($v.Added -gt [datetime]::MinValue) { [void]$years.Add($v.Added.Year) }
    }
    [void]$years.Add((Get-Date).Year)
    return @($years | Sort-Object -Descending)
}

function Get-YearData([int]$y) {
    $vis = (Get-VisibleViews).ToArray()   # it returns a List — @() would wrap the whole List as one item
    $seen = @($vis | ForEach-Object { $w = Get-WatchedOn $_; if ($w.Year -eq $y) { [pscustomobject]@{ V = $_; On = $w } } } | Sort-Object On)
    $added = @($vis | Where-Object { $_.Added.Year -eq $y })
    $mins = 0; foreach ($x in $seen) { $mins += $x.V.Runtime }
    $films = @($seen | ForEach-Object { $_.V })
    $top = { param($items) @($items | Where-Object { $_ } | Group-Object | Sort-Object @{ e = { $_.Count }; d = $true }, Name) }
    $shelf = & $top @($films | ForEach-Object { ($_.Shelf -split ' › ')[0] })
    $genre = & $top @($films | ForEach-Object { $_.Genres })
    $faces = & $top @($films | ForEach-Object { @($_.CastNames | Select-Object -First 8) })
    $dirs = & $top @($films | ForEach-Object { $_.DirectorNames })
    $longest = @($films | Where-Object { $_.Runtime -gt 0 } | Sort-Object Runtime -Descending | Select-Object -First 1)
    $oldest = @($films | Where-Object { $_.Year -gt 0 } | Sort-Object Year | Select-Object -First 1)
    $best = @($films | Where-Object { $_.MyRating -gt 0 } | Sort-Object @{ e = { $_.MyRating }; d = $true }, @{ e = { $_.Rating }; d = $true } | Select-Object -First 1)
    $bestIsMine = $true
    if (-not $best.Count) { $best = @($films | Where-Object { $_.Rating -gt 0 } | Sort-Object Rating -Descending | Select-Object -First 1); $bestIsMine = $false }
    $months = @(1..12 | ForEach-Object { $m = $_; @{ Label = (Get-Date -Year 2000 -Month $m -Day 1).ToString('MMMM'); Value = @($seen | Where-Object { $_.On.Month -eq $m }).Count } })
    $busiest = @($months | Sort-Object { $_.Value } -Descending | Select-Object -First 1)
    $size = 0.0; foreach ($v in $added) { $size += $v.Size }
    return @{ Year = $y; Seen = $seen; Films = $films; Added = $added; Mins = $mins; AddedSize = $size
              Shelf = $shelf; Genre = $genre; Faces = $faces; Dirs = $dirs; Longest = $longest; Oldest = $oldest; Best = $best; BestIsMine = $bestIsMine
              Months = $months; Busiest = $busiest }
}

function Refresh-Year {
    $years = Get-YearOptions
    $cur = 0; if ($UI.cbYear.SelectedItem) { $cur = [int]$UI.cbYear.SelectedItem }
    $Script:Loading = $true
    try {
        $UI.cbYear.ItemsSource = $years
        if ($cur -and $years -contains $cur) { $UI.cbYear.SelectedItem = $cur } else { $UI.cbYear.SelectedItem = $years[0] }
    } finally { $Script:Loading = $false }
    $d = Get-YearData ([int]$UI.cbYear.SelectedItem)
    $n = $d.Films.Count; $hrs = [math]::Round($d.Mins / 60.0)
    $UI.txtYearKicker.Text = (("YOUR $($d.Year) IN FILM").ToCharArray() -join ' ')
    if ($n -eq 0) {
        $UI.txtYearHero.Text = "Nothing marked as watched in $($d.Year) yet."
        $UI.txtYearHeroSub.Text = $(if ($d.Added.Count) { "But $($d.Added.Count) film$(if ($d.Added.Count -ne 1) { 's' }) joined your shelves." } else { 'Tick films as watched (or let Picture House do it when you play them) and they''ll show up here.' })
    } else {
        $UI.txtYearHero.Text = "You watched $n film$(if ($n -ne 1) { 's' }) — $hrs hour$(if ($hrs -ne 1) { 's' }) of cinema."
        $bits = @()
        if ($d.Genre.Count) { $bits += "mostly $($d.Genre[0].Name.ToLowerInvariant())" }
        if ($d.Faces.Count -and $d.Faces[0].Count -gt 1) { $bits += "with a lot of $($d.Faces[0].Name)" }
        if ($d.Busiest.Count -and $d.Busiest[0].Value -gt 0) { $bits += "and $($d.Busiest[0].Label) was your busiest month" }
        $UI.txtYearHeroSub.Text = $(if ($bits.Count) { ([string]::Join(', ', $bits)).Substring(0, 1).ToUpper() + ([string]::Join(', ', $bits)).Substring(1) + '.' } else { '' })
    }
    $card = { param($label, $value, $sub, $brush) [pscustomobject]@{ Label = $label; Value = $value; Sub = $sub; Brush = $brush } }
    $cards = @(
        (& $card 'FILMS WATCHED' ('{0:N0}' -f $n) ("$hrs hours  ·  {0:N1} days back to back" -f ($d.Mins / 1440.0)) '#C8432B'),
        (& $card 'FAVOURITE SHELF' $(if ($d.Shelf.Count) { $d.Shelf[0].Name } else { '–' }) $(if ($d.Shelf.Count) { "$($d.Shelf[0].Count) films" } else { '' }) '#173F3E'),
        (& $card 'FAVOURITE GENRE' $(if ($d.Genre.Count) { $d.Genre[0].Name } else { '–' }) $(if ($d.Genre.Count) { "$($d.Genre[0].Count) films" } else { '' }) '#5B6FB0'),
        (& $card 'BUSIEST MONTH' $(if ($n -and $d.Busiest.Count) { $d.Busiest[0].Label } else { '–' }) $(if ($n -and $d.Busiest.Count) { "$($d.Busiest[0].Value) films" } else { '' }) '#D9902F'),
        (& $card 'LONGEST SIT' $(if ($d.Longest.Count) { $d.Longest[0].Title } else { '–' }) $(if ($d.Longest.Count) { $d.Longest[0].RuntimeText } else { '' }) '#8E4C8F'),
        (& $card 'OLDEST FILM' $(if ($d.Oldest.Count) { $d.Oldest[0].Title } else { '–' }) $(if ($d.Oldest.Count) { "from $($d.Oldest[0].Year)" } else { '' }) '#7B5B3A'),
        (& $card $(if ($d.BestIsMine) { 'YOUR TOP RATED' } else { 'BEST RATED ON TMDb' }) $(if ($d.Best.Count) { $d.Best[0].Title } else { '–' }) $(if ($d.Best.Count) { $(if ($d.BestIsMine) { $d.Best[0].MyStars } else { '★ {0:0.0}' -f $d.Best[0].Rating }) } else { '' }) '#B5576B'),
        (& $card 'NEW ON YOUR SHELVES' ('{0:N0}' -f $d.Added.Count) $(if ($d.Added.Count) { (Format-Size $d.AddedSize) + ' added' } else { 'nothing added' }) '#3E8E4F')
    )
    $UI.icYearCards.ItemsSource = $cards
    $UI.icYearCards.Visibility = $(if ($n) { 'Visible' } else { 'Collapsed' })   # no "–" cards when nothing's been watched
    $pairs = { param($g) @($g | ForEach-Object { @{ Label = $_.Name; Value = $_.Count } }) }
    $UI.icYearLists.ItemsSource = @(
        [pscustomobject]@{ Title = 'Month by month'; Rows = (New-Bars $d.Months '#D9902F' 12) },
        [pscustomobject]@{ Title = 'Genres'; Rows = (New-Bars (& $pairs $d.Genre) '#5B6FB0' 10) },
        [pscustomobject]@{ Title = 'Faces you saw most'; Rows = (New-Bars (& $pairs @($d.Faces | Where-Object { $_.Count -gt 1 })) '#3E8E4F' 10) },
        [pscustomobject]@{ Title = 'Directors'; Rows = (New-Bars (& $pairs $d.Dirs) '#B5576B' 10) }
    )
    $UI.icYearFilms.ItemsSource = @($d.Films)
    $UI.capYearFilms.Text = $(if ($n) { "EVERYTHING YOU WATCHED IN $($d.Year)  ·  in the order you saw them" } else { '' })
    $UI.capYearFilms.Visibility = $(if ($n) { 'Visible' } else { 'Collapsed' })
    $UI.icYearLists.Visibility = $(if ($n) { 'Visible' } else { 'Collapsed' })
    $Script:YearData = $d
}

function Export-YearHtml {
    $d = $Script:YearData; if (-not $d) { Refresh-Year; $d = $Script:YearData }
    $enc = { param($t) [Net.WebUtility]::HtmlEncode([string]$t) }
    $cards = foreach ($c in @($UI.icYearCards.ItemsSource)) { "<div class='card'><div class='lab'>$(& $enc $c.Label)</div><div class='val' style='color:$($c.Brush)'>$(& $enc $c.Value)</div><div class='sub'>$(& $enc $c.Sub)</div></div>" }
    $lists = foreach ($l in @($UI.icYearLists.ItemsSource)) {
        $rows = foreach ($r in @($l.Rows)) { $pct = [double]($r.BarStar.TrimEnd('*')) * 100; "<div class='row'><span class='rl'>$(& $enc $r.Label)</span><span class='bar'><i style='width:$([math]::Round($pct,1))%;background:$($r.Brush)'></i></span><span class='rv'>$(& $enc $r.ValueText)</span></div>" }
        "<div class='card'><h3>$(& $enc $l.Title)</h3>$($rows -join '')</div>"
    }
    $posters = foreach ($x in @($d.Seen)) {
        $v = $x.V; $m = $Script:Meta[$v.Key]; $img = ''
        if ($m -and $m['PosterPath']) { $img = 'https://image.tmdb.org/t/p/w342' + $m['PosterPath'] }
        "<figure><div class='p' style=""background-image:url('$img')""></div><figcaption>$(& $enc $v.Title)<small>$($x.On.ToString('d MMM'))</small></figcaption></figure>"
    }
    $html = @"
<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>My $($d.Year) in film — Picture House</title>
<style>
body{margin:0;background:#F3EEE4;color:#1F1B16;font:15px/1.5 'Segoe UI',system-ui,sans-serif}
.hero{background:#173F3E;color:#F6EBD9;padding:48px 6vw}
.kick{letter-spacing:.4em;font-size:12px;opacity:.65}
h1{font:400 clamp(28px,4vw,46px)/1.15 Georgia,serif;margin:10px 0 8px}
.hero p{font-size:17px;opacity:.85;margin:0}
main{padding:28px 6vw 60px}
.grid{display:grid;grid-template-columns:repeat(auto-fill,minmax(230px,1fr));gap:14px;margin-bottom:22px}
.card{background:#FFFCF6;border:1px solid #E2D9C9;border-radius:12px;padding:16px 18px}
.lab{font-size:11px;font-weight:700;color:#7B7266;letter-spacing:.05em}
.val{font:400 24px/1.2 Georgia,serif;margin-top:4px}
.sub{font-size:12.5px;color:#9C9385}
h3{font:400 19px Georgia,serif;margin:0 0 10px}
.row{display:grid;grid-template-columns:110px 1fr 32px;gap:8px;align-items:center;font-size:13px;margin:5px 0}
.rl{white-space:nowrap;overflow:hidden;text-overflow:ellipsis}.rv{text-align:right;color:#7B7266}
.bar{height:8px;background:#ECE3D2;border-radius:4px;overflow:hidden}.bar i{display:block;height:100%;border-radius:4px}
h2{font:400 22px Georgia,serif;margin:28px 0 12px}
.films{display:grid;grid-template-columns:repeat(auto-fill,minmax(130px,1fr));gap:16px}
figure{margin:0}.p{aspect-ratio:2/3;border-radius:6px;background:#D8CCB7 center/cover;box-shadow:0 4px 12px rgba(0,0,0,.18)}
figcaption{font-size:13px;margin-top:6px;font-weight:600}figcaption small{display:block;font-weight:400;color:#7B7266}
footer{color:#9C9385;font-size:12px;margin-top:36px}
</style></head><body>
<header class="hero"><div class="kick">YOUR $($d.Year) IN FILM</div><h1>$(& $enc $UI.txtYearHero.Text)</h1><p>$(& $enc $UI.txtYearHeroSub.Text)</p></header>
<main>
<div class="grid">$($cards -join '')</div>
$(if ($d.Films.Count) { "<div class='grid'>$($lists -join '')</div><h2>Everything I watched in $($d.Year)</h2><div class='films'>$($posters -join '')</div>" })
<footer>Made with Picture House on $((Get-Date).ToString('d MMMM yyyy')).</footer>
</main></body></html>
"@
    try {
        $out = Join-Path (Join-Path $DataDir 'Exports') ("My $($d.Year) in film.html")
        [IO.File]::WriteAllText($out, $html, (New-Object Text.UTF8Encoding $false))
        Status "Year in review saved: $out"
        Start-Process $out
    } catch { Tell ("Couldn't save the year in review:`n" + $_.Exception.Message) 'Warning' }
}

# =====================================================================================
#  Exports
# =====================================================================================
function Export-Csv-Library {
    $dlg = New-Object Microsoft.Win32.SaveFileDialog
    $dlg.FileName = 'Picture House films ' + (Get-Date).ToString('yyyy-MM-dd') + '.csv'
    $dlg.Filter = 'CSV file|*.csv'; $dlg.InitialDirectory = (Join-Path $DataDir 'Exports')
    if (-not $dlg.ShowDialog($Window)) { return }
    $Script:AllViews | Sort-Object SortTitle | Select-Object Title, Year, Shelf, GenreText, RuntimeText, Rating, MyRating, Res, SizeText, AddedText, Watched, Fav, Watchlist, CollectionName, TmdbId, ImdbId, Path |
        Export-Csv -LiteralPath $dlg.FileName -NoTypeInformation -Encoding UTF8
    Status "Saved $($dlg.FileName)"
}

function Export-HealthHtml {
    if ($Script:Dirty.Health -or -not $Script:HealthRows.Count) { Run-Health }
    if (-not $Script:HealthRows.Count) { Tell 'Nothing to report — the library looks healthy.'; return }
    try {
        $rows = @($Script:HealthRows | ForEach-Object { @{ i = [string]$_.Issue; f = [string]$_.Film; s = [string]$_.Shelf; d = [string]$_.Detail; p = [string]$_.Path; c = $(if ($_.Shelf) { Get-ShelfColor ([string]$_.Shelf) } else { '#7B7266' }) } })
        $json = (PH-ConvertToJson @($rows)).Replace('</', '<\/')
        $films = @($Script:HealthRows | Where-Object { $_.Key } | ForEach-Object { $_.Key } | Select-Object -Unique).Count
        $html = $HealthTemplate.Replace('__DATA__', $json).Replace('__DATE__', (Get-Date).ToString('d MMMM yyyy, HH:mm')).Replace('__COUNT__', ('{0:N0}' -f $rows.Count)).Replace('__FILMS__', ('{0:N0}' -f $films)).Replace('__TOTAL__', ('{0:N0}' -f $Script:Lib.Count))
        $out = Join-Path (Join-Path $DataDir 'Exports') ('Picture House health ' + (Get-Date).ToString('yyyy-MM-dd HHmm') + '.html')
        [IO.File]::WriteAllText($out, $html, (New-Object Text.UTF8Encoding $false))
        Status "Health report saved: $out"
        Start-Process $out
    } catch { Tell ("Couldn't build the report:`n" + $_.Exception.Message) 'Warning' }
}

$HealthTemplate = @'
<!doctype html>
<html lang="en-GB"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Picture House — library health</title>
<style>
:root{--paper:#F3EEE4;--card:#FFFCF6;--ink:#1F1B16;--muted:#7B7266;--line:#E2D9C9;--accent:#C8432B;--teal:#173F3E;--cream:#F6EBD9}
*{box-sizing:border-box}body{margin:0;background:var(--paper);color:var(--ink);font:14px/1.45 "Segoe UI",system-ui,sans-serif}
header{background:var(--teal);color:var(--cream);padding:26px 32px 22px}h1{font:italic 32px Georgia,serif;margin:0}header p{margin:4px 0 0;opacity:.75;font-size:13px}
.bar{display:flex;flex-wrap:wrap;gap:10px;align-items:center;padding:14px 32px;position:sticky;top:0;background:var(--paper);border-bottom:1px solid var(--line);z-index:2}
input{font:inherit;padding:8px 12px;border:1px solid var(--line);border-radius:8px;background:var(--card);flex:1;min-width:220px}
button{font:inherit;padding:7px 14px;border:1px solid var(--line);border-radius:16px;background:var(--card);cursor:pointer}
.chips{display:flex;flex-wrap:wrap;gap:6px;padding:14px 32px 0}.chip{border:1px solid var(--line);background:var(--card);border-radius:16px;padding:4px 12px;cursor:pointer;font-size:13px}
.chip b{margin-left:6px;color:var(--accent)}.chip.on{background:var(--ink);color:var(--cream);border-color:var(--ink)}.chip.on b{color:var(--cream)}
main{padding:8px 32px 40px}section{background:var(--card);border:1px solid var(--line);border-radius:10px;margin-top:18px;overflow:hidden}
section h2{font:21px Georgia,serif;margin:0;padding:14px 18px;border-bottom:1px solid var(--line);display:flex;justify-content:space-between;cursor:pointer}
section h2 span{font:13px "Segoe UI",sans-serif;color:var(--muted)}section.closed table{display:none}
table{width:100%;border-collapse:collapse}th,td{text-align:left;padding:8px 12px;border-bottom:1px solid var(--line);vertical-align:top}
th{background:var(--paper);font-weight:600;font-size:12.5px}tr:last-child td{border-bottom:0}tr:nth-child(even) td{background:#FAF5EC}
.shelf{display:inline-block;padding:1px 9px;border-radius:9px;color:#fff;font-size:11.5px;font-weight:600;white-space:nowrap}
.path{font:11.5px Consolas,monospace;color:var(--muted);word-break:break-all}#none{display:none;padding:30px;text-align:center;color:var(--muted);font:italic 18px Georgia,serif}
@media print{.bar,.chips{display:none}section.closed table{display:table}header{background:#fff;color:#000}}
@media(max-width:700px){.bar,.chips,main{padding-left:14px;padding-right:14px}.path{display:none}}
</style></head><body>
<header><h1>Library health</h1><p>__COUNT__ things to look at across __FILMS__ of __TOTAL__ films · report made __DATE__</p></header>
<div class="bar"><input id="q" placeholder="Filter by film, shelf, detail or path…"><button id="exp">Expand all</button><button id="col">Collapse all</button><button onclick="print()">Print</button></div>
<div class="chips" id="chips"></div><main id="main"></main><div id="none">Nothing matches.</div>
<script>
const R=__DATA__;let only='';const $=s=>document.querySelector(s);
const esc=s=>String(s??'').replace(/[&<>"]/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;'}[c]));
const issues=[...new Set(R.map(r=>r.i))].sort((a,b)=>R.filter(r=>r.i===b).length-R.filter(r=>r.i===a).length);
$('#chips').innerHTML=`<span class="chip on" data-i="">Everything<b>${R.length}</b></span>`+issues.map(i=>`<span class="chip" data-i="${esc(i)}">${esc(i)}<b>${R.filter(r=>r.i===i).length}</b></span>`).join('');
$('#chips').onclick=e=>{const c=e.target.closest('.chip');if(!c)return;only=c.dataset.i;document.querySelectorAll('.chip').forEach(x=>x.classList.toggle('on',x===c));draw()};
function draw(){const q=$('#q').value.toLowerCase().split(/\s+/).filter(Boolean);let shown=0;
$('#main').innerHTML=issues.filter(i=>!only||i===only).map(i=>{const L=R.filter(r=>r.i===i&&q.every(t=>[r.f,r.s,r.d,r.p].join(' ').toLowerCase().includes(t)));if(!L.length)return'';shown+=L.length;
return `<section><h2 onclick="this.parentNode.classList.toggle('closed')">${esc(i)}<span>${L.length}</span></h2><table><tr><th>Film</th><th>Shelf</th><th>Detail</th><th>Path</th></tr>${L.map(r=>`<tr><td>${esc(r.f)||'—'}</td><td>${r.s?`<span class="shelf" style="background:${r.c}">${esc(r.s)}</span>`:''}</td><td>${esc(r.d)}</td><td class="path">${esc(r.p)}</td></tr>`).join('')}</table></section>`}).join('');
$('#none').style.display=shown?'none':'block'}
$('#q').oninput=draw;$('#exp').onclick=()=>document.querySelectorAll('section').forEach(s=>s.classList.remove('closed'));$('#col').onclick=()=>document.querySelectorAll('section').forEach(s=>s.classList.add('closed'));draw();
</script></body></html>
'@

# =====================================================================================
#  Back up: everything you'd miss (not the picture cache, which can be re-downloaded)
# =====================================================================================
function Backup-PictureHouse {
    $dlg = New-Object Microsoft.Win32.SaveFileDialog
    $dlg.FileName = 'Picture House backup ' + (Get-Date).ToString('yyyy-MM-dd') + '.zip'
    $dlg.Filter = 'Zip file|*.zip'; $dlg.InitialDirectory = [Environment]::GetFolderPath('MyDocuments')
    if (-not $dlg.ShowDialog($Window)) { return }
    Save-Settings; Save-User; Save-Meta
    $files = @(Get-ChildItem -LiteralPath $DataDir -File | Where-Object { $_.Extension -in '.json', '.log' } | ForEach-Object { $_.FullName })
    if ($files.Count -eq 0) { Tell 'There is nothing to back up yet.'; return }
    $Window.Cursor = [Windows.Input.Cursors]::Wait
    try {
        if (Test-Path -LiteralPath $dlg.FileName) { Remove-Item -LiteralPath $dlg.FileName -Force }
        Compress-Archive -LiteralPath $files -DestinationPath $dlg.FileName -CompressionLevel Optimal
        $kb = [math]::Round((Get-Item -LiteralPath $dlg.FileName).Length / 1KB)
        Status "Backup saved: $($dlg.FileName) ($kb KB)"
        Tell ("Backup saved:`n$($dlg.FileName)`n`nTo put it back later: Utilities → Restore from backup.")
    } catch { Tell ("The backup didn't work:`n" + $_.Exception.Message) 'Warning' }
    finally { $Window.Cursor = $null }
}

# =====================================================================================
#  Start again: wipe Picture House's own data (never the NAS), keep settings
# =====================================================================================
function Clear-AllData {
    if ($Script:Jobs.Count -gt 0) { Tell 'Picture House is busy (see the bottom-right of the window). Let it finish, or press Cancel, then try again.'; return }
    $msg = "Clear all of Picture House's data?`n`n" +
           "This removes the film list, film info, posters, collections, people, the Coming soon list — and your watched history, ratings, notes and watchlist.`n`n" +
           "Kept: your settings (NAS folders, keys, player), exported files and the log.`n`n" +
           "Nothing on the NAS is touched — no films or folders are deleted."
    if (-not (Ask $msg)) { return }
    $ans = [Windows.MessageBox]::Show($Window, "Make a backup first?`n`nYes — save a backup, then clear`nNo — clear without a backup`nCancel — don't clear anything", $AppName, 'YesNoCancel', 'Warning')
    if ($ans -eq 'Cancel') { return }
    if ($ans -eq 'Yes') {
        Backup-PictureHouse
        if (-not (Ask 'Backup done. Clear all data now?')) { return }
    }
    $Window.Cursor = [Windows.Input.Cursors]::Wait
    try {
        Hide-BigPoster
        # Picture House's own data files only — never anything outside the Data folder
        $keep = @('settings.json', 'settings.json.bak', 'picture-house.log', 'picture-house.log.old', 'launch.log')
        Get-ChildItem -LiteralPath $DataDir -File -ErrorAction SilentlyContinue | Where-Object { $keep -notcontains $_.Name } |
            ForEach-Object { Remove-Item -LiteralPath $_.FullName -Force -ErrorAction SilentlyContinue }
        foreach ($sub in 'posters', 'thumbs', 'backdrops', 'people') {
            $d = Join-Path $CacheDir $sub
            if (Test-Path -LiteralPath $d) { Get-ChildItem -LiteralPath $d -File -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue }
        }
        Get-ChildItem -LiteralPath $CacheDir -File -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue
        # and forget it all in memory
        $Script:Lib = @{}; $Script:Shelves = @(); $Script:ScanErrors = @()
        $Script:Meta = @{}; $Script:MatchFail = @{}; $Script:User = @{}; $Script:Colls = @{}
        $Script:PeopleCache = @{}; $Script:PersonDept = $null; $Script:PersonWorks = $null; $Script:Awards = @{ Checked = ''; Ids = @(); Films = @{}; Lists = @{} }; $Script:RadarrMovies = $null; $Script:YearData = $null; $Script:PeopleIndex = $null; $Script:Upcoming = @(); $Script:UpcomingViews = @(); $Script:UpcomingChecked = ''
        $Script:HealthRows = @(); $Script:RadarrRows = @(); $Script:PickSkip = @(); $Script:PickKey = $null
        $Script:CurKey = $null; $Script:CurShelf = @{ Kind = 'smart'; Id = 'all' }
        $Settings.LastScan = ''
        Save-Settings
        Write-Log 'All data cleared by the user (settings kept, NAS untouched).'
    } catch { Tell ("Something went wrong while clearing:`n" + $_.Exception.Message) 'Warning' }
    finally { $Window.Cursor = $null }
    Set-DetailOpen $false
    $UI.icPeopleFilms.ItemsSource = $null; $UI.icPersonMore.ItemsSource = $null; $UI.lbPeople.ItemsSource = $null
    $UI.txtPersonName.Text = 'Pick someone'; $UI.txtPersonInfo.Text = ''; Reset-PersonDetails; $UI.ibPerson.ImageSource = $null
    $UI.icParts.ItemsSource = $null; $UI.lbColls.ItemsSource = $null
    $UI.dgHealth.ItemsSource = $null; $UI.wpHealthSummary.Children.Clear()
    Reset-PickCard
    Refresh-Everything
    Status "All data cleared — press ‘Rescan the NAS’ (or ‘Save and rescan’) to start again."
    Tell "All data cleared.`n`nPress ‘Rescan the NAS’ in the left rail when you're ready to start again."
}

# =====================================================================================
#  Clear settings: back to first-run settings (your films, info and watched history are kept)
# =====================================================================================
function Clear-AllSettings {
    if ($Script:Jobs.Count -gt 0) { Tell 'Picture House is busy (see the bottom-right of the window). Let it finish, or press Cancel, then try again.'; return }
    $msg = "Reset all settings to how they were when Picture House was first installed?`n`n" +
           "This forgets your NAS folders, TMDb / Radarr / Seerr addresses and keys, video player, folders to ignore, hidden shelves and quality profile.`n`n" +
           "Kept: your film list, film info, posters, collections, and your watched history, ratings and notes.`n`n" +
           "Nothing on the NAS is touched."
    if (-not (Ask $msg)) { return }
    if (-not (Ask "Are you sure? You'll need to enter your NAS folder and API keys again.")) { return }
    $fresh = New-DefaultSettings
    $fresh.LastScan = $Settings.LastScan
    foreach ($k in @($Settings.Keys)) { [void]$Settings.Remove($k) }
    foreach ($k in @($fresh.Keys)) { $Settings[$k] = $fresh[$k] }
    $Settings.WinMax2 = $true
    $Script:RadarrProfiles = @(); $UI.cbRadarrProfile.ItemsSource = $null
    Set-IgnoreNames
    Save-Settings
    Write-Log 'Settings reset by the user (data kept, NAS untouched).'
    Load-SettingsUi
    Refresh-Everything
    Select-Tab 'Settings'
    Status 'Settings reset — add your NAS film folder and API keys, then press Save.'
}

function Export-HealthCsv {
    if (-not $Script:HealthRows.Count) { Tell 'Run the checks first.'; return }
    $dlg = New-Object Microsoft.Win32.SaveFileDialog
    $dlg.FileName = 'Picture House health ' + (Get-Date).ToString('yyyy-MM-dd') + '.csv'
    $dlg.Filter = 'CSV file|*.csv'; $dlg.InitialDirectory = (Join-Path $DataDir 'Exports')
    if (-not $dlg.ShowDialog($Window)) { return }
    @($UI.dgHealth.ItemsSource) | Select-Object Issue, Film, Shelf, Detail, Path | Export-Csv -LiteralPath $dlg.FileName -NoTypeInformation -Encoding UTF8
    Status "Saved $($dlg.FileName)"
}

function Export-HtmlCatalogue {
    $embed = Ask "Make a web catalogue of your films.`n`nInclude the poster pictures inside the file? (Yes = works offline but the file is bigger; No = posters load from TMDb when online.)"
    Status 'Building the web catalogue…'
    $Window.Cursor = [Windows.Input.Cursors]::Wait
    try {
        $visAll = Get-VisibleViews
        $films = foreach ($v in ($visAll | Sort-Object SortTitle)) {
            $m = $Script:Meta[$v.Key]; $img = ''
            if ($embed -and $v.Poster -and (Test-Path -LiteralPath $v.Poster)) { $img = 'data:image/jpeg;base64,' + [Convert]::ToBase64String([IO.File]::ReadAllBytes($v.Poster)) }
            elseif ($m -and $m['PosterPath']) { $img = 'https://image.tmdb.org/t/p/w342' + $m['PosterPath'] }
            @{ t = $v.Title; y = $v.Year; s = $v.Shelf; c = $v.ShelfBrush; g = $v.GenreText; r = $v.Rating; rt = $v.RuntimeText; q = $v.Res; o = $v.Overview
               d = ($v.DirectorNames -join ', '); a = (@($v.CastNames | Select-Object -First 6) -join ', '); w = $v.Watched; f = $v.Fav; p = $img; tm = $v.TmdbId }
        }
        $json = PH-ConvertToJson @($films)
        $json = $json.Replace('</', '<\/')
        $html = $CatalogueTemplate.Replace('__DATA__', $json).Replace('__DATE__', (Get-Date).ToString('d MMMM yyyy')).Replace('__COUNT__', ('{0:N0} film{1}' -f @($films).Count, $(if (@($films).Count -eq 1) { '' } else { 's' })))
        $out = Join-Path (Join-Path $DataDir 'Exports') ('Picture House catalogue ' + (Get-Date).ToString('yyyy-MM-dd') + '.html')
        [IO.File]::WriteAllText($out, $html, (New-Object Text.UTF8Encoding $false))
        Status "Web catalogue saved: $out"
        Start-Process $out
    } catch { Tell ("Couldn't build the catalogue:`n" + $_.Exception.Message) 'Warning' }
    finally { $Window.Cursor = $null }
}

$CatalogueTemplate = @'
<!doctype html>
<html lang="en-GB"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Picture House — film catalogue</title>
<style>
:root{--paper:#F3EEE4;--card:#FFFCF6;--ink:#1F1B16;--muted:#7B7266;--line:#E2D9C9;--accent:#C8432B;--teal:#173F3E;--cream:#F6EBD9}
*{box-sizing:border-box}body{margin:0;background:var(--paper);color:var(--ink);font:14px/1.45 "Segoe UI",system-ui,sans-serif}
header{background:var(--teal);color:var(--cream);padding:26px 32px 22px}
h1{font:italic 34px Georgia,serif;margin:0}header p{margin:4px 0 0;opacity:.7;font-size:13px}
.bar{display:flex;flex-wrap:wrap;gap:10px;padding:16px 32px;position:sticky;top:0;background:var(--paper);border-bottom:1px solid var(--line);z-index:2}
input,select{font:inherit;padding:8px 12px;border:1px solid var(--line);border-radius:8px;background:var(--card)}input{flex:1;min-width:220px}
.chips{display:flex;flex-wrap:wrap;gap:6px;padding:12px 32px 0}.chip{border:1px solid var(--line);background:var(--card);border-radius:16px;padding:4px 12px;cursor:pointer;font-size:13px}
.chip.on{background:var(--ink);color:var(--cream);border-color:var(--ink)}.chip i{display:inline-block;width:8px;height:8px;border-radius:2px;margin-right:6px}
#count{padding:10px 32px 0;color:var(--muted)}
.grid{display:grid;grid-template-columns:repeat(auto-fill,minmax(150px,1fr));gap:22px;padding:18px 32px 40px}
.film{cursor:pointer}.post{position:relative;aspect-ratio:2/3;border-radius:5px;overflow:hidden;box-shadow:0 4px 12px rgba(0,0,0,.18);display:flex;align-items:center;justify-content:center;color:var(--cream);font:17px Georgia,serif;text-align:center;padding:10px;transition:transform .15s}
.film:hover .post{transform:translateY(-4px)}.post img{position:absolute;inset:0;width:100%;height:100%;object-fit:cover}
.post .strip{position:absolute;left:0;right:0;bottom:0;height:4px}.post .seen{position:absolute;top:6px;right:6px;background:var(--teal);color:var(--cream);border-radius:50%;width:22px;height:22px;font:bold 12px sans-serif;display:flex;align-items:center;justify-content:center}
.film b{display:block;margin-top:8px;white-space:nowrap;overflow:hidden;text-overflow:ellipsis}.film small{color:var(--muted)}
dialog{border:0;border-radius:12px;max-width:720px;width:92%;padding:0;background:var(--card)}dialog::backdrop{background:rgba(20,16,12,.55)}
.dl{display:flex;gap:22px;padding:24px}.dl img{width:180px;border-radius:6px;align-self:flex-start}.dl h2{font:28px Georgia,serif;margin:0 0 6px}
.dl .m{color:var(--muted);margin-bottom:12px}
.acts{display:flex;flex-wrap:wrap;gap:8px;margin-top:16px}
.pill{display:inline-flex;align-items:center;gap:6px;padding:7px 15px;border-radius:17px;font:600 13px "Segoe UI",sans-serif;text-decoration:none;cursor:pointer;border:1px solid var(--line);background:var(--card);color:var(--ink);transition:background .15s,border-color .15s}
.pill:hover{background:#ECE3D2;border-color:#D8CCB7}.pill .ic{font-size:11px;opacity:.6}
.pill.tmdb .ic{opacity:1;color:#01B4E4}.pill:focus{outline:none}.pill:focus-visible{outline:2px solid #E7B7AC;outline-offset:2px}.pill.close{background:var(--accent);border-color:var(--accent);color:#fff;margin-left:auto}.pill.close:hover{background:#A3341F}
@media(max-width:560px){.dl{flex-direction:column}.dl img{width:140px}.bar,.grid,.chips,#count{padding-left:16px;padding-right:16px}}
</style></head><body>
<header><h1>Picture House</h1><p>__COUNT__ · catalogue made __DATE__</p></header>
<div class="bar"><input id="q" placeholder="Search titles, people, genres…"><select id="sort"><option value="t">Title A–Z</option><option value="y">Newest first</option><option value="o">Oldest first</option><option value="r">Best rated</option></select><select id="seen"><option value="">Watched or not</option><option value="n">Not watched</option><option value="y">Watched</option></select></div>
<div class="chips" id="chips"></div><div id="count"></div><div class="grid" id="grid"></div>
<dialog id="dlg"><div class="dl" id="dlb"></div></dialog>
<script>
const F=__DATA__;let shelf='';const $=s=>document.querySelector(s);
const esc=s=>String(s??'').replace(/[&<>"]/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;'}[c]));
const shelves=[...new Set(F.map(f=>f.s.split(' › ')[0]))].sort();
$('#chips').innerHTML='<span class="chip on" data-s="">All shelves</span>'+shelves.map(s=>{const c=F.find(f=>f.s.split(' › ')[0]===s).c;return `<span class="chip" data-s="${esc(s)}"><i style="background:${c}"></i>${esc(s)}</span>`}).join('');
$('#chips').onclick=e=>{const c=e.target.closest('.chip');if(!c)return;shelf=c.dataset.s;document.querySelectorAll('.chip').forEach(x=>x.classList.toggle('on',x===c));draw()};
function draw(){const q=$('#q').value.toLowerCase().split(/\s+/).filter(Boolean),so=$('#sort').value,se=$('#seen').value;
let L=F.filter(f=>(!shelf||f.s.split(' › ')[0]===shelf)&&(!se||(se==='y')===!!f.w)&&q.every(t=>[f.t,f.y,f.s,f.g,f.d,f.a].join(' ').toLowerCase().includes(t)));
const st=t=>t.toLowerCase().replace(/^(the|a|an)\s+/,'');
L.sort(so==='y'?(a,b)=>b.y-a.y:so==='o'?(a,b)=>(a.y||9999)-(b.y||9999):so==='r'?(a,b)=>b.r-a.r:(a,b)=>st(a.t).localeCompare(st(b.t)));
$('#count').textContent=L.length+' film'+(L.length===1?'':'s');
$('#grid').innerHTML=L.map(f=>`<div class="film" data-i="${F.indexOf(f)}"><div class="post" style="background:${f.c}">${esc(f.t)}${f.p?`<img loading="lazy" src="${f.p}" alt="">`:''}<div class="strip" style="background:${f.c}"></div>${f.w?'<div class="seen">✓</div>':''}</div><b title="${esc(f.t)}">${esc(f.t)}</b><small>${[f.y||'',f.rt].filter(Boolean).join(' · ')}</small></div>`).join('')}
$('#grid').onclick=e=>{const d=e.target.closest('.film');if(!d)return;const f=F[d.dataset.i];
$('#dlb').innerHTML=`${f.p?`<img src="${f.p}" alt="">`:''}<div><h2>${esc(f.t)}</h2><div class="m">${[f.y,f.rt,f.q,f.r?'★ '+f.r.toFixed(1):'',f.s].filter(Boolean).map(esc).join(' · ')}</div><div class="m">${esc(f.g)}</div><p>${esc(f.o)}</p>${f.d?`<p><b>Director:</b> ${esc(f.d)}</p>`:''}${f.a?`<p><b>Starring:</b> ${esc(f.a)}</p>`:''}<div class="acts">${f.tm?`<a class="pill tmdb" href="https://www.themoviedb.org/movie/${f.tm}" target="_blank" rel="noopener"><span class="ic">●</span>TMDb<span class="ic">↗</span></a>`:''}<a class="pill" href="https://www.youtube.com/results?search_query=${encodeURIComponent(f.t+' '+(f.y||'')+' trailer')}" target="_blank" rel="noopener"><span class="ic">▶</span>Trailer<span class="ic">↗</span></a><button class="pill close" autofocus onclick="dlg.close()">Close</button></div></div>`;$('#dlg').showModal()};
$('#dlg').onclick=e=>{if(e.target.id==='dlg')e.target.close()};['q','sort','seen'].forEach(i=>$('#'+i).oninput=draw);draw();
</script></body></html>
'@

# =====================================================================================
#  Settings tab
# =====================================================================================
function Load-SettingsUi {
    $UI.lbRoots.ItemsSource = @($Settings.Roots)
    $UI.chkUseNfo.IsChecked = [bool]$Settings.UseNfo
    $UI.txtExts.Text = [string]$Settings.Extensions
    $UI.txtIgnore.Text = [string]$Settings.IgnoreFolders
    $UI.txtPlayer.Text = [string]$Settings.PlayerPath
    $UI.chkWatchedOnPlay.IsChecked = [bool]$Settings.WatchedOnPlay
    $UI.pwTmdb.Password = [string]$Settings.TmdbKey
    $UI.txtLang.Text = [string]$Settings.Language; $UI.txtRegion.Text = [string]$Settings.Region
    $UI.chkAutoFetch.IsChecked = [bool]$Settings.AutoFetch
    $UI.txtRadarrUrl.Text = [string]$Settings.RadarrUrl; $UI.pwRadarr.Password = [string]$Settings.RadarrKey
    $UI.txtSeerrUrl.Text = [string]$Settings.SeerrUrl; $UI.pwSeerr.Password = [string]$Settings.SeerrKey
    # keep the full profile list (remembered between runs); only 'Load quality profiles' refreshes it
    if (@($UI.cbRadarrProfile.Items).Count -eq 0) {
        $list = @($Script:RadarrProfiles)
        if ($list.Count -eq 0 -and $Settings.RadarrProfileName) { $list = @([pscustomobject]@{ Id = [int]$Settings.RadarrProfileId; Name = [string]$Settings.RadarrProfileName }) }
        if ($list.Count) {
            $UI.cbRadarrProfile.ItemsSource = $list
            $hit = @($list | Where-Object { $_.Id -eq [int]$Settings.RadarrProfileId }); if ($hit.Count) { $UI.cbRadarrProfile.SelectedItem = $hit[0] } else { $UI.cbRadarrProfile.SelectedIndex = 0 }
        }
    }
    $UI.txtWelcome.Visibility = $(if (@($Settings.Roots).Count -eq 0) { 'Visible' } else { 'Collapsed' })
}

function Save-SettingsUi {
    $oldRoots = (@($Settings.Roots) -join '|')
    $Settings.Roots = @($UI.lbRoots.Items | ForEach-Object { [string]$_ })
    $Settings.UseNfo = [bool]$UI.chkUseNfo.IsChecked
    $Settings.Extensions = $UI.txtExts.Text.Trim()
    $oldIgnore = [string]$Settings.IgnoreFolders
    $Settings.IgnoreFolders = (@($UI.txtIgnore.Text -split '[,;]' | ForEach-Object { $_.Trim() } | Where-Object { $_ }) -join ', ')
    $UI.txtIgnore.Text = $Settings.IgnoreFolders
    if ($oldIgnore -ne $Settings.IgnoreFolders) { $n = Remove-IgnoredFromLibrary; if ($n) { Status "Removed $n film(s) inside ignored folders." } }
    $Settings.PlayerPath = $UI.txtPlayer.Text.Trim().Trim('"')
    $Settings.WatchedOnPlay = [bool]$UI.chkWatchedOnPlay.IsChecked
    $Settings.TmdbKey = $UI.pwTmdb.Password.Trim()
    $Settings.Language = $(if ($UI.txtLang.Text.Trim()) { $UI.txtLang.Text.Trim() } else { 'en-GB' })
    $Settings.Region = $(if ($UI.txtRegion.Text.Trim()) { $UI.txtRegion.Text.Trim().ToUpperInvariant() } else { 'GB' })
    $Settings.AutoFetch = [bool]$UI.chkAutoFetch.IsChecked
    $Settings.RadarrUrl = Normalize-ServiceUrl $UI.txtRadarrUrl.Text; $UI.txtRadarrUrl.Text = $Settings.RadarrUrl
    $Settings.RadarrKey = $UI.pwRadarr.Password.Trim()
    $Settings.SeerrUrl = Normalize-ServiceUrl $UI.txtSeerrUrl.Text; $UI.txtSeerrUrl.Text = $Settings.SeerrUrl
    $Settings.SeerrKey = $UI.pwSeerr.Password.Trim()
    if ($UI.cbRadarrProfile.SelectedItem) { $Settings.RadarrProfileId = [int]$UI.cbRadarrProfile.SelectedItem.Id; $Settings.RadarrProfileName = [string]$UI.cbRadarrProfile.SelectedItem.Name }
    Save-Settings
    $UI.txtWelcome.Visibility = $(if (@($Settings.Roots).Count -eq 0) { 'Visible' } else { 'Collapsed' })
    Status 'Settings saved.'
    return ($oldRoots -ne (@($Settings.Roots) -join '|'))
}

function Find-ZoomPlayer {
    $c = @("$env:ProgramFiles\Zoom Player\zplayer.exe", "${env:ProgramFiles(x86)}\Zoom Player\zplayer.exe",
           "$env:ProgramFiles\Inmatrix\Zoom Player\zplayer.exe", "${env:ProgramFiles(x86)}\Inmatrix\Zoom Player\zplayer.exe",
           "$env:ProgramFiles\Zoom Player MAX\zplayer.exe", "${env:ProgramFiles(x86)}\Zoom Player MAX\zplayer.exe")
    foreach ($p in $c) { if ($p -and (Test-Path -LiteralPath $p)) { return $p } }
    try {
        $reg = Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\zplayer.exe', 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\App Paths\zplayer.exe' -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($reg -and $reg.'(default)' -and (Test-Path -LiteralPath $reg.'(default)')) { return $reg.'(default)' }
    } catch {}
    return $null
}

$AboutText = @"
Picture House $AppVersion — a film library for the shelves on your NAS.

New in 1.3.1
•  Restore from backup (Utilities): choose a backup and see what's in it — films, watched, rated, notes — next to what you have now, tick which parts to put back, and Picture House restarts with it. Your data as it was is saved first in Data\Backups, so you can always go back.
•  Move to my other PC (Utilities): Send to my other PC makes one file with your watched history, ratings, notes, favourites, watchlist and settings (keys and film list optional). Bring in… on the other PC merges it — a film watched on either PC stays watched, and nothing on that PC is lost. Window size and other per-PC settings stay put.
•  Printable list (Utilities): a tidy page of one shelf or the whole collection — choose all, not watched, watched, watchlist or favourites, how to sort, what each line shows, grouped by shelf, in two columns, with tick boxes. It opens in your browser to print or save as a PDF.
•  Utilities is tidied into Export, Library, Your data and Housekeeping.
•  Build-PictureHouseExe.cmd makes Picture House.exe with the Picture House icon (every size from 16 to 256 px). It checks first that the PC has everything the build needs and says what to do if not, keeps your old exe if anything goes wrong, and can add a desktop shortcut.

New in 1.3.0
•  Its own icon: a teal film-strip tile with a cream "P" on the taskbar and title bar (instead of PowerShell's), saved as Picture House.ico for shortcuts too.
•  A new About button (next to Settings) with the version and credits; this list is now called Version history.
•  Smoother and tidier: talking to Radarr and Seerr now happens in the background (no more frozen window while they answer), the film panel keeps Play / Watched / Favourite / Watchlist up front with everything else under More ▾ (and every right-click menu now has the app's cream, rounded look), and the pop-up windows (Add to Radarr, Choose a copy, Fix match) match the app — teal header, red and cream buttons.
•  Tidier: easier-to-read text under the posters, the film panel closes when you open Stats or Upgrades, Year in review shows a simple message until you've watched something, and Health points to Upgrades for SD copies and duplicates.
•  Import it anyway: Picture House follows every copy you pick until Radarr swaps it in ("Your picks" on the Upgrades page). If Radarr downloads it but holds it back — e.g. "not an upgrade" — a card pops up with one button to import that file anyway. Your Radarr settings are never changed.
•  Choose a copy: on the Upgrades page (and when you add a film to Radarr) you now pick the download yourself — every English-language copy your indexers have, with its size, quality, seeders and age, sortable and filterable by maximum size. Radarr only downloads the one you choose, and Picture House tells you when it reaches your download client.
•  You can see what Radarr and Seerr did: a card pops up bottom-right when you add a film, request it or search for a better copy, and Picture House keeps an eye on Radarr afterwards — "Radarr found a 1080p copy… downloading now" or "nothing better yet". The Upgrades list shows the latest news on each film too.
•  People: how complete are you? Every director and actor shows "You have 6 of the 14 films they directed" with a progress bar, the list shows "6 of 14" under each name, and Sort → Most complete puts the ones you're closest to finishing first.
•  Award winners: a new shelf in the rail for your Oscar, BAFTA and Golden Globe winners and nominees (grouped), the awards listed in the film panel, and two new lists in Collections — every Oscar Best Picture and BAFTA Best Film winner, with the ones you're missing ready for Radarr or Seerr. From Wikidata, free and automatic.
•  Upgrades & duplicates: a new tab listing copies below 1080p or 4K and films you have twice, with what Radarr's quality profile thinks of each. Nothing is automatic — "Search for a better copy" asks first and only searches for that one film.
•  Stats → Year in review: your year in film — films watched, hours, favourite shelf and genre, busiest month, longest sit, your top rated, faces you saw most and every film in order. Export it as a web page to share.

New in 1.2.34
•  Tooltips have a new look — a dark teal card with cream text, to match the app. Coming soon films show a tidy card: title, cinema / digital / disc dates, the shelf it will land on and the story.
•  Coming soon: the posters no longer have COMING SOON / IN CINEMAS labels over them — the page title and the dates under each poster say it already.
•  Search: people whose name matches (e.g. "helen") now appear in a strip above the films, with photo, actor or director and how many of your films they're in. Click one to open their page.
•  The search box: what you type now starts exactly where the grey "Search titles, people, genres…" hint sits, instead of halfway along it.
•  People no longer freezes for a few seconds the first time you open it — sorting actors from producers now uses a small index file, built in the background if it's missing.
•  Opening: a small "Opening your film library…" card shows straight away so you know it's on its way, the window comes to the front when it's ready, and if something stops it opening you get a message instead of nothing.

New in 1.2.33
•  People → Actors only lists actors and directors. Producers, writers and other crew who happen to have a small part in a film (TMDb says what each person is mainly known for) are left out.

New in 1.2.32
•  Tonight's Pick: the dice looks like a proper cube again (less fish-eye), the pick sits in the middle of the stage with a bigger poster, and the small captions are easier to read.
•  Tonight's Pick: the films-in-the-hat count is now a big red number in the middle of the header.
•  Tonight's Pick: a Reset choices button (under the chips) puts shelf, length, era and "from" back to the start (and lets skipped films back in the hat).

New in 1.2.31
•  Tonight's Pick: a bigger dice, and the films-in-the-hat count is now a bold badge so it's easy to see.

New in 1.2.30
•  Tonight's Pick redesigned: click the 3D dice to roll for a film. One-click chips for shelf, length, era and where from (unwatched, watchlist, favourites or anything), a live count of films in the hat, and three "Or maybe" runners-up you can swap in. Rolling again skips the last pick.

New in 1.2.29
•  Tonight's Pick: the genre filter has gone — pick by shelf, decade, running time and rating instead.

New in 1.2.28
•  People: cast and crew details (photo, biography, birth date, other films) are now fetched automatically in the background — most-seen people first — so clicking someone shows their details straight away. Runs after film info is fetched and at start-up, refreshes every 90 days, and stops with Cancel.

New in 1.2.27
•  Settings → Start again: two separate buttons. Clear all data: wipes Picture House's stored data (film list, info, posters, your watched history and ratings) as if no scan had been done (settings kept, offers a backup first). Clear settings: resets every setting to first-run (your films, info and watched history kept). Nothing on the NAS is touched by either.

New in 1.2.26
•  Web catalogue: the film pop-up has proper buttons — TMDb ↗, Trailer ↗ and Close — instead of a plain link.

New in 1.2.25
•  New Utilities tab: exports (web catalogue, CSV, health report), Refresh all film info, show hidden shelves, open the log, open the data folder — and Back up my data, which saves your watched history, ratings, notes and settings to one .zip.

New in 1.2.24
•  Stats: the top lists sit four across on a wide screen, and their bars fill the card so the numbers sit next to them.

New in 1.2.23
•  People lists every actor, not just those in two or more of your films.

New in 1.2.22
•  Collections and People: the film title no longer shows through faded posters like a watermark — it only appears when there's no poster at all.

New in 1.2.21
•  Collections are checked against TMDb automatically — at start-up, after new film info is fetched and when you open the tab (anything not checked for a week). ‘Check TMDb’ still forces a full refresh.

New in 1.2.20
•  People → Directors now lists every director (the ‘2 or more films’ filter only applies to actors).

New in 1.2.19
•  The empty ‘Choose a film’ panel no longer flashes up on the right when Picture House opens.

New in 1.2.18
•  People: tidier ‘More films’ (no ‘not owned’ tags; buttons on one row), biographies without pronunciation guides, and the status bar no longer gets stuck on ‘Getting details…’.

New in 1.2.17
•  People: clicking a cast member or director fetches their profile from TMDb — photo, biography, birth date and place, links — plus the other films of theirs you don't have yet, with + Radarr / Seerr buttons.

New in 1.2.16
•  Click the poster in the film panel to see it big — the sharpest copy available (your NAS poster, or TMDb's full-resolution one).

New in 1.2.15
•  Slim beige scrollbars throughout (no grey bar or arrow buttons); they widen a little when you hover over them.
•  Dropdown lists open taller, so most fit without scrolling.

New in 1.2.14
•  Removed the quality tag (1080p / 720p / SD) from the corner of each poster.

New in 1.2.13
•  Easier-to-see progress: while scanning or fetching, the status bar shows a pill with what's running, a larger progress bar, the percentage and a Cancel button.

New in 1.2.12
•  MKV files: picture quality is now read straight from the MKV itself (Windows can't read MKV details on its own).

New in 1.2.11
•  Picture quality (4K / 1080p / 720p / SD) is now read from each video file itself during a scan, so the quality filter, Stats and Health know every film's real resolution. Results are remembered, so later scans only check new films.
•  Library growth chart: month labels no longer overlap at the right-hand end.

New in 1.2.10
•  Fixed: Stats charts didn't appear on Windows PowerShell 5.1.
•  Fixed: the bars in the Stats top lists didn't show — only the numbers.
•  Each chart is drawn on its own, so one problem can't blank the others (and any problem is logged in detail).

New in 1.2.8
•  New dropdowns everywhere: rounded cream pills that open a soft list with a tick on the current choice. Filter dropdowns turn teal while a filter is in use.

New in 1.2.7
•  The quality profile list stays put (even after a restart) — it only refreshes when you press ‘Load quality profiles’.

New in 1.2.6
•  No more Root folder setting: when you send a film to Radarr, the box lists Radarr's folders (with free space) and you choose the genre folder each time.

New in 1.2.5
•  Removed the Display setting — Picture House simply opens maximised at normal size.

New in 1.2.4
•  Settings is laid out in columns — your library, online services and version info side by side on wide screens (two columns on smaller ones) — with the Save buttons at the top.
•  The header above the posters refreshes once film info has been fetched.

New in 1.2.2
•  The film panel stays out of the way until you click a poster, so the wall uses the full width.
•  Poster rows now stretch to fill the width — no gap at the right.
•  ‘Hours of film’ only shows once running times are known, with correct wording.
•  The film-panel button (top right) now shows a proper icon.
•  The Seerr folder on the NAS is ignored (Settings → Folders to ignore).

New in 1.2.1
•  Graphics back to their normal size — still opens maximised. Settings → Display (or Ctrl + / Ctrl −) can still make everything bigger or smaller if you ever want it.

New in 1.2.0
•  Opens maximised.
•  Stats uses three chart columns when there's room.

New in 1.1.0
•  Stats now has proper charts: a shelves donut, progress rings (watched, film info, HD, posters), films by decade, library growth over two years, TMDb ratings, running times, watched shelf-by-shelf and a picture-quality donut. Hover for numbers; click a slice, column or bar to jump to those films.

New in 1.0.10
•  Folders to ignore (Settings): ‘Intros’ is skipped everywhere — never a shelf, film, Health item or export. Add more names, separated by commas.

New in 1.0.9
•  Health: “Export HTML report” — a searchable web page of every issue, grouped with counts, ready to print.

New in 1.0.8
•  Always opens on All films in the Library.

New in 1.0.7
•  Coming soon: films Radarr is waiting for that aren't out yet, with cinema / digital / disc dates and a countdown, grouped by month.
•  Health no longer flags the empty folders Radarr makes for unreleased films. Once a film's release date has passed and it still hasn't arrived, it shows as ‘Released — still missing’.

New in 1.0.6
•  Opens much bigger — about 92% of the screen, centred (not full screen). If you resize it, your size is remembered.

New in 1.0.5
•  “Test Radarr” button: checks the address and key, and shows Radarr's version, root folders with free space, and any health warnings.

New in 1.0.4
•  “Get a free API key” button beside the TMDb key.
•  Seerr: a Test button, and an optional Seerr API key — with it, the Seerr button on missing collection films sends the request straight to Seerr.

New in 1.0.3
•  Fixed “Cannot convert System.Object[] to System.Int32” when connecting to Radarr on Windows PowerShell 5.1.

New in 1.0.2
•  Radarr connection is more forgiving: the address is tidied up automatically (missing http://, stray double dots, pasted page paths), it warns when the port belongs to another app such as Deluge, and errors now show the address tried, the reply, and what to check.

New in 1.0.1
•  Every genre shelf has its own fixed colour (Action red, Horror blood red, Sci-Fi cyan, Mum rose…) — no two shelves share one.

What's in Picture House
•  Shelves come straight from your NAS folders, including sub-shelves, DVD/Blu-ray folder rips, ISOs and CD1/CD2 films.
•  Poster wall that stays quick with thousands of films; group by shelf, decade, letter or genre; or switch to a sortable list.
•  Film info from .nfo files already on the NAS, or from TMDb — posters, backdrops, cast, crew, certificates, trailers.
•  Watched, favourites, watchlist, star ratings, notes and play history (kept on this PC, not the NAS).
•  Collections: see which films in a series you own, which are missing, and send them to Radarr or Seerr.
•  Tonight's Pick: a spinning reel that chooses a film for you, filtered by shelf, mood, length and rating.
•  People: browse by actor or director across your whole library.
•  Health checks: naming problems, missing artwork, duplicates, upgrade candidates and a Radarr comparison.
•  Stats, a CSV export and a self-contained web catalogue you can open on any device.
•  Move a film to another shelf (folder) from inside the app.

Data folder: $DataDir
"@

# =====================================================================================
#  Stats charts (donuts, rings, columns, growth line, histograms) — drawn as WPF shapes
# =====================================================================================
$Inv = [Globalization.CultureInfo]::InvariantCulture
function N([double]$d) { return $d.ToString('0.##', $Inv) }
function X([string]$s) { return [Security.SecurityElement]::Escape([string]$s) }
$XNS = 'xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"'

$ChartStyles = @'
<Style TargetType="Path"><Setter Property="Cursor" Value="Hand"/><Style.Triggers><Trigger Property="IsMouseOver" Value="True"><Setter Property="Opacity" Value="0.78"/></Trigger></Style.Triggers></Style>
<Style TargetType="Rectangle"><Style.Triggers><Trigger Property="IsMouseOver" Value="True"><Setter Property="Opacity" Value="0.78"/></Trigger></Style.Triggers></Style>
<Style TargetType="ToolTip"><Setter Property="Background" Value="#1F1B16"/><Setter Property="Foreground" Value="#F6EBD9"/><Setter Property="BorderThickness" Value="0"/><Setter Property="Padding" Value="9,5"/></Style>
'@

function New-ChartCard([string]$title, [string]$sub, [string]$body, [int]$span = 1) {
    $subXml = ''; if ($sub) { $subXml = "<TextBlock Text=""$(X $sub)"" Foreground=""#7B7266"" FontSize=""12"" Margin=""0,0,0,10"" TextWrapping=""Wrap""/>" }
    $x = "<Border $XNS Background=""#FFFCF6"" BorderBrush=""#E2D9C9"" BorderThickness=""1"" CornerRadius=""10"" Padding=""18,16"" Margin=""0,0,14,14"">" +
         "<Border.Resources>$ChartStyles</Border.Resources><StackPanel>" +
         "<TextBlock Text=""$(X $title)"" FontFamily=""Georgia"" FontSize=""19"" Margin=""0,0,0,2""/>$subXml$body</StackPanel></Border>"
    try { return [Windows.Markup.XamlReader]::Parse($x) }
    catch { Write-Log "Chart '$title' failed: $($_.Exception.Message)"; return $null }
}

function Get-ArcPoint([double]$cx, [double]$cy, [double]$r, [double]$deg) {
    $a = ($deg - 90) * [math]::PI / 180
    return (N ($cx + $r * [math]::Cos($a))) + ',' + (N ($cy + $r * [math]::Sin($a)))
}

# Donut with legend. $items = @(@{ Label; Value; Color; Tag })
function New-DonutBody($items, [string]$centreBig, [string]$centreSmall, [string]$unit = 'films', [int]$maxLegend = 11) {
    $items = @($items | Where-Object { [double]$_.Value -gt 0 })
    $total = 0.0; foreach ($i in $items) { $total += [double]$i.Value }
    if ($total -le 0) { return '<TextBlock Text="Nothing to show yet." Foreground="#7B7266" FontStyle="Italic"/>' }
    if ($items.Count -gt $maxLegend + 1) {
        $keep = @($items | Select-Object -First $maxLegend); $rest = 0.0
        foreach ($i in ($items | Select-Object -Skip $maxLegend)) { $rest += [double]$i.Value }
        $items = $keep + @(@{ Label = 'Everything else'; Value = $rest; Color = '#C9BEA9'; Tag = '' })
    }
    $cx = 110; $cy = 110; $outerR = 100; $innerR = 62
    $paths = New-Object Text.StringBuilder
    $start = 0.0
    foreach ($i in $items) {
        $v = [double]$i.Value; $sweep = 360 * $v / $total
        if ($sweep -ge 359.9) { $sweep = 359.9 }
        $end = $start + $sweep
        $large = $(if ($sweep -gt 180) { 1 } else { 0 })
        $gap = $(if ($items.Count -gt 1) { 0.6 } else { 0 })
        $s0 = $start + $gap / 2; $e0 = $end - $gap / 2; if ($e0 -le $s0) { $e0 = $s0 + 0.01 }
        $d = "M $(Get-ArcPoint $cx $cy $outerR $s0) A $outerR,$outerR 0 $large 1 $(Get-ArcPoint $cx $cy $outerR $e0) L $(Get-ArcPoint $cx $cy $innerR $e0) A $innerR,$innerR 0 $large 0 $(Get-ArcPoint $cx $cy $innerR $s0) Z"
        $pct = 100 * $v / $total
        $tip = X ("{0}: {1:N0} {2} ({3:0.#}%)" -f $i.Label, $v, $unit, $pct)
        [void]$paths.Append("<Path Data=""$d"" Fill=""$($i.Color)"" ToolTip=""$tip"" Tag=""$(X $i.Tag)""/>")
        $start = $end
    }
    $legend = New-Object Text.StringBuilder
    foreach ($i in $items) {
        $pct = 100 * [double]$i.Value / $total
        [void]$legend.Append("<Grid Margin=""0,2""><Grid.ColumnDefinitions><ColumnDefinition Width=""16""/><ColumnDefinition Width=""*""/><ColumnDefinition Width=""Auto""/></Grid.ColumnDefinitions>" +
            "<Border Width=""10"" Height=""10"" CornerRadius=""2"" Background=""$($i.Color)"" HorizontalAlignment=""Left""/>" +
            "<TextBlock Grid.Column=""1"" Text=""$(X $i.Label)"" TextTrimming=""CharacterEllipsis"" FontSize=""12.5""/>" +
            "<TextBlock Grid.Column=""2"" Text=""$(X ('{0:N0}  ·  {1:0}%' -f [double]$i.Value, $pct))"" Foreground=""#7B7266"" FontSize=""12"" Margin=""8,0,0,0""/></Grid>")
    }
    return "<Grid><Grid.ColumnDefinitions><ColumnDefinition Width=""220""/><ColumnDefinition Width=""*""/></Grid.ColumnDefinitions>" +
           "<Viewbox Width=""200"" Height=""200"" HorizontalAlignment=""Left""><Canvas Width=""220"" Height=""220"">$paths" +
           "<TextBlock Canvas.Left=""40"" Canvas.Top=""82"" Width=""140"" TextAlignment=""Center"" Text=""$(X $centreBig)"" FontFamily=""Georgia"" FontSize=""$(if ($centreBig.Length -gt 6) { 23 } else { 32 })"" Foreground=""#1F1B16""/>" +
           "<TextBlock Canvas.Left=""40"" Canvas.Top=""124"" Width=""140"" TextAlignment=""Center"" Text=""$(X $centreSmall)"" FontSize=""12"" Foreground=""#7B7266""/></Canvas></Viewbox>" +
           "<StackPanel Grid.Column=""1"" VerticalAlignment=""Center"" Margin=""14,0,0,0"">$legend</StackPanel></Grid>"
}

# One ring gauge (0..1)
function New-RingXml([double]$frac, [string]$color, [string]$big, [string]$label, [string]$sub, [string]$tag = '') {
    $frac = [math]::Max(0.0, [math]::Min(1.0, $frac))
    $cx = 70; $cy = 70; $ringR = 58
    $arc = ''
    if ($frac -ge 0.999) { $arc = "<Ellipse Canvas.Left=""12"" Canvas.Top=""12"" Width=""116"" Height=""116"" Stroke=""$color"" StrokeThickness=""14""/>" }
    elseif ($frac -gt 0.002) {
        $sweep = 360 * $frac; $large = $(if ($sweep -gt 180) { 1 } else { 0 })
        $arc = "<Path Data=""M $(Get-ArcPoint $cx $cy $ringR 0) A $ringR,$ringR 0 $large 1 $(Get-ArcPoint $cx $cy $ringR $sweep)"" Stroke=""$color"" StrokeThickness=""14"" StrokeStartLineCap=""Round"" StrokeEndLineCap=""Round"" Tag=""$(X $tag)"" ToolTip=""$(X $sub)""/>"
    }
    return "<StackPanel Margin=""0,0,10,0"" Width=""150""><Viewbox Width=""130"" Height=""130"" HorizontalAlignment=""Center""><Canvas Width=""140"" Height=""140"">" +
           "<Ellipse Canvas.Left=""12"" Canvas.Top=""12"" Width=""116"" Height=""116"" Stroke=""#EFE6D6"" StrokeThickness=""14""/>$arc" +
           "<TextBlock Canvas.Left=""20"" Canvas.Top=""52"" Width=""100"" TextAlignment=""Center"" Text=""$(X $big)"" FontFamily=""Georgia"" FontSize=""28"" Foreground=""#1F1B16""/></Canvas></Viewbox>" +
           "<TextBlock Text=""$(X $label)"" HorizontalAlignment=""Center"" FontWeight=""SemiBold"" Margin=""0,6,0,0""/>" +
           "<TextBlock Text=""$(X $sub)"" HorizontalAlignment=""Center"" Foreground=""#7B7266"" FontSize=""11.5"" TextAlignment=""Center"" TextWrapping=""Wrap""/></StackPanel>"
}

# Vertical columns. $items = @(@{ Label; Value; Color; Tag; Tip })
function New-ColumnsBody($items, [string]$color, [int]$height = 190, [string]$unit = 'films') {
    $items = @($items)
    if ($items.Count -eq 0) { return '<TextBlock Text="Nothing to show yet." Foreground="#7B7266" FontStyle="Italic"/>' }
    $W = 560; $canvasH = $height; $top = 18; $bottom = 26; $plotH = $canvasH - $top - $bottom
    $max = 1.0; foreach ($i in $items) { if ([double]$i.Value -gt $max) { $max = [double]$i.Value } }
    $slot = $W / $items.Count; $bw = [math]::Max(4.0, [math]::Min(48.0, $slot * 0.68))
    $sb = New-Object Text.StringBuilder
    foreach ($g in 0.5, 1) { $y = $top + $plotH * (1 - $g); [void]$sb.Append("<Line X1=""0"" X2=""$W"" Y1=""$(N $y)"" Y2=""$(N $y)"" Stroke=""#EFE6D6"" StrokeThickness=""1""/>") }
    [void]$sb.Append("<Line X1=""0"" X2=""$W"" Y1=""$(N ($top + $plotH))"" Y2=""$(N ($top + $plotH))"" Stroke=""#D8CCB7"" StrokeThickness=""1""/>")
    $labelEvery = [math]::Max(1, [math]::Ceiling($items.Count / 14))
    for ($k = 0; $k -lt $items.Count; $k++) {
        $i = $items[$k]; $v = [double]$i.Value
        $barH = [math]::Max($(if ($v -gt 0) { 2.0 } else { 0.0 }), $plotH * $v / $max)
        $x = $slot * $k + ($slot - $bw) / 2; $y = $top + $plotH - $barH
        $c = $color; if ($i.Color) { $c = $i.Color }
        $tip = $i.Tip; if (-not $tip) { $tip = '{0}: {1:N0} {2}' -f $i.Label, $v, $unit }
        $cursor = $(if ($i.Tag) { ' Cursor="Hand"' } else { '' })
        [void]$sb.Append("<Rectangle Canvas.Left=""$(N $x)"" Canvas.Top=""$(N $y)"" Width=""$(N $bw)"" Height=""$(N $barH)"" RadiusX=""3"" RadiusY=""3"" Fill=""$c"" ToolTip=""$(X $tip)"" Tag=""$(X $i.Tag)""$cursor/>")
        if ($v -gt 0 -and $bw -ge 16) { [void]$sb.Append("<TextBlock Canvas.Left=""$(N ($x - 10))"" Canvas.Top=""$(N ($y - 16))"" Width=""$(N ($bw + 20))"" TextAlignment=""Center"" FontSize=""10.5"" Foreground=""#7B7266"" Text=""$('{0:N0}' -f $v)"" IsHitTestVisible=""False""/>") }
        if ($k % $labelEvery -eq 0) { [void]$sb.Append("<TextBlock Canvas.Left=""$(N ($slot * $k - 10))"" Canvas.Top=""$(N ($top + $plotH + 6))"" Width=""$(N ($slot + 20))"" TextAlignment=""Center"" FontSize=""11"" Foreground=""#5B5348"" Text=""$(X $i.Label)"" IsHitTestVisible=""False""/>") }
    }
    return "<Viewbox Stretch=""Uniform"" StretchDirection=""Both"" MaxHeight=""260""><Canvas Width=""$W"" Height=""$canvasH"">$sb</Canvas></Viewbox>"
}

# Cumulative growth line with monthly additions as faint columns
function New-GrowthBody($months) {
    $months = @($months)
    if ($months.Count -lt 2) { return '<TextBlock Text="Not enough history yet." Foreground="#7B7266" FontStyle="Italic"/>' }
    $W = 560; $H = 200; $top = 14; $bottom = 26; $left = 14; $plotH = $H - $top - $bottom; $plotW = $W - $left * 2
    $maxC = 1.0; $maxA = 1.0
    foreach ($m in $months) { if ($m.Total -gt $maxC) { $maxC = $m.Total }; if ($m.Added -gt $maxA) { $maxA = $m.Added } }
    $minC = [double]$months[0].Total; if ($minC -gt $maxC * 0.6) { $minC = [math]::Floor($minC * 0.9) } else { $minC = 0 }
    $span = [math]::Max(1.0, $maxC - $minC)
    $step = $plotW / ($months.Count - 1)
    $sb = New-Object Text.StringBuilder
    [void]$sb.Append("<Line X1=""0"" X2=""$W"" Y1=""$(N ($top + $plotH))"" Y2=""$(N ($top + $plotH))"" Stroke=""#D8CCB7""/>")
    $pts = New-Object Collections.ArrayList
    for ($k = 0; $k -lt $months.Count; $k++) {
        $m = $months[$k]; $x = $left + $step * $k
        $ah = ($plotH * 0.45) * $m.Added / $maxA
        if ($m.Added -gt 0) { [void]$sb.Append("<Rectangle Canvas.Left=""$(N ($x - [math]::Min(9.0, $step * 0.35)))"" Canvas.Top=""$(N ($top + $plotH - $ah))"" Width=""$(N ([math]::Min(18.0, $step * 0.7)))"" Height=""$(N $ah)"" Fill=""#E3D7C2"" RadiusX=""2"" RadiusY=""2"" ToolTip=""$(X ('{0}: {1:N0} added · {2:N0} in total' -f $m.Label, $m.Added, $m.Total))""/>") }
        $y = $top + $plotH * (1 - ($m.Total - $minC) / $span)
        [void]$pts.Add((N $x) + ',' + (N $y))
        if ((($months.Count - 1 - $k) % 3) -eq 0) { [void]$sb.Append("<TextBlock Canvas.Left=""$(N ([math]::Max(0.0, [math]::Min($W - 60.0, $x - 30))))"" Canvas.Top=""$(N ($top + $plotH + 6))"" Width=""60"" TextAlignment=""Center"" FontSize=""10.5"" Foreground=""#5B5348"" Text=""$(X $m.Short)""/>") }
    }
    $line = $pts -join ' '
    $area = "$(N $left),$(N ($top + $plotH)) $line $(N ($left + $step * ($months.Count - 1))),$(N ($top + $plotH))"
    [void]$sb.Append("<Polygon Points=""$area"" Fill=""#262A7F7A"" IsHitTestVisible=""False""/>")
    [void]$sb.Append("<Polyline Points=""$line"" Stroke=""#2A7F7A"" StrokeThickness=""2.5"" StrokeLineJoin=""Round"" IsHitTestVisible=""False""/>")
    $last = $pts[$pts.Count - 1] -split ','
    [void]$sb.Append("<Ellipse Canvas.Left=""$(N ([double]$last[0] - 5))"" Canvas.Top=""$(N ([double]$last[1] - 5))"" Width=""10"" Height=""10"" Fill=""#2A7F7A"" Stroke=""#FFFCF6"" StrokeThickness=""2""/>")
    [void]$sb.Append("<TextBlock Canvas.Left=""$(N ([double]$last[0] - 120))"" Canvas.Top=""$(N ([math]::Max(0.0, [double]$last[1] - 22)))"" Width=""114"" TextAlignment=""Right"" FontFamily=""Georgia"" FontSize=""15"" Foreground=""#173F3E"" Text=""$('{0:N0}' -f $months[-1].Total)""/>")
    return "<Viewbox Stretch=""Uniform"" MaxHeight=""260""><Canvas Width=""$W"" Height=""$H"">$sb</Canvas></Viewbox>"
}

# Horizontal "watched per shelf" progress bars
function New-ProgressBody($rows) {
    $rows = @($rows)
    if ($rows.Count -eq 0) { return '<TextBlock Text="Nothing to show yet." Foreground="#7B7266" FontStyle="Italic"/>' }
    $sb = New-Object Text.StringBuilder
    foreach ($r in $rows) {
        $frac = $(if ($r.Total) { $r.Seen / $r.Total } else { 0 })
        $tip = X ('{0}: watched {1:N0} of {2:N0} ({3:0}%)' -f $r.Label, $r.Seen, $r.Total, 100 * $frac)
        [void]$sb.Append("<Grid Margin=""0,3"" ToolTip=""$tip"" Tag=""$(X $r.Tag)"" Background=""Transparent"" Cursor=""Hand""><Grid.ColumnDefinitions><ColumnDefinition Width=""120""/><ColumnDefinition Width=""*""/><ColumnDefinition Width=""92""/></Grid.ColumnDefinitions>" +
            "<TextBlock Text=""$(X $r.Label)"" TextTrimming=""CharacterEllipsis"" VerticalAlignment=""Center""/>" +
            "<Grid Grid.Column=""1"" Height=""12"" VerticalAlignment=""Center""><Grid.ColumnDefinitions><ColumnDefinition Width=""$(([math]::Max(0.0001, $frac)).ToString('0.####', $Inv))*""/><ColumnDefinition Width=""$(([math]::Max(0.0001, 1 - $frac)).ToString('0.####', $Inv))*""/></Grid.ColumnDefinitions>" +
            "<Border Grid.ColumnSpan=""2"" Background=""#EFE6D6"" CornerRadius=""6""/><Border Background=""$($r.Color)"" CornerRadius=""6""/></Grid>" +
            "<TextBlock Grid.Column=""2"" Text=""$('{0:N0} / {1:N0}' -f $r.Seen, $r.Total)"" Foreground=""#7B7266"" FontSize=""12"" HorizontalAlignment=""Right"" VerticalAlignment=""Center""/></Grid>")
    }
    return "<StackPanel>$sb</StackPanel>"
}

function Write-ChartError([string]$name, $err) {
    $pos = ''; try { $pos = $err.InvocationInfo.PositionMessage } catch {}
    $st = ''; try { $st = $err.ScriptStackTrace } catch {}
    Write-Log ("Chart '$name' failed: " + $err.Exception.Message + "`n" + $pos + "`n" + $st)
    $note = "<Border $XNS Background=""#FFFCF6"" BorderBrush=""#E2D9C9"" BorderThickness=""1"" CornerRadius=""10"" Padding=""18,16"" Margin=""0,0,14,14""><StackPanel>" +
            "<TextBlock Text=""$(X $name)"" FontFamily=""Georgia"" FontSize=""19""/>" +
            "<TextBlock Text=""Couldn't draw this chart — details are in Data\picture-house.log"" Foreground=""#7B7266"" FontStyle=""Italic"" Margin=""0,6,0,0""/></StackPanel></Border>"
    try { [void]$UI.ugCharts.Children.Add([Windows.Markup.XamlReader]::Parse($note)) } catch {}
}

function Build-StatCharts($vis) {
    $panel = $UI.ugCharts
    $panel.Children.Clear()
    # Windows PowerShell 5.1 can't wrap a .NET List in @( ) ('Argument types do not match'), so use a plain array
    if ($vis -is [Collections.IList] -and $vis -isnot [array]) { $arr = New-Object object[] $vis.Count; $vis.CopyTo($arr, 0); $vis = $arr }
    $n = $vis.Count
    $add = { param($el) if ($el) { [void]$panel.Children.Add($el) } }

    # 1. Shelves donut
    try {
    $shelfGroups = @($vis | Group-Object { ($_.Shelf -split ' › ')[0] } | Sort-Object Count -Descending)
    $items = @($shelfGroups | ForEach-Object { @{ Label = $_.Name; Value = $_.Count; Color = (Get-ShelfColor $_.Name); Tag = 'shelf|' + $_.Name } })
    & $add (New-ChartCard 'Your shelves' 'Share of the library on each shelf — click a slice to open it' (New-DonutBody $items ('{0:N0}' -f $n) 'films'))

    } catch { Write-ChartError 'Shelves donut' $_ }
    # 2. Rings: watched / has info / HD or better
    try {
    $seen = 0; $info = 0; $hd = 0; $poster = 0
    foreach ($v in $vis) { if ($v.Watched) { $seen++ }; if ($v.HasInfo) { $info++ }; if ($v.Res -eq '4K' -or $v.Res -eq '1080p') { $hd++ }; if ($v.Poster) { $poster++ } }
    $pc = { param($a) if ($n) { '{0:0}%' -f (100 * $a / $n) } else { '0%' } }
    $fr = { param($a) if ($n) { $a / $n } else { 0 } }
    $rings = (New-RingXml (& $fr $seen) '#3E8E4F' (& $pc $seen) 'Watched' ('{0:N0} of {1:N0} films' -f $seen, $n) 'smart|unseen') +
             (New-RingXml (& $fr $info) '#3F6FB0' (& $pc $info) 'Have film info' ('{0:N0} of {1:N0} · {2:N0} without' -f $info, $n, ($n - $info)) 'smart|nomatch') +
             (New-RingXml (& $fr $hd) '#C8432B' (& $pc $hd) 'HD or 4K' ('{0:N0} films at 1080p or better' -f $hd) '') +
             (New-RingXml (& $fr $poster) '#D9902F' (& $pc $poster) 'Have a poster' ('{0:N0} of {1:N0} films' -f $poster, $n) '')
    & $add (New-ChartCard 'How complete is it?' 'Progress across the whole library' "<WrapPanel HorizontalAlignment=""Center"">$rings</WrapPanel>")

    } catch { Write-ChartError 'Rings: watched / has info / HD or better' $_ }
    # 3. Decades
    try {
    $dec = @($vis | Where-Object { $_.Decade } | Group-Object Decade | Sort-Object { [int]$_.Name })
    if ($dec.Count) {
        $first = [int]$dec[0].Name; $last = [int]$dec[-1].Name
        $map = @{}; foreach ($g in $dec) { $map[[int]$g.Name] = $g.Count }
        $items = for ($d = $first; $d -le $last; $d += 10) { @{ Label = "$($d)s"; Short = "'" + ([string]$d).Substring(2); Value = [int]$map[$d]; Tag = "decade|$d" } }
        $items = @($items | ForEach-Object { $_.Label = $(if (@($items).Count -gt 8) { $_.Short } else { $_.Label }); $_ })
    } else { $items = @() }
    & $add (New-ChartCard 'Films by decade' 'When your films were made — click a column to see that decade' (New-ColumnsBody $items '#D9902F'))

    } catch { Write-ChartError 'Decades' $_ }
    # 4. Growth over 24 months (by date added to the NAS)
    try {
    $now = Get-Date; $startM = (Get-Date -Year $now.Year -Month $now.Month -Day 1).Date.AddMonths(-23)
    $before = 0; $perMonth = @{}
    foreach ($v in $vis) {
        if ($v.Added -le [datetime]::MinValue) { continue }
        if ($v.Added -lt $startM) { $before++ } else { $k = $v.Added.ToString('yyyy-MM'); $perMonth[$k] = 1 + [int]$perMonth[$k] }
    }
    $run = $before
    $months = for ($k = 0; $k -lt 24; $k++) {
        $m = $startM.AddMonths($k); $a = [int]$perMonth[$m.ToString('yyyy-MM')]; $run += $a
        [pscustomobject]@{ Label = $m.ToString('MMMM yyyy'); Short = $m.ToString('MMM yy'); Added = $a; Total = $run }
    }
    $last12 = 0; foreach ($m in ($months | Select-Object -Last 12)) { $last12 += $m.Added }
    & $add (New-ChartCard 'Library growth' ("Films on the NAS over the last two years · {0:N0} added in the last 12 months" -f $last12) (New-GrowthBody $months))

    } catch { Write-ChartError 'Growth over 24 months (by date added to the NAS)' $_ }
    # 5. TMDb ratings histogram
    try {
    $rated = @($vis | Where-Object { $_.Rating -gt 0 })
    $buckets = @(@{ L = 'under 5'; Lo = 0; Hi = 5 }, @{ L = '5'; Lo = 5; Hi = 6 }, @{ L = '6'; Lo = 6; Hi = 7 }, @{ L = '7'; Lo = 7; Hi = 8 }, @{ L = '8'; Lo = 8; Hi = 9 }, @{ L = '9+'; Lo = 9; Hi = 11 })
    $cols = @('#B5576B', '#D06A3A', '#D9902F', '#7A8B2E', '#3E8E4F', '#2A7F7A')
    $items = for ($b = 0; $b -lt $buckets.Count; $b++) {
        $bk = $buckets[$b]; $c = @($rated | Where-Object { $_.Rating -ge $bk.Lo -and $_.Rating -lt $bk.Hi }).Count
        @{ Label = $bk.L; Value = $c; Color = $cols[$b]; Tip = ('Rated {0}: {1:N0} films' -f $bk.L, $c) }
    }
    $avg = 0.0; if ($rated.Count) { foreach ($r in $rated) { $avg += $r.Rating }; $avg = $avg / $rated.Count }
    & $add (New-ChartCard 'TMDb ratings' $(if ($rated.Count) { 'Average {0:0.0} across {1:N0} rated films' -f $avg, $rated.Count } else { 'Fetch film info to see ratings' }) (New-ColumnsBody @($items) '#3E8E4F' 170))

    } catch { Write-ChartError 'TMDb ratings histogram' $_ }
    # 6. Running times histogram
    try {
    $timed = @($vis | Where-Object { $_.Runtime -gt 0 })
    $rb = @(@{ L = 'under 80'; Lo = 0; Hi = 80 }, @{ L = '80–99'; Lo = 80; Hi = 100 }, @{ L = '100–119'; Lo = 100; Hi = 120 }, @{ L = '120–139'; Lo = 120; Hi = 140 }, @{ L = '140–159'; Lo = 140; Hi = 160 }, @{ L = '160+'; Lo = 160; Hi = 9999 })
    $items = foreach ($bk in $rb) { $c = @($timed | Where-Object { $_.Runtime -ge $bk.Lo -and $_.Runtime -lt $bk.Hi }).Count; @{ Label = $bk.L; Value = $c; Tip = ('{0} minutes: {1:N0} films' -f $bk.L, $c) } }
    $avgRt = 0.0; if ($timed.Count) { foreach ($t in $timed) { $avgRt += $t.Runtime }; $avgRt = $avgRt / $timed.Count }
    & $add (New-ChartCard 'Running times (minutes)' $(if ($timed.Count) { 'Average ' + (Format-Runtime ([int]$avgRt)) } else { 'Fetch film info to see running times' }) (New-ColumnsBody @($items) '#5B6FB0' 170))

    } catch { Write-ChartError 'Running times histogram' $_ }
    # 7. Watched per shelf
    try {
    $rows = foreach ($g in $shelfGroups) { $s = @($g.Group | Where-Object { $_.Watched }).Count; [pscustomobject]@{ Label = $g.Name; Seen = $s; Total = $g.Count; Color = (Get-ShelfColor $g.Name); Tag = 'shelf|' + $g.Name } }
    & $add (New-ChartCard 'Watched, shelf by shelf' 'How far through each shelf you are' (New-ProgressBody $rows))

    } catch { Write-ChartError 'Watched per shelf' $_ }
    # 8. Picture quality donut
    try {
    $qc = @{ '4K' = '#7B4FA6'; '1080p' = '#2A7F7A'; '720p' = '#D9902F'; 'SD' = '#B5576B'; 'Unknown' = '#C9BEA9' }
    $items = foreach ($q in '4K', '1080p', '720p', 'SD', 'Unknown') {
        $c = @($vis | Where-Object { ($(if ($_.Res) { $_.Res } else { 'Unknown' })) -eq $q }).Count
        @{ Label = $q; Value = $c; Color = $qc[$q]; Tag = "res|$q" }
    }
    $gb = 0.0; foreach ($v in $vis) { $gb += $v.Size }
    & $add (New-ChartCard 'Picture quality' 'Click a slice to list those films' (New-DonutBody @($items) (Format-Size $gb) 'on the NAS'))
    } catch { Write-ChartError 'Picture quality donut' $_ }
}

# Clicking a slice, column or bar jumps to those films in the Library
function Invoke-ChartTag([string]$tag) {
    if (-not $tag) { return }
    $kind, $val = $tag -split '\|', 2
    $Script:Loading = $true
    try {
        foreach ($c in @('tgUnwatched', 'tgFavs', 'tgList', 'tgNoInfo')) { $UI[$c].IsChecked = $false }
        foreach ($c in @('cbGenre', 'cbDecade', 'cbRes')) { $UI[$c].SelectedIndex = 0 }
        $UI.txtSearch.Text = ''
        switch ($kind) {
            'shelf'  { $Script:CurShelf = @{ Kind = 'shelf'; Id = $val } }
            'smart'  { $Script:CurShelf = @{ Kind = 'smart'; Id = $val } }
            'decade' { $Script:CurShelf = @{ Kind = 'smart'; Id = 'all' }; $UI.cbDecade.SelectedItem = "$($val)s" }
            'res'    { $Script:CurShelf = @{ Kind = 'smart'; Id = 'all' }; $UI.cbRes.SelectedItem = $val }
        }
    } finally { $Script:Loading = $false }
    Refresh-Rail
    Select-Tab 'Library'
    Apply-Filter
}

$UI.ugCharts.Add_PreviewMouseLeftButtonUp({
    param($s, $e)
    $el = $e.OriginalSource; $guard = 0
    while ($el -and $guard -lt 12) {
        $guard++
        if ($el -is [Windows.FrameworkElement] -and $el.Tag -and ([string]$el.Tag) -match '^(shelf|smart|decade|res)\|') { Invoke-ChartTag ([string]$el.Tag); $e.Handled = $true; return }
        if ($el -is [Windows.Media.Visual]) { $el = [Windows.Media.VisualTreeHelper]::GetParent($el) } else { $el = $null }
    }
})

# =====================================================================================
#  Choose a copy — Radarr's interactive search, so you pick the download (size, quality, seeders) yourself
# =====================================================================================
$ReleasesWork = {
    param($sync, $p)
    $sync.Status = "Asking your indexers for copies of $($p.Title)…"
    $h = @{ 'X-Api-Key' = $p.Key; Accept = 'application/json' }
    $r = Invoke-RestMethod -Uri ($p.Url + "/api/v3/release?movieId=$($p.MovieId)") -Headers $h -TimeoutSec 240 -UseBasicParsing
    $out = New-Object Collections.ArrayList
    foreach ($x in $r) {
        if (-not $x -or -not $x.guid) { continue }
        $age = 0.0; try { $age = [double]$x.ageHours / 24.0 } catch {}
        if (-not $age) { try { $age = [double]$x.age } catch {} }
        [void]$out.Add(@{
            Guid = [string]$x.guid; IndexerId = [int]$x.indexerId; Title = [string]$x.title; Size = [double]$x.size
            Quality = [string]$x.quality.quality.name; Res = [int]$x.quality.quality.resolution
            Seeders = $(if ($null -ne $x.seeders) { [int]$x.seeders } else { -1 }); Leechers = $(if ($null -ne $x.leechers) { [int]$x.leechers } else { -1 })
            Protocol = [string]$x.protocol; Indexer = [string]$x.indexer; AgeDays = $age
            Rejected = [bool]$x.rejected; Rejections = (@($x.rejections | ForEach-Object { if ($_ -is [string]) { $_ } else { [string]$_.reason } } | Where-Object { $_ }) -join '; ')
            Languages = (@($x.languages | ForEach-Object { [string]$_.name } | Where-Object { $_ }) -join ', ')
            Score = $(try { [int]$x.customFormatScore } catch { 0 })
        })
    }
    $sync.Result = $out.ToArray()
}

$ReleaseDialogXaml = @'
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Choose a copy" Width="1080" Height="700" MinWidth="760" MinHeight="420" WindowStartupLocation="CenterOwner" Background="#F3EEE4" FontFamily="Segoe UI" FontSize="13">
  <Window.Resources><!--COMBOSTYLES--></Window.Resources>
  <DockPanel>
  <!--HEADER-->
  <DockPanel Margin="22,14,22,16">
    <StackPanel DockPanel.Dock="Top">
      <TextBlock x:Name="rTitle" FontWeight="SemiBold" FontSize="15" Margin="0,0,0,0" TextWrapping="Wrap"/>
      <TextBlock x:Name="rCurrent" Foreground="#7B7266" Margin="0,2,0,12" TextWrapping="Wrap"/>
      <WrapPanel Margin="0,0,0,10">
        <TextBlock Text="Sort" Foreground="#7B7266" VerticalAlignment="Center" Margin="0,0,6,6"/>
        <ComboBox x:Name="rSort" Width="170" Margin="0,0,14,6"/>
        <TextBlock Text="Up to" Foreground="#7B7266" VerticalAlignment="Center" Margin="0,0,6,6"/>
        <ComboBox x:Name="rMax" Width="110" Margin="0,0,14,6"/>
        <TextBlock Text="Quality" Foreground="#7B7266" VerticalAlignment="Center" Margin="0,0,6,6"/>
        <ComboBox x:Name="rQual" Width="130" Margin="0,0,14,6"/>
        <CheckBox x:Name="rHideRej" Content="Hide ones Radarr would refuse" VerticalAlignment="Center" Margin="0,0,14,6"/>
        <TextBlock x:Name="rCount" Foreground="#7B7266" VerticalAlignment="Center" Margin="0,0,0,6"/>
      </WrapPanel>
    </StackPanel>
    <DockPanel DockPanel.Dock="Bottom" Margin="0,12,0,0">
      <StackPanel DockPanel.Dock="Right" Orientation="Horizontal">
        <Button Content="Close" Style="{StaticResource PHDlgGhost}" Margin="0,0,8,0" IsCancel="True"/>
        <Button x:Name="rGo" Content="Download this one" Style="{StaticResource PHDlgPrimary}" IsEnabled="False"/>
      </StackPanel>
      <TextBlock x:Name="rPicked" Foreground="#173F3E" VerticalAlignment="Center" TextTrimming="CharacterEllipsis" Margin="0,0,12,0"/>
    </DockPanel>
    <Grid>
      <ListBox x:Name="rList" Background="#FFFCF6" BorderBrush="#E2D9C9" BorderThickness="1" HorizontalContentAlignment="Stretch"
               ScrollViewer.HorizontalScrollBarVisibility="Disabled" VirtualizingPanel.IsVirtualizing="True" VirtualizingPanel.ScrollUnit="Pixel">
        <ListBox.ItemTemplate>
          <DataTemplate>
            <Grid Margin="4,6" Opacity="{Binding Opac}">
              <Grid.ColumnDefinitions>
                <ColumnDefinition Width="112"/><ColumnDefinition Width="86"/><ColumnDefinition Width="110"/><ColumnDefinition Width="70"/><ColumnDefinition Width="130"/><ColumnDefinition Width="*"/>
              </Grid.ColumnDefinitions>
              <Border Background="{Binding QBrush}" CornerRadius="3" Padding="7,2" HorizontalAlignment="Left" VerticalAlignment="Top">
                <TextBlock Text="{Binding Quality}" Foreground="White" FontSize="11" FontWeight="Bold"/>
              </Border>
              <TextBlock Grid.Column="1" Text="{Binding SizeText}" FontWeight="Bold" FontSize="14" Foreground="{Binding SizeBrush}"/>
              <TextBlock Grid.Column="2" Text="{Binding PeersText}" Foreground="#4A433B"/>
              <TextBlock Grid.Column="3" Text="{Binding AgeText}" Foreground="#7B7266"/>
              <TextBlock Grid.Column="4" Text="{Binding Indexer}" Foreground="#7B7266" TextTrimming="CharacterEllipsis" Margin="0,0,8,0"/>
              <StackPanel Grid.Column="5">
                <TextBlock Text="{Binding Title}" TextTrimming="CharacterEllipsis" ToolTip="{Binding Title}"/>
                <TextBlock Text="{Binding Extra}" Foreground="#7B7266" FontSize="11.5" Visibility="{Binding ExtraVis}" TextTrimming="CharacterEllipsis"/>
                <TextBlock Text="{Binding RejectText}" Foreground="#C8432B" FontSize="11.5" Visibility="{Binding RejectVis}" TextWrapping="Wrap"/>
              </StackPanel>
            </Grid>
          </DataTemplate>
        </ListBox.ItemTemplate>
      </ListBox>
      <StackPanel x:Name="rLoading" HorizontalAlignment="Center" VerticalAlignment="Center" MaxWidth="520">
        <TextBlock x:Name="rLoadingText" FontFamily="Georgia" FontStyle="Italic" FontSize="19" Foreground="#7B7266" TextWrapping="Wrap" TextAlignment="Center"
                   Text="Asking your indexers for every available copy… this can take up to a minute."/>
        <ProgressBar IsIndeterminate="True" Height="4" Margin="40,16,40,0" Foreground="#173F3E" Background="#E2D9C9" BorderThickness="0"/>
      </StackPanel>
    </Grid>
  </DockPanel>
  </DockPanel>
</Window>
'@

$Script:RelDlg = $null
function Show-ReleasePicker([int]$movieId, [string]$label, [string]$current, [int]$tmdbId) {
    if ($movieId -le 0) { return }
    [xml]$dx = $ReleaseDialogXaml.Replace('<!--COMBOSTYLES-->', $ComboStyles + $DialogStyles).Replace('<!--HEADER-->', (New-DialogHeader 'Choose a copy'))
    $dw = [Windows.Markup.XamlReader]::Load((New-Object System.Xml.XmlNodeReader $dx))
    $dw.Owner = $Window
    $d = @{ Win = $dw; MovieId = $movieId; Label = $label; TmdbId = $tmdbId; Items = $null; Loading = $true
            List = $dw.FindName('rList'); Go = $dw.FindName('rGo'); Picked = $dw.FindName('rPicked'); Count = $dw.FindName('rCount')
            Sort = $dw.FindName('rSort'); Max = $dw.FindName('rMax'); Qual = $dw.FindName('rQual'); HideRej = $dw.FindName('rHideRej')
            LoadPanel = $dw.FindName('rLoading'); LoadText = $dw.FindName('rLoadingText') }
    $Script:RelDlg = $d
    $dw.FindName('rTitle').Text = $label
    $dw.FindName('rCurrent').Text = $current + "   ·   Nothing downloads until you pick one and press ‘Download this one’."
    $d.Sort.ItemsSource = @('Largest first', 'Smallest first', 'Most seeders', 'Best quality', 'Newest first'); $d.Sort.SelectedIndex = 0
    $d.Max.ItemsSource = @('Any size', '2 GB', '4 GB', '6 GB', '8 GB', '12 GB', '20 GB', '40 GB'); $d.Max.SelectedIndex = 0
    $d.Qual.ItemsSource = @('Any quality', '720p or better', '1080p or better', '1080p only', '4K only'); $d.Qual.SelectedIndex = 0
    foreach ($c in @($d.Sort, $d.Max, $d.Qual)) { $c.Add_SelectionChanged({ Update-ReleaseList }) }
    $d.HideRej.Add_Click({ Update-ReleaseList })
    $d.List.Add_SelectionChanged({
        $x = $Script:RelDlg; if (-not $x) { return }
        $it = $x.List.SelectedItem
        $x.Go.IsEnabled = ($null -ne $it)
        $x.Picked.Text = $(if ($it) { "Picked: $($it.Quality)  ·  $($it.SizeText)  ·  $($it.Indexer)" } else { '' })
    })
    $d.List.Add_MouseDoubleClick({ if ($Script:RelDlg -and $Script:RelDlg.List.SelectedItem) { Invoke-ReleaseGrab } })
    $d.Go.Add_Click({ Invoke-ReleaseGrab })
    $dw.Add_Closed({ $Script:RelDlg = $null })
    [void](Start-BgJob 'Releases' $ReleasesWork @{ Url = (Normalize-ServiceUrl $Settings.RadarrUrl); Key = ([string]$Settings.RadarrKey).Trim(); MovieId = $movieId; Title = $label } $null ${function:On-ReleasesDone})
    [void]$dw.ShowDialog()
}

function On-ReleasesDone($sync) {
    $d = $Script:RelDlg; if (-not $d) { return }   # dialog already closed
    $d.Loading = $false
    if ($sync.Error -or $null -eq $sync.Result) {
        $d.LoadText.Text = "Radarr couldn't get the list of copies.`n`n" + [string]$sync.Error
        $d.LoadPanel.Children[1].Visibility = 'Collapsed'
        return
    }
    $d.Items = @($sync.Result)
    if ($d.Items.Count -eq 0) {
        $d.LoadText.Text = 'Your indexers didn''t find any copies of this film right now.'
        $d.LoadPanel.Children[1].Visibility = 'Collapsed'
        return
    }
    $d.LoadPanel.Visibility = 'Collapsed'
    Update-ReleaseList
}

function Get-ReleaseResRank($it) {
    $r = [int]$it['Res']
    if ($r -ge 2000) { return 4 }; if ($r -ge 1000) { return 3 }; if ($r -ge 700) { return 2 }; if ($r -gt 0) { return 1 }
    $q = [string]$it['Quality']
    if ($q -match '2160|4K|UHD') { return 4 }; if ($q -match '1080') { return 3 }; if ($q -match '720') { return 2 }
    return 1
}

function Update-ReleaseList {
    $d = $Script:RelDlg; if (-not $d -or -not $d.Items) { return }
    $maxGb = 0.0; if ([string]$d.Max.SelectedItem -match '^(\d+) GB') { $maxGb = [double]$Matches[1] }
    $q = [string]$d.Qual.SelectedItem
    $hide = [bool]$d.HideRej.IsChecked
    $d.NonEnglish = 0
    $rows = foreach ($it in $d.Items) {
        $rank = Get-ReleaseResRank $it
        if ($maxGb -gt 0 -and [double]$it['Size'] -gt $maxGb * 1GB) { continue }
        # (plain ifs: "continue" inside a PowerShell switch only leaves the switch)
        if ($q -eq '720p or better' -and $rank -lt 2) { continue }
        if ($q -eq '1080p or better' -and $rank -lt 3) { continue }
        if ($q -eq '1080p only' -and $rank -ne 3) { continue }
        if ($q -eq '4K only' -and $rank -ne 4) { continue }
        if ($hide -and $it['Rejected']) { continue }
        # English only: a copy must be labelled English (copies with no language label are left out too)
        $langs = @(([string]$it['Languages']) -split ',\s*' | Where-Object { $_ })
        if (-not ($langs -contains 'English')) { $Script:RelDlg.NonEnglish++; continue }
        $gb = [double]$it['Size'] / 1GB
        $peers = $(if ($it['Protocol'] -eq 'usenet') { 'Usenet' } elseif ([int]$it['Seeders'] -ge 0) { "$($it['Seeders']) seeders" } else { '' })
        $ageD = [double]$it['AgeDays']
        $ageT = $(if ($ageD -lt 1) { 'today' } elseif ($ageD -lt 60) { '{0:0} days' -f $ageD } elseif ($ageD -lt 730) { '{0:0} months' -f ($ageD / 30.4) } else { '{0:0} years' -f ($ageD / 365.25) })
        $extra = @(); if ($it['Languages']) { $extra += $it['Languages'] }; if ([int]$it['Score']) { $extra += "custom format score $($it['Score'])" }
        [pscustomobject]@{
            Guid = $it['Guid']; IndexerId = $it['IndexerId']; Title = $it['Title']; Size = [double]$it['Size']; Rank = $rank; Seeders = [int]$it['Seeders']; AgeDays = $ageD
            Quality = $(if ($it['Quality']) { $it['Quality'] } else { 'Unknown' })
            QBrush = @('#7B7266', '#C8432B', '#D9902F', '#3F86B0', '#3E8E4F')[$rank]
            SizeText = $(if ($gb -ge 1) { '{0:0.0} GB' -f $gb } else { '{0:0} MB' -f ($gb * 1024) })
            SizeBrush = $(if ($gb -le 4) { '#2A7F7A' } elseif ($gb -le 12) { '#1F1B16' } else { '#C8432B' })
            PeersText = $peers; AgeText = $ageT; Indexer = $it['Indexer']
            Extra = ($extra -join '  ·  '); ExtraVis = $(if ($extra.Count) { 'Visible' } else { 'Collapsed' })
            Rejected = [bool]$it['Rejected']; RejectText = $(if ($it['Rejected']) { 'Radarr would refuse this: ' + $it['Rejections'] } else { '' })
            RejectVis = $(if ($it['Rejected']) { 'Visible' } else { 'Collapsed' }); Opac = $(if ($it['Rejected']) { 0.6 } else { 1.0 })
        }
    }
    $rows = @($rows)
    $rows = switch ([string]$d.Sort.SelectedItem) {
        'Largest first' { @($rows | Sort-Object Size -Descending) }
        'Most seeders'  { @($rows | Sort-Object @{ e = { $_.Seeders }; d = $true }, Size) }
        'Best quality'  { @($rows | Sort-Object @{ e = { $_.Rank }; d = $true }, Size) }
        'Newest first'  { @($rows | Sort-Object AgeDays, Size) }
        'Smallest first' { @($rows | Sort-Object Size) }
        default         { @($rows | Sort-Object Size -Descending) }
    }
    $d.List.ItemsSource = $rows
    $d.Count.Text = "$($rows.Count) cop$(if ($rows.Count -eq 1) { 'y' } else { 'ies' })"
}

function Invoke-ReleaseGrab {
    $d = $Script:RelDlg; if (-not $d) { return }
    $it = $d.List.SelectedItem; if (-not $it) { return }
    $msg = "Download this copy of $($d.Label)?`n`n$($it.Title)`n$($it.Quality)  ·  $($it.SizeText)  ·  $($it.Indexer)$(if ($it.PeersText) { '  ·  ' + $it.PeersText })`n`n" +
           "Radarr sends it to your download client now, and swaps it in for your current copy when the download finishes."
    if ($it.Rejected) { $msg += "`n`nHeads up — Radarr would normally refuse this one: $($it.RejectText.Replace('Radarr would refuse this: ', ''))" }
    if ([Windows.MessageBox]::Show($d.Win, $msg, $AppName, 'YesNo', 'Question') -ne 'Yes') { return }
    $vars = @{ Guid = [string]$it.Guid; IndexerId = [int]$it.IndexerId; Release = [string]$it.Title; Label = $d.Label; MovieId = $d.MovieId; TmdbId = $d.TmdbId; Quality = $it.Quality; Size = $it.SizeText }
    $d.Win.Close()
    Show-Toast "Sending your pick to Radarr…" "$($vars.Quality)  ·  $($vars.Size)" 'wait' 5
    Invoke-Async "Sending your pick for $($vars.Label) to Radarr…" { param($v) [void](Invoke-Radarr 'POST' '/release' @{ guid = $v.Guid; indexerId = $v.IndexerId }); $true } $vars {
        param($r, $v)
        Write-Log "Radarr: you picked $($v.Release) ($($v.Size)) for $($v.Label)."
        Show-Toast "Sent to Radarr: $($v.Label)" "$($v.Quality)  ·  $($v.Size)`nI'll check it reached your download client." 'ok' 10
        $Script:RadarrActivity[[string]$v.TmdbId] = "You picked a $($v.Quality) copy ($($v.Size)) — sent to Radarr"
        if ($UI.navUpgrades.IsChecked) { Refresh-Upgrades }
        Add-Pick $v.MovieId $v.Label $v.TmdbId $v.Release $v.Quality $v.Size
        Start-RadarrWatch $v.MovieId 0 $v.Label $v.TmdbId 'grab'
    } { param($err) Tell ("Radarr didn't take that one.`n`n" + $err + "`n`n(The list goes stale after about half an hour — open Choose a copy again.)") 'Warning' }
}


# =====================================================================================
#  Your picks — copies you chose in "Choose a copy". Picture House follows each one until Radarr
#  swaps it in, and if Radarr holds it back (e.g. "not an upgrade") offers "Import it anyway".
# =====================================================================================
$Files.Picks = Join-Path $DataDir 'radarr-picks.json'
$Script:Picks = @{}
$j = PH-LoadJson $Files.Picks
if ($j) { foreach ($k in @($j.Keys)) { $Script:Picks[$k] = $j[$k] } }
Remove-Variable j -ErrorAction SilentlyContinue

function Save-Picks { PH-SaveJson $Script:Picks $Files.Picks }

function Add-Pick([int]$movieId, [string]$title, [int]$tmdbId, [string]$release, [string]$quality, [string]$size) {
    $Script:Picks[[string]$movieId] = @{ MovieId = $movieId; Title = $title; TmdbId = $tmdbId; Release = $release; Quality = $quality; Size = $size
                                         Picked = (Get-Date).ToUniversalTime().ToString('s'); State = 'sent'; Note = ''; DownloadId = ''; Warned = $false }
    Save-Picks
    Refresh-Picks
}

$PicksWork = {
    param($sync, $p)
    $sync.Status = 'Checking on the copies you picked…'
    $h = @{ 'X-Api-Key' = $p.Key; Accept = 'application/json' }
    $base = $p.Url + '/api/v3'
    $out = @{}
    # ask Radarr to re-read your download client first, so the % is up to the moment (Radarr otherwise refreshes about once a minute)
    if ($p.Refresh) {
        try { [void](Invoke-RestMethod -Method Post -Uri "$base/command" -Headers $h -Body '{"name":"RefreshMonitoredDownloads"}' -ContentType 'application/json' -TimeoutSec 20 -UseBasicParsing); Start-Sleep -Seconds 2 } catch {}
    }
    foreach ($pk in @($p.Picks)) {
        $mid = [int]$pk.MovieId
        $r = @{ State = ''; Note = ''; DownloadId = ''; Pct = -1 }
        try {
            $q = $null
            foreach ($x in (Invoke-RestMethod -Uri "$base/queue/details?movieId=$mid" -Headers $h -TimeoutSec 30 -UseBasicParsing)) { if ($x -and $x.title) { $q = $x; break } }
            if ($q) {
                $r.DownloadId = [string]$q.downloadId
                $ts = [string]$q.trackedDownloadState; $st = [string]$q.trackedDownloadStatus
                $msgs = @($q.statusMessages | ForEach-Object { @($_.messages) } | Where-Object { $_ } | Select-Object -Unique)
                if ([double]$q.size -gt 0) { $r.Pct = [int](100 * (1 - [double]$q.sizeleft / [double]$q.size)) }
                if ($ts -match 'failed' -or $st -eq 'error') { $r.State = 'failed'; $r.Note = ($msgs -join ' ') }
                elseif ($ts -in @('importPending', 'importBlocked') -or ($st -eq 'warning' -and [double]$q.sizeleft -le 0)) { $r.State = 'stuck'; $r.Note = ($msgs -join ' ') }
                elseif ($ts -eq 'importing') { $r.State = 'importing' }
                else { $r.State = 'downloading'; if ($st -eq 'warning') { $r.Note = ($msgs -join ' ') } }
            } else {
                $m = Invoke-RestMethod -Uri "$base/movie/$mid" -Headers $h -TimeoutSec 30 -UseBasicParsing
                $added = [datetime]::MinValue
                if ($m.movieFile -and $m.movieFile.dateAdded) {
                    if ($m.movieFile.dateAdded -is [datetime]) { $added = $m.movieFile.dateAdded.ToUniversalTime() }
                    else { [void][datetime]::TryParse([string]$m.movieFile.dateAdded, [Globalization.CultureInfo]::InvariantCulture, [Globalization.DateTimeStyles]::AdjustToUniversal, [ref]$added) }
                }
                $picked = [datetime]::Parse([string]$pk.Picked, [Globalization.CultureInfo]::InvariantCulture)
                if ($added -gt $picked.AddMinutes(-2)) { $r.State = 'imported'; $r.Note = [string]$m.movieFile.quality.quality.name }
                else { $r.State = 'gone' }
            }
        } catch { $r.State = 'error'; $r.Note = $_.Exception.Message }
        $out[[string]$mid] = $r
    }
    $sync.Result = $out
}

function Start-PicksCheck {
    if (-not $Script:Picks.Count -or -not $Settings.RadarrUrl -or -not $Settings.RadarrKey) { return }
    if (Test-Busy 'Picks') { return }
    $active = @($Script:Picks.Values | Where-Object { [string]$_['State'] -in @('sent', 'downloading', 'importing') }).Count
    [void](Start-BgJob 'Picks' $PicksWork @{ Url = (Normalize-ServiceUrl $Settings.RadarrUrl); Key = ([string]$Settings.RadarrKey).Trim(); Picks = @($Script:Picks.Values); Refresh = ($active -gt 0) } $null ${function:On-PicksDone})
}

function On-PicksDone($sync) {
    if (-not $sync.Result) { return }
    $changed = $false
    foreach ($k in @($sync.Result.Keys)) {
        $pk = $Script:Picks[$k]; if (-not $pk) { continue }
        $r = $sync.Result[$k]
        if ($r.State -eq 'error') { continue }   # Radarr not reachable right now — try again later
        $old = [string]$pk['State']
        $pk['Note'] = $r.Note; if ($r.DownloadId) { $pk['DownloadId'] = $r.DownloadId }; $pk['Pct'] = $r.Pct
        $title = [string]$pk['Title']
        # (plain ifs: "continue" inside a PowerShell switch only leaves the switch)
        if ($r.State -eq 'stuck' -and $old -ne 'stuck') {
            Show-Toast "Radarr is holding back $title" ("The download finished, but Radarr won't swap it in by itself" + $(if ($r.Note) { ":`n$($r.Note)" } else { '.' })) 'warn' 0 'Import it anyway' { param($id) Invoke-ImportAnyway $id } ([int]$k)
        }
        if ($r.State -eq 'imported') {
            Show-Toast "$title has been upgraded" ("Radarr swapped in the copy you picked$(if ($r.Note) { " ($($r.Note))" }). Rescan the NAS to see it here.") 'ok' 15
            $Script:RadarrActivity[[string]$pk['TmdbId']] = "Upgraded to the $(if ($r.Note) { $r.Note } else { 'copy you picked' }) — rescan to see it"
            $Script:Picks.Remove($k); $changed = $true; continue
        }
        if ($r.State -eq 'failed') {
            Show-Toast "The download of $title failed" ($(if ($r.Note) { $r.Note } else { 'Look in Radarr → Activity for the reason.' }) + "`nOpen Choose a copy again to pick another.") 'warn' 0
            $Script:Picks.Remove($k); $changed = $true; continue
        }
        if ($r.State -eq 'gone') {
            # not in the queue and no new file: only give up after a while (it may not have reached the queue yet)
            $picked = PH-Date $pk['Picked']
            if ($old -in @('downloading', 'importing', 'stuck') -or $picked -lt (Get-Date).ToUniversalTime().AddHours(-6)) {
                Show-Toast "$title isn't in Radarr's queue any more" 'It was removed or failed — check Radarr → Activity → History.' 'wait' 15
                $Script:Picks.Remove($k); $changed = $true; continue
            }
        }
        if ($r.State -and $r.State -ne 'gone') { $pk['State'] = $r.State }
        $changed = $true
    }
    if ($changed) { Save-Picks }
    Refresh-Picks
    Set-PicksPace
}

function Invoke-ImportAnyway([int]$movieId) {
    $pk = $Script:Picks[[string]$movieId]; if (-not $pk) { return }
    $title = [string]$pk['Title']
    $msg = "Import the copy you picked for $title anyway?`n`n$($pk['Release'])`n$($pk['Quality'])  ·  $($pk['Size'])`n`n" +
           "Radarr will swap it in for your current copy — Radarr removes the old file (to its recycle bin, if you've set one in Radarr → Settings → Media Management).`n`n" +
           "Nothing else is changed — your Radarr settings stay as they are."
    if (-not (Ask $msg)) { return }
    Invoke-Async "Importing $title…" {
        param($v)
        $dl = $v.DownloadId
        if (-not $dl) { foreach ($x in @(Invoke-Radarr 'GET' "/queue/details?movieId=$($v.MovieId)" $null)) { if ($x -and $x.downloadId) { $dl = [string]$x.downloadId; break } } }
        if (-not $dl) { return @{ State = 'nodownload' } }
        $cands = @(Invoke-Radarr 'GET' ("/manualimport?downloadId=" + [uri]::EscapeDataString($dl) + "&filterExistingFiles=false") $null | Where-Object { $_ -and $_.path })
        # the film itself, not samples or extras: the biggest video file
        $f = @($cands | Where-Object { [string]$_.path -match '\.(mkv|mp4|avi|m4v|ts|m2ts|wmv|mov|iso)$' -and [string]$_.path -notmatch '(?i)[\\/._-]sample[\\/._-]' } | Sort-Object { [double]$_.size } -Descending | Select-Object -First 1)
        if (-not $f.Count) { return @{ State = 'nofile' } }
        $f = $f[0]
        $item = @{ path = [string]$f.path; movieId = $v.MovieId; downloadId = $dl; releaseGroup = [string]$f.releaseGroup }
        if ($f.folderName) { $item.folderName = [string]$f.folderName }
        if ($f.quality) { $item.quality = $f.quality }
        if ($f.languages) { $item.languages = @($f.languages) }
        if ($null -ne $f.indexerFlags) { $item.indexerFlags = [int]$f.indexerFlags }
        [void](Invoke-Radarr 'POST' '/command' @{ name = 'ManualImport'; importMode = 'auto'; files = @($item) })
        return @{ State = 'importing'; Path = [string]$f.path }
    } @{ MovieId = $movieId; DownloadId = [string]$pk['DownloadId']; Title = $title } {
        param($r, $v)
        $title = $v.Title
        if ($r.State -eq 'nodownload') { Tell "Radarr hasn't got that download in its queue any more, so there's nothing to import.`n`nCheck Radarr → Activity." 'Warning'; return }
        if ($r.State -eq 'nofile') { Tell "Radarr couldn't find the downloaded film file to import.`n`nIt may still be unpacking — try again in a minute, or use Radarr → Activity → Queue → Manual Import." 'Warning'; return }
        Write-Log "Radarr: import anyway for $title ($($r.Path))."
        $pk = $Script:Picks[[string]$v.MovieId]; if ($pk) { $pk['State'] = 'importing'; Save-Picks; Refresh-Picks }
        Show-Toast "Importing $title" 'Radarr is swapping it in now — I''ll tell you when it''s done.' 'wait' 10
        $Script:PicksTimer.Interval = [TimeSpan]::FromSeconds(20)   # check back soon
    } { param($err) Tell ("Radarr wouldn't import it.`n`n" + $err + "`n`nYou can still do it in Radarr → Activity → Queue → Manual Import.") 'Warning' }
}

function Remove-Pick([int]$movieId) { $Script:Picks.Remove([string]$movieId); Save-Picks; Refresh-Picks }

# the "Your picks" strip on the Upgrades page
function Refresh-Picks {
    $rows = foreach ($pk in @($Script:Picks.Values | Sort-Object { [string]$_['Picked'] } -Descending)) {
        $st = [string]$pk['State']; $pct = [int]$pk['Pct']
        $text = switch ($st) {
            'downloading' { 'Downloading' + $(if ($pct -ge 0) { " — $pct%" } else { '' }) }
            'stuck'       { 'Downloaded, but Radarr is holding it back' + $(if ($pk['Note']) { ': ' + $pk['Note'] } else { '' }) }
            'importing'   { 'Being swapped in…' }
            default       { 'Sent to Radarr — waiting for it to start' }
        }
        [pscustomobject]@{ Pct = [double][math]::Max(0, $pct); PctVis = $(if ($st -eq 'downloading' -and $pct -ge 0) { 'Visible' } else { 'Collapsed' })
                           Title = [string]$pk['Title']; Detail = "$($pk['Quality'])  ·  $($pk['Size'])  ·  $($pk['Release'])"; StateText = $text
                           StateBrush = $(if ($st -eq 'stuck') { '#C8432B' } else { '#173F3E' })
                           ImportTag = "import|$($pk['MovieId'])"; ImportVis = $(if ($st -eq 'stuck') { 'Visible' } else { 'Collapsed' }); ForgetTag = "forget|$($pk['MovieId'])" }
    }
    $rows = @($rows)
    $UI.icPicks.ItemsSource = $rows
    $UI.bdPicks.Visibility = $(if ($rows.Count) { 'Visible' } else { 'Collapsed' })
}

# check every few minutes while you have picks on the go
$Script:PicksTimer = New-Object Windows.Threading.DispatcherTimer
$Script:PicksTimer.Interval = [TimeSpan]::FromMinutes(2)
$Script:PicksTimer.Add_Tick({ Set-PicksPace; Start-PicksCheck })
function Set-PicksPace {
    # every 10 seconds while you're watching a download on the Upgrades page, every 2 minutes otherwise
    $active = @($Script:Picks.Values | Where-Object { [string]$_['State'] -in @('sent', 'downloading', 'importing') }).Count
    $fast = ($active -gt 0 -and $UI.navUpgrades.IsChecked -and $Window.IsActive)
    $Script:PicksTimer.Interval = $(if ($fast) { [TimeSpan]::FromSeconds(10) } else { [TimeSpan]::FromMinutes(2) })
}

# =====================================================================================
#  About — what Picture House is, and who and what made it possible
# =====================================================================================
$AboutDialogXaml = @'
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="About Picture House" Width="560" SizeToContent="Height" WindowStartupLocation="CenterOwner" Background="#F3EEE4" FontFamily="Segoe UI" FontSize="13" ResizeMode="NoResize">
  <Window.Resources><!--COMBOSTYLES--></Window.Resources>
  <DockPanel>
    <Border DockPanel.Dock="Top" Background="#173F3E" Padding="26,22,26,22">
      <StackPanel>
        <TextBlock Text="Picture House" FontFamily="Georgia" FontStyle="Italic" FontSize="34" Foreground="#F6EBD9"/>
        <TextBlock x:Name="aVersion" Foreground="#C9F6EBD9" FontSize="14" Margin="0,4,0,0"/>
      </StackPanel>
    </Border>
    <StackPanel Margin="26,18,26,22">
      <TextBlock TextWrapping="Wrap" LineHeight="20" Foreground="#2E2924"
                 Text="A film library for the shelves on your NAS — posters, cast and crew, collections, Tonight's Pick, awards, upgrades and your year in film, all from your PC. Your films stay where they are; Picture House only reads them."/>
      <TextBlock Text="CREDITS" FontSize="10.5" FontWeight="Bold" Foreground="#7B7266" Margin="0,18,0,8"/>
      <Grid>
        <Grid.ColumnDefinitions><ColumnDefinition Width="130"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
        <Grid.RowDefinitions><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/></Grid.RowDefinitions>
        <TextBlock Text="Created by" Foreground="#7B7266" Margin="0,0,0,8"/>
        <TextBlock Grid.Column="1" Text="Jason Rhodes" FontWeight="SemiBold" Margin="0,0,0,8"/>
        <TextBlock Grid.Row="1" Text="Built with" Foreground="#7B7266" Margin="0,0,0,8"/>
        <TextBlock Grid.Row="1" Grid.Column="1" TextWrapping="Wrap" Margin="0,0,0,8" Text="Claude, by Anthropic — written together with Claude"/>
        <TextBlock Grid.Row="2" Text="Film information" Foreground="#7B7266" Margin="0,0,0,8"/>
        <StackPanel Grid.Row="2" Grid.Column="1" Margin="0,0,0,8">
          <TextBlock TextWrapping="Wrap" Text="Posters, plots, cast and crew, collections and people from The Movie Database (TMDb)."/>
          <TextBlock TextWrapping="Wrap" FontSize="11.5" Foreground="#7B7266" Margin="0,2,0,0" Text="This product uses the TMDB API but is not endorsed or certified by TMDB."/>
        </StackPanel>
        <TextBlock Grid.Row="3" Text="Awards" Foreground="#7B7266" Margin="0,0,0,8"/>
        <TextBlock Grid.Row="3" Grid.Column="1" TextWrapping="Wrap" Margin="0,0,0,8" Text="Oscar, BAFTA and Golden Globe data from Wikidata (free to use, CC0)."/>
        <TextBlock Grid.Row="4" Text="Works with" Foreground="#7B7266" Margin="0,0,0,8"/>
        <TextBlock Grid.Row="4" Grid.Column="1" TextWrapping="Wrap" Margin="0,0,0,8" Text="Radarr and Seerr for finding and downloading films; Zoom Player (or your own player) for watching them."/>
        <TextBlock Grid.Row="5" Text="Made with" Foreground="#7B7266" Margin="0,0,0,8"/>
        <TextBlock Grid.Row="5" Grid.Column="1" TextWrapping="Wrap" Margin="0,0,0,8" Text="Windows PowerShell and WPF, Georgia and Segoe UI type, Segoe Fluent Icons."/>
        <TextBlock Grid.Row="6" Text="Your data" Foreground="#7B7266"/>
        <TextBlock Grid.Row="6" Grid.Column="1" TextWrapping="Wrap" x:Name="aData"/>
      </Grid>
      <WrapPanel Margin="0,16,0,0">
        <Button x:Name="aTmdb" Content="TMDb ↗" Style="{StaticResource PHDlgGhost}" Margin="0,0,6,6"/>
        <Button x:Name="aWiki" Content="Wikidata ↗" Style="{StaticResource PHDlgGhost}" Margin="0,0,6,6"/>
      </WrapPanel>
      <DockPanel Margin="0,10,0,0">
        <Button x:Name="aClose" DockPanel.Dock="Right" Content="Close" Style="{StaticResource PHDlgPrimary}" IsCancel="True" IsDefault="True"/>
        <Button x:Name="aHistory" Content="Version history…" Style="{StaticResource PHDlgGhost}" HorizontalAlignment="Left"/>
      </DockPanel>
    </StackPanel>
  </DockPanel>
</Window>
'@
function Show-About {
    [xml]$dx = $AboutDialogXaml.Replace('<!--COMBOSTYLES-->', $ComboStyles + $DialogStyles)
    $dw = [Windows.Markup.XamlReader]::Load((New-Object System.Xml.XmlNodeReader $dx))
    $dw.Owner = $Window
    $dw.FindName('aVersion').Text = "Version $AppVersion  ·  Windows PowerShell $($PSVersionTable.PSVersion.Major).$($PSVersionTable.PSVersion.Minor)"
    $dw.FindName('aData').Text = "Everything Picture House stores is in $DataDir"
    $dw.FindName('aTmdb').Add_Click({ Open-Url 'https://www.themoviedb.org/' })
    $dw.FindName('aWiki').Add_Click({ Open-Url 'https://www.wikidata.org/' })
    $dw.FindName('aClose').Add_Click({ $Script:AboutWin.Close() })
    $dw.FindName('aHistory').Add_Click({ $Script:AboutWin.Close(); Select-Tab 'Settings'; try { $UI.spSettingsAbout.BringIntoView() } catch {} })
    $Script:AboutWin = $dw
    [void]$dw.ShowDialog()
    $Script:AboutWin = $null
}

# =====================================================================================
#  Utilities (1.3.1): Restore from backup, Move to my other PC, Printable list
#  Everything here works on Picture House's own Data folder — never on the NAS.
# =====================================================================================
Add-Type -AssemblyName System.IO.Compression, System.IO.Compression.FileSystem
$Script:DataFileInfo = [ordered]@{
    'userdata.json'        = 'Your watched history, ratings, notes, favourites and watchlist'
    'settings.json'        = 'Settings — NAS folders, keys, video player, hidden shelves'
    'library.json'         = 'Film list from the last scan'
    'metadata.json'        = 'Film info from TMDb'
    'collections.json'     = 'Collections'
    'radarr-picks.json'    = 'Copies you picked for Radarr'
    'radarr-upcoming.json' = 'Coming soon list'
    'awards.json'          = 'Award winners and nominees'
    'people-index.json'    = 'People (who is an actor or director)'
    'people.json'          = 'People (older format)'
    'resolutions.json'     = 'Picture quality readings'
}
# settings that belong to one PC (window size and so on) — never copied between PCs
$Script:PerPcSettings = @('WinW2', 'WinH2', 'WinMax2', 'WinCustom', 'UiZoom', 'DetailOpen', 'LastScan')
$Script:KeySettings   = @('TmdbKey', 'RadarrKey', 'SeerrKey')

function Get-DataLabel([string]$name) {
    $l = $Script:DataFileInfo[$name.ToLowerInvariant()]
    if ($l) { return $l }
    return "Other data ($name)"
}

# Only plain top-level .json names are ever taken out of a zip (no folders, no ..\ tricks)
function Get-ZipJsonEntries($zip) {
    return @($zip.Entries | Where-Object { $_.Name -and ($_.FullName -eq $_.Name) -and ($_.Name -match '^[\w\-. ]+\.json$') -and $_.Name -notmatch '\.\.' })
}
function Expand-ZipJson([string]$zipPath, [string]$dest, [string[]]$only) {
    if (-not (Test-Path -LiteralPath $dest)) { [void](New-Item -ItemType Directory -Path $dest -Force) }
    $zip = [IO.Compression.ZipFile]::OpenRead($zipPath)
    try {
        $out = @()
        foreach ($e in (Get-ZipJsonEntries $zip)) {
            if ($only -and ($only -notcontains $e.Name)) { continue }
            $target = Join-Path $dest $e.Name
            [IO.Compression.ZipFileExtensions]::ExtractToFile($e, $target, $true)
            $out += [pscustomobject]@{ Name = $e.Name; Size = [long]$e.Length; When = $e.LastWriteTime.LocalDateTime; Path = $target }
        }
        return , $out
    } finally { $zip.Dispose() }
}
function New-TempFolder([string]$tag) {
    $d = Join-Path ([IO.Path]::GetTempPath()) ("PictureHouse-$tag-" + [guid]::NewGuid().ToString('N').Substring(0, 8))
    [void](New-Item -ItemType Directory -Path $d -Force)
    return $d
}
function Remove-TempFolder([string]$d) {
    if ($d -and $d.StartsWith([IO.Path]::GetTempPath()) -and (Test-Path -LiteralPath $d)) { Remove-Item -LiteralPath $d -Recurse -Force -ErrorAction SilentlyContinue }
}

# Counts that make a backup easy to recognise: films, watched, rated, notes, watchlist, favourites
function Get-UserCounts($user) {
    $c = @{ Watched = 0; Rated = 0; Notes = 0; Watchlist = 0; Fav = 0 }
    if (-not $user) { return $c }
    foreach ($k in @($user.Keys)) {
        $u = $user[$k]; if (-not ($u -is [Collections.IDictionary])) { continue }
        if ($u['Watched']) { $c.Watched++ }
        if ([int]$u['MyRating'] -gt 0) { $c.Rated++ }
        if ([string]$u['Notes']) { $c.Notes++ }
        if ($u['Watchlist']) { $c.Watchlist++ }
        if ($u['Fav']) { $c.Fav++ }
    }
    return $c
}
function Get-DataSummary([string]$dir) {
    $s = Get-UserCounts (PH-LoadJson (Join-Path $dir 'userdata.json'))
    $s.Films = -1
    $lib = PH-LoadJson (Join-Path $dir 'library.json')
    if ($lib) { $s.Films = @($lib['Films'] | Where-Object { $_ }).Count }
    return $s
}
function Get-CurrentSummary {
    $s = Get-UserCounts $Script:User
    $s.Films = $Script:Lib.Count
    return $s
}

# A quiet copy of the current data, made before anything is replaced — so a restore or import can be undone
function New-SafetyBackup([string]$why) {
    Save-Settings; Save-User; Save-Meta
    $dir = Join-Path $DataDir 'Backups'
    if (-not (Test-Path -LiteralPath $dir)) { [void](New-Item -ItemType Directory -Path $dir -Force) }
    $files = @(Get-ChildItem -LiteralPath $DataDir -File -Filter '*.json' | ForEach-Object { $_.FullName })
    if ($files.Count -eq 0) { return '' }
    $zip = Join-Path $dir ("$why " + (Get-Date).ToString('yyyy-MM-dd HHmm') + '.zip')
    if (Test-Path -LiteralPath $zip) { Remove-Item -LiteralPath $zip -Force }
    Compress-Archive -LiteralPath $files -DestinationPath $zip -CompressionLevel Optimal
    # keep the newest 5 of each kind
    Get-ChildItem -LiteralPath $dir -Filter "$why *.zip" -File | Sort-Object LastWriteTime -Descending | Select-Object -Skip 5 |
        Remove-Item -Force -ErrorAction SilentlyContinue
    Write-Log "Safety backup saved: $zip"
    return $zip
}

# Close and start again, without saving over the files that were just put back
function Restart-PictureHouse {
    foreach ($j in @($Script:Jobs)) { $j.Sync.Cancel = $true }
    $Script:NoSaveOnClose = $true
    $Script:RestartOnClose = $true
    $Window.Close()
}
function Start-PictureHouseAgain {
    try {
        $self = [Diagnostics.Process]::GetCurrentProcess().MainModule.FileName
        $cmd = Join-Path $Base 'Start-PictureHouse.cmd'
        if ($self -notmatch '(?i)\\(powershell|pwsh|powershell_ise)\.exe$') { Start-Process -FilePath $self }          # Picture House.exe
        elseif (Test-Path -LiteralPath $cmd) { Start-Process -FilePath $cmd -WindowStyle Hidden }
        else {
            $ps1 = Join-Path $Base 'Picture-House.ps1'
            Start-Process -FilePath $self -WindowStyle Hidden -ArgumentList @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-STA', '-File', "`"$ps1`"")
        }
        Write-Log 'Restarting Picture House.'
    } catch { Write-Log "Couldn't restart: $($_.Exception.Message)" }
}

# A small dialog in the app's style; $body is the XAML between the header and the buttons
function New-UtilDialog([string]$title, [string]$heading, [int]$width, [string]$body, [string]$okText) {
    $x = @'
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="#TITLE#" Width="#WIDTH#" SizeToContent="Height" WindowStartupLocation="CenterOwner" Background="#F3EEE4" FontFamily="Segoe UI" FontSize="13" ResizeMode="NoResize">
  <Window.Resources><!--COMBOSTYLES-->
    <Style TargetType="CheckBox"><Setter Property="Margin" Value="0,5,0,0"/><Setter Property="Foreground" Value="#2B2620"/></Style>
  </Window.Resources>
  <DockPanel>
  <!--HEADER-->
  <StackPanel Margin="22,16,22,22">
    #BODY#
    <StackPanel Orientation="Horizontal" HorizontalAlignment="Right" Margin="0,18,0,0">
      <Button Content="Cancel" Style="{StaticResource PHDlgGhost}" Margin="0,0,8,0" IsCancel="True"/>
      <Button x:Name="uOk" Content="#OK#" Style="{StaticResource PHDlgPrimary}" IsDefault="True"/>
    </StackPanel>
  </StackPanel>
  </DockPanel>
</Window>
'@
    $enc = { param($t) [Security.SecurityElement]::Escape([string]$t) }
    $x = $x.Replace('#TITLE#', (& $enc $title)).Replace('#WIDTH#', [string]$width).Replace('#OK#', (& $enc $okText)).Replace('#BODY#', $body)
    [xml]$dx = $x.Replace('<!--COMBOSTYLES-->', $ComboStyles + $DialogStyles).Replace('<!--HEADER-->', (New-DialogHeader (& $enc $heading)))
    $dw = [Windows.Markup.XamlReader]::Load((New-Object System.Xml.XmlNodeReader $dx))
    $dw.Owner = $Window
    $dw.FindName('uOk').Add_Click({ param($s, $e) [Windows.Window]::GetWindow($s).DialogResult = $true })
    return $dw
}
function New-TextLine([string]$text, [string]$color = '#2B2620', [double]$size = 13, [string]$weight = 'Normal', [string]$margin = '0,0,0,0') {
    $t = New-Object Windows.Controls.TextBlock
    $t.Text = $text; $t.TextWrapping = 'Wrap'; $t.FontSize = $size; $t.FontWeight = $weight
    $t.Foreground = (New-Object Windows.Media.BrushConverter).ConvertFromString($color)
    $t.Margin = (New-Object Windows.ThicknessConverter).ConvertFromString($margin)
    return $t
}
# "Now" vs "In the backup" table
function New-CompareGrid([string]$leftHead, $left, [string]$rightHead, $right) {
    $g = New-Object Windows.Controls.Grid
    foreach ($w in 150, 120, 120) { $cd = New-Object Windows.Controls.ColumnDefinition; $cd.Width = (New-Object Windows.GridLength $w); $g.ColumnDefinitions.Add($cd) }
    $rows = @(@('', $leftHead, $rightHead), @('Films', $left.Films, $right.Films), @('Watched', $left.Watched, $right.Watched),
              @('Rated', $left.Rated, $right.Rated), @('Notes', $left.Notes, $right.Notes), @('Watchlist', $left.Watchlist, $right.Watchlist),
              @('Favourites', $left.Fav, $right.Fav))
    $r = 0
    foreach ($row in $rows) {
        $g.RowDefinitions.Add((New-Object Windows.Controls.RowDefinition))
        for ($c = 0; $c -lt 3; $c++) {
            $v = $row[$c]; if ($v -is [int] -and $v -lt 0) { $v = '—' }
            $t = New-TextLine ([string]$v) $(if ($r -eq 0 -or $c -eq 0) { '#7B7266' } else { '#2B2620' }) $(if ($r -eq 0) { 11.5 } else { 13 }) $(if ($r -gt 0 -and $c -gt 0) { 'SemiBold' } else { 'Normal' }) '0,2,0,2'
            [Windows.Controls.Grid]::SetRow($t, $r); [Windows.Controls.Grid]::SetColumn($t, $c)
            [void]$g.Children.Add($t)
        }
        $r++
    }
    $b = New-Object Windows.Controls.Border
    $b.Background = (New-Object Windows.Media.BrushConverter).ConvertFromString('#FFFCF6'); $b.BorderBrush = (New-Object Windows.Media.BrushConverter).ConvertFromString('#E2D9C9')
    $b.BorderThickness = 1; $b.CornerRadius = 8; $b.Padding = (New-Object Windows.Thickness 14, 8, 14, 8); $b.Margin = (New-Object Windows.Thickness 0, 10, 0, 6)
    $b.Child = $g
    return $b
}

# =====================================================================================
#  Restore from backup
# =====================================================================================
function Restore-PictureHouse {
    $dlg = New-Object Microsoft.Win32.OpenFileDialog
    $dlg.Title = 'Choose a Picture House backup'
    $dlg.Filter = 'Picture House backup (*.zip)|*.zip'
    $dlg.InitialDirectory = [Environment]::GetFolderPath('MyDocuments')
    if (-not $dlg.ShowDialog($Window)) { return }
    $zipPath = $dlg.FileName
    $tmp = New-TempFolder 'restore'
    try {
        try { $got = Expand-ZipJson $zipPath $tmp $null }
        catch { Tell ("That file can't be opened as a backup:`n" + $_.Exception.Message) 'Warning'; return }
        if (Test-Path -LiteralPath (Join-Path $tmp 'transfer.json')) {
            Tell "That file was made with ‘Send to my other PC’.`n`nUse ‘Bring in from my other PC’ instead — it merges your watched history rather than replacing it."
            return
        }
        $got = @($got | Where-Object { $_.Name -ne 'transfer.json' })
        if ($got.Count -eq 0) { Tell "There's no Picture House data in that file." 'Warning'; return }
        $made = ($got | Sort-Object When -Descending | Select-Object -First 1).When

        $dw = New-UtilDialog 'Restore from backup' 'Restore from backup' 560 @'
    <TextBlock x:Name="uFile" FontWeight="SemiBold" FontSize="15" TextWrapping="Wrap"/>
    <TextBlock x:Name="uWhen" Foreground="#7B7266" Margin="0,2,0,0"/>
    <ContentControl x:Name="uCompare"/>
    <TextBlock Text="Put back" Foreground="#7B7266" Margin="0,8,0,0"/>
    <StackPanel x:Name="uParts" Margin="0,0,0,4"/>
    <TextBlock Foreground="#7B7266" FontSize="12" TextWrapping="Wrap" Margin="0,10,0,0"
               Text="Your data as it is now is saved first (Data\Backups), so you can go back. Picture House then restarts to load the backup. Nothing on the NAS is touched."/>
'@ 'Restore and restart'
        $dw.FindName('uFile').Text = [IO.Path]::GetFileName($zipPath)
        $dw.FindName('uWhen').Text = 'Backup made ' + $made.ToString('dddd d MMMM yyyy, HH:mm') + '  ·  ' + (Format-Size ((Get-Item -LiteralPath $zipPath).Length))
        $dw.FindName('uCompare').Content = (New-CompareGrid 'NOW' (Get-CurrentSummary) 'IN THE BACKUP' (Get-DataSummary $tmp))
        $boxes = @()
        foreach ($name in @($Script:DataFileInfo.Keys) + @($got | ForEach-Object { $_.Name.ToLowerInvariant() } | Where-Object { -not $Script:DataFileInfo.Contains($_) })) {
            $f = @($got | Where-Object { $_.Name -ieq $name }); if (-not $f.Count) { continue }
            $cb = New-Object Windows.Controls.CheckBox
            $cb.Content = (Get-DataLabel $name); $cb.IsChecked = $true; $cb.Tag = $f[0].Name
            if ($name -eq 'settings.json') { $cb.ToolTip = "Untick to keep this PC's settings (NAS folders, keys, player) as they are." }
            [void]$dw.FindName('uParts').Children.Add($cb); $boxes += $cb
        }
        if (-not $dw.ShowDialog()) { return }
        $pick = @($boxes | Where-Object { $_.IsChecked } | ForEach-Object { [string]$_.Tag })
        if ($pick.Count -eq 0) { Tell 'Nothing was ticked, so nothing was restored.'; return }

        $Window.Cursor = [Windows.Input.Cursors]::Wait
        $safe = ''
        try {
            $safe = New-SafetyBackup 'Before restore'
            foreach ($n in $pick) { Copy-Item -LiteralPath (Join-Path $tmp $n) -Destination (Join-Path $DataDir $n) -Force }
            Write-Log ("Restored from backup $zipPath : " + ($pick -join ', '))
        } catch { $Window.Cursor = $null; Tell ("The restore didn't finish:`n" + $_.Exception.Message + "`n`nYour data from before is in:`n" + $safe) 'Warning'; return }
        $Window.Cursor = $null
        Tell ("Backup restored.`n`nPicture House will now restart to load it.`n`nIf you change your mind, your data from before is saved in Data\Backups:`n" + [IO.Path]::GetFileName($safe))
        Restart-PictureHouse
    } finally { Remove-TempFolder $tmp }
}

# =====================================================================================
#  Move to my other PC: send (export) and bring in (import, merging watched history)
# =====================================================================================
function Export-ForOtherPc {
    Save-Settings; Save-User; Save-Meta
    $c = Get-CurrentSummary
    $dw = New-UtilDialog 'Send to my other PC' 'Send to my other PC' 560 @'
    <TextBlock Text="Make one file to open in Picture House on your other PC (Utilities → Bring in from my other PC)." Foreground="#5B5348" TextWrapping="Wrap"/>
    <TextBlock Text="Include" Foreground="#7B7266" Margin="0,12,0,0"/>
    <CheckBox x:Name="uUser" IsChecked="True"/>
    <CheckBox x:Name="uSet" IsChecked="True" Content="Settings — NAS folders, video player, folders to ignore, hidden shelves, Radarr choices"/>
    <CheckBox x:Name="uKeys" IsChecked="True" Content="API keys (TMDb, Radarr, Seerr)"/>
    <CheckBox x:Name="uLib" IsChecked="False" Content="Film list and film info — saves the other PC a rescan and download (bigger file)"/>
    <TextBlock Foreground="#7B7266" FontSize="12" TextWrapping="Wrap" Margin="0,10,0,0"
               Text="Window size and other things that belong to this PC stay here. If you include the keys, keep the file private — don't share it or put it anywhere public."/>
'@ 'Save the file…'
    $dw.FindName('uUser').Content = "Watched history, ratings, notes, favourites and watchlist  ($($c.Watched) watched, $($c.Rated) rated)"
    $dw.FindName('uSet').Add_Checked({ param($s, $e) [Windows.Window]::GetWindow($s).FindName('uKeys').IsEnabled = $true })
    $dw.FindName('uSet').Add_Unchecked({ param($s, $e) $k = [Windows.Window]::GetWindow($s).FindName('uKeys'); $k.IsChecked = $false; $k.IsEnabled = $false })
    if (-not $dw.ShowDialog()) { return }
    $wantUser = [bool]$dw.FindName('uUser').IsChecked; $wantSet = [bool]$dw.FindName('uSet').IsChecked
    $wantKeys = [bool]$dw.FindName('uKeys').IsChecked; $wantLib = [bool]$dw.FindName('uLib').IsChecked
    if (-not ($wantUser -or $wantSet -or $wantLib)) { Tell 'Nothing was ticked, so there is nothing to send.'; return }

    $sd = New-Object Microsoft.Win32.SaveFileDialog
    $sd.FileName = 'Picture House for my other PC ' + (Get-Date).ToString('yyyy-MM-dd') + '.zip'
    $sd.Filter = 'Zip file|*.zip'; $sd.InitialDirectory = [Environment]::GetFolderPath('MyDocuments')
    if (-not $sd.ShowDialog($Window)) { return }
    $tmp = New-TempFolder 'send'
    $Window.Cursor = [Windows.Input.Cursors]::Wait
    try {
        $parts = @()
        if ($wantUser) { Copy-Item -LiteralPath $Files.User -Destination (Join-Path $tmp 'userdata.json') -ErrorAction SilentlyContinue; $parts += 'user' }
        if ($wantSet) {
            $s = @{}; foreach ($k in @($Settings.Keys)) { if ($Script:PerPcSettings -notcontains $k) { $s[$k] = $Settings[$k] } }
            if (-not $wantKeys) { foreach ($k in $Script:KeySettings) { $s.Remove($k) } } else { $parts += 'keys' }
            PH-SaveJson $s (Join-Path $tmp 'settings.json'); $parts += 'settings'
        }
        if ($wantLib) {
            foreach ($n in 'library.json', 'metadata.json', 'collections.json', 'awards.json', 'people-index.json') {
                $p = Join-Path $DataDir $n; if (Test-Path -LiteralPath $p) { Copy-Item -LiteralPath $p -Destination (Join-Path $tmp $n) }
            }
            $parts += 'library'
        }
        PH-SaveJson @{ Kind = 'PictureHouseTransfer'; Version = 1; App = $AppVersion; From = $env:COMPUTERNAME; Made = (Get-Date).ToString('s'); Parts = $parts } (Join-Path $tmp 'transfer.json')
        Get-ChildItem -LiteralPath $tmp -Filter '*.bak' -File | Remove-Item -Force -ErrorAction SilentlyContinue
        if (Test-Path -LiteralPath $sd.FileName) { Remove-Item -LiteralPath $sd.FileName -Force }
        Compress-Archive -Path (Join-Path $tmp '*.json') -DestinationPath $sd.FileName -CompressionLevel Optimal
        Write-Log "Saved a file for the other PC: $($sd.FileName) ($($parts -join ', '))"
        Show-Toast 'Ready for your other PC' ("Saved " + [IO.Path]::GetFileName($sd.FileName) + "`nOn the other PC: Utilities → Bring in from my other PC.") 'ok' 10
    } catch { Tell ("The file couldn't be made:`n" + $_.Exception.Message) 'Warning' }
    finally { $Window.Cursor = $null; Remove-TempFolder $tmp }
}

# Merge the other PC's watched history into this one: nothing you've done on either PC is lost
function Merge-UserData($mine, $theirs) {
    $out = @{}; $n = @{ NewFilms = 0; Watched = 0; Rated = 0; Notes = 0; Lists = 0 }
    if ($mine) { foreach ($k in @($mine.Keys)) { $out[$k] = $mine[$k] } }
    if (-not $theirs) { return @{ Data = $out; Counts = $n } }
    foreach ($k in @($theirs.Keys)) {
        $t = $theirs[$k]; if (-not ($t -is [Collections.IDictionary])) { continue }
        $m = $out[$k]
        if (-not ($m -is [Collections.IDictionary])) {
            $out[$k] = $t; $n.NewFilms++
            if ($t['Watched']) { $n.Watched++ }; if ([int]$t['MyRating'] -gt 0) { $n.Rated++ }; if ([string]$t['Notes']) { $n.Notes++ }
            if ($t['Watchlist'] -or $t['Fav']) { $n.Lists++ }
            continue
        }
        $u = @{}; foreach ($x in @($m.Keys)) { $u[$x] = $m[$x] }
        if ($t['Watched'] -and -not $u['Watched']) { $u['Watched'] = $true; $n.Watched++ }
        foreach ($d in 'WatchedOn', 'LastPlayed', 'ListAdded') {
            if ((PH-Date $t[$d]) -gt (PH-Date $u[$d])) { $u[$d] = $t[$d] }
        }
        if ([int]$t['PlayCount'] -gt [int]$u['PlayCount']) { $u['PlayCount'] = [int]$t['PlayCount'] }
        if ([int]$t['MyRating'] -gt 0 -and [int]$u['MyRating'] -le 0) { $u['MyRating'] = [int]$t['MyRating']; $n.Rated++ }
        $tn = ([string]$t['Notes']).Trim(); $un = ([string]$u['Notes']).Trim()
        if ($tn -and -not $un) { $u['Notes'] = $tn; $n.Notes++ }
        elseif ($tn -and $un -and -not $un.Contains($tn) -and -not $tn.Contains($un)) { $u['Notes'] = $un + "`r`n`r`n" + $tn; $n.Notes++ }
        elseif ($tn -and $tn.Length -gt $un.Length -and $tn.Contains($un)) { $u['Notes'] = $tn; $n.Notes++ }
        if ($t['Fav'] -and -not $u['Fav']) { $u['Fav'] = $true; $n.Lists++ }
        if ($t['Watchlist'] -and -not $u['Watchlist'] -and -not $u['Watched']) { $u['Watchlist'] = $true; $n.Lists++ }
        $out[$k] = $u
    }
    return @{ Data = $out; Counts = $n }
}

function Import-FromOtherPc {
    $dlg = New-Object Microsoft.Win32.OpenFileDialog
    $dlg.Title = 'Choose the file from your other PC'
    $dlg.Filter = 'Picture House file (*.zip)|*.zip'
    $dlg.InitialDirectory = [Environment]::GetFolderPath('MyDocuments')
    if (-not $dlg.ShowDialog($Window)) { return }
    $zipPath = $dlg.FileName
    $tmp = New-TempFolder 'bring'
    try {
        try { [void](Expand-ZipJson $zipPath $tmp $null) }
        catch { Tell ("That file can't be opened:`n" + $_.Exception.Message) 'Warning'; return }
        $man = PH-LoadJson (Join-Path $tmp 'transfer.json')
        if (-not $man -or [string]$man['Kind'] -ne 'PictureHouseTransfer') {
            Tell "That isn't a file made with ‘Send to my other PC’.`n`nIf it's a backup, use ‘Restore from backup’ instead."
            return
        }
        $parts = @($man['Parts'])
        $from = [string]$man['From']; $made = PH-Date $man['Made']
        $theirUser = PH-LoadJson (Join-Path $tmp 'userdata.json')
        $merge = Merge-UserData $Script:User $theirUser
        $mc = $merge.Counts

        $dw = New-UtilDialog 'Bring in from my other PC' 'Bring in from my other PC' 580 @'
    <TextBlock x:Name="uFrom" FontWeight="SemiBold" FontSize="15" TextWrapping="Wrap"/>
    <TextBlock x:Name="uWhen" Foreground="#7B7266" Margin="0,2,0,0"/>
    <TextBlock Text="Bring in" Foreground="#7B7266" Margin="0,12,0,0"/>
    <CheckBox x:Name="uUser" Content="Watched history, ratings, notes, favourites and watchlist"/>
    <TextBlock x:Name="uUserNote" Foreground="#5B5348" FontSize="12" TextWrapping="Wrap" Margin="22,2,0,4"/>
    <CheckBox x:Name="uSet" Content="Settings — NAS folders, video player, folders to ignore, hidden shelves, Radarr choices"/>
    <CheckBox x:Name="uKeys" Content="API keys (TMDb, Radarr, Seerr)"/>
    <CheckBox x:Name="uLib" Content="Film list and film info (replaces this PC's)"/>
    <TextBlock Foreground="#7B7266" FontSize="12" TextWrapping="Wrap" Margin="0,10,0,0"
               Text="Nothing you've done on this PC is lost: a film watched on either PC stays watched, and your data as it is now is saved first (Data\Backups). Picture House then restarts. Nothing on the NAS is touched."/>
'@ 'Bring in and restart'
        $dw.FindName('uFrom').Text = $(if ($from) { "From $from" } else { 'From your other PC' })
        $dw.FindName('uWhen').Text = $(if ($made -gt [datetime]::MinValue) { 'Made ' + $made.ToString('dddd d MMMM yyyy, HH:mm') } else { '' })
        $bits = @()
        if ($mc.Watched) { $bits += "$($mc.Watched) more watched" }
        if ($mc.Rated) { $bits += "$($mc.Rated) more rated" }
        if ($mc.Notes) { $bits += "$($mc.Notes) notes" }
        if ($mc.Lists) { $bits += "$($mc.Lists) favourites / watchlist" }
        $dw.FindName('uUserNote').Text = $(if ($bits.Count) { 'Adds ' + ($bits -join ', ') + ' — merged with this PC''s.' } else { 'This PC already has everything in it — nothing new to add.' })
        $map = @{ uUser = 'user'; uSet = 'settings'; uKeys = 'keys'; uLib = 'library' }
        foreach ($n in @($map.Keys)) {
            $cb = $dw.FindName($n); $has = ($parts -contains $map[$n])
            $cb.IsChecked = $has; $cb.IsEnabled = $has
            if (-not $has) { $cb.Content = [string]$cb.Content + '  (not in the file)'; $cb.Opacity = 0.6 }
        }
        if (-not ($parts -contains 'user')) { $dw.FindName('uUserNote').Visibility = 'Collapsed' }
        if (-not $dw.ShowDialog()) { return }
        $doUser = [bool]$dw.FindName('uUser').IsChecked; $doSet = [bool]$dw.FindName('uSet').IsChecked
        $doKeys = [bool]$dw.FindName('uKeys').IsChecked; $doLib = [bool]$dw.FindName('uLib').IsChecked
        if (-not ($doUser -or $doSet -or $doKeys -or $doLib)) { Tell 'Nothing was ticked, so nothing was brought in.'; return }

        $Window.Cursor = [Windows.Input.Cursors]::Wait
        $safe = ''
        try {
            $safe = New-SafetyBackup 'Before import'
            if ($doUser) { PH-SaveJson $merge.Data $Files.User }
            if ($doSet -or $doKeys) {
                $theirs = PH-LoadJson (Join-Path $tmp 'settings.json')
                if ($theirs) {
                    $new = @{}; foreach ($k in @($Settings.Keys)) { $new[$k] = $Settings[$k] }
                    foreach ($k in @($theirs.Keys)) {
                        if ($Script:PerPcSettings -contains $k) { continue }
                        $isKey = ($Script:KeySettings -contains $k)
                        if ($isKey -and -not $doKeys) { continue }
                        if (-not $isKey -and -not $doSet) { continue }
                        if ($k -eq 'PlayerPath' -and $theirs[$k] -and -not (Test-Path -LiteralPath ([string]$theirs[$k]))) { continue }   # their player isn't installed here
                        $new[$k] = $theirs[$k]
                    }
                    PH-SaveJson $new $Files.Settings
                }
            }
            if ($doLib) {
                foreach ($n in 'library.json', 'metadata.json', 'collections.json', 'awards.json', 'people-index.json') {
                    $p = Join-Path $tmp $n; if (Test-Path -LiteralPath $p) { Copy-Item -LiteralPath $p -Destination (Join-Path $DataDir $n) -Force }
                }
            }
            Write-Log ("Brought in from $from ($zipPath): " + (@($(if ($doUser) { 'watched history' }), $(if ($doSet) { 'settings' }), $(if ($doKeys) { 'keys' }), $(if ($doLib) { 'film list' })) | Where-Object { $_ }) -join ', ')
        } catch { $Window.Cursor = $null; Tell ("That didn't finish:`n" + $_.Exception.Message + "`n`nYour data from before is in Data\Backups.") 'Warning'; return }
        $Window.Cursor = $null
        Tell "Done.`n`nPicture House will now restart to load what you brought in."
        Restart-PictureHouse
    } finally { Remove-TempFolder $tmp }
}

# =====================================================================================
#  Printable list — a tidy page of a shelf or the whole collection (print it or save as PDF)
# =====================================================================================
function Show-PrintList {
    $all = (Get-VisibleViews).ToArray()
    if ($all.Count -eq 0) { Tell 'There are no films yet — rescan the NAS first.'; return }
    $dw = New-UtilDialog 'Printable list' 'Printable list' 560 @'
    <TextBlock Text="Which films" Foreground="#7B7266"/>
    <ComboBox x:Name="uShelf" Margin="0,4,0,10"/>
    <Grid>
      <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="14"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
      <StackPanel>
        <TextBlock Text="Show" Foreground="#7B7266"/>
        <ComboBox x:Name="uWhich" Margin="0,4,0,10"/>
      </StackPanel>
      <StackPanel Grid.Column="2">
        <TextBlock Text="Sort by" Foreground="#7B7266"/>
        <ComboBox x:Name="uSort" Margin="0,4,0,10"/>
      </StackPanel>
    </Grid>
    <TextBlock Text="On each line" Foreground="#7B7266"/>
    <WrapPanel>
      <CheckBox x:Name="uYear" Content="Year" IsChecked="True" Margin="0,5,16,0"/>
      <CheckBox x:Name="uTime" Content="Running time" IsChecked="True" Margin="0,5,16,0"/>
      <CheckBox x:Name="uDir" Content="Director" Margin="0,5,16,0"/>
      <CheckBox x:Name="uQual" Content="Quality" Margin="0,5,16,0"/>
      <CheckBox x:Name="uMine" Content="My rating" Margin="0,5,16,0"/>
    </WrapPanel>
    <CheckBox x:Name="uGroup" Content="Group by shelf" IsChecked="True" Margin="0,10,0,0"/>
    <CheckBox x:Name="uTick" Content="Tick boxes to mark off (films you've watched are ticked)" IsChecked="True"/>
    <CheckBox x:Name="uCols" Content="Two columns — fits more on a page" IsChecked="True"/>
    <TextBlock x:Name="uCount" Foreground="#C8432B" FontWeight="SemiBold" Margin="0,12,0,0"/>
    <TextBlock Foreground="#7B7266" FontSize="12" TextWrapping="Wrap" Margin="0,4,0,0"
               Text="The list opens in your web browser. Press Print there — choose ‘Microsoft Print to PDF’ or ‘Save as PDF’ for a PDF."/>
'@ 'Make the list'
    $shelves = @('Whole collection') + @($all | ForEach-Object { $_.Shelf } | Where-Object { $_ } | Sort-Object -Unique)
    $cS = $dw.FindName('uShelf'); $cS.ItemsSource = $shelves; $cS.SelectedIndex = 0
    $cW = $dw.FindName('uWhich'); $cW.ItemsSource = @('All films', 'Not watched yet', 'Watched', 'Watchlist', 'Favourites'); $cW.SelectedIndex = 0
    $cO = $dw.FindName('uSort'); $cO.ItemsSource = @('Title A–Z', 'Year (oldest first)', 'Year (newest first)', 'My rating', 'Recently added', 'Running time'); $cO.SelectedIndex = 0
    $Script:PrintDlg = @{ Win = $dw; All = $all }
    $count = {
        $d = $Script:PrintDlg; $w = $d.Win
        $n = (Select-PrintFilms $d.All ([string]$w.FindName('uShelf').SelectedItem) ([string]$w.FindName('uWhich').SelectedItem)).Count
        $w.FindName('uCount').Text = $(if ($n -eq 1) { '1 film' } else { "$n films" })
        $w.FindName('uGroup').IsEnabled = ([string]$w.FindName('uShelf').SelectedItem -eq 'Whole collection')
        $w.FindName('uOk').IsEnabled = ($n -gt 0)
    }
    $Script:PrintDlg.Count = $count
    $cS.Add_SelectionChanged({ & $Script:PrintDlg.Count }); $cW.Add_SelectionChanged({ & $Script:PrintDlg.Count })
    & $count
    $ok = $dw.ShowDialog()
    $Script:PrintDlg = $null
    if (-not $ok) { return }
    $opt = @{
        Shelf = [string]$cS.SelectedItem; Which = [string]$cW.SelectedItem; Sort = [string]$cO.SelectedItem
        Year = [bool]$dw.FindName('uYear').IsChecked; Time = [bool]$dw.FindName('uTime').IsChecked; Dir = [bool]$dw.FindName('uDir').IsChecked
        Qual = [bool]$dw.FindName('uQual').IsChecked; Mine = [bool]$dw.FindName('uMine').IsChecked
        Group = ([bool]$dw.FindName('uGroup').IsChecked -and [string]$cS.SelectedItem -eq 'Whole collection')
        Tick = [bool]$dw.FindName('uTick').IsChecked; Cols = [bool]$dw.FindName('uCols').IsChecked
    }
    try { Export-PrintList $all $opt } catch { Tell ("The list couldn't be made:`n" + $_.Exception.Message) 'Warning' }
}
function Select-PrintFilms($all, [string]$shelf, [string]$which) {
    $out = New-Object Collections.Generic.List[object]
    foreach ($v in $all) {
        if ($shelf -and $shelf -ne 'Whole collection' -and $v.Shelf -ne $shelf) { continue }
        $keep = $true
        if ($which -eq 'Not watched yet') { $keep = -not $v.Watched }
        elseif ($which -eq 'Watched') { $keep = [bool]$v.Watched }
        elseif ($which -eq 'Watchlist') { $keep = [bool]$v.Watchlist }
        elseif ($which -eq 'Favourites') { $keep = [bool]$v.Fav }
        if ($keep) { $out.Add($v) }
    }
    return , $out
}
function Get-PrintSorted($list, [string]$sort) {
    $l = @(foreach ($x in $list) { $x })
    if ($sort -eq 'Year (oldest first)') { return @($l | Sort-Object @{ e = { if ($_.Year -gt 0) { $_.Year } else { 9999 } } }, SortTitle) }
    if ($sort -eq 'Year (newest first)') { return @($l | Sort-Object @{ e = { $_.Year }; Descending = $true }, SortTitle) }
    if ($sort -eq 'My rating')           { return @($l | Sort-Object @{ e = { $_.MyRating }; Descending = $true }, SortTitle) }
    if ($sort -eq 'Recently added')      { return @($l | Sort-Object @{ e = { $_.Added }; Descending = $true }, SortTitle) }
    if ($sort -eq 'Running time')        { return @($l | Sort-Object @{ e = { $_.Runtime }; Descending = $true }, SortTitle) }
    return @($l | Sort-Object SortTitle, Year)
}
function Export-PrintList($all, $opt) {
    $films = Select-PrintFilms $all $opt.Shelf $opt.Which
    $enc = { param($t) [Net.WebUtility]::HtmlEncode([string]$t) }
    $name = $(if ($opt.Shelf -eq 'Whole collection') { 'My films' } else { ($opt.Shelf -split ' › ')[-1] })
    if ($opt.Which -ne 'All films') { $name += ' — ' + $opt.Which.ToLowerInvariant() }
    $groups = @()
    if ($opt.Group) {
        foreach ($g in @($films | Group-Object Shelf | Sort-Object { ([string]$_.Name).ToLowerInvariant() })) { $groups += , @($g.Name, (Get-PrintSorted $g.Group $opt.Sort)) }
    } else { $groups += , @('', (Get-PrintSorted $films $opt.Sort)) }
    $sb = New-Object Text.StringBuilder
    foreach ($g in $groups) {
        $head = [string]$g[0]; $rows = @($g[1])
        [void]$sb.Append('<section>')
        if ($head) { [void]$sb.Append('<h2>' + (& $enc $head) + '<span>' + $rows.Count + '</span></h2>') }
        [void]$sb.Append('<ol>')
        foreach ($v in $rows) {
            $bits = @()
            if ($opt.Year -and $v.Year -gt 0) { $bits += [string]$v.Year }
            if ($opt.Time -and $v.Runtime -gt 0) { $bits += $v.RuntimeText }
            if ($opt.Dir -and @($v.DirectorNames).Count) { $bits += (@($v.DirectorNames) | Select-Object -First 2) -join ', ' }
            if ($opt.Qual -and $v.Res) { $bits += $v.Res }
            if ($opt.Mine -and $v.MyRating -gt 0) { $bits += ('★' * [int]$v.MyRating) }
            $tick = ''
            if ($opt.Tick) { $tick = '<i class="box' + $(if ($v.Watched) { ' on' } else { '' }) + '"></i>' }
            [void]$sb.Append('<li>' + $tick + '<b>' + (& $enc $v.Title) + '</b>' + $(if ($bits.Count) { '<em>' + (& $enc ($bits -join '  ·  ')) + '</em>' } else { '' }) + '</li>')
        }
        [void]$sb.Append('</ol></section>')
    }
    $sub = $(if ($films.Count -eq 1) { '1 film' } else { "$($films.Count) films" }) + '  ·  ' + (Get-Date).ToString('d MMMM yyyy')
    $html = $PrintListHtml.Replace('#TITLE#', (& $enc $name)).Replace('#SUB#', (& $enc $sub)).Replace('#BODY#', $sb.ToString()).Replace('#COLS#', $(if ($opt.Cols) { '2' } else { '1' }))
    $dir = Join-Path $DataDir 'Exports'
    $safeName = ($name -replace '[\\/:*?"<>|]', '-')
    $path = Join-Path $dir ("Picture House list - $safeName " + (Get-Date).ToString('yyyy-MM-dd') + '.html')
    [IO.File]::WriteAllText($path, $html, (New-Object Text.UTF8Encoding $false))
    Write-Log "Printable list saved: $path"
    Start-Process -FilePath $path
    Show-Toast 'Your list is ready' ("Opened in your browser — press Print, or choose Save as PDF.`n" + [IO.Path]::GetFileName($path)) 'ok' 8
}
$PrintListHtml = @'
<!DOCTYPE html><html lang="en-GB"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1">
<title>#TITLE# — Picture House</title>
<style>
:root{--ink:#2B2620;--muted:#7B7266;--line:#E2D9C9;--teal:#173F3E;--red:#C8432B;--paper:#FFFCF6}
*{box-sizing:border-box}
body{margin:0;background:#F3EEE4;color:var(--ink);font:13px/1.45 "Segoe UI",system-ui,sans-serif}
.page{max-width:900px;margin:24px auto;background:var(--paper);padding:34px 42px 40px;border-radius:10px;box-shadow:0 2px 14px rgba(0,0,0,.08)}
header{display:flex;align-items:flex-end;justify-content:space-between;border-bottom:2px solid var(--teal);padding-bottom:10px;margin-bottom:16px}
.brand{font-size:10px;letter-spacing:.35em;color:var(--muted)}
h1{font:italic 30px/1.1 Georgia,serif;margin:4px 0 0;color:var(--teal)}
.sub{color:var(--muted);margin-top:4px}
button{background:var(--red);color:#fff;border:0;border-radius:18px;padding:8px 18px;font:600 13px "Segoe UI",sans-serif;cursor:pointer}
.cols{column-count:#COLS#;column-gap:34px}
section{margin:0 0 14px}
h2{font:600 12px "Segoe UI",sans-serif;letter-spacing:.12em;text-transform:uppercase;color:var(--teal);margin:0 0 4px;padding-bottom:3px;border-bottom:1px solid var(--line);break-after:avoid}
h2 span{float:right;color:var(--muted);letter-spacing:0;font-weight:400}
ol{list-style:none;margin:0;padding:0}
li{padding:2px 0;break-inside:avoid;display:flex;align-items:baseline;gap:7px;flex-wrap:wrap}
li b{font-weight:600}
li em{font-style:normal;color:var(--muted);font-size:11.5px}
.box{flex:none;width:11px;height:11px;border:1.4px solid #8E8578;border-radius:2px;position:relative;top:1px}
.box.on{background:var(--teal);border-color:var(--teal)}
.box.on:after{content:"";position:absolute;left:3px;top:0;width:3px;height:7px;border:solid #fff;border-width:0 1.6px 1.6px 0;transform:rotate(45deg)}
footer{margin-top:18px;color:var(--muted);font-size:11px;text-align:right}
@media print{
  body{background:#fff}
  .page{margin:0;max-width:none;box-shadow:none;border-radius:0;padding:0}
  button{display:none}
  @page{margin:14mm 12mm}
  .box.on{-webkit-print-color-adjust:exact;print-color-adjust:exact}
}
</style></head><body><div class="page">
<header><div><div class="brand">P I C T U R E &nbsp; H O U S E</div><h1>#TITLE#</h1><div class="sub">#SUB#</div></div>
<button onclick="window.print()">Print / Save as PDF</button></header>
<div class="cols">#BODY#</div>
<footer>Made with Picture House</footer>
</div></body></html>
'@

# =====================================================================================
#  Navigation
# =====================================================================================
$TabNames = @('Library', 'Collections', 'Tonight', 'People', 'Health', 'Upgrades', 'Stats', 'Utilities', 'Settings')
function Select-Tab([string]$name) {
    $i = [array]::IndexOf($TabNames, $name); if ($i -lt 0) { return }
    $nav = $UI['nav' + $name]
    if (-not $nav.IsChecked) { $nav.IsChecked = $true } else { On-TabShown $name }
}
function On-TabShown([string]$name) {
    $UI.tabs.SelectedIndex = [array]::IndexOf($TabNames, $name)
    switch ($name) {
        'Collections' { if ($Script:Dirty.Collections) { Refresh-Collections }; Start-CollFetch -Auto }
        'Tonight'     { Update-PickPoolText }
        'People'      { if ($Script:Dirty.People -or -not $UI.lbPeople.ItemsSource) { Refresh-People } }
        'Health'      { if ($Script:Dirty.Health) { Run-Health } }
        'Upgrades'    { Set-DetailOpen $false; Refresh-Upgrades; Refresh-Picks; if (-not $Script:RadarrMovies) { Start-RadarrMoviesFetch -Quiet }; Start-PicksCheck; Set-PicksPace }
        'Stats'       { Set-DetailOpen $false; if ($Script:Dirty.Stats) { Refresh-Stats }; if ($UI.rbStatsYear.IsChecked) { Refresh-Year } }
        'Settings'    { Load-SettingsUi }
    }
}
foreach ($t in $TabNames) {
    $UI['nav' + $t].Tag = $t
    $UI['nav' + $t].Add_Checked({ On-TabShown ([string]$this.Tag) })
}

function Refresh-Everything {
    Rebuild-Views
    Refresh-Rail
    Refresh-FilterCombos
    Apply-Filter
    Refresh-Totals
    $cur = $TabNames[$UI.tabs.SelectedIndex]
    if ($cur -ne 'Library' -and $cur -ne 'Settings') { On-TabShown $cur }
    if ($Script:CurKey -and -not $Script:Lib.ContainsKey($Script:CurKey)) { Show-Detail $null }
}

# =====================================================================================
#  Rail events
# =====================================================================================
$UI.lbSmart.Add_SelectionChanged({
    if ($Script:Loading -or -not $UI.lbSmart.SelectedItem) { return }
    $Script:Loading = $true; $UI.lbShelves.SelectedIndex = -1; $Script:Loading = $false
    $id = $UI.lbSmart.SelectedItem.Id
    $Script:CurShelf = @{ Kind = 'smart'; Id = $id }
    $Script:Loading = $true
    if ($id -eq 'recent') { $UI.cbSort.SelectedItem = 'Recently added' }
    elseif ($id -eq 'played') { $UI.cbSort.SelectedItem = 'Recently played' }
    elseif ($id -eq 'list') { $UI.cbSort.SelectedItem = 'Added to watchlist' }
    $Script:Loading = $false
    Select-Tab 'Library'
    Apply-Filter
})
$UI.lbShelves.Add_SelectionChanged({
    if ($Script:Loading -or -not $UI.lbShelves.SelectedItem) { return }
    $Script:Loading = $true; $UI.lbSmart.SelectedIndex = -1; $Script:Loading = $false
    $Script:CurShelf = @{ Kind = 'shelf'; Id = $UI.lbShelves.SelectedItem.Id }
    Select-Tab 'Library'
    Apply-Filter
})
$UI.lbShelves.Add_PreviewMouseRightButtonUp({
    param($s, $e)
    $item = Get-FromSource $e.OriginalSource 'Kind'
    if (-not $item) { return }
    $e.Handled = $true
    $cm = New-Object Windows.Controls.ContextMenu
    $Script:ShelfCtx = $item
    $mi = New-Object Windows.Controls.MenuItem; $mi.Header = 'Open this folder on the NAS'
    $mi.Add_Click({ if ($Script:ShelfCtx.Path) { Start-Process explorer.exe -ArgumentList ('"' + $Script:ShelfCtx.Path + '"') } }); [void]$cm.Items.Add($mi)
    $mi = New-Object Windows.Controls.MenuItem; $mi.Header = 'Roll the dice on this shelf'
    $mi.Add_Click({ Select-Tab 'Tonight'; Fill-PickShelves ([string]$Script:ShelfCtx.Id); $Script:PickSkip = @(); $Script:PickKey = $null; Update-PickPoolText; Start-Spin }); [void]$cm.Items.Add($mi)
    [void]$cm.Items.Add((New-Object Windows.Controls.Separator))
    $mi = New-Object Windows.Controls.MenuItem; $mi.Header = 'Hide this shelf'
    $mi.Add_Click({
        $n = [string]$Script:ShelfCtx.Id
        if (Ask "Hide the ‘$n’ shelf?`n`nIts films disappear from every list until you choose ‘Show all hidden shelves’ in Utilities. Nothing is deleted.") {
            $Settings.HiddenShelves = @(@($Settings.HiddenShelves) + $n | Select-Object -Unique)
            Save-Settings
            if ($Script:CurShelf.Id -eq $n) { $Script:CurShelf = @{ Kind = 'smart'; Id = 'all' } }
            Refresh-Everything
        }
    }); [void]$cm.Items.Add($mi)
    $cm.PlacementTarget = $UI.lbShelves; $cm.IsOpen = $true
})
$UI.btnScan.Add_Click({ Start-Scan })
$UI.btnMatchAll.Add_Click({ Start-Fetch -OnlyMissing })
$UI.btnCancel.Add_Click({ foreach ($j in @($Script:Jobs)) { $j.Sync.Cancel = $true }; Status 'Stopping…' })

# =====================================================================================
#  Library events
# =====================================================================================
Fill-Combo $UI.cbSort $SortNames ([string]$Settings.Sort)
Fill-Combo $UI.cbGroup $GroupNames ([string]$Settings.Group)
Fill-Combo $UI.cbCollFilter @('All collections', 'Incomplete', 'Complete', 'Not checked yet') 'All collections'
if ($Settings.View -eq 'List') { $UI.rbList.IsChecked = $true }

$UI.cbSort.Add_SelectionChanged({ if (-not $Script:Loading) { $Settings.Sort = [string]$UI.cbSort.SelectedItem; Apply-Filter } })
$UI.cbGroup.Add_SelectionChanged({ if (-not $Script:Loading) { $Settings.Group = [string]$UI.cbGroup.SelectedItem; Apply-Filter } })
foreach ($c in @('cbGenre', 'cbDecade', 'cbRes')) { $UI[$c].Add_SelectionChanged({ if (-not $Script:Loading) { Apply-Filter } }) }
foreach ($c in @('tgUnwatched', 'tgFavs', 'tgList', 'tgNoInfo')) { $UI[$c].Add_Click({ Apply-Filter }) }
$UI.rbPosters.Add_Checked({ if (-not $Script:Loading) { $Settings.View = 'Posters'; Apply-Filter } })
$UI.rbList.Add_Checked({ if (-not $Script:Loading) { $Settings.View = 'List'; Apply-Filter } })
$UI.btnClearFilters.Add_Click({
    $Script:Loading = $true
    foreach ($c in @('tgUnwatched', 'tgFavs', 'tgList', 'tgNoInfo')) { $UI[$c].IsChecked = $false }
    foreach ($c in @('cbGenre', 'cbDecade', 'cbRes')) { $UI[$c].SelectedIndex = 0 }
    $UI.txtSearch.Text = ''
    $Script:Loading = $false
    Apply-Filter
})

$UI.icPeopleHits.Add_PreviewMouseLeftButtonUp({
    param($s, $e)
    $o = $e.OriginalSource
    while ($o -and -not ($o -is [Windows.Controls.Border] -and $o.Tag -is [string] -and ([string]$o.Tag).Contains('|'))) { $o = [Windows.Media.VisualTreeHelper]::GetParent($o) }
    if ($o) { $bits = ([string]$o.Tag).Split([char]'|', 2); Show-Person $bits[1] $bits[0] }
})

# search (debounced)
$Script:SearchTimer = New-Object Windows.Threading.DispatcherTimer
$Script:SearchTimer.Interval = [TimeSpan]::FromMilliseconds(280)
$Script:SearchTimer.Add_Tick({ $Script:SearchTimer.Stop(); if (-not $UI.navLibrary.IsChecked) { Select-Tab 'Library' }; Apply-Filter })
$UI.txtSearch.Add_TextChanged({
    $UI.txtSearchHint.Visibility = $(if ($UI.txtSearch.Text) { 'Collapsed' } else { 'Visible' })
    if ($Script:Loading) { return }
    $Script:SearchTimer.Stop(); $Script:SearchTimer.Start()
})

# re-flow the wall when the window changes width
$Script:ResizeTimer = New-Object Windows.Threading.DispatcherTimer
$Script:ResizeTimer.Interval = [TimeSpan]::FromMilliseconds(150)
$Script:ResizeTimer.Add_Tick({
    $Script:ResizeTimer.Stop()
    $per = [int][math]::Max(1, [math]::Floor(($UI.lbWall.ActualWidth - 28) / 172))
    if ($per -ne $Script:PerRow -and $UI.lbWall.Visibility -eq 'Visible') { Render-Wall }
})
$UI.lbWall.Add_SizeChanged({ $Script:ResizeTimer.Stop(); $Script:ResizeTimer.Start() })

# clicking films anywhere (wall, people, collections)
$FilmClick = {
    param($s, $e)
    $v = Get-FromSource $e.OriginalSource 'IsFilm'
    if (-not $v) {
        $u = Get-FromSource $e.OriginalSource 'IsUpcoming'
        if ($u) { if ($e.ClickCount -ge 2) { Open-InRadarr $u; $e.Handled = $true } else { Status ("$($u.Title) — $($u.Sub)  ·  lands on $($u.Shelf)  ·  double-click to open in Radarr") } }
        return
    }
    if ($e.ClickCount -ge 2) { Invoke-Play $v.Key; $e.Handled = $true }
    else { Show-Detail $v.Key }
}
$FilmRightClick = {
    param($s, $e)
    $v = Get-FromSource $e.OriginalSource 'IsFilm'
    if (-not $v) { return }
    $e.Handled = $true
    $Script:CtxKey = $v.Key
    $cm = Build-FilmMenu $v.Key
    $cm.PlacementTarget = $s; $cm.IsOpen = $true
}
foreach ($c in @('lbWall', 'icPeopleFilms', 'icParts', 'icYearFilms')) {
    $UI[$c].Add_PreviewMouseLeftButtonDown($FilmClick)
    $UI[$c].Add_PreviewMouseRightButtonUp($FilmRightClick)
}
$UI.dgList.Add_SelectionChanged({ $it = $UI.dgList.SelectedItem; if ($it -and $it.IsFilm) { Show-Detail $it.Key } })
$UI.dgList.Add_MouseDoubleClick({ $it = $UI.dgList.SelectedItem; if (-not $it) { return }; if ($it.IsFilm) { Invoke-Play $it.Key } elseif ($it.IsUpcoming) { Open-InRadarr $it } })
$UI.dgList.Add_PreviewMouseRightButtonUp($FilmRightClick)

# =====================================================================================
#  Film panel events
# =====================================================================================
$UI.btnCloseDetail.Add_Click({ Set-DetailOpen $false })
$UI.bdDetailPoster.Add_MouseLeftButtonUp({ if ($Script:CurKey) { Show-BigPoster $Script:CurKey } })
$UI.gridBigPoster.Add_MouseLeftButtonUp({ Hide-BigPoster })
$UI.btnShowDetail.Add_Click({
    if ($UI.colDetail.Width.Value -ge 10) { Set-DetailOpen $false }
    elseif ($Script:CurKey) { Set-DetailOpen $true }
    else { Status 'Click a poster to see its details.' }
})
$UI.btnPlay.Add_Click({ if ($Script:CurKey) { Invoke-Play $Script:CurKey } })
$UI.tgWatched.Add_Click({ if ($Script:CurKey) { Set-UserFlag $Script:CurKey 'Watched' ([bool]$UI.tgWatched.IsChecked) } })
$UI.tgFav.Add_Click({ if ($Script:CurKey) { Set-UserFlag $Script:CurKey 'Fav' ([bool]$UI.tgFav.IsChecked) } })
$UI.tgWatchlist.Add_Click({ if ($Script:CurKey) { Set-UserFlag $Script:CurKey 'Watchlist' ([bool]$UI.tgWatchlist.IsChecked) } })
$UI.btnFolder.Add_Click({ if ($Script:CurKey) { Open-FilmFolder $Script:CurKey } })
# the film panel's More menu: the less-used actions, one click away
$UI.btnMore.Add_Click({
    if (-not $Script:CurKey) { return }
    $cm = New-Object Windows.Controls.ContextMenu
    $add = {
        param($text, $btn, [string]$glyph)
        if (-not $btn -or $btn.Visibility -ne 'Visible' -or -not $btn.IsEnabled) { return }
        $mi = New-Object Windows.Controls.MenuItem; $mi.Header = $text; $mi.Tag = $btn
        $ic = New-Object Windows.Controls.TextBlock; $ic.Text = $glyph; $ic.FontFamily = 'Segoe Fluent Icons, Segoe MDL2 Assets'; $ic.FontSize = 14
        $ic.Foreground = (New-Object Windows.Media.BrushConverter).ConvertFromString('#173F3E'); $mi.Icon = $ic
        $mi.Add_Click({ $b = $this.Tag; if ($b -eq $UI.btnMove) { Show-MoveMenu $Script:CurKey $UI.btnMore } else { $b.RaiseEvent((New-Object Windows.RoutedEventArgs ([Windows.Controls.Button]::ClickEvent))) } })
        [void]$cm.Items.Add($mi)
    }
    $hasTrailer = ([string]$UI.btnTrailer.Content).StartsWith([string][char]0x25B6)
    & $add $(if ($hasTrailer) { 'Watch the trailer' } else { 'Find a trailer' }) $UI.btnTrailer ([string][char]0xE768)
    & $add 'Open folder on the NAS' $UI.btnFolder ([string][char]0xE8B7)
    [void]$cm.Items.Add((New-Object Windows.Controls.Separator))
    & $add 'TMDb page' $UI.btnTmdb ([string][char]0xE8A7)
    & $add 'IMDb page' $UI.btnImdb ([string][char]0xE8A7)
    [void]$cm.Items.Add((New-Object Windows.Controls.Separator))
    & $add 'Refresh film info' $UI.btnFetchOne ([string][char]0xE72C)
    & $add 'Fix match…' $UI.btnFixMatch ([string][char]0xE721)
    & $add 'Move to shelf…' $UI.btnMove ([string][char]0xE8DE)
    $cm.PlacementTarget = $UI.btnMore; $cm.Placement = 'Bottom'; $cm.IsOpen = $true
})
$UI.btnTrailer.Add_Click({ if ($Script:CurKey) { Open-Trailer $Script:CurKey } })
$UI.btnTmdb.Add_Click({ if ($Script:CurKey) { Open-Tmdb $Script:CurKey } })
$UI.btnImdb.Add_Click({ if ($Script:CurKey) { Open-Imdb $Script:CurKey } })
$UI.btnFetchOne.Add_Click({ if ($Script:CurKey) { Start-Fetch -Keys @($Script:CurKey) } })
$UI.btnFixMatch.Add_Click({ if ($Script:CurKey) { Show-FixMatch $Script:CurKey } })
$UI.btnMove.Add_Click({ if ($Script:CurKey) { Show-MoveMenu $Script:CurKey $UI.btnMove } })
$UI.bdDetailShelf.Add_MouseLeftButtonUp({
    if (-not $Script:CurKey) { return }
    $Script:CurShelf = @{ Kind = 'shelf'; Id = $Script:ViewByKey[$Script:CurKey].Shelf }
    Refresh-Rail; Select-Tab 'Library'; Apply-Filter
})
$UI.bdCollection.Add_MouseLeftButtonUp({
    if (-not $Script:CurKey) { return }
    $v = $Script:ViewByKey[$Script:CurKey]
    Select-Tab 'Collections'
    if ($Script:Dirty.Collections) { Refresh-Collections }
    $UI.cbCollFilter.SelectedIndex = 0
    $hit = @($UI.lbColls.Items | Where-Object { $_.Id -eq $v.CollectionId })
    if ($hit.Count) { $UI.lbColls.SelectedItem = $hit[0]; $UI.lbColls.ScrollIntoView($hit[0]) }
})
for ($i = 1; $i -le 5; $i++) {
    $UI["star$i"].Add_MouseLeftButtonUp({
        if (-not $Script:CurKey) { return }
        $n = [int]$this.Tag
        $cur = $Script:ViewByKey[$Script:CurKey].MyRating
        if ($n -eq $cur) { $n = 0 }
        Set-UserFlag $Script:CurKey 'MyRating' $n
    })
}
$UI.icCast.Add_PreviewMouseLeftButtonUp({
    param($s, $e)
    $p = Get-FromSource $e.OriginalSource 'IsPerson'
    if ($p) { Show-Person $p.Name 'Actors' }
})
$UI.txtNotes.Add_LostFocus({
    if (-not $Script:CurKey) { return }
    $u = Get-User $Script:CurKey -Create
    if ([string]$u['Notes'] -ne $UI.txtNotes.Text) { $u['Notes'] = $UI.txtNotes.Text; Save-User; Status 'Note saved.' }
})

# =====================================================================================
#  Collections / Tonight / People / Health / Stats events
# =====================================================================================
$UI.cbCollFilter.Add_SelectionChanged({ if (-not $Script:Loading) { Refresh-Collections } })
$UI.lbColls.Add_SelectionChanged({ Show-Collection $UI.lbColls.SelectedItem })
foreach ($rb in @($UI.rbUp1080, $UI.rbUp4K, $UI.rbUpDupes)) { $rb.Add_Checked({ if (-not $Script:Loading) { Refresh-Upgrades } }) }
$UI.btnUpRadarr.Add_Click({ Start-RadarrMoviesFetch; Start-PicksCheck })
$UI.icPicks.AddHandler([Windows.Controls.Primitives.ButtonBase]::ClickEvent, [Windows.RoutedEventHandler]{
    param($s, $e)
    $b = $e.OriginalSource
    if (-not ($b -is [Windows.Controls.Button] -and $b.Tag)) { return }
    $bits = ([string]$b.Tag).Split([char]'|', 2)
    if ($bits[0] -eq 'import') { Invoke-ImportAnyway ([int]$bits[1]) } elseif ($bits[0] -eq 'forget') { Remove-Pick ([int]$bits[1]) }
})
$UI.rbStatsAll.Add_Checked({ $UI.spYear.Visibility = 'Collapsed'; $UI.spStatsAll.Visibility = 'Visible'; $UI.txtStatsTitle.Text = 'The numbers' })
$UI.rbStatsYear.Add_Checked({ $UI.spStatsAll.Visibility = 'Collapsed'; $UI.spYear.Visibility = 'Visible'; $UI.txtStatsTitle.Text = 'Year in review'; Refresh-Year })
$UI.cbYear.Add_SelectionChanged({ if (-not $Script:Loading -and $UI.cbYear.SelectedItem) { Refresh-Year } })
$UI.btnYearExport.Add_Click({ Export-YearHtml })
$UI.lbUpgrades.AddHandler([Windows.Controls.Primitives.ButtonBase]::ClickEvent, [Windows.RoutedEventHandler]{
    param($s, $e)
    $b = $e.OriginalSource
    if ($b -is [Windows.Controls.Button] -and $b.Tag) { Invoke-UpgradeButton ([string]$b.Tag) }
})
$UI.btnCollRefresh.Add_Click({ Start-CollFetch; Start-AwardsFetch })
$UI.icParts.AddHandler([Windows.Controls.Primitives.ButtonBase]::ClickEvent, [Windows.RoutedEventHandler]{
    param($s, $e)
    $b = $e.OriginalSource
    if ($b -is [Windows.Controls.Button] -and $b.Tag) { Invoke-PartButton ([string]$b.Tag) }
})

foreach ($wp in @($UI.wpPickLen, $UI.wpPickEra, $UI.wpPickFrom)) { foreach ($rb in $wp.Children) { $rb.Add_Checked({ On-PickFilterChanged }) } }
$UI.bdDice.Add_MouseLeftButtonUp({ Start-Spin })
$UI.btnPickReset.Add_Click({ Reset-PickChoices })
$UI.btnPickPlay.Add_Click({ if ($Script:PickKey) { Invoke-Play $Script:PickKey } })
$UI.btnPickDetail.Add_Click({ if ($Script:PickKey) { Show-Detail $Script:PickKey } })
$UI.btnPickList.Add_Click({ if ($Script:PickKey) { Set-UserFlag $Script:PickKey 'Watchlist' $true; $UI.btnPickList.Content = '⌚  On your watchlist' } })
$UI.bdPickPoster.Add_MouseLeftButtonUp({ if ($Script:PickKey -and -not $Script:DiceTimer.IsEnabled) { Show-Detail $Script:PickKey } })
$UI.icPickAlt.Add_PreviewMouseLeftButtonUp({
    param($s, $e)
    if ($Script:DiceTimer.IsEnabled) { return }
    $o = $e.OriginalSource
    while ($o -and -not ($o -is [Windows.Controls.Border] -and $o.Tag -is [string] -and $o.Tag)) { $o = [Windows.Media.VisualTreeHelper]::GetParent($o) }
    if ($o) { Swap-PickAlt ([string]$o.Tag) }
})

$UI.rbActors.Add_Checked({ if (-not $Script:Loading) { Refresh-People } })
$UI.rbDirectors.Add_Checked({ if (-not $Script:Loading) { Refresh-People } })
$UI.rbPplCount.Add_Checked({ if (-not $Script:Loading) { Refresh-People } })
$UI.rbPplDone.Add_Checked({ if (-not $Script:Loading) { Refresh-People } })
$UI.chkPeopleMulti.Add_Click({ Refresh-People })
$Script:PeopleTimer = New-Object Windows.Threading.DispatcherTimer
$Script:PeopleTimer.Interval = [TimeSpan]::FromMilliseconds(250)
$Script:PeopleTimer.Add_Tick({ $Script:PeopleTimer.Stop(); Refresh-People })
$UI.txtPeopleSearch.Add_TextChanged({ $Script:PeopleTimer.Stop(); $Script:PeopleTimer.Start() })
$UI.btnBioMore.Add_Click({
    if ($UI.txtPersonBio.MaxHeight -lt 10000) { $UI.txtPersonBio.MaxHeight = [double]::PositiveInfinity; $UI.btnBioMore.Content = 'Show less' }
    else { $UI.txtPersonBio.MaxHeight = 120; $UI.btnBioMore.Content = 'Read more' }
})
$UI.btnPersonTmdb.Add_Click({ if ($Script:PersonLinks.Tmdb) { Open-Url "https://www.themoviedb.org/person/$($Script:PersonLinks.Tmdb)" } })
$UI.btnPersonImdb.Add_Click({ if ($Script:PersonLinks.Imdb) { Open-Url "https://www.imdb.com/name/$($Script:PersonLinks.Imdb)/" } })
$UI.icPersonMore.AddHandler([Windows.Controls.Primitives.ButtonBase]::ClickEvent, [Windows.RoutedEventHandler]{
    param($s, $e)
    $b = $e.OriginalSource
    if ($b -is [Windows.Controls.Button] -and $b.Tag) { Invoke-PartButton ([string]$b.Tag) }
})
$UI.lbPeople.Add_SelectionChanged({
    if ($Script:Loading -or -not $UI.lbPeople.SelectedItem) { return }
    Show-Person $UI.lbPeople.SelectedItem.Name $(if ($UI.rbDirectors.IsChecked) { 'Directors' } else { 'Actors' })
})

$UI.btnHealthRun.Add_Click({ Run-Health; Status "Health check: $($Script:HealthRows.Count) things to look at." })
$UI.btnHealthRadarr.Add_Click({ Compare-Radarr })
$UI.btnHealthExport.Add_Click({ Export-HealthCsv })
$UI.btnHealthHtml.Add_Click({ Export-HealthHtml })
$UI.cbHealthFilter.Add_SelectionChanged({ if (-not $Script:Loading) { Apply-HealthFilter } })
$UI.dgHealth.Add_SelectionChanged({ $r = $UI.dgHealth.SelectedItem; if ($r -and $r.Key -and $Script:Lib.ContainsKey($r.Key)) { Show-Detail $r.Key } })
$UI.dgHealth.Add_MouseDoubleClick({
    $r = $UI.dgHealth.SelectedItem; if (-not $r) { return }
    if ($r.Key -and $Script:Lib.ContainsKey($r.Key)) { Open-FilmFolder $r.Key }
    elseif ($r.Path -and (Test-Path -LiteralPath $r.Path)) { Start-Process explorer.exe -ArgumentList ('"' + $r.Path + '"') }
})

$UI.btnExportHtml.Add_Click({ Export-HtmlCatalogue })
$UI.btnUtilHealthHtml.Add_Click({ Export-HealthHtml })
$UI.btnUtilRefetch.Add_Click({
    if ($Script:Lib.Count -eq 0) { return }
    if (Ask "Fetch the details for all $($Script:Lib.Count) films again from TMDb?`n`nIt runs in the background and takes a minute or two. Your ratings, notes and watched history aren't touched.") {
        $Script:MatchFail = @{}
        Start-Fetch -Keys @($Script:Lib.Keys)
    }
})
$UI.btnUtilLog.Add_Click({ if (Test-Path -LiteralPath $Files.Log) { Start-Process notepad.exe -ArgumentList ('"' + $Files.Log + '"') } else { Tell 'The log is empty — nothing has gone wrong yet.' } })
$UI.btnUtilBackup.Add_Click({ Backup-PictureHouse })
$UI.btnUtilRestore.Add_Click({ Restore-PictureHouse })
$UI.btnUtilSend.Add_Click({ Export-ForOtherPc })
$UI.btnUtilBring.Add_Click({ Import-FromOtherPc })
$UI.btnUtilPrint.Add_Click({ Show-PrintList })
$UI.btnClearAll.Add_Click({ Clear-AllData })
$UI.btnClearSettings.Add_Click({ Clear-AllSettings })
$UI.btnExportCsv.Add_Click({ Export-Csv-Library })

# =====================================================================================
#  Settings events
# =====================================================================================
$UI.btnRootAdd.Add_Click({
    $p = $UI.txtRootAdd.Text.Trim().Trim('"').TrimEnd('\')
    if (-not $p) { return }
    if (-not (Test-Path -LiteralPath $p)) { if (-not (Ask "I can't see $p right now.`n`nAdd it anyway? (Fine if the NAS is just asleep.)")) { return } }
    $UI.lbRoots.ItemsSource = @(@($UI.lbRoots.Items | ForEach-Object { [string]$_ }) + $p | Select-Object -Unique)
    $UI.txtRootAdd.Text = ''
})
$UI.btnRootBrowse.Add_Click({
    $fb = New-Object System.Windows.Forms.FolderBrowserDialog
    $fb.Description = 'Pick the NAS folder that holds your film shelves'
    $fb.ShowNewFolderButton = $false
    if ($fb.ShowDialog() -eq 'OK') { $UI.txtRootAdd.Text = $fb.SelectedPath }
})
$UI.btnRootRemove.Add_Click({
    $sel = $UI.lbRoots.SelectedItem; if (-not $sel) { return }
    $UI.lbRoots.ItemsSource = @($UI.lbRoots.Items | Where-Object { $_ -ne $sel } | ForEach-Object { [string]$_ })
})
$UI.btnPlayerBrowse.Add_Click({
    $d = New-Object Microsoft.Win32.OpenFileDialog
    $d.Filter = 'Programs|*.exe'; $d.Title = 'Choose your video player'
    if ($d.ShowDialog($Window)) { $UI.txtPlayer.Text = $d.FileName }
})
$UI.btnPlayerDetect.Add_Click({
    $z = Find-ZoomPlayer
    if ($z) { $UI.txtPlayer.Text = $z; Status "Found Zoom Player: $z" } else { Tell "I couldn't find Zoom Player in the usual places — use Browse… to point at zplayer.exe." }
})
$UI.btnTmdbTest.Add_Click({
    $k = $UI.pwTmdb.Password.Trim(); if (-not $k) { Tell 'Paste your TMDb key first.'; return }
    $Window.Cursor = [Windows.Input.Cursors]::Wait
    try { $r = PH-Tmdb $k '/movie/603' @{ language = 'en-GB' }; if ($r -and $r.title) { Tell "TMDb is happy — test lookup returned ‘$($r.title)’." } else { Tell 'TMDb answered, but oddly. Check the key.' 'Warning' } }
    catch { Tell ("TMDb said no:`n" + $_.Exception.Message) 'Warning' }
    finally { $Window.Cursor = $null }
})
$UI.btnTmdbGetKey.Add_Click({
    Tell "Your browser will open TMDb's API page.`n`n1. Sign in, or create a free account (the Join button).`n2. Under Settings → API, create a key if you don't have one — choose Developer / personal use.`n3. Copy either the API Key or the longer API Read Access Token and paste it here, then press Test."
    Open-Url 'https://www.themoviedb.org/settings/api'
})
$UI.btnSeerrTest.Add_Click({
    $Settings.SeerrUrl = Normalize-ServiceUrl $UI.txtSeerrUrl.Text; $UI.txtSeerrUrl.Text = $Settings.SeerrUrl
    $Settings.SeerrKey = $UI.pwSeerr.Password.Trim()
    Test-Seerr
})
$UI.btnRadarrTest.Add_Click({
    $Settings.RadarrUrl = Normalize-ServiceUrl $UI.txtRadarrUrl.Text; $UI.txtRadarrUrl.Text = $Settings.RadarrUrl; $Settings.RadarrKey = $UI.pwRadarr.Password.Trim()
    Test-Radarr
})
$UI.btnRadarrLoad.Add_Click({
    $Settings.RadarrUrl = Normalize-ServiceUrl $UI.txtRadarrUrl.Text; $UI.txtRadarrUrl.Text = $Settings.RadarrUrl; $Settings.RadarrKey = $UI.pwRadarr.Password.Trim()
    [void](Load-RadarrOptions)
})
$UI.btnSaveSettings.Add_Click({ $changed = Save-SettingsUi; Refresh-Everything; if ($changed -and (Ask 'Your NAS folders changed. Rescan now?')) { Start-Scan } })
$UI.btnSaveScan.Add_Click({ [void](Save-SettingsUi); Start-Scan })
$UI.btnOpenData.Add_Click({ Start-Process explorer.exe -ArgumentList ('"' + $DataDir + '"') })
$UI.btnUnhide.Add_Click({ $Settings.HiddenShelves = @(); Save-Settings; Refresh-Everything; Status 'All shelves are visible again.' })
$UI.txtAbout.Text = $AboutText
$UI.btnAbout.Add_Click({ Show-About })

# =====================================================================================
#  Help
# =====================================================================================
$HelpText = @'
GETTING STARTED
1. Settings → add the NAS folder that holds your film folders (e.g. \\NAS\video\Films) → Save and rescan.
2. Each folder inside it becomes a shelf in the left rail. Folders inside a shelf that don't hold a film of their own become sub-shelves.
3. Paste your TMDb key in Settings ("Get a free API key" opens the TMDb page where you make one), then press "Fetch missing film info" for posters, plots, cast and more.
   (If Radarr, Jellyfin or Plex already wrote .nfo files and poster.jpg beside your films, those are used straight away.)

THE POSTER WALL
• Click a poster to open it in the film panel, which slides in on the right (✕ or the panel button hides it again); double-click to play it.
• Right-click a poster for everything else: watched, favourite, watchlist, open folder, fix match, move to another shelf.
• Sort, group (by shelf, decade, letter or genre) and filter with the controls above the wall. ▦ / ☰ switches between posters and a list.
• The search box looks through titles, years, genres, directors, cast and collection names.
  Anyone whose name matches shows in a People strip above the films — click them to open their page.

FILM PANEL
• Click a cast member or director to open them in People, with their TMDb profile (photo, biography, birth date)
  and the other films of theirs you don't have yet — send any of those to Radarr or Seerr.
• The Actors list leaves out producers, writers and crew who only had a small part — TMDb says what each person is mainly known for.
• Those details are fetched automatically in the background (most-seen people first, refreshed every 90 days),
  so they're usually there before you click. Cancel in the bottom-right stops it; it carries on next time.
• Play, Watched, Favourite and Watchlist sit at the top of the film panel; More ▾ has the trailer, open folder, TMDb / IMDb,
  refresh info, fix match and move to shelf.
• Click the poster in the film panel to see it full size (Esc or a click closes it).
• Stars are your own rating (click the same star again to clear it). Notes save when you click away.
• Click a genre to filter by it, a director or cast member to open them in People, or the shelf badge to jump to that shelf.
• "Fix match…" lets you search TMDb yourself, or paste a TMDb ID / IMDb tt-number, when the automatic match is wrong.
• "Move to shelf" moves the film's folder to a different shelf folder on the NAS (same share only — you confirm every move).

PEOPLE — HOW COMPLETE ARE YOU?
• Each person shows how many of their films you have: "You have 6 of the 14 films they directed · 43%", with a bar.
  For actors it counts their better-known films (20+ votes on TMDb), leaving out documentaries and "Himself" cameos.
• The list shows the same "6 of 14" under each name. Sort → "Most complete" puts the people you're closest to finishing at the top
  (people with fewer than 3 films go to the bottom so a single film doesn't count as 100%).

AWARD WINNERS
• "Award winners" in the rail lists your films that won or were nominated for an Oscar, BAFTA or Golden Globe,
  grouped Oscar winners → BAFTA winners → Golden Globe winners → nominees. The film panel shows exactly which awards.
• Collections has two extra lists at the top: every Oscar Best Picture winner and every BAFTA Best Film winner — what you
  have in colour, the rest dimmed with + Radarr / Seerr buttons.
• The information comes from Wikidata (free, no key) and is re-checked every two weeks or when you add films.

COLLECTIONS
• Collections are checked against TMDb automatically (at start-up, after fetching film info, and when you open the tab). "Check TMDb" forces a full refresh. Missing films are dimmed with a red MISSING tag:
  send them to Radarr (you choose which genre folder it goes in) or to Seerr. With a Seerr API key in Settings the
  Seerr button requests the film straight away; without one it opens the film's Seerr page.

TONIGHT'S PICK
• Pick a shelf, length, era and where from (unwatched, watchlist, favourites or anything), then click the dice.
  The count top-right shows how many films are in the hat. Watchlist, favourite and better-rated films get a few extra chances.
• Reset choices (under the chips) puts every chip back to the start: any shelf, length and era, films you haven't watched.
• Rolling again means "not that one tonight" — it won't come up again until you change a filter.
• Under the pick, "Or maybe" shows three runners-up; click one to swap it in. Click the poster for the film panel.
• Right-click a shelf in the left rail → "Roll the dice on this shelf".

STATS
• "★ Year in review" (next to the Stats title) picks a year: films watched, hours, favourite shelf and genre, busiest month, longest film,
  your top-rated, faces you saw most, and every film you watched in order. "Export as a web page" saves a shareable page.
  It uses the date you marked each film as watched.
• Number cards along the top, then charts. Hover over any slice, column or bar for the exact figures.
• Click a shelf slice or a "watched" bar to open that shelf, a decade column to filter by decade, or a quality slice to list those films.

COMING SOON
• Appears in the rail once Radarr is set up: films Radarr is waiting for that aren't out yet, grouped by month,
  with their cinema / digital / disc dates and a countdown. Double-click one to open it in Radarr.
• The dates under each poster say whether it's in cinemas yet; hover for cinema, digital and disc dates.
• Folders named in Settings → Folders to ignore (Intros by default) are skipped everywhere.
• Their empty folders on the NAS are not counted as problems. Once a release date passes and the film still hasn't
  arrived, Health lists it as "Released — still missing".

UPGRADES & DUPLICATES
• Lists copies below 1080p (or below 4K) and films you have more than once, best copy first.
• "Check with Radarr" shows what Radarr thinks of each copy — whether its quality profile would upgrade it or is happy as it is.
• Nothing happens on its own. "Choose a copy…" asks Radarr for every copy your indexers have and lists them with size,
  quality, seeders and age (only copies labelled English) — sort by largest (the default) or smallest, set a maximum size, hide ones Radarr would refuse. Pick one (double-click or
  "Download this one"), confirm, and only that copy is downloaded; Radarr swaps it in when it finishes.
• Copies you pick are followed under "YOUR PICKS" at the top of Upgrades (downloading — % with a bar, updated every 10 seconds
  while you're on that page, then swapped in). If Radarr
  finishes the download but holds it back (for example "not an upgrade"), a card pops up with "Import it anyway": one click
  imports that one file for that one film — your Radarr settings aren't changed. Radarr removes the old copy when it swaps.
• Adding a film to Radarr offers the same choice: pick the copy yourself, let Radarr pick, or don't search yet.
• Nothing is ever deleted — duplicates just get "Open folder".

HEALTH
• Finds films with no info or poster, names without a year, wrong-looking matches, duplicates, SD copies, split files and loose files.
• "Export HTML report" saves a tidy, searchable web page of every issue (grouped, with counts) and opens it in your browser.
• "Compare with Radarr" lists films Radarr thinks are missing but are on the NAS, and films on the NAS Radarr isn't tracking.

RADARR AND SEERR (Settings)
• Whenever you send something to Radarr or Seerr, a card pops up in the bottom-right saying what happened. After a search,
  Picture House watches Radarr for a minute or two and tells you whether it grabbed something (and which copy) or found nothing better.
• "Test Radarr" / "Test Seerr" check the address and API key. Test Radarr also lists its root folders with free space and any Radarr health warnings.
• "Load quality profiles" fills in the default download quality used when you send a film to Radarr.
• When you send a film to Radarr (+ Radarr in Collections) you're asked which folder (genre shelf) it should go in — there's no default, so it always lands where you choose.

KEYS
Ctrl+F search   ·   F5 rescan   ·   Esc clear search   ·   Ctrl+P play the open film

UTILITIES
• Exports (web catalogue, CSV spreadsheet, health report), Refresh all film info, show hidden shelves, open the log.
• Printable list: pick a shelf (or the whole collection), what to show (all, not watched, watched, watchlist, favourites),
  how to sort and what each line shows. It opens in your browser — press Print, or choose Save as PDF.
• Back up my data saves your watched history, ratings, notes, settings and film info to one .zip.
• Restore from backup: choose a backup, compare it with what you have now, tick the parts to put back. Your current
  data is saved to Data\Backups first, then Picture House restarts with the backup.
• Move to my other PC: "Send to my other PC…" makes one file (watched history, ratings, notes, settings; keys and
  film list optional). On the other PC press "Bring in…" — it merges, so a film watched on either PC stays watched.
  Window size and other per-PC settings aren't copied, and a video player that isn't installed there is skipped.
  If you include the keys, keep the file private.

ABOUT AND VERSION HISTORY
• The About button (next to Settings at the top) shows the version and credits.
• Settings → Version history lists what changed in each version.

OPENING
• A small "Opening your film library…" card appears while Picture House loads — give it a few seconds rather than starting it again.
• If something stops it opening you'll get a message, and the reason is written to Data\picture-house.log.

START AGAIN
• Settings → Clear all data wipes what Picture House has stored (it offers a backup first) — your settings stay.
  Press "Rescan the NAS" afterwards.
• Settings → Clear settings resets every setting to first-run — your films, info and watched history stay.
• Neither ever deletes films or folders on the NAS.

WHERE THINGS LIVE
Everything the app stores (settings, cached posters, your ratings) is in the Data folder beside the script.
The NAS is only read — apart from "Move to shelf".
'@
$UI.btnHelp.Add_Click({
    $w = New-Object Windows.Window
    $w.Title = "$AppName — help"; $w.Width = 760; $w.Height = 720; $w.Owner = $Window; $w.WindowStartupLocation = 'CenterOwner'
    $w.Background = (New-Object Windows.Media.BrushConverter).ConvertFromString('#F3EEE4')
    $sv = New-Object Windows.Controls.ScrollViewer; $sv.Padding = New-Object Windows.Thickness 28, 22, 28, 22
    $sp = New-Object Windows.Controls.StackPanel
    $h = New-Object Windows.Controls.TextBlock; $h.Text = 'How Picture House works'; $h.FontFamily = 'Georgia'; $h.FontSize = 26; $h.Margin = New-Object Windows.Thickness 0, 0, 0, 12
    $t = New-Object Windows.Controls.TextBlock; $t.Text = $HelpText; $t.TextWrapping = 'Wrap'; $t.FontSize = 13; $t.LineHeight = 21
    [void]$sp.Children.Add($h); [void]$sp.Children.Add($t); $sv.Content = $sp; $w.Content = $sv
    [void]$w.ShowDialog()
})

# =====================================================================================
#  Keyboard
# =====================================================================================
$Window.Add_PreviewKeyDown({
    param($s, $e)
    $ctrl = ([Windows.Input.Keyboard]::Modifiers -band [Windows.Input.ModifierKeys]::Control) -ne 0
    if ($ctrl -and $e.Key -eq 'F') { $UI.txtSearch.Focus(); $UI.txtSearch.SelectAll(); $e.Handled = $true }
    elseif ($e.Key -eq 'F5') { Start-Scan; $e.Handled = $true }
    elseif ($ctrl -and $e.Key -eq 'P' -and $Script:CurKey) { Invoke-Play $Script:CurKey; $e.Handled = $true }
    elseif ($e.Key -eq 'Escape' -and $UI.gridBigPoster.Visibility -eq 'Visible') { Hide-BigPoster; $e.Handled = $true }
    elseif ($e.Key -eq 'Escape' -and $UI.txtSearch.IsKeyboardFocused) { $UI.txtSearch.Text = ''; $e.Handled = $true }
})

# =====================================================================================
#  Start-up and shut-down
# =====================================================================================
# Open big — about 92% of the screen, centred — unless you've sized it yourself since 1.0.6
$wa = [Windows.SystemParameters]::WorkArea
$Script:DefaultW = [math]::Round($wa.Width * 0.92); $Script:DefaultH = [math]::Round($wa.Height * 0.92)
$w = $Script:DefaultW; $h = $Script:DefaultH
if ($Settings.WinCustom -and [int]$Settings.WinW2 -gt 900 -and [int]$Settings.WinH2 -gt 600) { $w = [math]::Min([int]$Settings.WinW2, $wa.Width); $h = [math]::Min([int]$Settings.WinH2, $wa.Height) }
$Window.WindowStartupLocation = 'Manual'
$Window.Width = $w; $Window.Height = $h
$Window.Left = $wa.Left + ($wa.Width - $w) / 2; $Window.Top = $wa.Top + ($wa.Height - $h) / 2
# Always open maximised (the size above is what you get if you un-maximise it)
$Window.WindowState = 'Maximized'


# Settings: three columns on wide screens, two on medium, one when narrow
function Set-SettingsCell($el, [int]$row, [int]$col, [bool]$gap) {
    [Windows.Controls.Grid]::SetRow($el, $row); [Windows.Controls.Grid]::SetColumn($el, $col)
    $el.Margin = New-Object Windows.Thickness 0, 0, $(if ($gap) { 18 } else { 0 }), 0
}
$UI.gridSettings.Add_SizeChanged({
    $w = $UI.gridSettings.ActualWidth
    $star = New-Object Windows.GridLength 1, ([Windows.GridUnitType]::Star); $zero = New-Object Windows.GridLength 0
    if ($w -ge 1700) {
        $UI.colSettings2.Width = $star; $UI.colSettings3.Width = $star
        Set-SettingsCell $UI.spSettingsLeft 0 0 $true; Set-SettingsCell $UI.spSettingsRight 0 1 $true; Set-SettingsCell $UI.spSettingsAbout 0 2 $false
    } elseif ($w -ge 980) {
        $UI.colSettings2.Width = $star; $UI.colSettings3.Width = $zero
        Set-SettingsCell $UI.spSettingsLeft 0 0 $true; Set-SettingsCell $UI.spSettingsRight 0 1 $false; Set-SettingsCell $UI.spSettingsAbout 1 1 $false
    } else {
        $UI.colSettings2.Width = $zero; $UI.colSettings3.Width = $zero
        Set-SettingsCell $UI.spSettingsLeft 0 0 $false; Set-SettingsCell $UI.spSettingsRight 1 0 $false; Set-SettingsCell $UI.spSettingsAbout 2 0 $false
    }
})

# Stats adapts to the space: 3 chart columns on wide layouts, fewer number cards per row when narrow
$UI.spStats.Add_SizeChanged({
    $w = $UI.spStats.ActualWidth
    $UI.ugCharts.Columns = $(if ($w -ge 1350) { 3 } else { 2 })
    $ug = $null
    try { $p = $UI.icStatCards.ItemContainerGenerator; if ($UI.icStatCards.Items.Count) { $c = $p.ContainerFromIndex(0); if ($c) { $ug = [Windows.Media.VisualTreeHelper]::GetParent($c) } } } catch {}
    if ($ug -is [Windows.Controls.Primitives.UniformGrid]) { $ug.Columns = $(if ($w -lt 780) { 3 } else { 6 }) }
    # top lists: four across when wide, two when narrower
    try { if ($UI.icStatCharts.Items.Count) { $c2 = $UI.icStatCharts.ItemContainerGenerator.ContainerFromIndex(0); if ($c2) { $ug2 = [Windows.Media.VisualTreeHelper]::GetParent($c2); if ($ug2 -is [Windows.Controls.Primitives.UniformGrid]) { $ug2.Columns = $(if ($w -ge 1350) { 4 } else { 2 }) } } } } catch {}
})
if (-not $Settings.PlayerPath) { $z = Find-ZoomPlayer; if ($z) { $Settings.PlayerPath = $z } }

function Select-AllFilms {
    $Script:CurShelf = @{ Kind = 'smart'; Id = 'all' }
    $Script:Loading = $true
    try {
        $UI.lbShelves.SelectedIndex = -1
        $hit = @($UI.lbSmart.Items | Where-Object { $_.Id -eq 'all' })
        if ($hit.Count) { $UI.lbSmart.SelectedItem = $hit[0] }
        if (-not $UI.navLibrary.IsChecked) { $UI.navLibrary.IsChecked = $true }
        $UI.tabs.SelectedIndex = 0
    } finally { $Script:Loading = $false }
    Apply-Filter
    if ($UI.lbWall.Items.Count) { $UI.lbWall.ScrollIntoView($UI.lbWall.Items[0]) }
}

$Window.Add_ContentRendered({
    Close-Splash
    try { $Window.Activate() | Out-Null } catch {}   # make sure it comes to the front, not behind other windows
    Set-DetailOpen $false   # the panel slides in when you click a poster
    Refresh-Everything
    Select-AllFilms
    Start-UpcomingFetch
    Start-CollFetch -Auto
    Start-PeopleAuto
    Start-AwardsFetch -Auto
    $Script:PicksTimer.Start(); Start-PicksCheck
    try { Init-Dice } catch { Write-Log "Dice: $($_.Exception.Message)" }
    if ($Script:Lib.Count -eq 0) {
        if (@($Settings.Roots).Count -eq 0) { Select-Tab 'Settings'; Status 'Welcome to Picture House — add your NAS film folder to begin.' }
        else { Start-Scan }
    } else {
        $last = PH-Date $Settings.LastScan
        Status ("Ready. {0:N0} films on the shelves." -f $Script:Lib.Count)
        if ($last -lt (Get-Date).AddHours(-12)) { Start-Scan }
    }
})

$Window.Add_Closing({
    if ($Script:NoSaveOnClose) { foreach ($j in @($Script:Jobs)) { $j.Sync.Cancel = $true }; return }   # a restore or import just replaced the files — don't save over them
    try {
        if ($UI.txtNotes.IsKeyboardFocused -and $Script:CurKey) { $u = Get-User $Script:CurKey -Create; $u['Notes'] = $UI.txtNotes.Text }
        foreach ($j in @($Script:Jobs)) { $j.Sync.Cancel = $true }
        $Settings.WinMax2 = ($Window.WindowState -eq 'Maximized')
        if ($Window.WindowState -eq 'Normal') {
            $cw = [int]$Window.ActualWidth; $ch = [int]$Window.ActualHeight
            # only remember a size you chose yourself; otherwise keep opening at the big default
            $Settings.WinCustom = ([math]::Abs($cw - $Script:DefaultW) -gt 30 -or [math]::Abs($ch - $Script:DefaultH) -gt 30)
            $Settings.WinW2 = $cw; $Settings.WinH2 = $ch
        }
        Save-Settings; Save-User
        try { Save-PersonDepts } catch {}
        if ($Script:FetchStats.SinceSave -gt 0) { Save-Meta }
    } catch { Write-Log "Closing: $($_.Exception.Message)" }
})

Write-Log "Started $AppName $AppVersion (PowerShell $($PSVersionTable.PSVersion))"
try { [void]$Window.ShowDialog() }
catch { $ex = $_.Exception; while ($ex.InnerException) { $ex = $ex.InnerException }; Stop-Startup ("The window stopped unexpectedly: " + $ex.Message) }
foreach ($j in @($Script:Jobs)) { try { $j.PS.Stop(); $j.PS.Dispose(); $j.RS.Dispose() } catch {} }
if ($Script:RestartOnClose) { Start-PictureHouseAgain }
