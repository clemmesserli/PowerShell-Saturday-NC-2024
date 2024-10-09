<#
Music by Lindy Deneault (https://pixabay.com)
Image generated via https://chat.openai.com/
#>

# First load relevant function into memory using dot-sourcing
. .\functions\Enable-MKScreenLock.ps1

$audioPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath('data/audio/ambient-horror-05-247844.mp3')
$imagePath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath('data/images/hacker-02.jpg')

# Next, we'll use splatting and a simple hash table to set input parameters
$params = @{
	AudioPath      = $audioPath
	BlurRadius     = 15
	FontColor      = 'green'
	ImagePath      = $imagePath
	ImageOpacity   = 2
	Opacity        = 5
	MessageContent = "PowerShell Saturday: `nData Piracy to Data Privacy"
	Duration       = '00:02:30'
	AudioVolume    = 50
}
Enable-MKScreenLock @params