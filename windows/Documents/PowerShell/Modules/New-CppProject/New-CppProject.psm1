function ToSnakeCase([String] $Str) {
    $Result = $Str.ToLower() -replace '-', '_' -replace '[^a-z0-9_]', ''
    if ($Result -match '^[^a-z_]') {
        $Result = 'n' + $Result
    }
    return $Result
}

function ToKebabCase([String] $Str) {
    $Result = $Str.ToLower() -replace '_', '-' -replace '[^a-z0-9\-]', ''
    if ($Result -match '^[^a-z\-]') {
        $Result = 'n' + $Result
    }
    return $Result
}

function ToPascalCase([String] $Str) {
    $Result = ToSnakeCase($Str)
    $Result = [regex]::replace($Result, '(?:^|_)(.)', { $args[0].Groups[1].Value.ToUpper() })
    return $Result
}

function ToValidDirectoryName([String] $Str) {
    return $Str -replace '[<>:"/\\|?*]', ''
}

function ToValidPythonIdentifier([String] $Str) {
    $Result = $Str -creplace '[^a-zA-Z0-9_]', ''
    if ($Result -match '^[^a-z_]') {
        $Result = 'n' + $Result
    }
    return $Result
}

function ToValidVcpkgPackageName([String] $Str) {
    $Result = $Str -creplace '[^a-z0-9\-]', ''
    $Result = $Result.Trim('-')
    return $Result
}

function New-CppProject {
    [CmdLetBinding(
        PositionalBinding=$false,
        DefaultParameterSetName='Predefined'
    )]
    param(
        [Parameter(Mandatory=$true, Position=0)] 
        [ValidatePattern('\S', ErrorMessage='Path may not contain any whitespace')]
        [ValidateScript({!$(Test-Path "$_" -PathType Any)}, ErrorMessage="A file or folder with the name '{0}' already exists")]
        [String] $Path,

        [Parameter(Position=1)]
        [String] $FriendlyName = $(Split-Path $Path -Leaf),
        
        [ValidateScript({($_ -ne "") -and ($_ -ne $null)})]
        [String] $Author = $Env:FULLNAME,

        [ValidatePattern('\d{4}', ErrorMessage='Year must consist of four digits')] 
        [String] $Year = (Get-Date).Year,

        [Parameter(ParameterSetName='Predefined')]
        [ValidateSet('Default', 'HeaderOnlyLibrary', 'WxWidgets', 'Qt')]
        [String] $Type = 'Default',

        [Parameter(ParameterSetName='Custom')]
        [ValidateScript({Test-Path "$_" -PathType Container}, ErrorMessage="{0} must exists and must be a directory")]
        [String] $Template,

        [Switch] $CreateRemote,

	    [String] $GithubToken = $Env:GITHUB_TOKEN,

        [Switch] $PublicRepo
    )

    $PredefinedTemplates = @{
        Default           = "$PSScriptRoot\CppProjectTemplate"
        HeaderOnlyLibrary = "$PSScriptRoot\CppHeaderOnlyLibraryTemplate"
        WxWidgets         = "$PSScriptRoot\wxWidgetsProjectTemplate"
        Qt                = "$PSScriptRoot\QtProjectTemplate"
    }

    if ($Type) {
        $Template = $PredefinedTemplates[$Type]
    }

    if (!$Author) {
        throw 'Author and/or %FULLNAME% is not defined'
    }
    if (! $(Test-Path "$Template" -PathType Container)) {
        throw "Ivalid path: $Template. Template must exists and must be a directory"
    }


    New-Item ".\" -ItemType 'directory' -Name "$Path" | Out-Null
    Copy-Item "$Template\*" "$Path" -Recurse

    $Values = @{
        PROJECT_NAME=$(Split-Path $Path -Leaf)
        PROJECT_FRIENDLY_NAME=$FriendlyName
        AUTHOR=$Author
        YEAR=$Year
        INCLUDE_GUARD=($Path.ToUpper() + '_' + ((New-Guid).Guid.ToUpper() -replace '-','_') + '_HPP')
    }
    $Values['PROJECT_NAME_SNAKE_CASE'] = ToSnakeCase($Values['PROJECT_NAME'])
    $Values['PROJECT_NAME_CAPITAL_SNAKE_CASE'] = $Values['PROJECT_NAME_SNAKE_CASE'].ToUpper()
    $Values['PROJECT_NAME_PASCAL_CASE'] = ToPascalCase($Values['PROJECT_NAME'])
    $Values['PROJECT_NAME_KEBAB_CASE'] = ToKebabCase($Values['PROJECT_NAME'])
    $Values['PROJECT_NAME_CAPTIAL_KEBAB_CASE'] = $Values['PROJECT_NAME_KEBAB_CASE'].ToUpper()
    $Values['CONAN_CLASS_NAME'] = ToValidPythonIdentifier($Values['PROJECT_NAME_PASCAL_CASE'])
    $Values['VCPKG_PACKAGE_NAME'] = ToValidVcpkgPackageName($Values['PROJECT_NAME_KEBAB_CASE'])

    $ValuesAsJson = ConvertTo-Json $Values -Compress

    Get-ChildItem "$Path\*" -Include '*{{*}}*' -Recurse | ForEach-Object {
        $Key = (Select-String -Pattern '.*\{\{(.*)\}\}.*' -InputObject $_.FullName).Matches.Groups[1]
        Rename-Item $_ ($_.FullName -replace "{{$Key}}", $Values["$Key"])
    }
    Get-ChildItem "$Path\*" -Include '*.mustache' -Recurse | ForEach-Object {
        Set-Content $_ ($ValuesAsJson | mustache - $_)
        Rename-Item $_ ($_.FullName -replace '\.mustache', '')
    }
    
    $CmakeTemplatePath = "$Env:HOMEDRIVE$Env:HOMEPATH\Documents\VisualStudio\CMakeSettingsTemplates\Standard.json"
    if (Test-Path "$CmakeTemplatePath" -PathType Leaf) {
        Copy-Item "$CmakeTemplatePath" "$Path\CMakeSettings.json" 
    }

    Push-Location "$Path"
    git init -q                       | Out-Null
    git add .                         | Out-Null
    git commit -q -m 'Initial commit' | Out-Null

    git checkout -q -b 'develop'      | Out-Null
    git branch -q 'release'           | Out-Null

    if ($CreateRemote) {
        try {
            New-GithubRepo $(Split-Path $Path -Leaf) -Token $GithubToken -Public:$PublicRepo -OutVariable result | Out-Null
            git remote add origin $result.html_url | Out-Null
            git push -q --set-upstream origin 'develop' | Out-Null
        } catch {
            Write-Error "Something went wrong when creating the remote repository:`r`n $_"
        }
    }

    Pop-Location
}