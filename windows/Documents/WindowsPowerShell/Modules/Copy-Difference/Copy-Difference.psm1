function Copy-Difference(
    [Parameter(Mandatory=$true)] [String] $Parent,
    [Parameter(Mandatory=$true)] [String] $Child,
    [String] $Destination = '.\diff\'
) {
    copy $Child (Join-Path $Destination $Child) -Filter {PSIsContainer} -Recurse -Force
    $ParentFiles = (dir $Parent -Recurse | ?{ ! $_.PSIsContainer })
    $ChildFiles = (dir $Child -Recurse | ?{ ! $_.PSIsContainer })
    $Difference = (compare $ParentFiles $ChildFiles -Property Name | ?{ $_.SideIndicator -eq '=>'}) | select -ExpandProperty Name
    $Paths = (($ChildFiles | ?{ $_.Name -In $Difference }) | select -ExpandProperty FullName)
    foreach ($Path in $Paths) {
        $RelativePath = (Resolve-Path $Path -Relative)
        copy $Path (Join-Path $Destination $RelativePath) -Force
    }
    
    do {
        $Dirs = (dir $Destination -Directory -Recurse | ?{ (dir $_.FullName).Count -eq 0 } | select -ExpandProperty FullName) 
        $Dirs | %{ erase $_ }
    } while ($Dirs.Count -Gt 0)
}

Export-ModuleMember * -Alias *
