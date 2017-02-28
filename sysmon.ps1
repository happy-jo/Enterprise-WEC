
function get-sysmon {

$sysmondir = "c:\temp\sysmon\"

if (!(test-path -Path $sysmondir)) {
    mkdir $sysmondir
}

$sysmonurl = "https://download.sysinternals.com/files/Sysmon.zip"
$savedzip = $sysmondir+"Sysmon.zip"

(New-Object System.Net.WebClient).DownloadFile($sysmonurl, $savedzip)

add-type -AssemblyName "system.io.compression.filesystem"

[io.compression.zipfile]::ExtractToDirectory($savedzip, $sysmondir)

cd $sysmondir
}

function install-sysmon {

sysmon64.exe -i -n -accepteula 

}

