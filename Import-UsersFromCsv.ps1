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
#   $csvLocation = $env:itg_Users
	$csvLocation = 'SkyDrive:\НЦСМ\Network\Users\users.csv'
,
    # Полный путь к файлу, из которого будем импортировать.
    [System.IO.FileInfo]
	$csvFile
) 

Import-Module `
    (join-path `
        -path ( ( [System.IO.FileInfo] ( $myinvocation.mycommand.path ) ).directory ) `
        -childPath 'ITG.PrepareModulesEnv.ps1' `
    ) `
;
Import-Module 'ITG.SkyDrive' -ErrorAction Stop;

if ( -not $csvFile ) { $csvFile = Get-Item $csvLocation; };

get-content `
    -Path $csvFile `
| convertFrom-csv `
	-UseCulture `
| ? { $_.sn } `
;