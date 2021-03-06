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
	$logoLocation = (
		Join-Path `
			-Path ( Split-Path -Path $csvLocation -Parent ) `
			-ChildPath 'logo.png' `
	)
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
	Import-Module 'ITG.Yandex.PDD' -Prefix 'Yandex' -ErrorAction Stop -Force;
	
	New-YandexMailList -DomainName 'csm.nov.ru' -MailList 'mail';
	New-YandexMailList -DomainName 'csm.nov.ru' -MailList 'master' -Force;
	New-YandexMailList -DomainName 'csm.nov.ru' -MailList 'legal' -Force;
	New-YandexMailList -DomainName 'csm.nov.ru' -MailList 'priem' -Force;
	New-YandexMailList -DomainName 'csm.nov.ru' -MailList 'Borovichi.priem' -Force;
	New-YandexMailList -DomainName 'csm.nov.ru' -MailList 'StRussa.priem' -Force;
	New-YandexMailList -DomainName 'csm.nov.ru' -MailList 'buh' -Force;
	New-YandexMailList -DomainName 'csm.nov.ru' -MailList 'gost' -Force;
	
	'priem' | New-YandexMailList -DomainName 'csm.nov.ru' -MailList '9141' -Force;
	'borovichi.priem' | New-YandexMailList -DomainName 'csm.nov.ru' -MailList '9091' -Force;
	'strussa.priem' | New-YandexMailList -DomainName 'csm.nov.ru' -MailList '9081' -Force;
	'gost' | New-YandexMailList -DomainName 'csm.nov.ru' -MailList '9147' -Force;
	'buh' | New-YandexMailList -DomainName 'csm.nov.ru' -MailList '9151' -Force;

	'mail' | New-YandexMailList -DomainName 'csm.nov.ru' -MailList 'fax';

	$ProcessUser = ( {
		% {
			$_ `
			| ? { 'Бетке', 'Гущин' -notcontains $_.sn } `
			| New-YandexMailbox `
				-DomainName 'csm.nov.ru' `
				-Force `
			;
			$_;
		} `
		| New-YandexMailList `
			-DomainName 'csm.nov.ru' `
			-MailList 'all' `
			-PassThru `
		| % {
			$_ `
			| ? { 'Бетке', 'Гущин' -contains $_.sn } `
			| New-YandexMailListMember -DomainName 'csm.nov.ru' -MailList 'master' `
			;
			$_;
		} `
		| % {
			$_ `
			| ? { 'Бабкова', 'Бетке' -contains $_.sn } `
			| New-YandexMailListMember -DomainName 'csm.nov.ru' -MailList 'legal' `
			;
			$_;
		} `
		| % {
			$_ `
			| ? { $_.department -eq 'Бюро приёмки СИ' } `
			| New-YandexMailListMember -DomainName 'csm.nov.ru' -MailList 'priem' `
			;
			$_;
		} `
		| % {
			$_ `
			| ? { 'Пашинин' -contains $_.sn } `
			| New-YandexMailListMember -DomainName 'csm.nov.ru' -MailList 'Borovichi.priem' `
			;
			$_;
		} `
		| % {
			$_ `
			| ? { 'Рябова' -contains $_.sn } `
			| New-YandexMailListMember -DomainName 'csm.nov.ru' -MailList 'StRussa.priem' `
			;
			$_;
		} `
		| % {
			$_ `
			| ? { $_.department -eq 'бухгалтерия' } `
			| New-YandexMailListMember -DomainName 'csm.nov.ru' -MailList 'buh' `
			;
			$_;
		} `
		| % {
			$_ `
			| ? { $_.department -eq 'Отдел стандартизации' } `
			| New-YandexMailListMember -DomainName 'csm.nov.ru' -MailList 'gost' `
			;
			$_;
		} `
		| ConvertTo-YandexContact `
		| Export-Csv `
			-Path $csvYandexContactsLocation `
			-Encoding 'UTF8' `
			-UseCulture `
			-NoTypeInformation `
			-Force `
	} ).GetSteppablePipeline( $myInvocation.CommandOrigin );
	$ProcessUser.Begin( $PSCmdlet );
}
process {
	$ProcessUser.Process( $user );
	if ( $PassThru ) { return $user; };
}
end {
	$ProcessUser.End();
	
	# to-do предварительно нужно создать группу рассылки mail
	Set-YandexDefaultEmail -DomainName 'csm.nov.ru' -LName 'mail';

	'master' `
	| New-YandexMailList -DomainName 'csm.nov.ru' -MailList 'hostmaster' -Force -PassThru `
	| New-YandexMailList -DomainName 'csm.nov.ru' -MailList 'noc' -Force -PassThru `
	| New-YandexMailList -DomainName 'csm.nov.ru' -MailList 'webmaster' -Force -PassThru `
	| New-YandexMailList -DomainName 'csm.nov.ru' -MailList 'www' -Force -PassThru `
	| New-YandexMailList -DomainName 'csm.nov.ru' -MailList 'ftp' -Force -PassThru `
	| New-YandexMailList -DomainName 'csm.nov.ru' -MailList 'novline' -Force -PassThru `
	| New-YandexMailList -DomainName 'csm.nov.ru' -MailList 'mts' -Force -PassThru `
	| New-YandexMailList -DomainName 'csm.nov.ru' -MailList '1c' -Force -PassThru `
	| Out-Null `
	;
}