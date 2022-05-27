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
# clear errors
$error.Clear()
# Turn off download progress bar otherwise downloads take SIGNIFICANTLY longer
$ProgressPreference = 'SilentlyContinue'

#endregion

#region ------------------------------ Global Variables

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
$pathConfigEmu = "$pathEmulation\config"

$pathDesktopShortcuts = "$pathHome\Desktop\Emulation"

$outputString = ""

$fileLogName = 'Steamu_log.txt'
$fileLog = "$pathLogs\$fileLogName"

#endregion

#region ------------------------------ Functions

function Write-Log ($stringMessageArg, [switch]$toHost, [switch]$IsError)
# http://woshub.com/write-output-log-files-powershell/
{
	$timeStamp = (Get-Date).toString("yyyy/MM/dd HH:mm:ss")
	$stringLogMessage = "$timeStamp $stringMessageArg"
	
	Add-content $fileLog -value $stringLogMessage

	If ($toHost) {
		If ($IsError) {
			Write-Host $stringMessageArg -ForegroundColor Red
		} else {
			Write-Host $stringMessageArg
		}
	}
}
Function Suspend-Console ($stringMessageArg)
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
        Write-Log $stringMessageArg -ToHost
        $x = $host.ui.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    }
}

Function New-Download ([string]$URI, [string]$TargetFile, [string]$Name) {

		Try {
			$outputString = "DOWNLOADS: Downloading $Name"
			Write-Log $outputString -ToHost
			Invoke-WebRequest -URI $URI -OutFile $TargetFile
			$outputString = "DOWNLOADS: $Name Complete - $TargetFile"
			Write-Log $outputString
		} Catch {
			$errorString = $PSItem.Exception.Message
			$outputString = @"
DOWNLOADS: An error occured while attempting download: $Name -> $TargetFile
ERROR: $errorString
"@
			Write-Log $outputString -ToHost -IsError
		} 
}

function New-Shortcut([string]$SourceExe, [string]$DestinationPath, [string]$SourcePath){
# https://stackoverflow.com/a/9701907
	If(Test-Path -Path $DestinationPath -PathType Leaf) {
		try {
			Remove-Item -Path $DestinationPath -Force | Out-Null
			$outputString = "SHORTCUTS: Already exists. Removed - $DestinationPath"
			Write-Log $outputString
		}
		catch {
			$errorString = $PSItem.Exception.Message
			$outputString = @"
SHORTCUTS: An error occured while attempting to remove shortcut: $DestinationPath
ERROR: $errorString
"@
			Write-Log $outputString -ToHost -IsError
		}
		
	}

	try {
		$WshShell = New-Object -comObject WScript.Shell
		$Shortcut = $WshShell.CreateShortcut($DestinationPath)
		$Shortcut.TargetPath = $SourceExe
		$Shortcut.WorkingDirectory = $SourcePath
		$Shortcut.Save() | Out-Null
		$outputString = "SHORTCUTS: Created shortcut - $DestinationPath"
		Write-Log $outputString
	}
	catch {
		$errorString = $PSItem.Exception.Message
		$outputString = @"
SHORTCUTS: An error occured while attempting to create shortcut: $DestinationPath
ERROR: $errorString
"@
		Write-Log $outputString -ToHost -IsError
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

	# If a bad junction was created it may leave an extension-less file and will be confused for the target
	If (Test-Path -Path $Target -PathType Leaf) {
		Remove-Item -Path $target -Force
	}

	# make target if it doesn't exist
	If ((Test-Path -Path $Target) -eq $false) {
		New-Directory -path $Target
	}

	$pathLinkType = (Get-Item -Path $target -Force).LinkType

	If ($pathLinkType -eq "Junction"){
		$isJunction = $true
	}

	#test if target is path, and empty

	If ($isJunction) {
		Try {
			Remove-Item -Path $target -Force -Recurse | Out-Null
			$outputString = "JUNCTIONS: Already exists, removed: $target"
			Write-Log $outputString
		} Catch {
			$errorString = $PSItem.Exception.Message
			$outputString = @"
JUNCTIONS: An error occured while trying to remove junction: $target
ERROR: $errorString
"@
			Write-Log $outputString -ToHost -IsError
		}
		
	}
		Try {
			New-Item -ItemType Junction -Path $target -Target $source | Out-Null
			$outputString = "JUNCTIONS: Junction created for $Name - $target -> $source"
			Write-Log $outputString
		} Catch {
			$errorString = $PSItem.Exception.Message
			$outputString = @"
JUNCTIONS: An error occured while creating a junction for $Name - $target -> $source
ERROR: $errorString
"@
			Write-Log $outputString -ToHost -IsError
		}
		
}

Function Write-Space {
	#Clear-Host
}

Function New-Directory([string]$path) {
	If ((Test-Path -Path $path) -eq $false) {
		Try {
			New-Item -ItemType "directory" -Path $path | Out-Null
			$outputString = "DIRECTORIES: Created directory: $path"
			Write-Log $outputString
		} Catch {
			$errorString = $PSItem.Exception.Message
			$outputString = @"
DIRECTORIES: An error occured while trying to create path: $path
ERROR: $errorString
"@
			Write-Log $outputString -ToHost -IsError
		}
			
	} else {
		$outputString = "DIRECTORIES: Already exists: $path"
		Write-Log $outputString
	}
}

Function Expand-Archive ([string]$Source, [string]$Destination, [string]$Name) {
	If (Test-Path -Path $Source -PathType Leaf) {
		try {
			$outputString = "EXTRACTS: Extracting archive for $Name"
			Write-Log $outputString -ToHost
			Expand-7Zip -ArchiveFileName $Source -TargetPath $Destination | Out-Null
			$outputString = "EXTRACTS: Extracted archive for $Name - $Source -> $Destination"
			Write-Log $outputString
		}
		catch {
			$errorString = $PSItem.Exception.Message
			$outputString = @"
EXTRACTS: An error occured while trying to extract archive for $Name
ERROR: $errorString
"@
			Write-Log $outputString -ToHost -IsError
		}
	} else {
		$outputString = @"
EXTRACTS: An error occured while trying to extract archive for $Name.
Source archive doesn't exist: $Source
"@
			Write-Log $outputString -ToHost -IsError
	}
}

Function Move-Directory ([string]$Source, [string]$Destination, [string]$Name, [switch]$OverwriteDestination) {
	try {
		$outputString = "EXTRACTS: Moving files for $Name"
		Write-Log $outputString -ToHost
		If ($OverwriteDestination) {
			Copy-Item -Path $Source -Destination $Destination -Force -Recurse | Out-Null
		} else {
			Copy-Item -Path $Source -Destination $Destination -Recurse | Out-Null
		}
		
		$outputString = "EXTRACTS: Moved files for $Name - $Source -> $Destination"
		Write-Log $outputString
	}
	catch {
		$errorString = $PSItem.Exception.Message
		$outputString = @"
EXTRACTS: An error occured while trying to move files for $Name
ERROR: $errorString
"@
			Write-Log $outputString -ToHost -IsError
	}
}

#endregion

#region ------------------------------ Load XML

# config
If (Test-Path -Path .\configuration.xml -PathType Leaf) {
	[xml]$configXml = Get-Content -Path .\configuration.xml	
} else {
	$outputString = "XML: Unable to load configuration.xml"
	Suspend-Console $outputString 
	exit
}

# directories
If (Test-Path -Path .\directories.xml -PathType Leaf) {
	[xml]$dirXml = Get-Content -Path .\directories.xml
} else {
	$outputString = "XML: Unable to load configuration.xml"
	Suspend-Console $outputString 
	exit
}

# Settings
If (Test-Path -Path "$pathSteamu\userSettings.xml" -PathType Leaf) {
	[xml]$setXml = Get-Content -Path "$pathSteamu\userSettings.xml"

	$doFirstTimeSetup = $false
	$doUpdate = $true
} else {
	$doFirstTimeSetup = $true
	$doUpdate = $false
}


# version numbers from configuration.xml

$configXml.SelectNodes('//Program') | ForEach-Object {
	$variablePrefix = $_.VariableName
	$variableVersion = $variablePrefix + 'Version'
	$versionNumber = $_.Version
	if ($variableVersion) {
		Set-Variable -Name $VariableVersion -Value $versionNumber
	} else {
		New-Variable -Name $VariableVersion -Value $versionNumber
	}	
}

# load paths from userSettings.xml
If ($setXml) {
	$pathRoms = $setXml.SelectSingleNode('//Roms').InnerText
	$pathSaves = $setXml.SelectSingleNode('//Saves').InnerText
	$pathStates = $setXml.SelectSingleNode('//States').InnerText
}

# reset to default if the paths are for some reason null
If (!$pathRoms) {
	$pathRoms = "$pathEmulation\roms"
}
If (!$pathSaves) {
	$pathSaves = "$pathEmulation\saves"
}
If (!$pathStates) {
	$pathStates = "$pathEmulation\states"
}


# version numbers from userSettings.xml
#If ($setXml) {
# $setXml.SelectNodes('//Program') | ForEach-Object {
# 	$name = $_.Name
# 	$variablePrefix = $configXml.SelectSingleNode("//Program[Name = $name]").VariableName
# 	$variableVersion = $variablePrefix + 'VersionOld'
# 	$versionNumber = $_.Version
# 	if ($variableVersion) {
# 		Set-Variable -Name $VariableVersion -Value $versionNumber
# 	} else {
# 		New-Variable -Name $VariableVersion -Value $versionNumber
# 	}
# }
#}

# check for updateable programs
If ($setXml) {
	$doUpdateNames = @()
	$configXml.SelectNodes('//Program') | ForEach-Object {
		$name = $_.Name
		$version = $_.Version
		$setCheck = $setXml.SelectSingleNode("//Program[Name = '$name']")
		$versionOld = $setXml.SelectSingleNode("//Program[Name = '$name']").Version

		If (!$setCheck) {
			$doUpdateNames += $name
		} elseif (($versionOld) -and ($versionOld -ne $version)) {
			$doUpdateNames += $name
		}
	}
}

#endregion

#region ------------------------------ Start Steamu Log FIle

if (Test-Path -path $fileLog -PathType Leaf) {
	#Clear-Content -path $fileLog
	#$outputString = "$fileLog Cleared Log File"
	#Write-Log $outputString

} else {

	If ((Test-Path -Path $pathLogs) -eq $false) {
		New-Item -Path $pathLogs -ItemType "directory"  | Out-Null
	}

	New-Item -path $fileLog -ItemType "file" | Out-Null
	
	$outputString = "Created Log File at $pathLogs"
	Write-Log $outputString

}

#endregion

#region ------------------------------ Validate CLI parameters

if ( !$gitBranches -contains $branch ) {
	$outputString = "Invalid branch $branch. Valid parameters include: $gitBranches. Press any key to exit."
	Suspend-Console $outputString
	exit
}
else {
	$outputString = "Valid branch: $branch"
	Write-Log $outputString
}

#endregion

#region ------------------------------ Gather installation/update parameters

#check new xml for changes in versions against old xml HERE

If ($doUpdate) {
	If (!$doUpdateNames) {
		$updateString = @"
	No programs found to be updateable. You may choose a Clean installation
	or exit.
"@
	} else {
		$updateString = @"
	The following programs where found to be updatable:
	$doUpdateNames
"@
	}

	$title = 'Steamu'
	$question = @"

	Existing installation detected. We will attempt to detect any needed
	updates and apply them. 
	
	You also have the option to continue as if this were a new install. This
	will allow you to choose new paths or make changes to custom options.

	Default installation path for Steamu, Apps and Emulators:
	$pathSteamu

	Default path for ROMs, Bios files, saves, states and misc storage:
	$pathEmulation

	Default path for shortcuts to Apps and Emulators:
	$pathDesktopShortcuts

	The following paths are customizable and have been loaded from User Settings as follows:
	Roms: $pathRoms
	Saves: $pathSaves
	States: $pathStates

	$updateString
"@
	If (!$doUpdateNames) {
		$choices = @('&Clean Installation','&Quit')
		$default = 1
		Write-Space
		$updateInstallation = Get-Choice $title $question $default $choices
	
		If ($updateInstallation -eq 1) {
			Suspend-Console 'Installation cancelled. Press any key to exit.'
			exit
		} else {
			Suspend-Console 'Performing Clean Installation. Press any key to continue.'
			$doUpdate = $false
			$doFirstTimeSetup = $true
			#Remove-Item -Recurse -Force -Path $pathSteamu
		}
	} else {
		$choices = @('&Update','&Clean Installation','&Quit')
		$default = 0
		Write-Space
		$updateInstallation = Get-Choice $title $question $default $choices
	
		If ($updateInstallation -eq 2) {
			Suspend-Console 'Installation cancelled. Press any key to exit.'
			exit
		} elseif ($updateInstallation -eq 1) {
			$doUpdate = $false
			$doFirstTimeSetup = $true
		} else {
			Suspend-Console 'Performing update. Press any key to continue.'
		}
	}

}

If ($doFirstTimeSetup) {
# Set automated installation parameters
	$doDownload = $true
	$doCustomRomDirectory = $false
	$doRomSubFolders = $true

	$title = 'Steamu'
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
		Suspend-Console 'Installation cancelled. Press any key to exit.'
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

	########## choose a custom rom directory
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

			# if get-folder is cancelled then revert to default path
			If ($null -eq $pathRoms) {
				$outputString = "CUSTOM: No custom rom folder selected. Reverting to default."
				Write-Log $outputString -ToHost
				$pathRoms = "$pathEmulation\roms"
				$doCustomRomDirectory = $false
			}

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

	########## custom saves directory selection
		$title = 'Custom Saves Directory Selection'
		$question = @"

	Would you like to choose your own Saves path?

	Default path: $pathSaves

	If you choose yes, you will be prompted to select the proper path.

"@
		$default = 1
		$choices = @('&Yes','&No')
		Write-Space
		$customSavesDirectoryChoice = Get-Choice $title $question $default $choices
		if ($customSavesDirectoryChoice -eq 0) {
			
			$doCustomSavesDirectory = $true
			$pathSaves = Get-Folder

			# if get-folder is cancelled then revert to default path
			If ($null -eq $pathSaves) {
				$outputString = "CUSTOM: No custom Saves folder selected. Reverting to default."
				Write-Log $outputString -ToHost
				$pathSaves = "$pathEmulation\saves"
				$doCustomSavesDirectory = $false
			}

			Write-Log @"
	CUSTOM: Custom Saves directory chosen.

	Path: $pathSaves
"@ $true
		} else {
			Write-Log @"
	Using default Saves directory.

	Path: $pathSaves
"@ $true
			$doCustomSavesDirectory = $false
		}

	########## custom states directory selection
	$title = 'Custom States Directory Selection'
	$question = @"

	Would you like to choose your own States path?
	This folder stores save states if an emulator supports them.

	Default path: $pathStates

	If you choose yes, you will be prompted to select the proper path.

"@
	$default = 1
	$choices = @('&Yes','&No')
	Write-Space
	$customStatesDirectoryChoice = Get-Choice $title $question $default $choices
	if ($customStatesDirectoryChoice -eq 0) {
		
		$doCustomStatesDirectory = $true
		$pathStates = Get-Folder

		# if get-folder is cancelled then revert to default path
		If ($null -eq $pathStates) {
			$outputString = "CUSTOM: No custom States folder selected. Reverting to default."
			Write-Log $outputString -ToHost
			$pathStates = "$pathEmulation\states"
			$doCustomStatesDirectory = $false
		}

		Write-Log @"
	CUSTOM: Custom States directory chosen.

	Path: $pathStates
"@ $true
	} else {
		Write-Log @"
	Using default States directory.

	Path: $pathStates
"@ $true
		$doCustomStatesDirectory = $false
		}

	}
}

#endregion

#region ------------------------------ Build directory structure

If ($doFirstTimeSetup) {

	$outputString = 'DIRECTORIES: Creating Steamu directory structure'
	Write-Log $outputString -ToHost

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

	$outputString = 'DIRECTORIES: Steamu directory structure created.'
	Write-Log $outputString -ToHost

}

#endregion

#region ------------------------------ Download required files
IF (($doDownload -eq $true) -and ($devSkip -eq $false)) {
	if (test-path -path $pathDownloads) {
		$outputString = 'DOWNLOADS: Beginning downloads.'
		Write-Log $outputString -ToHost

# new foreach logic here for downloads from xml, add foreach for extras, select url node
		$configXml.SelectNodes('//Download') | ForEach-Object{
			$name = $ExecutionContext.InvokeCommand.ExpandString($_.parentnode.Name)
			$url = $ExecutionContext.InvokeCommand.ExpandString($_.Url)
			$saveAs = $ExecutionContext.InvokeCommand.ExpandString($_.SaveAs)

			$fullTargetPath = "$pathDownloads\$saveAs"

			If (($doFirstTimeSetup) -or (($doUpdate) -and ($doUpdateNames -contains $name))) {
					New-Download -URI $url -TargetFile $fullTargetPath -Name $name
			} 
		}

		$outputString = 'DOWNLOADS: Downloads complete'
		Write-Log $outputString -ToHost

	} Else {
		$outputString = "DOWNLOADS: Unable to continue. $pathDownloads does not exist! Press any key to exit."
		Suspend-Console $outputString
		exit
	}
} else {
	$outputString = @"
Downloads are skipped due to configuration.

doDownload: $doDownload
devSkip: $devSkip
"@
	Write-Log $outputString -ToHost
}

#endregion

## TODO backup any existing configs

# backup configs listed in xml first

#region ------------------------------ Install all-the-things
	
	if (Get-Module -ListAvailable -Name '7Zip4PowerShell') {
		$outputString = '7z Powershell Module exists. Skipping.'
		Write-Log $outputString
	} else {
		# install 7z powershell module
		$outputString = 'Installing 7z Powershell Module'
		Write-Log $outputString -ToHost

		[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
		Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -Scope CurrentUser | Out-Null
		Set-PSRepository -Name 'PSGallery' -SourceLocation "https://www.powershellgallery.com/api/v2" -InstallationPolicy Trusted | Out-Null
		Install-Module -Name 7Zip4PowerShell -Force -Scope CurrentUser | Out-Null
	}

If (($doDownload -eq $true) -and ($devSkip -eq $false)) {

	$outputString = "EXTRACTS: Beginning extraction"
	Write-Log $outputString -ToHost

	$configXml.SelectNodes('//Extract') | ForEach-Object  {
		$name = $ExecutionContext.InvokeCommand.ExpandString($_.parentnode.Name)
		$type = $ExecutionContext.InvokeCommand.ExpandString($_.Type)
	    $destinationBasePath = $ExecutionContext.InvokeCommand.ExpandString($_.parentnode.BasePath)
	    $destinationDirectoryName = $ExecutionContext.InvokeCommand.ExpandString($_.parentnode.DirectoryName)
		$directToPath = If ($_.DirectToPath -ne $null) {$true} else {$false}
		$extractToPath = $pathTemp
		$saveAs = $ExecutionContext.InvokeCommand.ExpandString($_.parentnode.Download.SaveAs)
		$downloadFileLocation = "$pathDownloads\$saveAs"

	    $extractFolder = IF ($_.ExtractFolder.Count -gt 1) { 
	        $_.SelectSingleNode("//ExtractFolder[@Arch = '$architecture']").InnerText 
	    } else { 
	        $ExecutionContext.InvokeCommand.ExpandString($_.ExtractFolder)
	    }

		$copyFromPath = "$pathTemp\$extractFolder"
		$moveToPath = "$destinationBasePath\$DestinationDirectoryName"
		
		If ($type -eq 'zip'){
			If ($directToPath) {
				$extractToPath = "$pathTemp\$destinationDirectoryName"
				$copyFromPath = $extractToPath
				New-Directory -path $extractToPath
			}
			$copyFromPath += "\*"
			If (($doFirstTimeSetup) -or (($doUpdate) -and ($doUpdateNames -contains $name))) {
				Expand-Archive -Source $downloadFileLocation -Destination $extractToPath -Name $name
				Move-Directory -Source $copyFromPath -Destination $moveToPath -Name $name -OverwriteDestination
			}
				
		} elseif ($type -eq 'exe') {
			If (($doFirstTimeSetup) -or (($doUpdate) -and ($doUpdateNames -contains $name))) {
				Move-Directory -Source $downloadFileLocation -Destination $moveToPath -Name $name -OverwriteDestination
			}
		} else {
			$outputString = "EXTRACTS: Extraction type not handled for $Name! Type: $type"
			Write-Log $outputString -ToHost
		}
	}

		$outputString = 'EXTRACTS: Extraction complete!'
		Write-Log $outputString -ToHost

} else {
	$outputString = @"
EXTRACTS: Extraction is skipped due to configuration.

doDownload: $doDownload
devSkip: $devSkip
"@
	Write-Log $outputString -ToHost
}

#endregion

## TODO restore any existing configs

# restore configs listed in xml first

#region ------------------------------ Set up junctions (symlinks)

$outputString = 'JUNCTIONS: Creating Junctions (symlinks)...'
Write-Log $outputString -ToHost

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

$outputString = 'JUNCTIONS: Created Junctions (symlinks).'
Write-Log $outputString -ToHost

#endregion

#region ------------------------------ Copy configs
		If ($doDownload) {
#make backup function

			$outputString = "CONFIGS: Backing up existing configs..."
			Write-Log $outputString -ToHost

			$backupDateTime = $(get-date -f yyyyMMddHHmm)

			#Backup existing configs
			If (Test-Path -Path "$pathRetroarch\retroarch.cfg" -PathType Leaf) {
				Rename-Item -Path "$pathRetroarch\retroarch.cfg" -NewName "retroarch-$backupDateTime.cfg" -Force | Out-Null
				$outputString = "$pathRetroarch\retroarch.cfg backed up to retroarch-$backupDateTime.cfg"
				Write-Log $outputString
			}

			If (Test-Path -Path "$pathSrmData\userConfigurations.json" -PathType Leaf) {
				Rename-Item -Path "$pathSrmData\userConfigurations.json" -NewName "userConfigurations-$backupDateTime.json" -Force | Out-Null #need to do something here when these backup files already exist... probably an md5 so if it's the same file ignore it.
				$outputString = "$pathSrmData\userConfigurations.json backed up to userConfigurations-$backupDateTime.json"
				Write-Log $outputString
			}

			# If (Test-Path -Path "$pathEsData\es_find_rules.xml" -PathType Leaf) {
			# 	Rename-Item -Path "$pathEsData\es_find_rules.xml" -NewName "es_find_rules-$backupDateTime.xml" -Force | Out-Null
			# 	$outputString = "$pathEsData\es_find_rules.xml backed up to es_find_rules-$backupDateTime.xml"
			# 	Write-Log $outputString
			# }

			# If (Test-Path -Path "$pathEsData\es_systems.xml" -PathType Leaf) {
			# 	Rename-Item -Path "$pathEsData\es_systems.xml" -NewName "es_systems-$backupDateTime.xml" -Force | Out-Null
			# 	$outputString = "$pathEsData\es_systems.xml backed up to es_systems-$backupDateTime.xml"
			# 	Write-Log $outputString
			# }

			$outputString = "CONFIGS: Existing configs backed up."
			Write-Log $outputString -ToHost

			$outputString = "CONFIGS: Updating existing configs..."
			Write-Log $outputString -ToHost

			# Copy default configs
			$configXml.SelectNodes('//Program') | ForEach-Object {
				$name = $ExecutionContext.InvokeCommand.ExpandString($_.Name)
				$destinationPath = $ExecutionContext.InvokeCommand.ExpandString($_.BasePath)
				$destinationName = $ExecutionContext.InvokeCommand.ExpandString($_.DirectoryName)

				$copyConfigs = IF ($_.CopyConfigs -ne $null) {$true} else {$false}

				$copyFromPath = "$pathConfigs\$destinationName"
				$copyToPath = "$destinationPath\$destinationName"
				
				If ($doFirstTimeSetup) {
					IF ($copyConfigs) {
						If (Test-Path -Path $copyFromPath) {
							$copyFromPath += "\*"

							$outputString = "CONFIGS: First time setup. Overwriting configs for $name"
							Write-Log $outputString -ToHost

							Move-Directory -Source $copyfromPath -Destination $copyToPath -Name $name -OverwriteDestination
							} else {
								$outputString = "CONFIGS: Unable to overwrite configs for $name. Path does not exist: $copyFromPath"
								Write-Log $outputString -ToHost
							}
					}
				} elseif ($doUpdate) {
					IF ($copyConfigs) {
						If (Test-Path -Path $copyFromPath) {
							$copyFromPath += "\*"

							$outputString = "CONFIGS: Processing updates. Placing any new configs for $name, if any."
							Write-Log $outputString -ToHost

							Move-Directory -Source $copyfromPath -Destination $copyToPath -Name $name
							} else {
								$outputString = "CONFIGS: Unable to place new configs for $name. Path does not exist: $copyFromPath"
								Write-Log $outputString -ToHost
							}
					}
				}
			}

			$outputString = "CONFIGS: Existing configs updated."
			Write-Log $outputString -ToHost

		}

		#need to replace paths in SRM most likely

#endregion

#region ------------------------------ Set up exe shortcuts

	$outputString = "SHORTCUTS: Setting up application shortcuts in $pathDesktopShortcuts..."
	Write-Log $outputString -ToHost

	If ((Test-Path -Path "$pathDesktopShortcuts") -eq $false) {
		New-Item -Path "$pathDesktopShortcuts" -ItemType "directory" | Out-Null
	}

	If (Test-Path -Path "$pathDesktopShortcuts") {
		$configXml.SelectNodes('//Program') | ForEach-Object {
			$name = $ExecutionContext.InvokeCommand.ExpandString($_.Name)

			$exePath = $ExecutionContext.InvokeCommand.ExpandString($_.BasePath)
			$exePathName = $ExecutionContext.InvokeCommand.ExpandString($_.DirectoryName)
			$exeName = IF ($_.Exe.Count -gt 1) { 
					$_.SelectSingleNode("//Exe[@Arch = '$architecture']").InnerText 
				} else { 
					$ExecutionContext.InvokeCommand.ExpandString($_.exe)
				}
			$startIn = "$exePath\$exePathName"
			$exeFullPath = "$exePath\$exePathName\$exeName"
			$shortcutDesktopPath = "$pathDesktopShortcuts\$name.lnk"
			$shortcutSteamPath = "$pathShortcuts\$name.lnk"

			$createShortcutDesktop = IF ($_.CreateDesktopShortcut -ne $null) {$true} else {$false}
			$createShortcutSteam = IF ($_.CreateSteamShortcut -ne $null) {$true} else {$false}


			IF ($createShortcutDesktop){

				New-Shortcut -SourceExe $exeFullPath -DestinationPath $shortcutDesktopPath -SourcePath $startIn

			} 
			If ($createShortcutSteam) {

				New-Shortcut -SourceExe $exeFullPath -DestinationPath $shortcutSteamPath  -SourcePath $startIn

			}
		}
	} else {
		$outputString = "SHORTCUTS: Unable to create shortcuts. Directory $pathDesktopShortcuts does not exist!"
		Write-Log $outputString -ToHost
	}

#endregion

## TODO if existing configs exit, replace, else, copy new configs

## TODO if existing controller configs exist, replace, else, copy new configs

#Clean up temp folder
$outputString = "EXTRACTS: Cleaning up temp folder..."
Write-Log $outputString -ToHost
Remove-Item -Path "$pathTemp\*" -Recurse -Force

#Clean up temp folder
$outputString = "DOWNLOADS: Cleaning up download folder..."
Write-Log $outputString -ToHost
Remove-Item -Path "$pathDownloads\*" -Recurse -Force

# Write/Update userSettings.xml
$pathSetXml = "$pathSteamu\userSettings.xml"
$testPath = Test-Path -Path $pathSetXml -PathType Leaf 
If ((!$testPath) -and (!$error.count)) {
	$setXmlWriter = New-Object System.XML.XmlTextWriter($pathSetXml,$null)
	$setXmlWriter.Formatting = 'Indented'
	$setXmlWriter.Indentation = 1
	$setXmlWriter.IndentChar = "`t"
	$setXmlWriter.WriteStartDocument()
	$setXmlWriter.WriteStartElement('UserSettings')

	$setXmlWriter.WriteStartElement('Path')
	$setXmlWriter.WriteElementString('Roms',"$pathRoms")
	$setXmlWriter.WriteElementString('Saves',"$pathSaves")
	$setXmlWriter.WriteElementString('States',"$pathStates")
	$setXmlWriter.WriteEndElement()

	$configXml.SelectNodes('//Version') | ForEach-Object {
		$name = $_.parentnode.name
		$version = $_.InnerText

		$setXmlWriter.WriteStartElement('Program')
		$setXmlWriter.WriteElementString('Name',"$name")
		$setXmlWriter.WriteElementString('Version',"$version")
		$setXmlWriter.WriteEndElement()
	}

	$setXmlWriter.WriteEndElement()
	$setXmlWriter.WriteEndDocument()
	$setXmlWriter.Flush()
	$setXmlWriter.Close()
} elseif (($testPath) -and (!$error.count)) {
	$configXml.SelectNodes('//Program') | ForEach-Object {
		$name = $_.Name
		$version = $_.Version
		$setCheck = $setXml.SelectSingleNode("//Program[Name = '$name']")
		$versionOld = $setXml.SelectSingleNode("//Program[Name = '$name']").Version

		If (!$setCheck) {
			$element = $setXml.userSettings.Program[0].Clone()
			$element.Name = $name
			$element.Version = $version
			$setXml.DocumentElement.AppendChild($element)
		}

		If (($versionOld) -and ($versionOld -ne $version)) {
			$_.Version = $version
		}
	}
	$setXml.Save()
}

##### FINISH ######
Write-Space
$error.Clear()
$outputString = 'All Done =) Press any key to exit.'
Suspend-Console $outputString
exit