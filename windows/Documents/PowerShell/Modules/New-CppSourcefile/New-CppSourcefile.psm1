function ToRelativePath([String] $RootPath, [String] $Path) {
    $Segments = @()

    $RootPath = (Join-Path $RootPath '')
    $Path = (Join-Path $Path '')

    if (-not ($Path.StartsWith($RootPath))) {
        throw "Internal Error"
    }

    while (-not ($Path -eq $RootPath)) {
        $Segments += (Split-Path -Leaf -Path $Path)
        $Path = (Join-Path (Split-Path -Parent -Path $Path) '')
    }
    [array]::Reverse($Segments)
    return (Join-Path @Segments)
}

function IncludeGuard([String] $TargetName, [String] $Namespace, [String] $Name) {
    $Guard = $TargetName.ToUpper();
    if ($Namespace -and (-not ($Namespace -eq ''))) {
        $Guard += ('_' + ($Namespace.ToUpper() -replace '::','_'))
    }
    $Guard += ('_' + $Name.ToUpper() + '_HPP')
    $Guard += ('_' + ((New-Guid).Guid.ToUpper() -replace '-','_'))
    return $Guard
}

function New-CppSourcefile {
    [CmdLetBinding()]
    param(
        [Parameter(Mandatory=$True, Position=0)]
        [ValidatePattern('^[a-zA-Z0-9_]+$')]
        [String] $Name,

        [ValidateScript({ Test-Path -Path $_ -PathType Container })]
        [Alias('Root','R')]
        [String] $RootDirectory,
        
        [ValidateScript({ Test-Path -Path $_ -PathType Container })]
        [Alias('Source','Src','S')]
        [String] $SourceDirectory,

        [ValidateScript({ Test-Path -Path $_ -PathType Container })]
        [Alias('H')]
        [String] $HeaderDirectory,

        [ValidatePattern('^[a-zA-Z0-9_]+$')]
        [Alias('T')]
        [String] $TargetName,

        [Switch] $HeaderOnly,

        [ValidateScript({ Test-Path -Path $_ -PathType Leaf })]
        [String] $CMakeLists,

        [ValidatePattern('^(?:[a-zA-Z][a-zA-Z0-9_]*)(?:\:\:[a-zA-Z][a-zA-Z0-9_]*)*$')]
        [Alias('N')]
        [String] $Namespace
    )

    if (-not $RootDirectory) {
        if (-not $CMakeLists) {
            $RootDirectory = (Convert-Path '.')
        }
        else {
            $RootDirectory = (Convert-Path (Split-Path -Path $CMakeLists -Parent))
        }
    }
    else {
        $RootDirectory = (Convert-Path $RootDirectory)
    }

    if (-not $CMakeLists) {
        $CMakeLists = (Join-Path -Path $RootDirectory -ChildPath 'CMakeLists.txt')
    }
    else {
        $CMakeLists = (Convert-Path $CMakeLists)
    }

    if (-not $SourceDirectory) {
        $SourceDirectory = (Convert-Path (Join-Path -Path $RootDirectory -ChildPath 'src'))
    }
    else {
        $SourceDirectory = (Convert-Path $SourceDirectory)
    }

    if (-not $HeaderDirectory) {
        $HeaderDirectory = $SourceDirectory
    }
    else {
        $HeaderDirectory = (Convert-Path $HeaderDirectory)
    }

    if (-not (Test-Path -Path $RootDirectory -PathType Container)) {
        throw "Could not find directory $RootDirectory"
    }
    if (-not (Test-Path -Path $CMakeLists -PathType Leaf)) {
        throw "Could not find $CMakeLists"
    }
    if (-not (Test-Path -Path $SourceDirectory -PathType Container)) {
        throw "Could not find directory $SourceDirectory"
    }
    if (-not (Test-Path -Path $HeaderDirectory -PathType Container)) {
        throw "Could not find directory $HeaderDirectory"
    }

    if (-not $TargetName) {
        $TargetName = (Get-Content -Raw -Path $CMakeLists | Select-String "(?:add_(?:(?:executable)|(?:library))\(\s*)([a-zA-Z0-9_]+)").Matches.Groups[1]
    }

    $SourceFileName = "${Name}.cpp"
    $HeaderFileName = "${Name}.hpp"
    $SourceFilePath = (Join-Path -Path $SourceDirectory -ChildPath $SourceFileName)
    $HeaderFilePath = (Join-Path -Path $HeaderDirectory -ChildPath $HeaderFileName)
    
    $RelativeSourceFilePath = (ToRelativePath (Split-Path $CMakeLists -Parent) $SourceFilePath)
    $RelativeHeaderFilePath = (ToRelativePath (Split-Path $CMakeLists -Parent) $HeaderFilePath)

    $IncludeGuard = IncludeGuard -TargetName $TargetName -Namespace $Namespace -Name $Name

    if (Test-Path $HeaderFilePath) {
        throw "Header file already exists"
    }
    if ((-not $HeaderOnly) -and (Test-Path $SourceFilePath)) {
        throw "Sourcefile already exists"
    }

    Add-Content -Path $HeaderFilePath -Value @(
        "#ifndef $IncludeGuard"
        "#define $IncludeGuard"
        ''
    )
    if ($Namespace -and (-not ($Namespace -eq ''))) {
        Add-Content -Path $HeaderFilePath -Value @(
            "namespace $Namespace {"
            ''
            '}'
            ''
        )
    }
    Add-Content -Path $HeaderFilePath -Value @('#endif'; '')

    if (-not $HeaderOnly) {
        Add-Content -Path $SourceFilePath -Value @("#include `"$(Split-Path $HeaderFilePath -Leaf)`""; '')
        if ($Namespace -and (-not ($Namespace -eq ''))) {
            Add-Content -Path $SourceFilePath -Value @(
                "namespace $Namespace {"
                ''
                '}'
                ''
            )
        }
    }

    $NewCMakeContent = @()
    $InsideAddTarget = $False
    $InsideAddSpecifiedTarget = $False
    Get-Content -Path $CMakeLists | ForEach-Object {
        $Line = $_
        if ($Line -match 'add_(?:(?:executable)|(?:library))') {
            $InsideAddTarget = $True
        }
        if ($InsideAddTarget -and ($Line -match $TargetName)) {
            $InsideAddSpecifiedTarget = $True
        }
        if ($InsideAddTarget -and ($Line -match '\)')) {
            if ($InsideAddSpecifiedTarget) {
                $Line = ($Line -replace '\)', '')
                $NewCMakeContent += ("`t" + ($RelativeHeaderFilePath -replace '\\','/'))
                if (-not $HeaderOnly) {
                    $NewCMakeContent += ("`t" + ($RelativeSourceFilePath -replace '\\','/'))
                }
                $NewCMakeContent += ')'
                $InsideAddSpecifiedTarget = $False
            }
            $InsideAddTarget = $False
        }
        $NewCMakeContent += $Line
    }
    Set-Content -Path $CMakeLists -Value $NewCMakeContent
}