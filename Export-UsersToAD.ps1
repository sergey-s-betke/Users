<#
	.Synopsis
		Создаёт объекты пользователей в AD / обновляет аттрибуты существующих объектов
	.Description
		Создаёт объекты пользователей в AD / обновляет аттрибуты существующих объектов
#>
[CmdletBinding(
	ConfirmImpact = 'High'
)]

param (
	# Данные сотрудника
	[Parameter(
		ValueFromPipeline=$true
	)]
	[ValidateNotNull()]
	$user
, 
	# Данные сотрудника
	[ValidateNotNullOrEmpty()]
	$UsersOU = 'CN=Users,DC=csm,DC=nov,DC=ru'
,
	[switch]
	$PassThru
)

begin {
    Import-Module `
        -Name ActiveDirectory `
        -ErrorAction Stop `
    ;
}
process {
    $ADUser = Get-ADUser `
        -Filter "userPrincipalName -eq '$( $user.userPrincipalName )'" `
    ;
    if ( $ADUser ) {
    } else {
        $user `
        | % {
            $_.AccountPassword = ConvertTo-SecureString `
                -String ( $_.AccountPassword ) `
                -AsPlainText `
                -Force `
            ;
            $_;
        } `
        | New-ADUser `
            -Enabled $true `
        ;
    };

    if ( $PassThru ) { return $_ };
}