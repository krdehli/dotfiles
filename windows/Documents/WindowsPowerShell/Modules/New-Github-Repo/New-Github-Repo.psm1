function New-Github-Repo(
    [Parameter(Mandatory=$true)] [String] $Name,
	[String] $Token,
    [String] $Private = $true
) {
	if ((!$Token) -and ($Env:GITHUB_TOKEN)) {
		$Token = $Env:GITHUB_TOKEN
	} else {
		throw "Parameter `"Token`" was missing and the GITHUB_TOKEN environment variable was not set"
	}
    $data = @{name=$Name; private=$Private}
    $data | ConvertTo-Json -Compress | curl `
		-H 'Accept: application/vnd.github.v3+json' `
        -H 'Content-Type: application/json' `
        -H "Authorization: token ${Token}" `
        https://api.github.com/user/repos `
        -d '@-' 
}

Export-ModuleMember * -Alias *