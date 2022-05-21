$architecture = 'x86_64'
if ((Get-WmiObject Win32_OperatingSystem).OSArchitecture.Contains("64") -eq $false) {
	$architecture = 'x86'
}

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

$doRomSubFolders = $True

[xml]$configXml = Get-Content -Path .\configuration.xml
[xml]$dirXml = Get-Content .\directories.xml


$configXml.SelectNodes('//Download') | ForEach-Object{
    $name = $ExecutionContext.InvokeCommand.ExpandString($_.parentnode.Name)
    #$exe = $ExecutionContext.InvokeCommand.ExpandString($_.parentnode.exe)
    $url = $ExecutionContext.InvokeCommand.ExpandString($_.Url)
    $type = $ExecutionContext.InvokeCommand.ExpandString($_.Type)
    $saveAs = $ExecutionContext.InvokeCommand.ExpandString($_.SaveAs)
    #$extractFolder = $ExecutionContext.InvokeCommand.ExpandString($_.ExtractFolder)
    $destinationBasePath = $ExecutionContext.InvokeCommand.ExpandString($_.Destination.BasePath)
    $destinationDirectoryName = $ExecutionContext.InvokeCommand.ExpandString($_.Destination.DirectoryName)


    $exe = IF ($_.parentnode.Exe.Count -gt 1) { 
        $_.parentnode.SelectSingleNode("//Exe[@Arch = '$architecture']").InnerText 
    } else { 
        $ExecutionContext.InvokeCommand.ExpandString($_.parentnode.exe)
    }

    $extractFolder = IF ($_.ExtractFolder.Count -gt 1) { 
        $_.SelectSingleNode("//ExtractFolder[@Arch = '$architecture']").InnerText 
    } else { 
        $ExecutionContext.InvokeCommand.ExpandString($_.ExtractFolder)
    }

#If ($name -eq 'PPSSPP'){
    Write-Host @"
$name
$exe
$url
$type
$saveAs
$extractFolder
$destinationBasePath
$destinationDirectoryName
"@
#}
}

