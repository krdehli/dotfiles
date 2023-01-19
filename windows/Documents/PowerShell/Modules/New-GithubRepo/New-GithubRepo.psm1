function New-GithubRepo {
    [CmdLetBinding(PositionalBinding=$false)]
    param(
        [Parameter(Mandatory=$true, Position=0)]
        [ValidatePattern('\S', ErrorMessage='Name may not contain any whitespace')]
        [String] $Name,

	    [String] $Token = $Env:GITHUB_TOKEN,

        [Switch] $Public
    )
	if (!$Token) {
		throw "Token and/or %GITHUB_TOKEN% was missing"
	}
    $data = @{name=$Name; private="$(!$Public)"}
    $data | ConvertTo-Json -Compress | curl `
        -s -f -d '@-'`
		-H 'Accept: application/vnd.github+json' `
        -H 'X-GitHub-Api-Version: 2022-11-28' `
        -H 'Content-Type: application/json' `
        -H "Authorization: Bearer ${Token}" `
        https://api.github.com/user/repos `
        | ConvertFrom-Json | Write-Output

}