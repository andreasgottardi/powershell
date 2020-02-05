param (
	# The apache version
	[String] $ApacheVersion = "2.4.41",
	# port to listen on
	[String] $ListeningPort = "80"
)

if ((New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
	New-Item -ItemType "Directory" -Path "$env:ProgramData\Apache"
	New-Item -ItemType "Directory" -Path "$env:ProgramData\Apache\conf"
	New-Item -ItemType "Directory" -Path "$env:ProgramData\Apache\www"
	Copy-Item -Path "$env:ProgramFiles\Apache\$ApacheVersion\conf\httpd.conf" -Destination "$env:ProgramData\Apache\conf\httpd.conf"
	Get-Content "$env:ProgramData\Apache\conf\httpd.conf" | ForEach-Object {
		if($_ -match 'Define SRVROOT *'){
			Add-Content -Path "$env:ProgramData\Apache\conf\httpd.conf.new" -Value "Define SRVROOT `"C:/Program Files/Apache/$ApacheVersion`""
		} elseif($_ -match 'DocumentRoot "\${SRVROOT}/htdocs"'){
			Add-Content -Path "$env:ProgramData\Apache\conf\httpd.conf.new" -Value "DocumentRoot `"$env:ProgramData\Apache\www`""
		} elseif($_ -match '<Directory "\${SRVROOT}/htdocs"'){
			Add-Content -Path "$env:ProgramData\Apache\conf\httpd.conf.new" -Value "<Directory `"$env:ProgramData\Apache\www`">"
		} elseif($_ -match 'Listen 80'){
			Add-Content -Path "$env:ProgramData\Apache\conf\httpd.conf.new" -Value "Listen $ListeningPort"
		} else {
			Add-Content -Path "$env:ProgramData\Apache\conf\httpd.conf.new" -Value $_
		}
	}
	Remove-Item -Path "$env:ProgramData\Apache\conf\httpd.conf"
	Move-Item -Path "$env:ProgramData\Apache\conf\httpd.conf.new" -Destination "$env:ProgramData\Apache\conf\httpd.conf"

	Start-Process -FilePath "$env:ProgramFiles\Apache\$ApacheVersion\bin\httpd.exe" -ArgumentList "-k","install","-n","`"Apache web server`"","-f","`"$env:ProgramData\Apache\conf\httpd.conf`""
} else {
	Start-Process -FilePath "powershell" -ArgumentList "$PSScriptRoot\$($MyInvocation.MyCommand.Name)","-ApacheVersion","`"$ApacheVersion`"","-ListeningPort","`"$ListeningPort`"" -Wait -Verb RunAs
}