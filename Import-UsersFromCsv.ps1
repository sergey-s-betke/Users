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

Import-Csv `
	-Path $csvLocation `
    -Encoding UTF8 `
    -UseCulture `
| ? { $_.sn } `
| % {
	$_.birthday = [System.DateTime]::Parse($_.birthday);
	$_;
} `
| Sort-Object `
	-Property cn `
	-Unique `
;