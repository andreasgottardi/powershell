function Convert-ArrayToString {
	param (
		# Array of strings
		[Parameter(Mandatory=$true)]
		[String[]]
		$StringArray
	)
	$String = ""
	for ($i = 0; $i -lt $StringArray.Count - 1; $i++) {
		$Element = $StringArray[$i]
		$String += "$Element,"
	}
	$String += $StringArray[$i]
	return $String
}

$name = Read-Host -Prompt 'Please provide URL to eclipse zip file'

# Set to default URL if no URL is specified by user.
if ([string]::IsNullOrWhiteSpace($name)) {
    $name = 'http://mirrors.uniri.hr/eclipse/eclipse/downloads/drops4/R-4.13-201909161045/eclipse-platform-4.13-win32-x86_64.zip'
}

$pa = "$env:ProgramData\InstSys\eclipse"

# Clean up first
if ( -not (Test-Path "$pa")) { New-Item -Path "$pa" -ItemType Directory }
if (Test-Path "$pa\Eclipse") { Remove-Item -Recurse "$pa\Eclipse" }
if (Test-Path "$pa\Eclipse.zip") { Remove-Item -Recurse "$pa\Eclipse.zip" }
if (Test-Path "$pa\Eclipse.tmp") { Remove-Item -Recurse "$pa\Eclipse.tmp" }
if (Test-Path "$pa\WorkSpace") { Remove-Item -Recurse "$pa\WorkSpace" }

# Download Eclipse
Start-BitsTransfer -Source $name -Destination "$pa\Eclipse.zip"
Expand-Archive -Path "$pa\Eclipse.zip" -Destination "$pa\Eclipse.tmp"
Move-Item "$pa\Eclipse.tmp\eclipse" "$pa\Eclipse"
Remove-Item "$pa\Eclipse.zip"
Remove-Item "$pa\Eclipse.tmp" -Recurse

$FeatureList = @(
	"org.eclipse.epp.mpc.feature.group",
	"org.jkiss.dbeaver.ide.feature.feature.group",
	"org.jkiss.dbeaver.debug.feature.feature.group",
	"org.jkiss.dbeaver.git.feature.feature.group",
	"org.jkiss.dbeaver.ext.office.feature.feature.group",
	"org.jkiss.dbeaver.net.sshj.feature.feature.group",
	"org.jkiss.dbeaver.ext.ui.svg.feature.feature.group"
)

$Repos = @(
	"http://download.eclipse.org/releases/2019-09",
	"http://download.eclipse.org/eclipse/updates/4.13",
	"http://download.eclipse.org/usssdk/updates/release/latest",
	"https://dbeaver.io/update/latest/",
	"https://dbeaver.io/update/office/latest/",
	"https://dbeaver.io/update/git/latest/"
)

$ReposString = Convert-ArrayToString -StringArray $Repos

# Start and wait for user to finish modifications
New-Item -ItemType Directory -Path "$pa\WorkSpace"
$i = 1
$Plc = $FeatureList.Count

foreach($Feature in $FeatureList){
	
	Write-Host -Object "Installing plugin ${i} of ${Plc}: ${Feature}"

	Start-Process `
		-FilePath "$pa\Eclipse\eclipse.exe" `
		-Wait `
		-ArgumentList `
			"-application","org.eclipse.equinox.p2.director",`
			"-repository","$ReposString",`
			"-installIU","$Feature"
	$i++;
}

# Configure Workspace
$path = "$pa\WorkSpace\.metadata\.plugins\org.eclipse.core.runtime\.settings"

If (-Not (Test-Path -Path "$path")) {
	New-Item -ItemType Directory -Path "$path"
}

$file = "org.eclipse.e4.ui.workbench.renderers.swt.prefs"
Set-Content -Path "$path\$file" -Value "eclipse.preferences.version=1"
Add-Content -Path "$path\$file" -Value "enableMRU=true"
Add-Content -Path "$path\$file" -Value "themeEnabled=false"

$file = "org.eclipse.core.runtime.prefs"
Set-Content -Path "$path\$file" -Value "eclipse.preferences.version=1"
Add-Content -Path "$path\$file" -Value "line.separator=`\n"

$file = "org.eclipse.core.resources.prefs"
Set-Content -Path "$path\$file" -Value "eclipse.preferences.version=1"
Add-Content -Path "$path\$file" -Value "encoding=UTF-8"
Add-Content -Path "$path\$file" -Value "version=1"

$file = "org.eclipse.ui.ide.prefs"
Set-Content -Path "$path\$file" -Value "EXIT_PROMPT_ON_CLOSE_LAST_WINDOW=false"

$file = "org.eclipse.ui.prefs"
Set-Content -Path "$path\$file" -Value "eclipse.preferences.version=1"
Add-Content -Path "$path\$file" -Value "showIntro=false"

# Start eclipse for further customization
Start-Process -FilePath "$pa\Eclipse\eclipse.exe" -ArgumentList "-data","$pa\WorkSpace" -Wait