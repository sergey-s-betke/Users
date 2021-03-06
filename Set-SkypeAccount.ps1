<#
	.Synopsis
		Создаёт учётные записи skype для сотрудников через skype manager
	.Description
		Создаёт учётные записи skype для сотрудников через skype manager
#>
[CmdletBinding(
	ConfirmImpact = 'High'
	, SupportsShouldProcess = $true
)]

param (
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
		(Join-Path `
			-Path ( Split-Path -Path ( $myinvocation.mycommand.path ) -Parent ) `
			-ChildPath 'ITG.PrepareModulesEnv.ps1' `
		) `
	;
	Import-Module 'ITG.WinAPI.User32';
	Import-Module 'ITG.WinAPI.UrlMon';
	# Import-Module 'ITG.Skype' -ErrorAction Stop;
	
	$skypeCsvFileName = [System.IO.FileInfo]"$([System.IO.Path]::GetTempFileName()).csv";
	Write-Verbose "Создаём временный .csv файл с данными, подготовленными для загрузки в skype manager - $skypeCsvFileName."
	$ExportCsv = ( {
		Export-Csv `
			-Path $skypeCsvFileName `
			-Encoding 'UTF8' `
			-UseCulture `
			-NoTypeInformation `
	} ).GetSteppablePipeline( $myInvocation.CommandOrigin );
	$ExportCsv.Begin( $PSCmdlet );
#	$users = @();
}
process {
	$ExportCsv.Process( ( Select-Object `
		-InputObject $user `
		-Property `
			givenName `
			, sn `
			, mail `
			, @{ name='skype'; expression = {
				$_.mail -replace '@', '.'
			} } `
			, password `
	) );
#	$users += $user;
	if ( $PassThru ) { return $user; };
}
end {
	$ExportCsv.End();
	try {
		$skypeManagerURL = 'https://manager.skype.com/members/add/business-account?splash=no';
#		$skypePassportURL = 'https://secure.skype.com/login';
		Write-Verbose 'Создаём экземпляр InternetExplorer.';
		$ie = New-Object -Comobject InternetExplorer.application;
		Write-Verbose "Отправляем InternetExplorer manager.skype.com.";
		$ie.Navigate( $skypeManagerURL );
		$ie.Visible = $True;
		
		$ie `
		| Set-WindowZOrder -ZOrder ( [ITG.WinAPI.User32.HWND]::Top ) -PassThru `
		| Set-WindowForeground -PassThru `
		| Out-Null
		;

		Write-Verbose 'Проверяем и ждём при необходимости, пока администратор авторизуется в skype manager';
		while ( `
			$ie.Busy `
			-or (-not ([System.Uri]$ie.LocationURL).IsBaseOf( $skypeManagerURL ) ) `
		) { Sleep -milliseconds 100; };
		$form = ( $ie.Document.forms | ? { $_.name -eq 'addBusinessMembersForm' } );
		$token = ( $form.getElementsByTagName('input') | where {$_.name -eq 'session_token'} ).value;
		$CsvPostURL = "https://manager.skype.com/members/add/business-account/upload-csv?_target=fieldsHidden&session_token=$token";
		$Params = @{
			'upload' = 1;
			'members_file' = $skypeCsvFileName;
			'session_token' = $token;
		}
		
		$wreq = [System.Net.WebRequest]::Create( $CsvPostURL );
		$wreq.Method = [System.Net.WebRequestMethods+HTTP]::Post;
		$boundary = "##params-boundary##";
		$wreq.ContentType = "multipart/form-data; boundary=$boundary";
		$reqStream = $wreq.GetRequestStream();
		$writer = New-Object System.IO.StreamWriter( $reqStream );
		$writer.AutoFlush = $true;
		
		foreach( $param in $Params.keys ) {
			if ( $Params.$param -is [System.IO.FileInfo] ) {
				$writer.Write( @"
--$boundary
Content-Disposition: form-data; name="$param"; filename="$($Params.$param.Name)"
Content-Type: $(Get-MIME ($Params.$param))
Content-Transfer-Encoding: binary


"@
				);
				$fs = New-Object System.IO.FileStream (
					$Params.$param.FullName,
					[System.IO.FileMode]::Open,
					[System.IO.FileAccess]::Read,
					[system.IO.FileShare]::Read
				);
				try {
					$fs.CopyTo( $reqStream );
				} finally {
					$fs.Close();
					$fs.Dispose();
				};
				$writer.WriteLine();
			} else {
				$writer.Write( @"
--$boundary
Content-Disposition: form-data; name="$param"

$($Params.$param)

"@
				);
			};
		};
		$writer.Write( @"
--$boundary--

"@ );
		$writer.Close();
		$reqStream.Close();

		$wres = $wreq.GetResponse();
		$resStream = $wres.GetResponseStream();
		$reader = New-Object System.IO.StreamReader ( $resStream );
		$responseFromServer = [string]( $reader.ReadToEnd() );

		$reader.Close();
		$resStream.Close();
		$wres.Close();				

		$responseFromServer;

#		multipart/form-data post!
		#'https://manager.skype.com/members/add/business-account/upload-csv?_target=fieldsHidden&session_token=2b07c16ef8630d9155d7aa02ab5c9d0434fb191f'
#		( $ie.Document.getElementById('inviteBusinessCSV') ).value = $skypeCsvFileName;
#		( $form.getElementsByTagName('input') | where {$_.type -eq 'file'} ).value = $skypeCsvFileName;
#		( $form.getElementsByTagName('button') | where {$_.type -eq 'submit'} ).click();
#PS C:\Users\Sergey.S.Betke\Documents> $form.getElementsByTagName('input') | Select-Object name, type, value
#
#name   												type												   value												
#----   												----												   -----												
#upload 												hidden  											   1													
#members_file   										file																										
#session_token  										hidden  											   2b07c16ef8630d9155d7aa02ab5c9d0434fb191f 			

#		$ie.Visible = $False;
#
#		$res = ( [xml]$ie.document.documentElement.innerhtml );
#		Write-Debug "Ответ API get_token: $($ie.document.documentElement.innerhtml).";
#		if ( $res.ok ) {
#			$token = [System.String]$res.ok.token;
#			Write-Verbose "Получили токен для домена $($DomainName): $token.";
#			return $token;
#		} else {
#			$errMsg = $res.error.reason;
#			Write-Error `
#				-Message "Ответ API get_token для домена $DomainName отрицательный." `
#				-Category PermissionDenied `
#				-CategoryReason $errMsg `
#				-CategoryActivity 'Yandex.API.get_token' `
#				-CategoryTargetName $DomainName `
#				-RecommendedAction 'Проверьте правильность указания домена и Ваши права на домен.' `
#			;
#		};
	} finally {
#		Write-Verbose 'Уничтожаем экземпляр InternetExplorer.';
#		$ie.Quit(); 
#		$res = [System.Runtime.InteropServices.Marshal]::ReleaseComObject( $ie );
	};
}