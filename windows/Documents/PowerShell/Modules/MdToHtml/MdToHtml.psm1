function MdToHtml {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
        [String[]] $InputObject,

        [Alias('F')]
        [switch] $InputFromFiles,

        [Alias('O')]
        [switch] $OutputToFiles
    )

    begin {
        [String] $Pattern = '```(.+)\s+((?:.|\n|\r)*?)```'
        [String] $Skeleton = gc "$PSScriptRoot\skeleton.html.mustache" -Raw
        [int] $FileIndex = 0;
    }

    process {
        [String] $Markdown = if ($InputFromFiles) {gc $InputObject -Raw} else {$InputObject}

        [int] $CodeIndex = 0
        [String[]] $CodeArray = @()

        $CodeMatches = (Select-String -InputObject $Markdown -Pattern $Pattern).Matches
        while ($CodeMatches.Success) {
            $Match = $CodeMatches[0]

            $Lang = $Match.Groups[1].Value -replace "`r",''
            $CodeArray += $Match.Groups[2].Value | pygmentize -l $Lang -f html | Out-String
            $InputObject = $Markdown.remove($Match.Groups[0].Index, $Match.Groups[0].Length).insert($Match.Groups[0].Index, "<!-- code_highlight_${CodeIndex} -->")
            $CodeIndex += 1;

            $CodeMatches = (Select-String -InputObject $Markdown -Pattern $Pattern).Matches
        }
    
        $Html = ($Markdown | cmark --unsafe | Out-String)
        for ($i = 0; $i -lt $CodeArray.Length; $i += 1) {
            $Html = $Html -replace "<!-- code_highlight_${i} -->", $CodeArray[$i]
        }
        #[String]$Json = @{MARKDOWN=$Html} | ConvertTo-Json | Out-String
        $OutString = $Skeleton -replace '{{{MARKDOWN}}}',$Html
        if ($OutputToFiles) {
            $OutFile = if ($InputFromFiles) { Split-Path $InputObject -LeafBase } else { "out$FileIndex" }
            Set-Content -Path "$OutFile.html" -Value $OutString
            $FileIndex += 1
        } else {
            Write-Output $OutString
        }
    }

    end {
        sass "$PSScriptRoot\markdown.scss" "markdown.css"
    }
}