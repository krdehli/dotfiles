function New-Github-Repo(
    [Parameter(Mandatory=$true)] [String] $Name,
    [Parameter(Mandatory=$true)] [String] $Username,
    [Parameter(Mandatory=$true)] [String] $Token,
    [String] $Private = $true
) {
    $data = @{name=$Name; private=$Private}
    $data | ConvertTo-Json -Compress | curl `
        -H 'Content-Type: application/json' `
        -u "${Username}:${Token}" `
        https://api.github.com/user/repos `
        -d '@-' 
}

Export-ModuleMember * -Alias *