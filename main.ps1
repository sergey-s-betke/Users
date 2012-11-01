<#
    .Synopsis
        Комплексная обработка данных сотрудников 
    .Description
        Комплексная обработка данных сотрудников
#> 
[CmdletBinding(
	ConfirmImpact = 'Medium',
    SupportsShouldProcess = $true
)]

param (
    # Полный путь к файлу, из которого будем импортировать.
    [Parameter(
        Position=0
    )]
    [string]
#   $csvLocation = $env:itg_Users
	$csvLocation = 'SkyDrive:\НЦСМ\Network\Users\users.csv'
,
    # Полный путь к файлу, из которого будем импортировать.
    [System.IO.FileInfo]
	$csvFile
) 

$dir = ( [System.IO.FileInfo] ( $myinvocation.mycommand.path ) ).directory;

. (join-path $dir 'Import-UsersFromCsv.ps1' ) @PSBoundParameters `
| . (join-path $dir 'Set-UsersProperties.ps1' ) @PSBoundParameters `
| . (join-path $dir 'Export-UsersToCsv.ps1' ) @PSBoundParameters -PassThru `
| . (join-path $dir 'Set-YandexServices.ps1' ) @PSBoundParameters -PassThru `
| . (join-path $dir 'Set-OutlookContact.ps1' ) @PSBoundParameters -PassThru `
| . (join-path $dir 'Set-SkypeAccount.ps1' ) @PSBoundParameters -PassThru `
| Out-GridView `
;