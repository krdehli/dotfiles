function New-Cpp-Project(
    [String] $Author, 
    [Parameter(Mandatory=$true)] [String] $ProjectName,
    [String] $Year = (Get-Date).Year,
    [String] $FriendlyName = $ProjectName, 
    [String] $Template = "$PSScriptRoot\CppProjectTemplate"
) {
	if ((! $Author) -and ($Env:FULLNAME)) {
		$Author = $Env:FULLNAME
	} elseif (! $Author) {
		throw "Parameter `"Author`" was missing and the FULLNAME environment variable was not set"
	}
    if($ProjectName -match '\s') {
        throw "Parameter `"ProjectName`" may not contain whitespace"
    }

    New-Item ".\" -ItemType 'directory' -Name "$ProjectName"
    copy "$Template\*" ".\$ProjectName" -Recurse

    $Values = @{
        PROJECT_NAME=$ProjectName
        PROJECT_FRIENDLY_NAME=$FriendlyName
        AUTHOR=$Author
        YEAR=$Year
        INCLUDE_GUARD=($ProjectName.ToUpper() + '_HPP')
    }
    $ValuesAsJson = ConvertTo-Json $Values -Compress

    gci "$ProjectName\*" -Include '*{{*}}*' -Recurse | %{
        $Key = (Select-String -Pattern '.*\{\{(.*)\}\}.*' -InputObject $_.FullName).Matches.Groups[1]
        Rename-Item $_ ($_.FullName -replace "{{$Key}}", $Values["$Key"])
    }
    gci "$ProjectName\*" -Include '*.mustache' -Recurse | % {
        Set-Content $_ ($ValuesAsJson | mustache - $_)
        Rename-Item $_ ($_.FullName -replace '\.mustache', '')
    }
    
    Push-Location ".\$ProjectName"
    git init
    git add .
    git commit -m 'Initial commit'

    git checkout -b 'develop'
    git branch 'release'
    Pop-Location
}

function New-Qt-Project(
    [String] $Author, 
    [Parameter(Mandatory=$true)] [String] $ProjectName,
    [String] $Year = (Get-Date).Year,
    [String] $FriendlyName = $ProjectName
) {
    New-Cpp-Project `
        -Author $Author `
        -ProjectName $ProjectName `
        -Year $Year `
        -FriendlyName $FriendlyName `
        -Template "$PSScriptRoot\QtProjectTemplate"
}

function New-wxWidgets-Project(
    [String] $Author, 
    [Parameter(Mandatory=$true)] [String] $ProjectName,
    [String] $Year = (Get-Date).Year,
    [String] $FriendlyName = $ProjectName
) {
     New-Cpp-Project `
        -Author $Author `
        -ProjectName $ProjectName `
        -Year $Year `
        -FriendlyName $FriendlyName `
        -Template "$PSScriptRoot\wxWidgetsProjectTemplate"
}

Export-ModuleMember * -Alias *