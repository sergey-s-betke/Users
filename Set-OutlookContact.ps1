<#
	.Synopsis
		Обновляет контакты в Outlook по данным наших пользователей
	.Description
		Обновляет контакты в Outlook по данным наших пользователей
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
	# Путь к каталогу, в котором расположены фотографии пользователей
	[string]
	$PhotoLocation = (
		Join-Path `
			-Path ( Split-Path -Path $csvLocation -Parent ) `
			-ChildPath 'photo' `
	)
,
	# Путь к файлу xml схемы разметки визитной карты
	[string]
	$EBCLayoutLocation = (
		Join-Path `
			-Path ( Split-Path -Path $csvLocation -Parent ) `
			-ChildPath 'card-template.xml' `
	)
,
	# Путь к каталогу, в котором будут сохранены визитные карты
	[string]
	$EBCsLocation = (
		Join-Path `
			-Path ( Split-Path -Path $csvLocation -Parent ) `
			-ChildPath 'EBCards' `
	)
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
	Import-Module 'ITG.Outlook' -Prefix 'Outlook' -ErrorAction Stop;

	$LogoFile = Get-Item -Path $logoLocation;
	$BusinessCardLayout = ( Get-Content -Path $EBCLayoutLocation );
	$NewContact = ( {
		New-OutlookContact `
			-Force `
			-PassThru `
		| % {
			$Contact = $_;

			$Contact.BusinessCardLayoutXml = $BusinessCardLayout;
			$Contact.AddBusinessCardLogoPicture( $LogoFile.FullName );
			$Contact.Save();

			$fileName = (
				$Contact.LastName, $Contact.FirstName, $Contact.MiddleName `
				| ? { $_ }
			) -join ' ';
			Get-Item `
				-Path ( Join-Path `
					-Path $PhotoLocation `
					-ChildPath "$fileName.*" `
				) `
				-ErrorAction SilentlyContinue `
			| Select-Object -First 1 `
			| % {
				$Contact.AddPicture( $_ );
			};
			$Contact.Save();

			$Contact.SaveBusinessCardImage( ( New-Item `
				-Path ( join-path `
					-path $EBCsLocation `
					-childPath "$fileName.png" `
				) `
				-ItemType File `
				-Force `
			) );
			
			$Contact.Close( 0 );
		} `
	} ).GetSteppablePipeline( $myInvocation.CommandOrigin );
	$NewContact.Begin( $PSCmdlet );
}
process {
	$NewContact.Process( $user );
	if ( $PassThru ) { return $user; };
}
end {
	$NewContact.End();
}