<#
	.Synopsis
		Загружает дни рожднеия сотрудников из .csv файла
#>
[CmdletBinding(
	ConfirmImpact = 'Low'
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
	# Полный путь к файлу, из которого будем импортировать дни рождения.
	[string]
	$csvBirthdaysLocation = (
		Join-Path `
			-Path ( Split-Path -Path $csvLocation -Parent ) `
			-ChildPath 'birthdays.csv' `
	)
)

begin {
	$BirthDays = (
		get-content `
			-Path $csvBirthdaysLocation `
		| convertFrom-csv `
			-UseCulture `
	);
}
process {
	$user = $_;
	$userExtraData = $BirthDays | ? { $_.cn -eq $user.cn };
	if ( $userExtraData ) {
		Add-Member `
			-InputObject $user `
			-MemberType NoteProperty `
			-Name 'birthday' `
			-Value ($userExtraData.birthday) `
			-ErrorAction SilentlyContinue `
		;
		$user.birthday = [datetime]::Parse( $userExtraData.birthday );
		$user.title =  $userExtraData.title;
	};
	$user;
};