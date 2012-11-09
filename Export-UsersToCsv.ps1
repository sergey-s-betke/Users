<#
    .Synopsis
        Выгружает данные сотрудников в .csv файл
    .Description
        Выгружает данные сотрудников в .csv файл
#> 
[CmdletBinding(
	ConfirmImpact = 'Medium'
    , SupportsShouldProcess = $true
)]

param (
    # Полный путь к файлу, из которого будем импортировать.
    [string]
#   $csvLocation = $env:itg_Users
	$csvLocation = 'SkyDrive:\НЦСМ\Network\Users\users.csv'
,
    # Полный путь к файлу, из которого будем импортировать.
    [System.IO.FileInfo]
	$csvFile
,
    # Полный путь к файлу, в который будет осуществлена запись результата.
    [System.IO.FileInfo]
    $outputCsvFile
,
	# Данные сотрудника
    [Parameter(
        ValueFromPipeline=$true
    )]
	[ValidateNotNull()]
	$user
,
	[switch]
	$PassThru
) 

begin {
	Import-Module `
	    (join-path `
	        -path ( ( [System.IO.FileInfo] ( $myinvocation.mycommand.path ) ).directory ) `
	        -childPath 'ITG.PrepareModulesEnv.ps1' `
	    ) `
	;
	Import-Module 'ITG.SkyDrive' -ErrorAction Stop;

# to-do: имеет смысл всё-таки использовать конвейер, но в том случае, если файл занят - использовать временный файл.
#	if ( -not $csvFile ) { $csvFile = Get-Item $csvLocation; };
#	if ( -not $outputCsvFile ) { $outputCsvFile = $csvFile; };
#	$ExportCsv = ( { & (get-command Export-Csv) `
#		-Path $outputCsvFile `
#		-Encoding 'UTF8' `
#		-UseCulture `
#		-NoTypeInformation `
#	} ).GetSteppablePipeline();
#	$ExportCsv.Begin( $true );
	$users = @();
}
process {
#	$ExportCsv.Process( $user );
	$users += $user;
	if ( $PassThru ) { return $user; };
}
end {
#	$ExportCsv.End();
	if ( -not $csvFile ) { $csvFile = Get-Item $csvLocation; };
	if ( -not $outputCsvFile ) { $outputCsvFile = $csvFile; };
	$users `
	| Sort-Object -Unique -Property sn, givenName, middleName `
	| Export-Csv `
		-Path $outputCsvFile `
		-Encoding 'UTF8' `
		-UseCulture `
		-NoTypeInformation `
	;
}