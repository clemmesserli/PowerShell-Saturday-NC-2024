#Requires -RunAsAdministrator

<#
In poker, a marked deck allows one player to secretly know the value of the cards while everyone else believes
they are playing with a fair deck as the markings are subtle enough that no one notices.

Similarly in steganography, a text message or entire data file can be concealed within an image or audio file in
such a way that the everything looks completely normal to the untrained eye.
#>

# First load relevant function into memory using dot-sourcing
. .\functions\Protect-MKFile.ps1
. .\functions\UnProtect-MKFile.ps1
. .\functions\Hide-MKPixel.ps1
. .\functions\Show-MKPixel.ps1

# Import the Demo PFX certificate into the CurrentUser Personal store
$pfxPath = 'data/certs/MyLabDocEncryption.pfx'
$pfxPassword = Read-Host -Prompt 'Enter PFX Password' -AsSecureString
Import-PfxCertificate -FilePath $pfxPath -CertStoreLocation Cert:\CurrentUser\My -Password $pfxPassword

# Find the thumbprint of the imported certificate:
$cert = Get-ChildItem Cert:\CurrentUser\My |
	Where-Object { $_.Subject -like '*CN=MyLabDocEncryption*' } | Select-Object -First 1

# Encrypt all files ending "*.txt" within specified directory using (AES256 + GCM)
# then adds base64 encoding before deleting the original input file.
$folderPath = 'data/icod'
Get-ChildItem (Join-Path -Path $folderPath -ChildPath '*.txt') |
	Protect-MKFile -Base64 -Certificate $cert -DeleteOriginal

Get-Content (Join-Path -Path $folderPath -ChildPath 'passwords.enc')

# Now that we have each file encrypted, we're going to create a zip archive which itself is also
# password protected but will make for easier transport using 7Zip4Powershell module

# Check if the module is installed
$moduleName = '7Zip4Powershell'
if (Get-Module -ListAvailable -Name $moduleName) {
	Write-Host "$moduleName is installed. Proceeding with the script..."
} else {
	Write-Host "$moduleName is not installed. Please install the module to proceed."
	Install-Module $moduleName -Scope AllUsers -Force -ErrorAction Stop
	Import-Module $moduleName -ErrorAction Stop
}

## First create a traditional zip archive as Compress-Archive does not offer a -Password option
$zipFile = (Join-Path -Path $folderPath -ChildPath 'icod.zip')
$7zFile = (Join-Path -Path $folderPath -ChildPath 'icod.7z')

Get-ChildItem $folderPath\*.enc |
	Compress-7Zip -ArchiveFileName $zipFile -Format Zip -Password $pfxPassword

## Next we'll repeat but this time save as SevenZip format
Get-ChildItem $folderPath\*.enc |
	Compress-7Zip -ArchiveFileName $7zFile -Format SevenZip -Password $pfxPassword -EncryptFilenames

# To see the list of files within the encrypted archive
Get-7Zip -ArchiveFileName $zipFile | Select-Object FileName, Size -First 5
Get-7Zip -ArchiveFileName $7zFile | Select-Object FileName, Size -First 5
Get-7Zip -ArchiveFileName $7zFile -Password $pfxPassword |
	Select-Object FileName, Size -First 5

# Let's now read this password protected archive containing our encrypted files and try to hide inside an image
$fileBytes = [System.IO.File]::ReadAllBytes((Get-ChildItem $7zFile))
# Printing just the first few bytes to give you an idea of what the output looks like at this stage
$fileBytes[0..10]

# Convert the byte array to a Base64 Encoded string
$base64String = [Convert]::ToBase64String($fileBytes)
$base64String

# Using this to avoid hard-coding path and using relative paths
$CoverFile = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath('data/images/screenshot-1.jpg')
$StegoFile = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath('data/images/stego-1.jpg')
$param = @{
	Message        = $base64String
	CoverFile      = $CoverFile
	StegoFile      = $StegoFile
	ColorChannel   = 'RGB'
	BitsPerChannel = 2
}
Hide-MKPixel @param

Start-Process $CoverFile
Start-Process $StegoFile

Compare-Object -ReferenceObject (Get-FileHash $CoverFile).Hash -DifferenceObject (Get-FileHash $StegoFile).Hash

# We'll once again print just the first few bytes to validate
$stegoFileBytes = [Convert]::FromBase64String($(Show-MKPixel -StegoFile $StegoFile -cc 'RGB' -bpc 2))
$stegoFileBytes[0..10]

# Write the byte array back to archive file
$stegoZip = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath('data/icod/stego-icod.7z')
[System.IO.File]::WriteAllBytes($stegoZip, $stegoFileBytes)

# Let's quickly verify the archive itself seems ok
Get-7Zip -ArchiveFileName $stegoZip  -Password $pfxPassword |
	Select-Object FileName, Size -First 5

# Now we simply extract the encrypted files
$stegoFolder = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath('data/icod/7zip')
Expand-7Zip -ArchiveFileName $stegoZip -TargetPath $stegoFolder -Password $pfxPassword

# Finally, let's decrypt the files and make sure our data is still intact
# Note: Always make sure the param options match those that were used during encryption
Get-ChildItem "$stegoFolder\*.enc" | Unprotect-MKFile -Certificate $cert

# The same parameter inputs must be used during decryption that match the encryption
Get-ChildItem "$stegoFolder\*.enc" | Unprotect-MKFile -Certificate $cert -Base64 -DeleteOriginal

Get-Content "$folderPath\passwords.enc"

Get-Content "$stegoFolder\passwords.txt"