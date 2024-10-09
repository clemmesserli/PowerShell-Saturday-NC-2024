<#
In poker, if the deck isn't shuffled regularly players could predict the cards and gain an unfair advantage.
When it comes to protecting our data using PowerShell, there are a number of Password Managers or downloadable tools
that will do this but here's a slight twist as this will read back the NATO alphabet:
#>

# First load relevant function into memory using dot-sourcing
. .\functions\New-MKPassword.ps1
. .\functions\Get-MKPhonetic.ps1

# This sample will generate 10 unique passwords of varying lengths (24-32 chars)
# as it is good not only to rotate your passwords but to also vary the length to make it
# more difficult for attackers to use what are called 'Rainbow Tables' when trying to hack their values
(1..10) | ForEach-Object {
	$mkPassword = New-MKPassword

	$ht = @{
		Password = $mkPassword
		Length   = $mkPassword.length
	}
	$ht
}

# This will generate one customized string and read the NATO audio equivalent
New-MKPassword -PwdLength 8 -SymCount 1 -NumCount 1 -UCCount 2 -LCCount 4 |
	Get-MKPhonetic -Output Audio -VoiceName David -VoiceRate 3 -VoiceVolume 75 -Verbose

# This is another variation in which the resulting string is output
# with the corresponding NATO pronunciation keys in json
New-MKPassword -PwdLength 8 -SymCount 1 -NumCount 1 -UCCount 2 -LCCount 4 |
	Get-MKPhonetic -Output Json