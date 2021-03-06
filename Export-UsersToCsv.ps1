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
	$csvLocation = 'SkyDrive:\НЦСМ\Network\Users\users.csv'
,
	# Полный путь к файлу, в который будет осуществлена запись результата.
	[string]
	$outputCsvLocation = $csvLocation
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

# to-do: имеет смысл всё-таки использовать конвейер, но в том случае, если файл занят - использовать временный файл.
#	$ExportCsv = ( { Export-Csv `
#		-Path $outputCsvLocation `
#		-Encoding 'UTF8' `
#		-UseCulture `
#		-NoTypeInformation `
#	} ).GetSteppablePipeline( $myInvocation.CommandOrigin );
#	$ExportCsv.Begin( $PSCmdlet );
	$users = @();
}
process {
#	$ExportCsv.Process( $user );
	$users += $user;
	if ( $PassThru ) { return $user; };
}
end {
#	$ExportCsv.End();
	$users `
	| Sort-Object -Unique -Property sn, givenName, middleName `
	| % {
        if ( $_.birthday -is [System.DateTime] ) {
		    $_.birthday = $_.birthday.ToString('dd.MM.yyyy');
        };
		$_;
	} `
	| Export-Csv `
		-Path $outputCsvLocation `
		-Encoding 'UTF8' `
		-UseCulture `
		-NoTypeInformation `
	;
}