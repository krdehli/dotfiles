function New-GithubRepo {
    [CmdLetBinding(PositionalBinding=$false)]
    param(
        [Parameter(Mandatory=$true, Position=0)]
        [ValidatePattern('\S', ErrorMessage='Name may not contain any whitespace')]
        [String] $Name,

        [ValidatePattern('[\da-f]{40}', ErrorMessage='Invalid token format')]
	    [String] $Token = $Env:GITHUB_TOKEN,

        [Switch] $Public
    )
	if (!$Token -or !($Token -match '[\da-f]{40}')) {
		throw "Token and or %GITHUB_TOKEN% was missing or invalid"
	}
    $data = @{name=$Name; private=$(!$Public)}
    $data | ConvertTo-Json -Compress | curl `
        -s -f -d '@-'`
		-H 'Accept: application/vnd.github.v3+json' `
        -H 'Content-Type: application/json' `
        -H "Authorization: token ${Token}" `
        https://api.github.com/user/repos `
        | ConvertFrom-Json | Write-Output

}