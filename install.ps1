## Windows Powershell Script

#region ------------------------------ CLI Parameters

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

#endregion

#region ------------------------------ Overrides

# Turn off download progress bar otherwise downloads take SIGNIFICANTLY longer
$ProgressPreference = 'SilentlyContinue'

#endregion

#region ------------------------------ Path Variables

$architecture = 'x86_64'
if ((Get-WmiObject Win32_OperatingSystem).OSArchitecture.Contains("64") -eq $false) {
	$architecture = 'x86'
}

$gitUrl = "https://github.com/ch3vr0n5/Steamu.git"
$gitBranches = @('dev','beta','main')

$pathLocalAppData = $env:LOCALAPPDATA
$pathRoamingAppData = $env:APPDATA
$pathHome = $env:USERPROFILE
$pathSteam = If ($architecture -eq 'x86_64') {Get-ItemPropertyValue -Path 'HKLM:\SOFTWARE\WOW6432Node\Valve\Steam' -Name InstallPath} else {Get-ItemPropertyValue -Path 'HKLM:\SOFTWARE\Valve\Steam' -Name InstallPath}

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

$pathDesktopShortcuts = "$pathHome\Desktop\Emulation"

$stringOutput = ""

$fileLogName = 'Steamu_log.txt'
$fileLog = "$pathLogs\$fileLogName"

# dependency version

$retroarchVersion = '1.10.3'
$srmVersion = '2.3.36'
$ppssppVersion = '1_12_3'
$pcsx2Version = '1.6.0'
$cemuVersion = '1.27.0'

#endregion

#region ------------------------------ Load XML

# config
[xml]$configXml = Get-Content -Path "$pathSteamu\configuration.xml"

# directories
[xml]$dirXml = Get-Content -Path "$pathSteamu\directories.xml"

#endregion

#region ------------------------------ Functions

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
<#
function New-Download($URL, $TargetFile)
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
#>

Function New-Download ([string]$URI, [string]$TargetFile, [string]$Name) {

		Try {
			$stringOutput = "DOWNLOADS: Downloading $Name - $TargetFile"
			Write-Log $stringOutput $True
			Invoke-WebRequest -URI $URI -OutFile $TargetFile
			$stringOutput = "DOWNLOADS: $Name Complete - $TargetFile"
			Write-Log $stringOutput $false
		} Catch {
			$stringOutput = @"
DOWNLOADS: An error occured while attempting download: $Name -> $TargetFile
ERROR: $_
"@
			Write-Log $stringOutput $true
		} 
}

function New-Shortcut([string]$SourceExe, [string]$DestinationPath){
# https://stackoverflow.com/a/9701907
	If(Test-Path -Path $DestinationPath -PathType Leaf) {
		try {
			Remove-Item -Path $DestinationPath -Force | Out-Null
			$stringOutput = "SHORTCUTS: Already exists. Removed - $DestinationPath"
			Write-Log $stringOutput $false
		}
		catch {
			$stringOutput = @"
SHORTCUTS: An error occured while attempting to remove shortcut: $DestinationPath
ERROR: $_
"@
			Write-Log $stringOutput $true
		}
		
	}

	try {
		$WshShell = New-Object -comObject WScript.Shell
		$Shortcut = $WshShell.CreateShortcut($DestinationPath)
		$Shortcut.TargetPath = $SourceExe
		$Shortcut.Save() | Out-Null
		$stringOutput = "SHORTCUTS: Created shortcut - $DestinationPath"
		Write-Log $stringOutput $false
	}
	catch {
		$stringOutput = @"
SHORTCUTS: An error occured while attempting to create shortcut: $DestinationPath
ERROR: $_
"@
		Write-Log $stringOutput $true
	}
	
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

Function New-Junction([string]$Source, [string]$Target, [string]$Name){
	[bool]$isJunction = $false
	$pathLinkType = (Get-Item -Path $target -Force).LinkType

	If ($pathLinkType -eq "Junction"){
		$isJunction = $true
	}

	#test if target is path, and empty

	If ($isJunction) {
		Try {
			Remove-Item -Path $target -Force -Recurse | Out-Null
			$stringOutput = "JUNCTIONS: Already exists, removed: $target"
			Write-Log $stringOutput $false
		} Catch {
			$stringOutput = @"
JUNCTIONS: An error occured while trying to remove junction: $target
ERROR: $_
"@
			Write-Log $stringOutput $true
		}
		
	}
		Try {
			New-Item -ItemType Junction -Path $target -Target $source | Out-Null
			$stringOutput = "JUNCTIONS: Junction created for $Name - $target -> $source"
			Write-Log $stringOutput $false
		} Catch {
			$stringOutput = @"
JUNCTIONS: An error occured while creating a junction for $Name - $target -> $source
ERROR: $_
"@
			Write-Log $stringOutput $true
		}
		
}

Function Write-Space {
	$space = @"










"@
	Write-Host $space
}

Function New-Directory([string]$path) {
	If ((Test-Path -Path $path) -eq $false) {
		Try {
			New-Item -ItemType "directory" -Path $path
			$stringOutput = "DIRECTORIES: Created directory: $path"
			Write-Log $stringOutput $false
		} Catch {
			$stringOutput = @"
DIRECTORIES: An error occured while trying to create path: $path
ERROR: $_
"@
			Write-Log $stringOutput $true
		}
			
	} else {
		$stringOutput = "DIRECTORIES: Already exists: $path"
		Write-Log $stringOutput $false
	}
}

Function Extract-Archive([string]$Source, [string]$Destination, [string]$Name) {
	If (Test-Path -Path $Source -PathType Leaf) {
		try {
			$stringOutput = "EXTRACTS: Extracting archive for $Name - $Source -> $Destination"
			Write-Log $stringOutput $true
			Expand-7Zip -ArchiveFileName $Source -TargetPath $Destination
			$stringOutput = "EXTRACTS: Extracted archive for $Name"
			Write-Log $stringOutput $true
		}
		catch {
			$stringOutput = @"
EXTRACTS: An error occured while trying to extract archive for $Name
ERROR: $_
"@
			Write-Log $stringOutput $true
		}
	} else {
		$stringOutput = @"
EXTRACTS: An error occured while trying to extract archive for $Name.
Source archive doesn't exist: $Source
"@
			Write-Log $stringOutput $true
	}
}

Function Move-Directory ([string]$Source, [string]$Destination, [string]$Name) {
	try {
		$stringOutput = "EXTRACTS: Moving files for $Name - $Source -> $Destination"
		Write-Log $stringOutput $true
		Copy-Item -Path "$Source\*" -Destination $Destination
		$stringOutput = "EXTRACTS: Moved files for $Name"
		Write-Log $stringOutput $true
	}
	catch {
		$stringOutput = @"
EXTRACTS: An error occured while trying to move files for $Name
$_
"@
			Write-Log $stringOutput $true
	}
}

#endregion

#region ------------------------------ Start Steamu Log FIle

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

#endregion

#region ------------------------------ Validate CLI parameters

if ( !$gitBranches -contains $branch ) {
	$stringOutput = "Invalid branch $branch. Valid parameters include: $gitBranches. Press any key to exit."
	inputPause $stringOutput
	exit
}
else {
	$stringOutput = "Valid branch: $branch"
	Write-Log $stringOutput $false
}

#endregion

#region ------------------------------ Gather installation parameters

# Set automated installation parameters
$doDownload = $true
$doCustomRomDirectory = $false
$doRomSubFolders = $true

$title = 'Welcome to Steamu!'
$question = @"

This program is designed to simplify the process of
downloading, installing and configuring emulation
to get you retro gaming in a matter of minutes. 

You will have the option to use an entirely automated
installation using defaults or a customized installation
for more advanced configurations.

Default installation path for Steamu, Apps and Emulators:
$pathSteamu

Default path for ROMs, Bios files, saves, states and misc storage:
$pathEmulation

Default path for shortcuts to Apps and Emulators:
$pathDesktopShortcuts

Documentation is forthcoming, please be patient.

Enjoy!

"@
$choices = @('&Continue','&Quit')
$default = 0
Write-Space
$continueInstallation = Get-Choice $title $question $default $choices

If ($continueInstallation -eq 1) {
	inputPause 'Installation cancelled. Press any key to exit.'
	exit
}

# ask here to install Steamu, apps, emulators to a different path

$title = 'Installation Selection'
$question = @"

Would you like to proceed with an automated installation or do you wish to customize your install?

"@
$default = 0
$choices = @('&Automated','&Custom')
Write-Space
$installChoice = Get-Choice $title $question $default $choices


if ($installChoice -eq 0) {
    Write-Log 'Automated install chosen' $true
} else {
    Write-Log 'Custom install chosen' $true

	# choose a custom rom directory
	$title = 'Custom ROM Directory Selection'
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

	# check to make sure custom path was selected, if it is the same as the default then reset $doCustomRomDirectory
	If ($pathRoms -eq "$pathEmulation\roms") {
		$doCustomRomDirectory = $false
	}

	# choose if you want to populate your custom rom path only if they chose custom
	If ($doCustomRomDirectory) {
		$title = 'Custom ROM Directory Sub-folders'
		$question = @"

Would you like ROM system sub-directories created in your custom ROM path?

Custom path: $pathRoms

This will create properly named directories at the destination for all the supported systems
such as amiga, snes, mame, etc.

Existing ROMs at the destination won't be moved or deleted.

IMPORTANT: We use exact system directory names as defined in our documentation on Github.
		You may need to move existing roms into properly named system folders in order for them
		to be seen by the various apps and emulators.

"@
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

#endregion

#region ------------------------------ Build directory structure

$stringOutput = @"
Creating Steamu directory structure
Path: $pathSteamu

"@
Write-Log $stringOutput $true

# foreach logic here to create directories from xml, perhaps where-object parentnode.name = 'Steamu', etc.

$dirXml.SelectNodes('//sub-directory') | ForEach-Object{
    $basePath = $ExecutionContext.InvokeCommand.ExpandString($_.parentnode.Path)
    $name = $_.parentnode.name
    $subDirectoryName = $_.name

    $fullPath = "$basePath\$subDirectoryName"

    If ($name -ne 'Roms') {
        New-Directory -Path $fullPath
        #Write-Host "DIRECTORIES: $name - $fullPath"
    }

    If (($name -eq 'Roms') -and ($doRomSubFolders)) {
        New-Directory -Path $fullPath
        #Write-Host "DIRECTORIES: $name - $fullPath"
    }
}

$stringOutput = @"
Steamu directory structure created.

"@
Write-Log $stringOutput $true

#endregion

#region ------------------------------ Download required files
IF (($doDownload -eq $true) -and ($devSkip -eq $false)) {
	if (test-path -path $pathDownloads) {
		$stringOutput = 'Beginning downloads.'
		Write-Log $stringOutput $true

# new foreach logic here for downloads from xml, add foreach for extras, select url node
	$configXml.SelectNodes('//Download') | ForEach-Object{
	    $name = $ExecutionContext.InvokeCommand.ExpandString($_.parentnode.Name)
	    $url = $ExecutionContext.InvokeCommand.ExpandString($_.Url)
	    $saveAs = $ExecutionContext.InvokeCommand.ExpandString($_.SaveAs)

		New-Download -URI $url -TargetFile "$pathTemp\$saveAs" -Name $name

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

#endregion

## TODO backup any existing configs

#region ------------------------------ Install all-the-things
	
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

If (($doDownload -eq $true) -and ($devSkip -eq $false)) {

	$stringOutput = "EXTRACTS: Beginning etraction"
	Write-Log $stringOutput $true

	$configXml.SelectNodes('//Extract') | ForEach-Object  {
		$name = $ExecutionContext.InvokeCommand.ExpandString($_.parentnode.Name)
		$type = $ExecutionContext.InvokeCommand.ExpandString($_.Type)
	    $destinationBasePath = $ExecutionContext.InvokeCommand.ExpandString($_.Destination.BasePath)
	    $destinationDirectoryName = $ExecutionContext.InvokeCommand.ExpandString($_.Destination.DirectoryName)
		$directToPath = $ExecutionContext.InvokeCommand.ExpandString($_.DirectToPath)
		$extractToPath = $pathTemp

		<# this is for shortcuts
	    $exe = IF ($_.parentnode.Exe.Count -gt 1) { 
	        $_.parentnode.SelectSingleNode("//Exe[@Arch = '$architecture']").InnerText 
	    } else { 
	        $ExecutionContext.InvokeCommand.ExpandString($_.parentnode.exe)
	    }
		#>

	    $extractFolder = IF ($_.ExtractFolder.Count -gt 1) { 
	        $_.SelectSingleNode("//ExtractFolder[@Arch = '$architecture']").InnerText 
	    } else { 
	        $ExecutionContext.InvokeCommand.ExpandString($_.ExtractFolder)
	    }

		$copyFromPath = "$pathTemp\$extractFolder"

		$stringOutput = "Extracting $name..."
		Write-Log $stringOutput $true

		If ($directtopath) {
			$extractToPath = "$pathTemp\$destinationDirectoryName"
			$copyFromPath = $extractToPath
			New-Directory -path $extractToPath
		}

		If ($type -eq 'zip'){

				Extract-Archive -Source $archiveLocation -Destination $extractToPath -Name $Name
				
		} elseif ($type -eq 'exe') {
				
				Move-Directory -Source $copyFromPath -Destination $moveToPath -Name $Name

		} else {
			$stringOutput = "EXTRACTS: Extraction type not handled for $Name! Type: $type"
			Write-Log $stringOutput $True
		}

		#Clean up temp folder
		$stringOutput = "EXTRACTS: Cleaning up temp folder..."
		Write-Log $stringOutput $True
		Remove-Item -Path "$pathTemp\*" -Recurse -Force

	}

		$stringOutput = 'EXTRACTS: Extraction complete!'
		Write-Log $stringOutput $true

} else {
	$stringOutput = @"
EXTRACTS: Extraction is skipped due to configuration.

doDownload: $doDownload
devSkip: $devSkip
"@
	Write-Log $stringOutput $true
}

#endregion

#region ------------------------------ Set up junctions (symlinks)

$stringOutput = 'JUNCTIONS: Creating Junctions (symlinks)...'
Write-Log $stringOutput $true

		# RetroArch links

		$configXml.SelectNodes('//Junction') | ForEach-Object {
			$name = $ExecutionContext.InvokeCommand.ExpandString($_.parentnode.Name)
			$junctionName = $ExecutionContext.InvokeCommand.ExpandString($_.Name)
			$targetBasePath = $ExecutionContext.InvokeCommand.ExpandString($_.TargetBasePath)
			$sourcePath = $ExecutionContext.InvokeCommand.ExpandString($_.Source)

			$targetFullPath = "$targetBasePath\$junctionName"

			New-Junction -Source $sourcePath -Target $targetFullPath Name $name
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

#endregion

#region ------------------------------ Copy configs
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

#endregion

#region ------------------------------ Set up exe shortcuts

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

#endregion

## TODO if existing configs exit, replace, else, copy new configs

## TODO if existing controller configs exist, replace, else, copy new configs


##### FINISH ######
Write-Space
$stringOutput = 'All Done =) Press any key to exit.'
inputPause $stringOutput
exit