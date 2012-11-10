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
	# Полный путь к файлу, логотипа (который будет использован в визитных картах)
	[string]
	$logoLocation = ( & {
		Join-Path `
			-Path ( Split-Path -Path $csvLocation -Parent ) `
			-ChildPath 'logo.png' `
		;
	} )
,
	# Полный путь к csv файлу, в который будут выгружены контакты для Яндекса
	[string]
	$csvYandexContactsLocation = ( & {
		Join-Path `
			-Path ( Split-Path -Path $csvLocation -Parent ) `
			-ChildPath 'yaContacts.csv' `
		;
	} )
,
	[switch]
	$PassThru
)

begin {
	Import-Module `
		(Join-Path `
			-Path ( Split-Path -Path ( $myinvocation.mycommand.path ) -Parent ) `
			-ChildPath 'ITG.PrepareModulesEnv.ps1' `
		) `
	;
	Import-Module 'ITG.Yandex.PDD' -Prefix 'Yandex' -ErrorAction Stop;

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
	
	$users `
	| ConvertTo-YandexContact `
	| Export-Csv `
		-Path $csvYandexContactsLocation `
		-Encoding 'UTF8' `
		-UseCulture `
		-NoTypeInformation `
		-Force `
	;
}