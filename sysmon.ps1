
function get-sysmon {

$sysmondir = "c:\temp\sysmon\"

if (!(test-path -Path $sysmondir)) {
    mkdir $sysmondir
}

$sysmonurl = "https://download.sysinternals.com/files/Sysmon.zip"
$sysmonconfigurl = "https://github.com/SwiftOnSecurity/sysmon-config/blob/master/sysmonconfig-export.xml"

$savedzip = $sysmondir+"Sysmon.zip"

(New-Object System.Net.WebClient).DownloadFile($sysmonurl, $savedzip)
(New-Object System.Net.Webclient).DownloadFile($sysmonconfigurl, $sysmondir)

add-type -AssemblyName "system.io.compression.filesystem"

[io.compression.zipfile]::ExtractToDirectory($savedzip, $sysmondir)

cd $sysmondir
}

function install-sysmon {

sysmon64.exe -i -n -accepteula sysmonconfig-export.xml

}

