<#
	.Synopsis
		Загружает данные сотрудников из .csv файла
	.Description
		Загружает данные сотрудников из .csv файла
#>
[CmdletBinding(
	ConfirmImpact = 'Low'
)]

param (
	# Полный путь к файлу, из которого будем импортировать.
	[Parameter(
		Position=0
	)]
	[string]
	$csvLocation = 'SkyDrive:\НЦСМ\Network\Users\users.csv'
)

Get-Content `
	-Path $csvLocation `
    -ReadCount 0 `
| ConvertFrom-Csv `
    -UseCulture `
| ? { $_.Surname } `
| % {
	$_.birthday = [System.DateTime]::Parse($_.birthday);
	$_;
} `
| Sort-Object `
	-Property sn, givenName, middleName `
;