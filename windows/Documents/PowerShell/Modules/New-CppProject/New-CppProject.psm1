function New-CppProject {
    [CmdLetBinding(
        PositionalBinding=$false,
        DefaultParameterSetName='Predefined')]
    param(
        [Parameter(Mandatory=$true, Position=0)] 
        [ValidatePattern('\S')]
        [String] $ProjectName,

        [Parameter(Position=1)]
        [String] $FriendlyName = $ProjectName,
        
        [ValidateNotNullOrEmpty()]
        [String] $Author = $Env:FULLNAME,

        [ValidatePattern('\d{4}')] 
        [String] $Year = (Get-Date).Year,

        [Parameter(ParameterSetName='Predefined')]
        [ValidateSet('Default', 'WxWidgets', 'Qt')]
        [String] $Type = 'Default',

        [Parameter(ParameterSetName='Custom')]
        [ValidateScript({Test-Path $_ -PathType Container})]
        [String] $Template
    )
    begin {}
    process {}
    end {
        $PredefinedTemplates = @{
            Default   = "$PSScriptRoot\CppProjectTemplate"
            WxWidgets = "$PSScriptRoot\wxWidgetsProjectTemplate"
            Qt        = "$PSScriptRoot\QtProjectTemplate"
        }

        if ($Type) {
            $Template = $PredefinedTemplates[$Type]
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
}

Export-ModuleMember * -Alias *