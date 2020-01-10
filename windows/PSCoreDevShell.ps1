param(
	[String] $DevCmdPath = "${Env:ProgramFiles(x86)}\Microsoft Visual Studio\2019\Enterprise\Common7\Tools\VsDevCmd.bat",
	[String] $DevCmdArgs = "-arch=x64 -host_arch=x64"
)

$DevCmdOut = (cmd /c "`"$DevCmdPath`" $DevCmdArgs && set")

foreach ($Line in $DevCmdOut) {
	$VarLine = (Select-String -Pattern '([^=].*?)=(.*)$' -InputObject $Line)
	if ($VarLine) {
		$Name = $VarLine.Matches.Groups[1]
		$Value = $VarLine.Matches.Groups[2]
		Set-Item -Path "Env:$Name" -Value $Value
	}
}

if (Test-Path -Path "Env:VSCMD_BANNER_SHEL_NAME_ALT") {
	Remove-Item -Path "Env:VSCMD_BANNER_SHEL_NAME_ALT"
}
if (Test-Path -Path "Env:VSCMD_SKIP_SENDTELEMETRY") {
	Remove-Item -Path "Env:VSCMD_SKIP_SENDTELEMETRY"
}
