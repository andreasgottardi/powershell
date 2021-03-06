function Get-UninstallCommands {
	param (
		[String]
		$ApplicationName,

		[String]
		$UninstallProperty
	)

	$UninstStrings = @("", "")

	$UninstString32 = (Get-ChildItem -Path "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall" | Get-ItemProperty | Where-Object { $_.DisplayName -match $ApplicationName } | Select-Object -ExpandProperty $UninstallProperty)
	$UninstString64 = (Get-ChildItem -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall" | Get-ItemProperty | Where-Object { $_.DisplayName -match $ApplicationName } | Select-Object -ExpandProperty $UninstallProperty)

	if( -not ([string]::IsNullOrEmpty($UninstString32))){
		$UninstStrings[0] = $UninstString32
	}

	if( -not ([string]::IsNullOrEmpty($UninstString64))){
		$UninstStrings[1] = $UninstString64
	}

	return $UninstStrings
}

function Get-UninstallCommandsUser {
	param (
		[String]
		$ApplicationName,

		[String]
		$UninstallProperty
	)

	return (Get-ChildItem -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall" | Get-ItemProperty | Where-Object { $_.DisplayName -match $ApplicationName } | Select-Object -ExpandProperty $UninstallProperty)
}

function Stop-Processes {
	param (
		[String[]]
		$ProcessNames
	)
	foreach ($process in $ProcessNames) {
		$p = Get-Process "$process" -ErrorAction SilentlyContinue
		if ($p) {
			"Process $p is running. Trying to stop it."
			$p | Stop-Process -Force
		}
		else {
			"Process $process is not running."
		}
	}
}

function Get-Uuid {
	param (
		[String]
		$SearchTerm
	)
	$var1 = Get-ChildItem -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall, HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall | Get-ItemProperty | Where-Object { $_.DisplayName -match "$SearchTerm" }
	$var2 = $var1.PSChildName
	return $var2
}