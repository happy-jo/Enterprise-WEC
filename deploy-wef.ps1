# PowerShell
# deploy-wef.ps1
#
# This script was writen to setup and configure a Windows Server 2008 R2+ with act as a Windows Event Collector (WEC).
# It also provide deployment options to do the following things:
#
#  -Deploy the basic setting to collect a basic set of Windows events (The listing of event can be found in the "../subscription-configs/basic-event-collection.xml" file.
#  -Deploy role specific subscription configuration XML files. The files are locate at "../subcription-configs/."
#  -Deploy collector monitoring/alerting subscription configuration
#
#
# Configure WinRM service on the collector, the defaults are ok.


Write-Host "`nThis script will run the basic setting needed to enable this machine as a Windows Event Collector."
Write-Host "If you do not want to run this script, press ctrl-c an the script will exit."
Read-Host "`nPress any key to start setting up"

function setup-collector {
	try {

		clr
		#clearing error log
		$Error=$null

		# preformed a "quick configure" on the winrm services, this starts the services and adds incomming firewall rules.
		winrm qc

		# Implementing Service Control strategies. Seperate scvhost.exe dependencies to seperate services, and add WinRM as a dependency to Windows Event Collector service.
		sc.exe CONFIG winrm type= own
		sc.exe CONFIG WecSvc type= own
		sc.exe CONFIG WecSvc depend= WinRM
		
		# Restart the Windows Event Collection service if it fails to start after 10 seconds and after 3 minutes. If it continutes to fail, reboot the computer after 10 minutes. (Counter set to reset after 60 seconds of successful start)
		sc.exe FAILURE WecSvc reset= 60 actions = restart/5000/restart/180000/reboot/600000

		# Restart the Windows Event Log service if is fails start after 5 seconds and after 60 seconds (Counter set to reset after 60 seconds of successful start)
		sc.exe FAILURE EventLog reset= 60 actions = restart/5000/restart/60000


		# If using Splunk to forward logs, a special strategy is need to to delay it's startup
		
		# Change TCP HTTP idle disconnect limit, this will help the collector disconnect un-needed source connection. (Set to 30 seconds)
		Netsh.exe http add timeout timeouttype=idleconnectiontimeout value=30
	}
	catch {
		Write-Host "The following commands did not work!"
		$Error.Exception
	}
}

function setup-splunk {
	if (Get-Service SplunkForwarder -ErrorAction SilentlyContinue) {

			# In order for the Splunk Forwarder to decode the events, the Windows Event Log service must be running. Also, if logs are not coming in to the collector, there is no need for forward them.
			# A Splunk Forwarder config could be establish to monitor for these issue, But I optted out of this strategy
			sc.exe CONFIG SplunkForwarder depend= WecSvc/EventLog

			# Add a buffer of time between starts
			sc.exe CONFIG SplunkForwarder start= delayed-auto

			# Add failure strateg incase the Splunk Forwarder service fails to start. Yes, this happens. 
			# First try to restart the Splunkd.exe service after 5 seconds, then try to restart is again if it is still has not started after 3 minutes, they manually command the service to to restart (hard restart.)
			# (Counter set to reset after 60 seconds of successful start)
			sc.exe FAILURE SplunkForwarder reset= 60 command= "C:\Program Files\SplunkUniversalForwarder\bin\splunk.exe restart" actions= restart/5000/run/200000

		} 
		else {
			Write-Host "Splunk not installed."
		}
}

function get-configs {
	$savedconfig = "c:\temp\WEFconfig\"

	if (!(test-path -Path $savedconfig)) {
		mkdir $savedconfig
	}
	$config1 = "https://github.com/happy-jo/Enterprise-WEC/blob/master/dc_machine(all_events)_lowLat.xml"
	$config2 = "https://github.com/happy-jo/Enterprise-WEC/blob/master/non-dc_machine(all_events)_lowLat.xml"
	(New-Object System.Net.WebClient).DownloadFile($config1, $savedconfig)
	(New-Object System.Net.WebClient).DownloadFile($config2, $savedconfig)
}

function load-configs {
	cls
	Write-Host " Checking For Subscription files..."
	try {
		add-alldomaincontrollers
		add-alldomaincomputers
		}
	catch {
		Write-Error -Exception
		}
}

function add-alldomaincomputers {
	cls
	Write-Verbose "Checking for Config file..."
	#path check
	$rootpath = "c:\temp\WEFconfig\"
	if (Test-Path $rootpath+"non-dc_machine(all_events)_lowlat.xml") {
		Write-Verbose "`nConfig file exists. Loading file."
		try {
			[XML]$allcompxml = Get-Content -path $rootpath+"non-dc_machine(all_events)_lowlat.xml"
			wecutil.exe cs $allcompxml
			}
		catch {
			Write-Error -Exception
			}
		}
	else {
		Write-Host "`nConfig file not found. Make sure XML config is in the $rootpath." -ForegroundColor red
	}
}

function add-alldomaincontrollers {
	cls
	Write-Verbose " Checking for Config file."
	#path check
	$rootpath = "c:\temp\WEFconfig\"
	if (Test-Path $rootpath+"dc_machine(all_events)_lowlat.xml") {
		Write-Verbose "`nConfig file exists. Loading file."
		try{
			[XML]$alldcxml = Get-Content -Path $rootpath+"dc_machine(all_events)_lowlat.xml"
			wecutil.exe cs $alldcxml
			}
		catch {
		Write-Error -Exception
		}
	}
	else {
		Write-Host "`nConfig file not found. Make sure XML config is im the $rootpath." -ForegroundColor red
	}
}

setup-collector
get-configs
load-configs