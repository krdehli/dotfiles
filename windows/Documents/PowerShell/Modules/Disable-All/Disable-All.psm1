function Disable([Parameter(Mandatory=$true)] [String] $Path) {
    if (Test-Path $Path -PathType Leaf) {
        if ($Path -notlike '*.disabled') {
            Rename-Item $Path "$Path`.disabled"
        }
    } else {
        throw "$Path is not a file"
    }
}

function Enable([Parameter(Mandatory=$true)] [String] $Path) {
    if (Test-Path $Path -PathType Leaf) {
        if ($Path -like '*.disabled') {
            Rename-Item $Path ($Path -replace '\.disabled', '')
        }
    } else {
        throw "$Path is not a file"
    }
}

function Disable-All([String] $Path = '.') {
    dir $Path -File | ?{$_ -notlike '*.disabled'} | %{Rename-Item (Join-Path $Path $_) "$_`.disabled"}
}

function Enable-All([String] $Path = '.') {
    dir $Path -File | ?{$_ -like '*.disabled'}| %{Rename-Item (Join-Path $Path $_) ($_ -replace '\.disabled', '')}
}

Export-ModuleMember * -Alias *