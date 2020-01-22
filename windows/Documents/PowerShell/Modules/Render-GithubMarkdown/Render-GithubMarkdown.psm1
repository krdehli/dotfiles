function Render-Github-Markdown 
{
	[CmdletBinding()]
	Param(
		[Parameter(
			Mandatory=$true,
			ValueFromPipeline=$true,
			ParameterSetName='Piped')] 
		$Data,
		[Parameter(
			Mandatory=$true,
			ValueFromPipeline=$false,
			ParameterSetName='Filename')] 
		[String] $Filename,
		[String] $Token
	)

	Begin{
		if ((!$Token) -and ($Env:GITHUB_TOKEN)) {
			$Token = $Env:GITHUB_TOKEN
		} else {
			throw "Parameter `"Token`" was missing and the GITHUB_TOKEN environment variable was not set"
		}
		
		if ($PSCmdlet.ParameterSetName -eq 'Filename') {
			$Data = ((Get-Content ${Filename} -Raw) -join "`r`n")
		} else {
			if ($Data.GetType().FullName -eq 'System.Object[]') {
				$Data = $Data -join "`r`n"
			}
		}
	}
	
	Process{
		@{text=$Data} | ConvertTo-Json | curl -X POST `
			-H 'Accept: application/vnd.github.v3+json' `
			-H 'Content-Type: application/json' `
			-H "Authorization: token ${Token}" `
			https://api.github.com/markdown `
			-d '@-' `
			-o-
	}
	End{}
}

Export-ModuleMember Render-Github-Markdown