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
	$csvLocation = 'SkyDrive:\НЦСМ\Network\Users\users.csv'
)

Import-Module `
	(Join-Path `
		-Path ( Split-Path -Path ( $myinvocation.mycommand.path ) -Parent ) `
		-ChildPath 'ITG.PrepareModulesEnv.ps1' `
	) `
;
Import-Module 'ITG.SkyDrive' -ErrorAction Stop;

$dir = ( Split-Path -Path ( $myinvocation.mycommand.path ) -Parent );

& (join-path $dir 'Import-UsersFromCsv.ps1' ) @PSBoundParameters `
| & (join-path $dir 'Set-UsersProperties.ps1' ) @PSBoundParameters `
| & (join-path $dir 'Set-UsersBirthdays.ps1' ) @PSBoundParameters `
| & (join-path $dir 'Export-UsersToCsv.ps1' ) @PSBoundParameters -PassThru `
| & (join-path $dir 'Set-YandexServices.ps1' ) @PSBoundParameters -PassThru `
| & (join-path $dir 'Set-OutlookContact.ps1' ) @PSBoundParameters -PassThru `
| Out-GridView `

#| & (join-path $dir 'Set-SkypeAccount.ps1' ) @PSBoundParameters -PassThru `
;