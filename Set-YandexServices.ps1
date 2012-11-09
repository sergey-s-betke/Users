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
	Import-Module 'ITG.Yandex.PDD' -Prefix 'Yandex' -ErrorAction Stop;
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
	$NewMailbox = ( { & (get-command New-YandexMailbox) `
		-DomainName 'csm.nov.ru' `
		-Force `
	} ).GetSteppablePipeline();
	$NewMailbox.Begin( $true );
	$NewMailListAll = ( { & (get-command New-YandexMailList) `
		-DomainName 'csm.nov.ru' `
		-MailList 'all' `
		-Force `
	} ).GetSteppablePipeline();
	$NewMailListAll.Begin( $true );
	$users = @();
}
process {
	$users += $user;
	if ( 'Бетке', 'Гущин' -notcontains $user.sn ) {
		$NewMailbox.Process( $user );
	};
	$NewMailListAll.Process( $user );
	if ( $PassThru ) { return $user; };
}
end {
	$NewMailbox.End();
	$NewMailListAll.End();
	
	# to-do предварительно нужно создать группу рассылки mail
	Set-YandexDefaultEmail -DomainName 'csm.nov.ru' -LName 'mail';

	$users `
	| ? { 'Бетке', 'Гущин' -contains $_.sn } `
	| New-YandexMailList -DomainName 'csm.nov.ru' -MailList 'master' -Force `
	;

	'master' `
	| New-YandexMailList -DomainName 'csm.nov.ru' -MailList 'hostmaster' -Force -PassThru `
	| New-YandexMailList -DomainName 'csm.nov.ru' -MailList 'postmaster' -Force -PassThru `
	| New-YandexMailList -DomainName 'csm.nov.ru' -MailList 'noc' -Force -PassThru `
	| New-YandexMailList -DomainName 'csm.nov.ru' -MailList 'abuse' -Force -PassThru `
	| New-YandexMailList -DomainName 'csm.nov.ru' -MailList 'webmaster' -Force -PassThru `
	| New-YandexMailList -DomainName 'csm.nov.ru' -MailList 'www' -Force -PassThru `
	| New-YandexMailList -DomainName 'csm.nov.ru' -MailList 'ftp' -Force -PassThru `
	| Out-Null `
	;

	'master' `
	| New-YandexMailList -DomainName 'csm.nov.ru' -MailList 'novline' -Force -PassThru `
	| New-YandexMailList -DomainName 'csm.nov.ru' -MailList 'mts' -Force -PassThru `
	| Out-Null `
	;
	
#	$users `
#	| ConvertTo-YandexContact `
#	| Out-GridView `
#	;

}