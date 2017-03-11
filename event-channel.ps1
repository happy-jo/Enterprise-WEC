function check-os {
	$osname = (Get-WmiObject -Class win32_operatingsystem).caption
	$osversion = (Get-WmiObject -Class win32_operatingsystem).version
	$osarch = (Get-WmiObject -Class win32_operatingsystem).osarchitecture
	
	if (!($osname -like "Microsoft Windows Server 2012 R2*") -and ($osversion -like "6.3*") -and ($osarch -eq "64-bit")) {
		"This config if ment for Windows Server 2012 R2 64-bit Version 6.3. This OS is $osname $osarch Version $osversion."; break
	}
}

funtion get-eventchannelconfig {
	check-os

	$savedconfig = "c:\temp\WEFconfig\ChannelConfig"
	if (!(test-path -Path $savedconfig)) {
		mkdir $savedconfig
		}

	$config1 = "https://github.com/happy-jo/Enterprise-WEC/blob/master/EventChannelConfigs/WECEventChannels_WS2012R2.zip"
	(New-Object System.Net.WebClient).DownloadFile($config1, $savedconfig)

	$savedzip = $savedconfig+"WECEventChannels_WS2012R2.zip"

	add-type -AssemblyName "system.io.compression.filesystem"

	[io.compression.zipfile]::ExtractToDirectory($savedzip, $savedconfig)

	if (!((Test-Path $savedconfig+"\WECEventChannels_WS2012R2.dll") -and (Test-Path $savedconfig+"\WECEventChannels_WS2012R2.man"))) {
		Write-Error "Something went wrong and the Config files were not found.."; break
		}
}

function move-eventchannelconfig {
	check-os

	$savedconfig = "c:\temp\WEFconfig\ChannelConfig"
	if (!(test-path -Path $savedconfig)) {
		Write-Error "Could not find path, run get-eventchannelconfig to download Event Channel Configurations"; break
		}
	try {
		(cp $savedconfig+"\WECEventChannels_WS2012R2.dll" $env:windir+"\system32\") -and (cp $savedconfig+"\WECEventChannels_WS2012R2.man" $env:windir+"\system32\")
	}
	catch {
		Write-Error "Copy failed, check files!"
	}
}

function set-eventchannelconfig {
	Write-Host "The default setting for this function will put the log files in c:\Logs\ and set their default size to 1GB."

	if (!(test-path -Path c:\Logs)) {
		mkdir c:\Logs
		}

	wevtutil.exe im C:\WINDOWS\System32\WECEventChannels_WS2012R2.man

	wevtutil.exe sl WEC-DomainControllers /lfn:C:\Logs\WEC-DomainControllers.evtx /ms:1073741824

	wevtutil.exe sl WEC-DomainComputers /lfn:C:\Logs\WEC-DomainComputers.evtx /ms:1073741824

	wevtutil.exe sl WEC-Collector-Servers /lfn:C:\Logs\WEC-Collector-Servers.evtx /ms:1073741824

	wevtutil.exe sl WEC-Exchange-Servers /lfn:C:\Logs\WEC-Exchange-Servers.evtx /ms:1073741824

	wevtutil.exe sl WEC-Privileged-Access-Workstations /lfn:C:\Logs\WEC-Privileged-Access-Workstations.evtx /ms:1073741824
}