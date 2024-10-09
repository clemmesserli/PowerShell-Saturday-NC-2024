<#
In poker, when you fold, you discard your cards face down to help ensure no one else can see
what you had and whether or not you might have trying to bluff or should have stayed in the game.
Using PowerShell we can take this even further by shredding or deletings files using multiple passes so
that typical file recovery methods cannot be used to piece the data back together again.
#>

# First load relevant function into memory using dot-sourcing
. .\functions\Remove-MKFile.ps1

$fileName = 'data/docs/ShredMe.txt'
$multilineText = @'
-----BEGIN CERTIFICATE-----
MIIDJzCCAg+gAwIBAgIQcfgvoQdsaoBNzSS1IpP9PjANBgkqhkiG9w0BAQsFADAY
MRYwFAYDVQQDDA1NeUxhYklzc3VlckNBMB4XDTI0MTAwMjAzNTU0OVoXDTI1MTAw
MjA0MDU0OVowHTEbMBkGA1UEAwwSTXlMYWJEb2NFbmNyeXB0aW9uMIIBIjANBgkq
hkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAtxfzVsnQQtVdBHLRZmas5B9HLkyZzYoU
ZhgttCfHqFoR0KWpNRoWY7JmTYs5vFC83p7SNt83WFhFuXJwaSgJ5QDmslLxD7r7
DSa8dD9BRZaSYjreq+ZYda5YzG/91mmLzfBjkZ75jjjBdERur7bZH7tYkx6zK4Tb
kboE7XzCCzMNOyRgUUFswuyhFft8m2GjfORKIP2UuRm10tCAMc8e7tqDoU9XMWZf
/oZa3NLdvjuudEB4lq9Y3WE133Od88OZS75hDJrZZoyn+j7pNfWeLYt6Oxgw2qtb
XlIJqVQ3TcrVL4zAQiF6rSSGuptCnCW9Gnw7Mq4Si978lS0sg2weMQIDAQABo2gw
ZjAOBgNVHQ8BAf8EBAMCA7gwFAYDVR0lBA0wCwYJKwYBBAGCN1ABMB8GA1UdIwQY
MBaAFCiS+CujtoWAW+GcNzdL4haQiXxzMB0GA1UdDgQWBBS+MRkbaYLwndfa131R
AgQq7ACPUzANBgkqhkiG9w0BAQsFAAOCAQEALtvJpTGANHcSozWhkY0xcQkLABVN
9lZjhJKZeBFMN5/W1gRxRZpOc3/Q29xO8PcEqHDI35aADGgsAdgdLg/E7K1Hg7mh
o65eLIRH/NypkD6DeFp/YD5OyBwYtX7NgIXdJ+j5FjmXro6bn6nbRdzBkb8A8TTV
H2MZ9QbC8LWKpE7yysZDiEYZzT4A33RghR32CMB9J96I5JibG+X54CyXCpuYO5WV
5vLQk+gzAMPVQbAd+9Qz/n7HNsCLsSXmcjD/U6dSobRdavSKLC0uKjCn9L0CYR+e
HNK3r6geZDZaS1TvLrgEjIfCMtf/JICJE7K7kEZ7e+h3K31ZyLdozPMbxg==
-----END CERTIFICATE-----
'@
$multilineText | Set-Content $fileName -Force

Get-ChildItem (Split-Path $fileName) -File

Clear-Host

Remove-MKFile -Path $fileName -Passes 1 -WhatIF

Remove-MKFile -Path $fileName -Passes 5 -Verbose

Get-ChildItem (Split-Path $fileName) -File