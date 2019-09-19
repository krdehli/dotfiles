# Sets the color scheme for the Powershell console according to the Base16 color scheme.
# The color names do no not describe their actual colors, but are arbitrary values that have persisted since the creation of 
# the Windows Console. Refer to the following table to see the actual meanings of the color names:
# 
#       Black <-> Default Background
#    DarkBlue <-> Lighter Background
#   DarkGreen <-> Selection Background
#    DarkCyan <-> Comments
#     DarkRed <-> Dark Foreground
# DarkMagenta <-> Defeault Foreground
#  DarkYellow <-> Light Foreground
#        Gray <-> Light Background
#    DarkGray <-> Variables
#        Blue <-> Integers
#       Green <-> Classes
#        Cyan <-> Strings
#         Red <-> Support
#     Magenta <-> Functions
#      Yellow <-> Keywords
#       White <-> Deprecated

$Host.UI.RawUI.BackgroundColor = 'Black'
$Host.UI.RawUI.ForegroundColor = 'DarkMagenta'

$Host.PrivateData.ErrorForegroundColor    = 'White'
$Host.PrivateData.ErrorBackgroundColor    = 'Black'
$Host.PrivateData.WarningForegroundColor  = 'Red'
$Host.PrivateData.WarningBackgroundColor  = 'Black'
$Host.PrivateData.DebugForegroundColor    = 'DarkMagenta'
$Host.PrivateData.DebugBackgroundColor    = 'Black'
$Host.PrivateData.VerboseForegroundColor  = 'DarkMagenta'
$Host.PrivateData.VerboseBackgroundColor  = 'Black'
$Host.PrivateData.ProgressForegroundColor = 'DarkMagenta'
$Host.PrivateData.ProgressBackgroundColor = 'DarkBlue'

# Sets the Powershell syntax highlighting to the Base16 scheme in the same manner as the section above
Set-PSReadLineOption -colors @{
  Command            = 'Magenta'
  Number             = 'Blue'
  Member             = 'DarkMagenta'
  Operator           = 'DarkMagenta'
  Type               = 'Green'
  Variable           = 'DarkGray'
  Parameter          = 'DarkMagenta'
  ContinuationPrompt = 'DarkRed'
  Default            = 'DarkMagenta'
  Emphasis           = 'DarkGray'
  Error	             = 'White'
  Selection          = 'DarkMagenta'
  Keyword            = 'Yellow'
  String             = 'Cyan'
  Comment            = 'DarkCyan'
}

# Changes the prompt format
function prompt {
	$ESC = [char]27
	return "$ESC[36m[$env:UserName@$env:ComputerName]$ESC[0m $ESC[96m$($executionContext.SessionState.Path.CurrentLocation)$ESC[0m$('>' * ($nestedPromptLevel + 1)) "
}

# Enables vcpkg autocompletion
Import-Module 'D:\vcpkg\scripts\posh-vcpkg'

# Sets the console codepage to be compatible with the PostreSQL command line tool
# chcp 1252 > $null