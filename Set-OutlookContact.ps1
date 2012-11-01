<#
    .Synopsis
        обновляет сервисы Яндекс.Почты для домена для наших пользователей
    .Description
        обновляет сервисы Яндекс.Почты для домена для наших пользователей
#> 
[CmdletBinding(
	ConfirmImpact = 'High',
    SupportsShouldProcess = $true
)]

param (
	# Данные сотрудника
    [Parameter(
        ValueFromPipeline=$true
    )]
	[ValidateNotNull()]
	$user
,
	# Полный путь к файлу, из которого будем импортировать.
    [string]
	$csvLocation = 'SkyDrive:\НЦСМ\Network\Users\users.csv'
,
    # Полный путь к файлу, из которого будем импортировать.
    [System.IO.FileInfo]
	$csvFile
,
    # Полный путь к файлу, логотипа (который будет использован в визитных картах)
    [string]
    $logoLocation
,
    # Полный путь к файлу, логотипа (который будет использован в визитных картах).
    [System.IO.FileInfo]
	$logoFile
,
    # Путь к файлу xml схемы разметки визитной карты
    [string]
    $EBCLayoutLocation
,
    # Полный путь к файлу xml схемы разметки визитной карты.
    [System.IO.FileInfo]
	$EBCLayoutFile
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
	Import-Module 'ITG.Outlook' -Prefix 'Outlook' -ErrorAction Stop;
	Import-Module 'ITG.SkyDrive' -ErrorAction Stop;

	if ( -not $csvFile ) { $csvFile = Get-Item $csvLocation; };
	if ( -not $outputCsvFile ) { $outputCsvFile = $csvFile; };
	if ( -not $logoLocation ) {
	    $logoLocation = ( join-path `
	        -path ( [system.IO.Path]::GetDirectoryName( $csvLocation ) ) `
	        -childPath 'logo.png' `
	    );
	};
	if ( -not $logoFile ) { $logoFile = Get-Item $logoLocation; };
	$logoFileName = $logoFile;
	if ( -not $EBCLayoutLocation ) {
	    $EBCLayoutLocation = ( join-path `
	        -path ( [system.IO.Path]::GetDirectoryName( $csvLocation ) ) `
	        -childPath 'card-template.xml' `
	    );
	};
	if ( -not $EBCLayoutFile ) { $EBCLayoutFile = Get-Item $EBCLayoutLocation; };

	$BusinessCardLayout = ( Get-Content -Path $EBCLayoutLocation );
	$NewContact = ( { & (get-command New-OutlookContact) -Force -PassThru } ).GetSteppablePipeline();
	$NewContact.Begin( $true );
}
process {
	$Contact = ( $NewContact.Process( $user ) )[0];

	$Contact.BusinessCardLayoutXml = $BusinessCardLayout;
    $Contact.AddBusinessCardLogoPicture( $logoFileName );
    $Contact.Save();

	$fileName = ( 
		$Contact.LastName, $Contact.FirstName, $Contact.MiddleName `
		| ? { $_ } 
	) -join ' ';
    Get-Item `
        -Path ( join-path `
            -path ( [system.IO.Path]::GetDirectoryName( $csvLocation ) ) `
            -childPath "photo\\$fileName.*" `
        ) `
        -ErrorAction SilentlyContinue `
    | Select-Object -First 1 `
    | % {
        $Contact.AddPicture( $_ );
    };
    $Contact.Save();

	$Contact.SaveBusinessCardImage( ( New-Item `
        -Path ( join-path `
            -path ( [system.IO.Path]::GetDirectoryName( $csvLocation ) ) `
            -childPath "EBCards\\$fileName.png" `
        ) `
        -ItemType File `
        -Force `
    ) );
	
	$Contact.Close( 0 );
	
	if ( $PassThru ) { return $user; };
}
end {
	$NewContact.End();
	#$c = Get-OutlookContact -LastName 'Бетке';
	#Set-Content `
	#	-Path $EBCLayoutLocation `
	#	-Value ( ( [xml]$c.BusinessCardLayoutXml ).OuterXml ) `
	#;
}