function Remove-MKFile {
	<#
    .SYNOPSIS
    Securely deletes a file by overwriting it multiple times with random data before deletion.

    .DESCRIPTION
    The Remove-MKFile function performs secure file deletion by overwriting the file contents
    with random data for a specified number of passes before finally deleting the file.
    It randomizes the file's last access and last write times between passes, ensuring each new
    timestamp is within the last 14 days and never older than the previous timestamp.

    .PARAMETER Path
    The full path to the file that needs to be securely deleted.

    .PARAMETER Passes
    The number of overwrite passes to perform. Default is 5.

    .EXAMPLE
    Remove-MKFile -Path "C:\SecretDocuments\topsecret.txt"

    This example securely deletes the file "topsecret.txt" using the default 5 passes.

    .EXAMPLE
    Get-ChildItem "data/docs" -File | ForEach-Object { Remove-MKFile -Path $_.FullName -WhatIf }

    This example demonstrates how to use Remove-MKFile with pipeline input and the -WhatIf parameter
    to see what would happen without actually modifying or deleting the files.
    #>

	[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
	param (
		[Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
		[string]$Path,

		[Parameter(Mandatory = $false)]
		[int]$Passes = 5
	)

	process {
		if (-not (Test-Path $Path)) {
			Write-Error "File not found: $Path"
			return
		}

		$file = Get-Item $Path
		$size = $file.Length

		if ($PSCmdlet.ShouldProcess($file.FullName, 'Securely delete file')) {
			$buffer = New-Object byte[] $size
			$rng = New-Object System.Security.Cryptography.RNGCryptoServiceProvider
			$previousDate = $file.LastWriteTime

			for ($pass = 1; $pass -le $Passes; $pass++) {
				try {
					# Fill buffer with random data
					$rng.GetBytes($buffer)

					# Overwrite file with random data
					[System.IO.File]::WriteAllBytes($file.FullName, $buffer)

					# Flush to disk and release the file handle
					[System.IO.File]::OpenWrite($file.FullName).Close()

					# Generate a random date within the last 14 days, but not older than the previous date
					$randomDate = Get-RandomDate -PreviousDate $previousDate
					$previousDate = $randomDate

					# Attempt to set the new random date
					Set-ItemProperty -Path $file.FullName -Name LastAccessTime -Value $randomDate -ErrorAction SilentlyContinue
					Set-ItemProperty -Path $file.FullName -Name LastWriteTime -Value $randomDate -ErrorAction SilentlyContinue

					# Verify the changes
					if (Test-Path $file.FullName) {
						$updatedFile = Get-Item $file.FullName
						$content = [System.IO.File]::ReadAllBytes($updatedFile.FullName)
						$hash = Get-FileHash -InputStream ([System.IO.MemoryStream]::new($content)) -Algorithm SHA256
						Write-Verbose "Pass $pass hash: $($hash.Hash) TimeStamp $($updatedFile.LastWriteTime)"
					} else {
						Write-Verbose "Pass $pass completed, but file no longer exists"
					}
				} catch {
					Write-Error "Error during pass $pass - $_"
					return
				}
			}

			# Delete the file
			try {
				Remove-Item $file.FullName -Force -ErrorAction Stop
				Write-Verbose "File securely deleted: $($file.FullName)"
			} catch {
				Write-Error "Failed to delete file: $_"
			}
		} else {
			Write-Verbose "WhatIf: Would securely delete file: $($file.FullName)"
		}
	}
}

function Get-RandomDate {
	param (
		[DateTime]$PreviousDate
	)

	$now = Get-Date
	$fourteenDaysAgo = $now.AddDays(-14)

	# Ensure the lower bound is not earlier than 14 days ago or the previous date
	$lowerBound = if ($PreviousDate -gt $fourteenDaysAgo) { $PreviousDate } else { $fourteenDaysAgo }

	# Calculate the maximum number of seconds between the lower bound and now
	$maxSeconds = ($now - $lowerBound).TotalSeconds

	# Generate a random number of seconds
	$randomSeconds = Get-Random -Minimum 0 -Maximum $maxSeconds

	# Return the new random date
	return $lowerBound.AddSeconds($randomSeconds)
}