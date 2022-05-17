## Windows Powershell Script

<#
	TODO work on advanced install with options for replacing existing configs with defaults, path choices, etc.
	TODO write xml to save custom settings, then load those settings and present prompt to bypass install and use previous settings
	TODO fix Cemu paths in srm... why?
	TODO consider putting paths and other options in array to then load them based on name. This way if a custom path for an emulator or app is used then we can just update the array for that path and use it when making junctions, config changes, etc.
	TODO if custom path = normal path then don't junction
	TODO add junction switch/boolean and array to $dependency array and then reduce junction code to single instance
#>

## CLI Parameters
param (
	[Parameter()]
	[string]$branch = "main",
	[switch]$doDownload = $false,
	[switch]$doCustomRomDirectory = $false,
	[switch]$doCustomSavesDirectory = $false,
	[switch]$doCustomStatesDirectory = $false,
	[switch]$doRomSubFolders = $false,
	[switch]$devSkip = $false
)

$branch = 'dev' #set this for development only

## Overrides

# Turn off download progress bar otherwise downloads take SIGNIFICANTLY longer
$ProgressPreference = 'SilentlyContinue'

## Variables

$architecture = 'x86_64'
if ((Get-WmiObject Win32_OperatingSystem).OSArchitecture.Contains("64") -eq $false) {
	$architecture = 'x86'
}

# Paths & URLs

$gitUrl = "https://github.com/ch3vr0n5/Steamu.git"
$gitBranches = @('dev','beta','main')

$pathLocalAppData = $env:LOCALAPPDATA
$pathRoamingAppData = $env:APPDATA
$pathHome = $env:USERPROFILE
$pathSteam = If ($architecture -eq 'x86_64') {Get-ItemPropertyValue -Path 'HKLM:\SOFTWARE\WOW6432Node\Valve\Steam' -Name InstallPath} else {Get-ItemPropertyValue -Path 'HKLM:\SOFTWARE\Valve\Steam' -Name InstallPath}

$pathSteamu = "$pathLocalAppData\Steamu"
$pathLogs = "$pathSteamu\Logs"
$pathDownloads = "$pathSteamu\Downloads"
$pathShortcuts = "$pathSteamu\Shortcuts"
$pathConfigs = "$pathSteamu\Configs"
$pathTemp = "$pathSteamu\Temp"

$pathEmulators = "$pathSteamu\Emulators"
$pathRetroarch = "$pathEmulators\RetroArch"
$pathPcsx2 = "$pathEmulators\PCSX2"
$pathXemu = "$pathEmulators\Xemu"
$pathCemu = "$pathEmulators\Cemu"
$pathRpcs3 = "$pathEmulators\RPCS3"
$pathPpsspp = "$pathEmulators\PPSSPP"
$pathDolphin = "$pathEmulators\Dolphin"
$pathYuzu = "$pathEmulators\Yuzu"

$pathApps = "$pathSteamu\Apps"
$pathSrm = "$pathApps\SteamRomManager"
$pathSrmData = "$pathApps\SteamRomManager\userData"
$pathEs = "$pathApps\EmulationStation"
$pathEsData = "$pathEs\resources\systems\windows"

$pathEmulation = "$pathHome\Emulation"
$pathRoms = "$pathEmulation\roms"
$pathBios = "$pathEmulation\bios"
$pathSaves = "$pathEmulation\saves"
$pathStates = "$pathEmulation\states"

$pathDesktopShortcuts = "$pathHome\Desktop\Emulation"

$stringOutput = ""

$fileLogName = 'Steamu_log.txt'
$fileLog = "$pathLogs\$fileLogName"

# Dependency information

$retroarchVersion = '1.10.3'
$srmVersion = '2.3.36'
$ppssppVersion = '1_12_3'
$pcsx2Version = '1.6.0'
$cemuVersion = '1.27.0'

$dependencyArray = @(
	[PSCustomObject]@{
		Name = 'Steamu';
		Url = "https://github.com/ch3vr0n5/Steamu/archive/refs/heads/$branch.zip";
		Output = 'steamu.zip';
		DirectToPath = $false;
		DestinationPath = "$pathLocalAppData";
		DestinationName = 'Steamu';
		ExtractFolder = "Steamu-$branch";
		Type = 'zip';
		Extras = $false;
		ExtrasName = '';
		ExtrasUrl = '';
		ExtrasOutput = '';
		ExtrasDirectToPath = $false;
		ExtrasDestinationPath = "";
		ExtrasDestinationName = '';
		ExtrasExtractFolder = "";
		Exe = '';
		CreateSteamShortcut = $false;
		CreateDesktopShortcut = $false
	}
	[PSCustomObject]@{
		Name = 'Retroarch';
		Url = "https://buildbot.libretro.com/stable/$retroarchVersion/windows/$architecture/RetroArch.7z";
		Output = 'retroarch.7z';
		DirectToPath = $false;
		DestinationPath = "$pathEmulators";
		DestinationName = 'Retroarch';
		ExtractFolder = IF ($architecture -eq 'x86_64') {'RetroArch-Win64'} else {'RetroArch-Win32'};
		Type = 'zip';
		Extras = $true;
		ExtrasName = 'Retroarch Cores';
		ExtrasUrl = "https://buildbot.libretro.com/stable/$retroarchVersion/windows/$architecture/RetroArch_cores.7z";
		ExtrasOutput = 'retroarch_cores.7z';
		ExtrasDirectToPath = $false;
		ExtrasDestinationPath = "$pathEmulators";
		ExtrasDestinationName = 'Retroarch';
		ExtrasExtractFolder = IF ($architecture -eq 'x86_64') {'RetroArch-Win64'} else {'RetroArch-Win32'};
		Exe = 'retroarch.exe';
		CreateSteamShortcut = $true;
		CreateDesktopShortcut = $true
	}
	[PSCustomObject]@{
		Name = 'Steam Rom Manager';
		Url = "https://github.com/SteamGridDB/steam-rom-manager/releases/download/v$srmVersion/Steam-ROM-Manager-portable-$srmVersion.exe"; #https://github.com/SteamGridDB/steam-rom-manager/releases/download/v2.3.35/Steam-ROM-Manager-portable-2.3.35.exe
		Output = 'steam_rom_manager.exe';
		DirectToPath = $false;
		DestinationPath = "$pathApps";
		DestinationName = 'SteamRomManager';
		ExtractFolder = '';
		Type = 'exe';
		Extras = $false;
		ExtrasName = '';
		ExtrasUrl = '';
		ExtrasOutput = '';
		ExtrasDirectToPath = $false;
		ExtrasDestinationPath = "";
		ExtrasDestinationName = '';
		ExtrasExtractFolder = "";
		Exe = 'steam_rom_manager.exe'
		CreateSteamShortcut = $false;
		CreateDesktopShortcut = $true
	}
	[PSCustomObject]@{
		Name = 'Emulation Station DE';
		Url = "https://gitlab.com/es-de/emulationstation-de/-/package_files/36880305/download";
		Output = 'emulationstation.zip';
		DirectToPath = $false;
		DestinationPath = "$pathApps";
		DestinationName = 'EmulationStation';
		ExtractFolder = 'EmulationStation-DE';
		Type = 'zip';
		Extras = $false;
		ExtrasName = '';
		ExtrasUrl = '';
		ExtrasOutput = '';
		ExtrasDirectToPath = $false;
		ExtrasDestinationPath = "";
		ExtrasDestinationName = '';
		ExtrasExtractFolder = "";
		Exe = 'emulationstation.exe';
		CreateSteamShortcut = $true;
		CreateDesktopShortcut = $true
	}
	[PSCustomObject]@{
		Name = 'Xemu';
		Url = "https://github.com/mborgerson/xemu/releases/latest/download/xemu-win-release.zip";
		Output = 'xemu.zip';
		DirectToPath = $true;
		DestinationPath = "$pathEmulators";
		DestinationName = 'Xemu';
		ExtractFolder = 'Xemu';
		Type = 'zip';
		Extras = $false;
		ExtrasName = '';
		ExtrasUrl = '';
		ExtrasOutput = '';
		ExtrasDirectToPath = $false;
		ExtrasDestinationPath = "";
		ExtrasDestinationName = '';
		ExtrasExtractFolder = "";
		Exe = 'xemu.exe';
		CreateSteamShortcut = $true;
		CreateDesktopShortcut = $true
	}
	[PSCustomObject]@{
		Name = 'PPSSPP';
		Url = "https://www.ppsspp.org/files/$ppssppVersion/ppsspp_win.zip";
		Output = 'ppsspp.zip';
		DirectToPath = $true;
		DestinationPath = "$pathEmulators";
		DestinationName = 'PPSSPP';
		ExtractFolder = 'PPSSPP';
		Type = 'zip';
		Extras = $false;
		ExtrasName = '';
		ExtrasUrl = '';
		ExtrasOutput = '';
		ExtrasDirectToPath = $false;
		ExtrasDestinationPath = "";
		ExtrasDestinationName = '';
		ExtrasExtractFolder = "";
		Exe = IF ($architecture -eq 'x86_64') {'PPSSPPWindows64.exe'} else {'PPSSPPWindows.exe'};
		CreateSteamShortcut = $true;
		CreateDesktopShortcut = $true
	}
	[PSCustomObject]@{
		Name = 'RPCS3';
		Url = "https://github.com/RPCS3/rpcs3-binaries-win/releases/download/build-5ae9de4e3b7f4aa59ede098796c08e128783989a/rpcs3-v0.0.22-13592-5ae9de4e_win64.7z";
		Output = 'rpcs3.zip';
		DirectToPath = $true;
		DestinationPath = "$pathEmulators";
		DestinationName = 'RPCS3';
		ExtractFolder = 'RPCS3';
		Type = 'zip';
		Extras = $false;
		ExtrasName = '';
		ExtrasUrl = '';
		ExtrasOutput = '';
		ExtrasDirectToPath = $false;
		ExtrasDestinationPath = "";
		ExtrasDestinationName = '';
		ExtrasExtractFolder = "";
		Exe = 'rpcs3.exe';
		CreateSteamShortcut = $true;
		CreateDesktopShortcut = $true
	}
	[PSCustomObject]@{
		Name = 'PCSX2';
		Url = "https://github.com/PCSX2/pcsx2/releases/download/v$pcsx2Version/pcsx2-v$pcsx2Version-windows-32bit-portable.7z";
		Output = 'pcsx2.zip';
		DirectToPath = $false;
		DestinationPath = "$pathEmulators";
		DestinationName = 'PCSX2';
		ExtractFolder = "PCSX2 $pcsx2Version";
		Type = 'zip';
		Extras = $false;
		ExtrasName = '';
		ExtrasUrl = '';
		ExtrasOutput = '';
		ExtrasDirectToPath = $false;
		ExtrasDestinationPath = "";
		ExtrasDestinationName = '';
		ExtrasExtractFolder = "";
		Exe = 'pcsx2.exe';
		CreateSteamShortcut = $true;
		CreateDesktopShortcut = $true
	}
	[PSCustomObject]@{
		Name = 'Cemu';
		Url = "https://cemu.info/releases/cemu_$cemuVersion.zip";
		Output = 'cemu.zip';
		DirectToPath = $false;
		DestinationPath = "$pathEmulators";
		DestinationName = 'Cemu';
		ExtractFolder = "Cemu_$cemuVersion";
		Type = 'zip';
		Extras = $false;
		ExtrasName = '';
		ExtrasUrl = '';
		ExtrasOutput = '';
		ExtrasDirectToPath = $false;
		ExtrasDestinationPath = "";
		ExtrasDestinationName = '';
		ExtrasExtractFolder = "";
		Exe = 'Cemu.exe';
		CreateSteamShortcut = $true;
		CreateDesktopShortcut = $true
	}
	[PSCustomObject]@{
		Name = 'Yuzu';
		Url = "https://github.com/yuzu-emu/yuzu-mainline/releases/download/mainline-0-1014/yuzu-windows-msvc-20220512-4d5eaaf3f.zip";
		Output = 'yuzu.zip';
		DirectToPath = $false;
		DestinationPath = "$pathEmulators";
		DestinationName = 'Yuzu';
		ExtractFolder = "yuzu-windows-msvc";
		Type = 'zip';
		Extras = $false;
		ExtrasName = '';
		ExtrasUrl = '';
		ExtrasOutput = '';
		ExtrasDirectToPath = $false;
		ExtrasDestinationPath = "";
		ExtrasDestinationName = '';
		ExtrasExtractFolder = "";
		Exe = 'yuzu.exe';
		CreateSteamShortcut = $true;
		CreateDesktopShortcut = $true
	}
)

# directories
$directorySteamu = @(
		'Logs'
	,	'Downloads'
	,	'Tools'
	,	'Emulators'
	,	'Apps'
	,	'Shortcuts'
	,	'Temp'
	)

$directoryApps = @(
		'SteamRomManager'
	,	'EmulationStation'
	)

<# replaced in favor of foreach loop
$directoryEmulators = @(
		'Retroarch'
	,	'Xemu'
	,	'PPSSPP'
	,	'RPCS3'
	,	'PCSX2'
	)
#>

$directoryEmulation = @(
		'bios'
	,	'configs'
	,	'roms'
	,	'saves'
	,	'states'
	)

$directoryBios = @(
	'ps2'
	,'gba'
	,'mame'
)

$directoryRoms = @(
	'3do'
	,'3ds'
	,'64dd'
	,'ags'
	,'amiga'
	,'amiga600'
	,'amiga1200'
	,'amigacd32'
	,'amstradcpc'
	,'android'
	,'apple2'
	,'apple2gs'
	,'arcade'
	,'astrocade'
	,'atari800'
	,'atari2600'
	,'atari5200'
	,'atari7800'
	,'atarijaguar'
	,'atarijaguarcd'
	,'atarist'
	,'atarixe'
	,'atomiswave'
	,'bbcmicro'
	,'c64'
	,'cavestory'
	,'cdimono1'
	,'cdtv'
	,'chailove'
	,'channelf'
	,'coco'
	,'coleco'
	,'colecovision'
	,'cps1'
	,'cps2'
	,'cps3'
	,'daphne'
	,'desktop'
	,'doom'
	,'dos'
	,'dragon32'
	,'dreamcast'
	,'epic'
	,'famicom'
	,'fba'
	,'fbneo'
	,'fds'
	,'gameandwatch'
	,'gamecube'
	,'gamegear'
	,'gb'
	,'gba'
	,'gbc'
	,'genesis'
	,'genesiswide'
	,'gx4000'
	,'intellivision'
	,'j2me'
	,'kodi'
	,'lutris'
	,'lutro'
	,'lynx'
	,'macintosh'
	,'mame'
	,'mame2010'
	,'mame-advmame'
	,'mame-mame4all'
	,'mastersystem'
	,'megacd'
	,'megacdjp'
	,'megadrive'
	,'mess'
	,'moonlight'
	,'moto'
	,'msx'
	,'msx1'
	,'msx2'
	,'msxturbor'
	,'multivision'
	,'n64'
	,'naomi'
	,'naomigd'
	,'nds'
	,'neogeo'
	,'neogeocd'
	,'neogeocdjp'
	,'nes'
	,'ngp'
	,'ngpc'
	,'odyssey2'
	,'openbor'
	,'oric'
	,'palm'
	,'pc'
	,'pc88'
	,'pc98'
	,'pcengine'
	,'pcenginecd'
	,'pcfx'
	,'pico8'
	,'pokemini'
	,'ports'
	,'primehacks'
	,'ps2'
	,'ps3'
	,'ps4'
	,'psp'
	,'psvita'
	,'psx'
	,'quake_1'
	,'samcoupe'
	,'satellaview'
	,'saturn'
	,'saturnjp'
	,'scripts'
	,'scummvm'
	,'sega32x'
	,'sega32xjp'
	,'sega32xna'
	,'segacd'
	,'sg-1000'
	,'snes'
	,'sneshd'
	,'snesna'
	,'solarus'
	,'spectravideo'
	,'steam'
	,'stratagus'
	,'sufami'
	,'supergrafx'
	,'switch'
	,'symbian'
	,'tanodragon'
	,'tg16'
	,'tg-cd'
	,'ti99'
	,'tic80'
	,'to8'
	,'trs-80'
	,'uzebox'
	,'vectrex'
	,'vic20'
	,'videopac'
	,'virtualboy'
	,'wii'
	,'wiiu'
	,'wonderswan'
	,'wonderswancolor'
	,'x1'
	,'x68000'
	,'xbox'
	,'xbox360'
	,'zmachine'
	,'zx81'
	,'zxspectrum'
	)

## Functions

Function inputPause ($stringMessageArg)
# https://stackoverflow.com/a/28237896
{
    # Check if running Powershell ISE
    if ($psISE)
    {
        Add-Type -AssemblyName System.Windows.Forms
        [System.Windows.Forms.MessageBox]::Show("$stringMessageArg")
    }
    else
    {
        Write-Log $stringMessageArg $true
        $x = $host.ui.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    }
}

function Write-Log ($stringMessageArg, [bool]$toHost)
# http://woshub.com/write-output-log-files-powershell/
{
	$timeStamp = (Get-Date).toString("yyyy/MM/dd HH:mm:ss")
	$stringLogMessage = "$timeStamp $stringMessageArg"
	
	Add-content $fileLog -value $stringLogMessage

	If ($toHost) {
		Write-Host $stringMessageArg
	}
}
function DownloadFile($url, $targetFile)
# https://stackoverflow.com/a/21422517 -- replaces regular invoke-webrequest progress tracking since it severly reduces download speed
{
   $uri = New-Object "System.Uri" "$url"
   $request = [System.Net.HttpWebRequest]::Create($uri)
   $request.set_Timeout(15000) #15 second timeout
   $response = $request.GetResponse()
   $totalLength = [System.Math]::Floor($response.get_ContentLength()/1024)
   $responseStream = $response.GetResponseStream()
   $targetStream = New-Object -TypeName System.IO.FileStream -ArgumentList $targetFile, Create
   $buffer = new-object byte[] 10KB
   $count = $responseStream.Read($buffer,0,$buffer.length)
   $downloadedBytes = $count
   while ($count -gt 0)
   {
       $targetStream.Write($buffer, 0, $count)
       $count = $responseStream.Read($buffer,0,$buffer.length)
       $downloadedBytes = $downloadedBytes + $count
       Write-Progress -activity "Downloading file '$($url.split('/') | Select-Object -Last 1)'" -status "Downloaded ($([System.Math]::Floor($downloadedBytes/1024))K of $($totalLength)K): " -PercentComplete ((([System.Math]::Floor($downloadedBytes/1024)) / $totalLength)  * 100)
   }
   Write-Progress -activity "Finished downloading file '$($url.split('/') | Select-Object -Last 1)'"
   $targetStream.Flush()
   $targetStream.Close()
   $targetStream.Dispose()
   $responseStream.Dispose()
}

function New-Shortcut([string]$SourceExe, [string]$DestinationPath){
# https://stackoverflow.com/a/9701907
	If(Test-Path -Path $DestinationPath -PathType Leaf) {
		Remove-Item -Path $DestinationPath -Force | Out-Null
	}

	$WshShell = New-Object -comObject WScript.Shell
	$Shortcut = $WshShell.CreateShortcut($DestinationPath)
	$Shortcut.TargetPath = $SourceExe
	$Shortcut.Save() | Out-Null
}

function testUrl([string]$testUrl){
	# https://stackoverflow.com/a/20262872
	# First we create the request.
	

	# We then get a response from the site.
	Try {
		$HTTP_Request = [System.Net.WebRequest]::Create($testUrl)
		$HTTP_Response = $HTTP_Request.GetResponse()

		Return $true
	} catch {
		Return $false
		Continue
	}

	# Finally, we clean up the http request by closing it.
	$HTTP_Response.Close()
}

Function Get-Folder($initialDirectory="")
# https://stackoverflow.com/a/25690250

{
    [System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms")|Out-Null

    $foldername = New-Object System.Windows.Forms.FolderBrowserDialog
    $foldername.Description = "Select a folder"
    $foldername.rootfolder = "MyComputer"
    $foldername.SelectedPath = $initialDirectory

    if($foldername.ShowDialog() -eq "OK")
    {
        $folder += $foldername.SelectedPath
    }
    return $folder
}

Function Get-Choice([string]$title,[string]$question,[int]$default,[string[]]$choices) {


	$decision = $Host.UI.PromptForChoice($title, $question, $choices, $default)

	Return $decision
}

Function New-Junction([string]$source,[string]$target){
	[bool]$isJunction = $false
	$pathLinkType = (Get-Item -Path $target -Force).LinkType

	If ($pathLinkType -eq "Junction"){
		$isJunction = $true
	}

	If ($isJunction) {
		$stringOutput = "$target is an existing junction. Removing..."
		Write-Log $stringOutput $false
		Remove-Item -Path $target -Force -Recurse | Out-Null
	}

		New-Item -ItemType Junction -Path $target -Target $source | Out-Null
		$stringOutput = "Junction created at $target pointing to $source"
		Write-Log $stringOutput $false
}

Function Write-Space {
	$space = @"










"@
	Write-Host $space
}

## Steamu Log FIle

if (Test-Path -path $fileLog -PathType Leaf) {
	#Clear-Content -path $fileLog
	$stringOutput = "$fileLog Cleared Log File"
	Write-Log $stringOutput $false

} else {

	If ((Test-Path -Path $pathLogs) -eq $false) {
		New-Item -Path $pathLogs -ItemType "directory"  | Out-Null
	}

	New-Item -path $fileLog -ItemType "file" | Out-Null
	
	$stringOutput = "Created Log File at $pathLogs"
	Write-Log $stringOutput $false

}

## set up installation parameters

# Set automated installation parameters
$doDownload = $true
$doCustomRomDirectory = $false
$doRomSubFolders = $true

$title = 'Welcome'
$question = 'Welcome to Steamu!

This program is designed to simplify the process of
downloading, installing and configuring emulation
to get you retro gaming in a matter of minutes. At the
end of the installation process you will be presented
with information on where things are located as well
as shortcuts to installed apps and emulators.
Additionally you will be given instructions on 
further emulator setup that cannot be done via this
program as well as a quick walk-through on how to
use Steam ROM Manager to quickly add your games directly
to Steam!

Enjoy!'
$choices = @('&Continue','&Quit')
$default = 0
Write-Space
$continueInstallation = Get-Choice $title $question $default $choices

If ($continueInstallation -eq 1) {
	inputPause 'Installation cancelled. Press any key to exit.'
	exit
}

## Set up Steamu directory structure

$stringOutput = @"
Creating Steamu directory structure
Path: $pathSteamu
"@
Write-Log $stringOutput $true

# %LOCALAPPDATA%\Steamu directory
IF (Test-Path -path $pathSteamu) {
	$stringOutput = "$pathSteamu directory already exists"
	Write-Log $stringOutput $false
}
else {
	New-Item -path $pathSteamu -ItemType "directory" | Out-Null

	$stringOutput = "$pathSteamu directory created"
	Write-Log $stringOutput $false
}

# %LOCALAPPDATA%\Steamu sub-directories
ForEach ($sub in $directorySteamu) {
	IF (Test-Path -path "$pathSteamu\$sub") {
			$stringOutput = "$pathSteamu\$sub directory already exists"
			Write-Log $stringOutput $false
		}
		else {
			New-Item -path "$pathSteamu\$sub" -ItemType "directory" | Out-Null

			$stringOutput = "$pathSteamu\$sub directory created"
			Write-Log $stringOutput $false
		}
}

# %LOCALAPPDATA%\Steamu\Emulators sub-directories
ForEach ($dependency in $dependencyArray) {
	$testPathType = $dependency.DestinationPath
	IF ($testPathType -eq $pathEmulators) {
		$pathName = $dependency.DestinationName
		IF (Test-Path -path "$pathEmulators\$pathName") {
				$stringOutput = "$pathEmulators\$pathName directory already exists"
				Write-Log $stringOutput $false
			}
			else {
				New-Item -path "$pathEmulators\$pathName" -ItemType "directory" | Out-Null

				$stringOutput = "$pathEmulators\$pathName directory created"
				Write-Log $stringOutput $false
			}
		}
}

# %LOCALAPPDATA%\Steamu\Apps sub-directories
ForEach ($sub in $directoryApps) {
	IF (Test-Path -path "$pathApps\$sub") {
			$stringOutput = "$pathApps\$sub directory already exists"
			Write-Log $stringOutput $false
		}
		else {
			New-Item -path "$pathApps\$sub" -ItemType "directory" | Out-Null

			$stringOutput = "$pathApps\$sub directory created"
			Write-Log $stringOutput $false
		}
}

	IF (Test-Path -path $pathSrmData) {
			$stringOutput = "$pathSrmData directory already exists"
			Write-Log $stringOutput $false
		}
		else {
			New-Item -path $pathSrmData -ItemType "directory" | Out-Null

			$stringOutput = "$pathSrmData directory created"
			Write-Log $stringOutput $false
		}

$stringOutput = 'Steamu directory structure created.'
Write-Log $stringOutput $true

## Set up emulation directory structure
$stringOutput = @"
Creating user's home Emulation directory structure
Path: $pathEmulation
"@
Write-Log $stringOutput $true

# %HOMEPATH%\Emulation
IF (Test-Path -path $pathEmulation) {
		$stringOutput = "$pathEmulation directory already exists"
		Write-Log $stringOutput $false
	}
	else {
		New-Item -path $pathEmulation -ItemType "directory" | Out-Null

		$stringOutput = "$pathEmulation directory created"
		Write-Log $stringOutput $false
	}

# %HOMEPATH%\Emulation sub-directories
ForEach ($sub in $directoryEmulation) {
	IF (Test-Path -path "$pathEmulation\$sub") {
			$stringOutput = "$pathEmulation\$sub directory already exists"
			Write-Log $stringOutput $false
		}
		else {
			New-Item -path "$pathEmulation\$sub" -ItemType "directory" | Out-Null

			$stringOutput = "$pathEmulation\$sub directory created"
			Write-Log $stringOutput $false
		}
}

# now that basic folders are set up, get advanced installation parameters if needed
$title = 'Installation'
$question = 'Would you like to proceed with an automated installation or do you wish to customize your install?'
$default = 0
$choices = @('&Automated','&Custom')
Write-Space
$installChoice = Get-Choice $title $question $default $choices


if ($installChoice -eq 0) {
    Write-Log 'Automated install chosen' $true
} else {
    Write-Log 'Custom install chosen' $true

	# choose a custom rom directory
	$title = 'Custom ROM Directory'
	$question = @"
Would you like to choose your own ROM path?

Default path: $pathRoms

If you choose yes, you will be prompted to select the proper path.
"@
	$default = 1
	$choices = @('&Yes','&No')
	Write-Space
	$customRomDirectoryChoice = Get-Choice $title $question $default $choices
	if ($customRomDirectoryChoice -eq 0) {
    	
		$doCustomRomDirectory = $true
		$pathRoms = Get-Folder
		Write-Log @"
CUSTOM: Custom ROM directory chosen.

Path: $pathRoms
"@ $true
	} else {
    	Write-Log @"
Using default ROM directory.

Path: $pathRoms
"@ $true
		$doCustomRomDirectory = $false
	}

	# choose if you want to populate your custom rom path only if they chose custom
	If ($doCustomRomDirectory) {
		$title = 'Custom ROM Directory Sub-folders'
		$question = "Would you like ROM system sub-directories created in your custom ROM path?

					Custom path: $pathRoms

					This will create properly named directories at the destination for all the supported systems
					such as amiga, snes, mame, etc.

					Existing ROMs at the destination won't be moved or deleted.

					IMPORTANT: We use exact system directory names as defined in our documentation on Github.
						You may need to move existing roms into properly named system folders in order for them
						to be seen by the various apps and emulators."
		$default = 0
		$choices = @('&Yes','&No')
		Write-Space
		$subFolderChoice = Get-Choice $title $question $default $choices
		
		if ($subFolderChoice -eq 0) {
    		Write-Log 'CUSTOM: Yes, ROM sub-directories will be created, if missing.'
			$doRomSubFolders = $true
		} else {
    		Write-Log 'CUSTOM: No, ROM sub-directories will NOT be created. You will need to do this manually.'
			$doRomSubFolders = $false
		}
	}

	#further custom options here

}

# %HOMEPATH%\Emulation\roms sub-directories
If ($doRomSubfolders -eq $true) {
	ForEach ($rom in $directoryRoms) {
		IF (Test-Path -path "$pathRoms\$rom") {
				$stringOutput = "$pathRoms\$rom directory already exists"
				Write-Log $stringOutput $false
			}
			else {
				New-Item -path "$pathRoms\$rom" -ItemType "directory" | Out-Null

				$stringOutput = "$pathRoms\$rom directory created"
				Write-Log $stringOutput $false
			}
	}
}

# %HOMEPATH#\Emulation\bios sub-directories
ForEach ($system in $directoryBios) {
	IF (Test-Path -path "$pathBios\$system") {
			$stringOutput = "$pathBios\$system directory already exists"
			Write-Log $stringOutput $false
		}
		else {
			New-Item -path "$pathBios\$system" -ItemType "directory" | Out-Null

			$stringOutput = "$pathBios\$system directory created"
			Write-Log $stringOutput $false
		}
}

## Set Branch

if ( !$gitBranches -contains $branch ) {
	$stringOutput = "Invalid branch $branch. Valid parameters include: $gitBranches. Press any key to exit."
	inputPause $stringOutput
	exit
}
else {
	$stringOutput = "Valid branch: $branch"
	Write-Log $stringOutput $false
}

## Download required files
IF (($doDownload -eq $true) -and ($devSkip -eq $false)) {
	if (test-path -path $pathDownloads) {
		$stringOutput = 'Beginning downloads.'
		Write-Log $stringOutput $true

		ForEach ($dependency in $dependencyArray) {
			$name = $dependency.Name
			$file = $dependency.Output
			$url = $dependency.Url
			$extras = $dependency.Extras

			#If(testUrl($url)){
				$stringOutput = "Downloading $name"
				Write-Log $stringOutput $true
				Invoke-WebRequest -Uri $Url -Outfile "$pathDownloads\$file."	
			#} else {
			#	$stringOutput = "Unable to download $name. URL invalid."
			#	Write-Log $stringOutput
			#	Write-Host $stringOutput
			#}

			IF ($extras) {
				$name = $dependency.ExtrasName
				$file = $dependency.ExtrasOutput
				$url = $dependency.ExtrasUrl

				
				try {
					$stringOutput = "Downloading $name"
					Write-Log $stringOutput $true
					Invoke-WebRequest -Uri $Url -Outfile "$pathDownloads\$file."
				}
				catch {
					$stringOutput = "Unable to continue. Error downloading $name."
					inputPause $stringOutput
					exit
				}
					
			}
					
		}

		$stringOutput = 'Downloads complete'
		Write-Log $stringOutput $true

	} Else {
		$stringOutput = "Unable to continue. $pathDownloads does not exist! Press any key to exit."
		inputPause $stringOutput
		exit
	}
} else {
	$stringOutput = @"
Downloads are skipped due to configuration.

doDownload: $doDownload
devSkip: $devSkip
"@
	Write-Log $stringOutput $true
}

## TODO backup any existing configs

## Install all-the-things
	
	if (Get-Module -ListAvailable -Name '7Zip4PowerShell') {
		$stringOutput = '7z Powershell Module exists. Skipping.'
		Write-Log $stringOutput $false
	} else {
		# install 7z powershell module
		$stringOutput = 'Installing 7z Powershell Module'
		Write-Log $stringOutput $true

		[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
		Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -Scope CurrentUser | Out-Null
		Set-PSRepository -Name 'PSGallery' -SourceLocation "https://www.powershellgallery.com/api/v2" -InstallationPolicy Trusted | Out-Null
		Install-Module -Name 7Zip4PowerShell -Force -Scope CurrentUser | Out-Null
	}


	
	<#
	If(Test-Path -Path $pathTools) {
		# Extract Peazip
		
		$stringOutput = "Extracting Peazip to $pathTools"
		Write-Log $stringOutput
		Write-Host $stringOutput
		Expand-Archive -Path "$pathDownloads\$filePeazip" -DestinationPath "$pathTools"

		Copy-Item -path "$pathTools\$peazipFolder" -Destination "$pathTools\Peazip"
		Remove-Item -path "$pathTools\$peazipFolder" 
		

		# Extract 7zip
	}
	#>
If (($doDownload -eq $true) -and ($devSkip -eq $false)) {

	ForEach ($dependency in $dependencyArray) {
		$name = $dependency.Name
		$directtopath = $dependency.DirectToPath
		$type = $dependency.Type
		$extractFolder = $dependency.ExtractFolder
		$extractPath = "$pathTemp\$extractFolder"
		$sourceFileName = $dependency.Output
		$sourcePath = "$pathDownloads\$sourceFileName"
		$targetPath = $pathTemp
		$destinationPathBase = $dependency.DestinationPath
		$destinationName = $dependency.DestinationName
		$destinationPath = "$destinationPathBase\$DestinationName"

		$extras = $dependency.Extras
		$extrasName = $dependency.ExtrasName
		$extrasExtractFolder = $dependency.ExtrasExtractFolder
		$extrasExtractPath = "$pathTemp\$extrasExtractFolder"
		$extrasSourceFileName = $dependency.ExtrasOutput
		$extrasSourcePath = "$pathDownloads\$extrasSourceFileName"
		$extrasTargetPath = $pathTemp
		$extrasPathBase = $dependency.ExtrasDestinationPath
		$extrasPathName = $dependency.ExtrasDestinationName
		$extrasDestinationPath = "$extrasPathBase\$extrasPathName"

		$stringOutput = "Extracting $name..."
		Write-Log $stringOutput $true

		If ($directtopath) {
			$targetPath = $extractPath
			New-Item -ItemType "directory" -Path $targetPath | Out-Null
		}

		If ($type -eq 'zip'){
			IF (Test-Path -Path $sourcePath -PathType Leaf) {

				$stringOutput = "Extracting $name to $extractPath"
				Write-Log $stringOutput $false

				Expand-7Zip -ArchiveFileName $sourcePath -TargetPath $targetPath | Out-Null

				$stringOutput = "Moving $name to $DestinationPath from $extractPath"
				Write-Log $stringOutput $false
		
				Copy-Item -Path "$extractPath\*" -Destination $destinationPath -Recurse -Force | Out-Null

				$stringOutput = "Removing temp $name folder from $extractPath"
				Write-Log $stringOutput $false
				
				Remove-Item -Path $extractPath -Recurse -Force | Out-Null

				IF ($extras) {

					$stringOutput = "Extracting $extrasName to $extrasExtractPath"
					Write-Log $stringOutput $false

					Expand-7Zip -ArchiveFileName $extrasSourcePath -TargetPath $extrasTargetPath | Out-Null

					$stringOutput = "Moving $extrasName to $extrasDestinationPath from $extrasExtractPath"
					Write-Log $stringOutput $false
		
					Copy-Item -Path "$extrasExtractPath\*" -Destination $extrasDestinationPath -Recurse -Force | Out-Null

					$stringOutput = "Removing temp $extrasName folder from $extrasExtractPath"
					Write-Log $stringOutput $false

					Remove-Item -Path $extrasExtractPath -Recurse -Force | Out-Null
				}

			} else {
				$stringOutput = "Unable to extract $Name. Cannot continue. Press any key to exit"
				inputPause $stringOutput
				exit
			}
		} elseif ($type -eq 'exe') {
			IF (Test-Path -Path $sourcePath -PathType Leaf) {
				$stringOutput = "Moving $name to $DestinationPath from $sourcePath"
				Write-Log $stringOutput $false
				IF (Test-Path "$destinationPath\$sourceFileName" -PathType Leaf){
					Remove-Item "$destinationPath\$sourceFileName" -Force | Out-Null
				}
				Copy-Item -Path $sourcePath -Destination $DestinationPath -Force | Out-Null

				Remove-Item -Path $sourcePath -Recurse -Force | Out-Null
			} else {
				$stringOutput = "Unable to extract $Name. Cannot continue. Press any key to exit"
				inputPause $stringOutput
				exit
			}
		} else {
			$stringOutput = "Extraction type not handled for $Name! Type: $type"
			inputPause $stringOutput
		}

	}

		$stringOutput = 'Extraction complete'
		Write-Log $stringOutput $true

} else {
	$stringOutput = @"
Extraction is skipped due to configuration.

doDownload: $doDownload
devSkip: $devSkip
"@
	Write-Log $stringOutput $true
}

## Set up symlinks

$stringOutput = 'Creating Junctions (symlinks)...'
Write-Log $stringOutput $true

		# RetroArch links

		$junctionsRetroarch = @('roms','saves','states','bios')

		ForEach ($junction in $junctionsRetroarch) {
			$target = "$pathRetroarch\$junction"

			Switch ($junction.ToString()) {
				'roms' {$source = $pathRoms}
				 'saves' {$source = "$pathSaves"}
				 'states' {$source = "$pathStates"}
				 'bios' {$source = "$pathBios"}
			}
			
			New-Junction -source $source -target $target

		}

		# EmulationStation DE links

		$junctionsEs = @('ROMs','Emulators')

		ForEach ($junction in $junctionsEs) {
			$target = "$pathEs\$junction"

			Switch ($junction.ToString()) {
					'ROMs' {$source = $pathRoms} 
					 'Emulators' {$source = $pathEmulators}
			}
			
			New-Junction -source $source -target $target

		}

		# Steam Rom Manager links

		$junctionsSrm = @('steam', 'roms', 'retroarch', 'emulationstation', 'shortcuts')

		ForEach ($junction in $junctionsSrm) {
			$target = "$pathSrm\$junction"

			Switch ($junction.ToString()) {
					'steam' {$source = $pathSteam} 
					 'roms' {$source = $pathRoms}
					 'retroarch' {$source = $pathRetroarch}
					 'emulationstation' {$source = $pathEs}
					 'shortcuts' {$source = $pathShortcuts}
			}
	
			New-Junction -source $source -target $target
		}

		# pcsx2 symlinks

		$junctionsPcsx2 = @('bios')

		ForEach ($junction in $junctionsPcsx2) {
			$target = "$pathPcsx2\$junction"

			Switch ($junction.ToString()) {
					'bios' {$source = "$pathBios\ps2"} 
			}
	
			New-Junction -source $source -target $target
		}
		
		# %HOMEPATH%\Emulation symlinks
		If ($doCustomRomDirectory) {
			$source = $pathRoms
			$target = "$pathEmulation\roms"
			
			New-Junction -source $source -target $target

		}

		IF ($doCustomSavesDirectory) {
			$source = $pathSaves
			$target = "$pathEmulation\saves"

			New-Junction -source $source -target $target

		}

		If ($doCustomStatesDirectory) {
			$source = $pathStates
			$target = "$pathEmulation\states"

			New-Junction -source $source -target $target

		}

		$stringOutput = 'Created Junctions (symlinks).'
		Write-Log $stringOutput $true

## Copy configs
		If ($doDownload) {
			$stringOutput = "Backing up existing configs..."
			Write-Log $stringOutput $true

			$backupDateTime = $(get-date -f yyyyMMddHHmm)

			#Backup existing configs
			If (Test-Path -Path "$pathRetroarch\retroarch.cfg" -PathType Leaf) {
				Rename-Item -Path "$pathRetroarch\retroarch.cfg" -NewName "retroarch-$backupDateTime.cfg" -Force | Out-Null
				$stringOutput = "$pathRetroarch\retroarch.cfg backed up to retroarch-$backupDateTime.cfg"
				Write-Log $stringOutput $false
			}

			If (Test-Path -Path "$pathSrmData\userConfigurations.json" -PathType Leaf) {
				Rename-Item -Path "$pathSrmData\userConfigurations.json" -NewName "userConfigurations-$backupDateTime.json" -Force | Out-Null #need to do something here when these backup files already exist... probably an md5 so if it's the same file ignore it.
				$stringOutput = "$pathSrmData\userConfigurations.json backed up to userConfigurations-$backupDateTime.json"
				Write-Log $stringOutput $false
			}

			If (Test-Path -Path "$pathEsData\es_find_rules.xml" -PathType Leaf) {
				Rename-Item -Path "$pathEsData\es_find_rules.xml" -NewName "es_find_rules-$backupDateTime.xml" -Force | Out-Null
				$stringOutput = "$pathEsData\es_find_rules.xml backed up to es_find_rules-$backupDateTime.xml"
				Write-Log $stringOutput $false
			}
			If (Test-Path -Path "$pathEsData\es_systems.xml" -PathType Leaf) {
				Rename-Item -Path "$pathEsData\es_systems.xml" -NewName "es_systems-$backupDateTime.xml" -Force | Out-Null
				$stringOutput = "$pathEsData\es_systems.xml backed up to es_systems-$backupDateTime.xml"
				Write-Log $stringOutput $false
			}

			$stringOutput = "Existing configs backed up."
			Write-Log $stringOutput $true

			$stringOutput = "Updating existing configs..."
			Write-Log $stringOutput $true

			# Copy default configs
			ForEach ($dependency in $dependencyArray){
				$destinationPath = $dependency.DestinationPath
				If (@($pathEmulators, $pathApps) -contains $destinationPath) {

					$name = $dependency.Name
					$destinationName = $dependency.DestinationName
					If (Test-Path -Path "$pathConfigs\$DestinationName") {
						Copy-Item -Path "$pathConfigs\$DestinationName\*" -Destination "$destinationPath\$destinationName\" -Force -Recurse | Out-Null

						$stringOutput = "Copied configs for $name"
						Write-Log $stringOutput $true
					}
				}
			}

			$stringOutput = "Existing configs updated."
			Write-Log $stringOutput $true

			<# moved to ForEach

			If (Test-Path -Path "$pathConfigs\RetroArch") {
				Copy-Item -Path "$pathConfigs\RetroArch\*" -Destination "$pathRetroarch\" -Force -Recurse
			}
			If (Test-Path -Path "$pathConfigs\SteamRomManager\userConfigurations.json" -PathType Leaf) {
				If ((Test-Path -Path "$pathSrmData\") -eq $false) {
					New-Item -ItemType "directory" -path "$pathSrmData\"
				}
				Copy-Item -Path "$pathConfigs\SteamRomManager\*" -Destination "$pathSrm" -Force
			}
			If (Test-Path -Path "$pathConfigs\EmulationStation\es_systems.xml" -PathType Leaf) {
				Copy-Item -Path "$pathConfigs\EmulationStation\*" -Destination "$pathEs" -Force
			}
			#>
		}

		#need to replace paths in SRM most likely

## TODO use New-Shortcut to make shortcuts on Desktop
	$stringOutput = "Setting up shortcuts in $pathDesktopShortcuts..."
	Write-Log $stringOutput $true

	If ((Test-Path -Path "$pathDesktopShortcuts") -eq $false) {
		New-Item -Path "$pathDesktopShortcuts" -ItemType "directory" | Out-Null
	}

	If (Test-Path -Path "$pathDesktopShortcuts") {
		ForEach ($dependency in $dependencyArray){
			$name = $dependency.Name
			
			$createShortcutDesktop = $dependency.CreateDesktopShortcut
			$createShortcutSteam = $dependency.CreateSteamShortcut
			
			$shortcutName = $name
			$exePath = $dependency.DestinationPath
			$exePathName = $dependency.DestinationName
			$exeName = $dependency.Exe
			$exeFullPath = "$exePath\$exePathName\$exeName"
			$shortcutDesktopPath = "$pathDesktopShortcuts\$shortcutName.lnk"
			$shortcutSteamPath = "$pathShortcuts\$shortcutName.lnk"


			IF ($createShortcutDesktop){

					New-Shortcut -SourceExe $exeFullPath -DestinationPath $shortcutDesktopPath
					$stringOutput = "$shortcutDesktopPath created."
					Write-Log $stringOutput $false

			} 
			If ($createShortcutSteam) {

					New-Shortcut -SourceExe $exeFullPath -DestinationPath $shortcutSteamPath
					$stringOutput = "$shortcutSteamPath created."
					Write-Log $stringOutput $false

			}
		}
	} else {
		$stringOutput = "Unable to create shortcuts. Directory $pathDesktopShortcuts does not exist!"
		Write-Log $stringOutput $true
	}


## TODO if existing configs exit, replace, else, copy new configs

## TODO if existing controller configs exist, replace, else, copy new configs


##### FINISH ######
Write-Space
$stringOutput = 'All Done =) Press any key to exit.'
inputPause $stringOutput
exit