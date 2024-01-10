function IncludeGuard( [String] $Name, [String] $TargetName = $null, [String] $Namespace = $null) {
    $Guard = ($Name.ToUpper() + '_HPP_'+ ((New-Guid).Guid.ToUpper() -replace '-','_'))
    
    if ($Namespace -and (-not ($Namespace -eq ''))) {
        $Guard = (($Namespace.ToUpper() -replace '::','_') + '_' + $Guard)
    }
    if($TargetName -and (-not ($TargetName -eq ''))) {
        $Guard = ($TargetName.ToUpper() + '_' + $Guard);
    }
    return $Guard
}

function New-CppSourcefile {
    [CmdLetBinding()]
    param(
        [Parameter(Mandatory=$True, Position=0)]
        [ValidatePattern('^[a-zA-Z0-9_]+$')]
        [String] $Name,
        
        [Parameter(Mandatory=$True, ParameterSetName='SourceAndHeader')]
        [Parameter(Mandatory=$True, ParameterSetName='SourceOnly')]
        [ValidateScript({ Test-Path -Path $_ -PathType Container })]
        [Alias('Source','Src','S')]
        [String] $SourceDirectory,

        [Parameter(Mandatory=$True, ParameterSetName='SourceAndHeader')]
        [Parameter(Mandatory=$True, ParameterSetName='HeaderOnly')]
        [ValidateScript({ Test-Path -Path $_ -PathType Container })]
        [Alias('H')]
        [String] $HeaderDirectory,

        [Parameter(Mandatory=$True, ParameterSetName='HeaderOnly')]
        [Switch] $HeaderOnly,

        [Parameter(Mandatory=$True, ParameterSetName='SourceOnly')]
        [Switch] $SourceOnly,

        [ValidatePattern('^(?:[a-zA-Z][a-zA-Z0-9_]*)(?:\:\:[a-zA-Z][a-zA-Z0-9_]*)*$')]
        [Alias('N')]
        [String] $Namespace,

        [ValidatePattern('^[a-zA-Z0-9_]+$')]
        [Alias('T')]
        [String] $TargetName
    )

    if (-not $HeaderDirectory) {
        $HeaderDirectory = $SourceDirectory
    }
    else {
        $HeaderDirectory = (Convert-Path $HeaderDirectory)
    }

    if (-not (Test-Path -Path $SourceDirectory -PathType Container)) {
        throw "Could not find directory $SourceDirectory"
    }
    if (-not (Test-Path -Path $HeaderDirectory -PathType Container)) {
        throw "Could not find directory $HeaderDirectory"
    }

    $SourceFileName = "${Name}.cpp"
    $HeaderFileName = "${Name}.hpp"
    $SourceFilePath = (Join-Path -Path $SourceDirectory -ChildPath $SourceFileName)
    $HeaderFilePath = (Join-Path -Path $HeaderDirectory -ChildPath $HeaderFileName)

    $IncludeGuard = IncludeGuard -Name $Name -TargetName $TargetName -Namespace $Namespace

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
}