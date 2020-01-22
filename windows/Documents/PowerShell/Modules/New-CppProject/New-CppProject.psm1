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

        [ValidatePattern('\d{4}', ErrorMessage='Year must consist of for digits')] 
        [String] $Year = (Get-Date).Year,

        [Parameter(ParameterSetName='Predefined')]
        [ValidateSet('Default', 'WxWidgets', 'Qt')]
        [String] $Type = 'Default',

        [Parameter(ParameterSetName='Custom')]
        [ValidateScript({Test-Path "$_" -PathType Container}, ErrorMessage="{0} must exists and must be a directory")]
        [String] $Template,

        [Switch] $CreateRemote,

        [ValidatePattern('[\da-f]{40}', ErrorMessage='Invalid token format')]
	    [String] $GithubToken = $Env:GITHUB_TOKEN,

        [Switch] $PublicRepo
    )

    $PredefinedTemplates = @{
        Default   = "$PSScriptRoot\CppProjectTemplate"
        WxWidgets = "$PSScriptRoot\wxWidgetsProjectTemplate"
        Qt        = "$PSScriptRoot\QtProjectTemplate"
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
    copy "$Template\*" "$Path" -Recurse

    $Values = @{
        PROJECT_NAME=$(Split-Path $Path -Leaf)
        PROJECT_FRIENDLY_NAME=$FriendlyName
        AUTHOR=$Author
        YEAR=$Year
        INCLUDE_GUARD=($Path.ToUpper() + '_HPP')
    }
    $ValuesAsJson = ConvertTo-Json $Values -Compress

    gci "$Path\*" -Include '*{{*}}*' -Recurse | %{
        $Key = (Select-String -Pattern '.*\{\{(.*)\}\}.*' -InputObject $_.FullName).Matches.Groups[1]
        Rename-Item $_ ($_.FullName -replace "{{$Key}}", $Values["$Key"])
    }
    gci "$Path\*" -Include '*.mustache' -Recurse | % {
        Set-Content $_ ($ValuesAsJson | mustache - $_)
        Rename-Item $_ ($_.FullName -replace '\.mustache', '')
    }
    
    $CmakeTemplatePath = "$Env:HOMEDRIVE$Env:HOMEPATH\Documents\VisualStudio\CMakeSettingsTemplates\Standard.json"
    if (Test-Path "$CmakeTemplatePath" -PathType Leaf) {
        copy "$CmakeTemplatePath" "$Path\CMakeSettings.json" 
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