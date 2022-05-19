[xml]$dirXml = Get-Content .\directories.xml

$pathLocalAppData = $env:LOCALAPPDATA
$pathRoamingAppData = $env:APPDATA
$pathHome = $env:USERPROFILE
$pathSteam = If ($architecture -eq 'x86_64') {Get-ItemPropertyValue -Path 'HKLM:\SOFTWARE\WOW6432Node\Valve\Steam' -Name InstallPath} elseIf ($architecture -eq 'x86') {Get-ItemPropertyValue -Path 'HKLM:\SOFTWARE\Valve\Steam' -Name InstallPath}

$pathSteamuBase = "$pathLocalAppData" # can be custom
$pathSteamu = "$pathSteamuBase\Steamu"
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
$pathDuckstation = "$pathEmulators\Duckstation"

$pathApps = "$pathSteamu\Apps"
$pathSrm = "$pathApps\SteamRomManager"
$pathSrmData = "$pathApps\SteamRomManager\userData"
$pathEs = "$pathApps\EmulationStation"
$pathEsData = "$pathEs\resources\systems\windows"

$pathEmulationBase = "$pathHome" # can be custom
$pathEmulation = "$pathEmulationBase\Emulation"
$pathRoms = "$pathEmulation\roms" # can be custom
$pathBios = "$pathEmulation\bios" 
$pathSaves = "$pathEmulation\saves" # can be custom
$pathStates = "$pathEmulation\states" # can be custom
$pathStorage = "$pathEmulation\storage" # can be custom

$directories = $dirXml.SelectNodes('//sub-directory')

$directories | ForEach-Object{
    $Path = $ExecutionContext.InvokeCommand.ExpandString($_.parentnode.Path)
    $Name = $_.parentnode.name
    $subName = $_.name
    Write-Host "$Path\$subName"
}