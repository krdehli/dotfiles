function New-Cpp-Project(
    [Parameter(Mandatory=$true)] [String] $Author, 
    [Parameter(Mandatory=$true)] [String] $ProjectName,
    [String] $Year = (Get-Date).Year,
    [String] $FriendlyName = $ProjectName, 
    [String] $Template = "$Env:HOME\CppProjectTemplate"
) {
    if($ProjectName -match '\s') {
        throw "Parameter `"ProjectName`" may not contain whitespace"
    }

    New-Item ".\" -ItemType 'directory' -Name "$ProjectName"
    copy "$Template\*" ".\$ProjectName" -Recurse

    Rename-Item ".\$ProjectName\src\{{PROJECT_NAME}}.cpp" "$ProjectName.cpp"

    (cat ".\$ProjectName\CMakeLists.txt")     -replace '{{PROJECT_NAME}}', "$ProjectName"                    | Set-Content ".\$ProjectName\CMakeLists.txt"
    (cat ".\$ProjectName\.vs\launch.vs.json") -replace '{{PROJECT_NAME}}', "$ProjectName"                    | Set-Content ".\$ProjectName\.vs\launch.vs.json"
    ((cat ".\$ProjectName\LICENSE")           -replace '{{AUTHOR}}', "$Author") -replace '{{YEAR}}', "$Year" | Set-Content ".\$ProjectName\LICENSE"
    (cat ".\$ProjectName\Readme.md")          -replace '{{PROJECT_FRIENDLY_NAME}}', "$FriendlyName"          | Set-Content ".\$ProjectName\Readme.md"

    Push-Location ".\$ProjectName"
    git init
    git add .
    git commit -m 'Initial commit'

    git checkout -b 'develop'
    git branch 'release'
    Pop-Location
}

Export-ModuleMember * -Alias *