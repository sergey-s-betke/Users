<#
	.Synopsis
		Добавляет необходимые атрибуты к данным сотрудников
	.Description
		Добавляет необходимые атрибуты к данным сотрудников
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
)

begin {
	Import-Module `
		(Join-Path `
			-Path ( Split-Path -Path ( $myinvocation.mycommand.path ) -Parent ) `
			-ChildPath 'ITG.PrepareModulesEnv.ps1' `
		) `
	;
	Import-Module 'ITG.Translit' -ErrorAction Stop;

	function Add-Attribute {
		[CmdletBinding(
			ConfirmImpact = 'Low',
			SupportsShouldProcess = $true
		)]
		param (
			[Parameter(
				Mandatory=$true,
				Position=0,
				ValueFromPipeline=$false,
				ValueFromPipelineByPropertyName=$false
			)]
			[string]
			$Name,
			[Parameter(
				Mandatory=$false,
				Position=1,
				ValueFromPipeline=$false,
				ValueFromPipelineByPropertyName=$false
			)]
			[scriptBlock]
			$Value = {$null},
			[Parameter(
				Mandatory=$true,
				Position=2,
				ValueFromPipeline=$true
			)]
			[PSObject]
			$InputObject,
			[switch]
			$Force
		)
		
		process {
			$rValue = ( $InputObject | % { & $Value } );
			if ( $Force ) {
				if ( -not ( $InputObject.$Name -eq $rValue ) ) {
					Write-Verbose "Принудительно перезаписываем атрибут $Name объекта $($InputObject.cn) значением $rValue.";
					Add-Member `
						-InputObject $InputObject `
						-MemberType noteProperty `
						-Name $Name `
						-Value $rValue `
						-Force `
					;
				};
			} else {
				if ( -not ($InputObject | Get-Member -Name $Name) ) {
					Write-Verbose "Устанавливаем атрибут $Name объекта $($InputObject.cn) значением $rValue (атрибута объект не имел).";
					Add-Member `
						-InputObject $InputObject `
						-MemberType noteProperty `
						-Name $Name `
						-Value $rValue `
					;
				} else {
					# Write-Verbose "Не перезаписываем атрибут $Name объекта $($InputObject.cn) - атрибут присутствует.";
				};
			};
			$InputObject;
		};
	};
}
process {
	$user `
	| Add-Attribute -Force SurName { $_.Surname.Trim() | ?{$_} | %{ $_.Substring(0,1).ToUpper() + $_.Substring(1).ToLower() } } `
	| Add-Attribute -Force GivenName { $_.givenName.Trim() | ?{$_} | %{ $_.Substring(0,1).ToUpper() + $_.Substring(1).ToLower() } } `
	| Add-Attribute -Force OtherName { $_.OtherName.Trim() | ?{$_} | %{ $_.Substring(0,1).ToUpper() + $_.Substring(1).ToLower() } } `
	| Add-Attribute extensionName `
	| Add-Attribute personalTitle `
	| Add-Attribute generationQualifier `
	| Add-Attribute -Force initials { ( $_.givenName, $_.OtherName | ? { $_ } | % { $_[0] + '.' } ) -join ' ' } `
	`
	| Add-Attribute -Force cn { ( $_.Surname, $_.givenName, $_.OtherName | ? { $_ } ) -join ' ' } `
	| Add-Attribute -Force name { $_.cn } `
	| Add-Attribute -Force displayName { $_.cn } `
	`
	| Add-Attribute -Force mailNickname { ( $_.givenName, $_.OtherName[0], $_.Surname | ? { $_ } | ConvertTo-Translit ) -join '.' } `
	| Add-Attribute -Force EmailAddress { $_.mailNickname + '@csm.nov.ru' } `
	| Add-Attribute -Force HomePage { 'http://www.csm.nov.ru' } `
	`
	| Add-Attribute sAMAccountName { if ($_.mailNickname.length -gt 20) {$_.mailNickname.Substring(0, 20)} else {$_.mailNickname} } `
	| Add-Attribute -Force userPrincipalName { $_.EmailAddress } `
	`
	| Add-Attribute -Force company { 'Новгородский филиал ФБУ "Тест-С.-Петербург"' } `
	| Add-Attribute employeeID `
	| Add-Attribute employeeType `
	| Add-Attribute department {
		switch ( $_.department.Trim() ) {
			'АУП' { 'Дирекция' }
			'Старорусское подраз-е' { 'Старорусский филиал' }
			'Боровическое подраз-е' { 'Боровический филиал' }
			'СОФФ' { 'Технический отдел' }
			default { $_ }
		}
	} `
	| Add-Attribute departmentNumber `
	| Add-Attribute division {
		switch ( $_.department ) {
			'Старорусский филиал' { 'Старорусский филиал' }
			'Боровический филиал' { 'Боровический филиал' }
			default { 'Новгородский филиал' }
		}
	} `
	| Add-Attribute title `
	| Add-Attribute businessCategory `
	| Add-Attribute businessRoles `
	| Add-Attribute description `
	`
	| Add-Attribute -Force OfficePhone {
		if ( $_.OfficePhone -match '(?:[+](?<КодСтраны>\d{1,3}))?\s*(?:[(](?<КодГорода>\d{3}[\s-]*\d{1,2})[)])?[\s-]*(?<Телефон>(?:\d[\s-]?){5,7})' ) {
			$countryCode = if ( $matches['КодСтраны'] ) { $matches['КодСтраны'] } else { '7' };
			$cityCode = if ( $matches['КодГорода'] ) {
				$matches['КодГорода'] -replace '[\s-]', ''
			} else {
				switch ( $_.division ) {
					'Старорусский филиал' { '81652' }
					'Боровический филиал' { '81664' }
					default { '8162' }
				}
			};
			$phone = $matches['Телефон'] -replace '[\s-]', '-';
			"+$countryCode ($cityCode) $phone";
		} else {
			if ( $_.OfficePhone ) {
				Write-Warning "OfficePhone $($_.OfficePhone) сотрудника $($_.cn) не соответствует маске.";
			};
			$_.OfficePhone;
		};
	} `
	| Add-Attribute -Force Fax {
		if ( $_.Fax -match '(?:[+](?<КодСтраны>\d{1,3}))?\s*(?:[(](?<КодГорода>\d{3}[\s-]*\d{1,2})[)])?[\s-]*(?<Телефон>(?:\d[\s-]?){5,7})' ) {
			$countryCode = if ( $matches['КодСтраны'] ) { $matches['КодСтраны'] } else { '7' };
			$cityCode = if ( $matches['КодГорода'] ) {
				$matches['КодГорода'] -replace '[\s-]', ''
			} else {
				switch ( $_.division ) {
					'Старорусский филиал' { '81652' }
					'Боровический филиал' { '81664' }
					default { '8162' }
				}
			};
			$phone = $matches['Телефон'] -replace '[\s-]', '-';
			"+$countryCode ($cityCode) $phone";
		} else {
			if ( $_.Fax ) {
				Write-Warning "Fax $($_.Fax) сотрудника $($_.cn) не соответствует маске.";
			};
			$_.Fax;
		};
	} `
	| Add-Attribute -Force MobilePhone {
		if ( $_.MobilePhone -match '(?:[+]?(?<КодСтраны>\d{1,3}))?[-\s]*(?:[(]?(?<КодОператора>\d{3})[)]?)[\s-]*(?<Телефон>(?:\d[\s-]?){7})' ) {
			$countryCode = if ( $matches['КодСтраны'] ) { $matches['КодСтраны'] } else { '7' };
			$provCode = if ( $matches['КодОператора'] ) {
				$matches['КодОператора'];
			} else {
				'911';
			};
			$phone = $matches['Телефон'] -replace '[\s-]', '-';
			"+$countryCode ($provCode) $phone";
		} else {
			if ( $_.MobilePhone ) {
				Write-Warning "MobilePhone $($_.MobilePhone) сотрудника $($_.cn) не соответствует маске.";
			};
			$_.MobilePhone;
		};
	} `
	| Add-Attribute -Force otherTelephone {
		if ( $_.otherTelephone -match '(?<Телефон>\d{2})' ) {
			$matches['Телефон'];
		} else {
			if ( $_.otherTelephone ) {
				Write-Warning "Внутренний телефон otherTelephone $($_.otherTelephone) сотрудника $($_.cn) не соответствует маске.";
			};
			$_.otherTelephone;
		};
	} `
	`
	| Add-Attribute -Force Country { 'RU' } `
	| Add-Attribute -Force State { 'Новгородская область' } `
	| Add-Attribute -Force City {
		switch ( $_.division ) {
			'Старорусский филиал' { 'г. Старая Русса' }
			'Боровический филиал' { 'г. Боровичи' }
			default { 'Великий Новгород' }
		}
	} `
	| Add-Attribute -Force st `
	| Add-Attribute -Force postalCode { 
		switch ( $_.division ) {
			'Старорусский филиал' { '175200' }
			'Боровический филиал' { '174400' }
			default { '173021' }
		}
	} `
	| Add-Attribute -Force street {
		switch ( $_.division ) {
			'Старорусский филиал' { 'ул. Володарского' }
			'Боровический филиал' { 'ул. Сушанская' }
			default { 'ул. Нехинская' }
		}
	} `
	| Add-Attribute -Force streetAddress {
		switch ( $_.division ) {
			'Старорусский филиал' { 'ул. Володарского, д.43' }
			'Боровический филиал' { 'ул. Сушанская, д.6' }
			default { 'ул. Нехинская, д.57' }
		}
	} `
	| Add-Attribute -Force houseIdentifier {
		switch ( $_.division ) {
			'Старорусский филиал' { '43' }
			'Боровический филиал' { '6' }
			default { '57' }
		}
	} `
	| Add-Attribute -Force postalAddress {
		switch ( $_.division ) {
			'Старорусский филиал' { 'ул. Володарского, д.43' }
			'Боровический филиал' { 'ул. Сушанская, д.6' }
			default { 'ул. Нехинская, д.57' }
		}
	} `
	| Add-Attribute Office `
	| Add-Attribute managerCn {
	<#
		if ( $_.Руководитель.Trim() -match '(?<Фамилия>\w+)\s+(?<И>\w)[`.]?\s*(?<О>\w)[`.]?' ) {
			$testInitials = $matches['И'] + '.', $matches['О'] + '.' -join ' ';
			$candidate = $users `
				| ? { ($_.Surname -eq $matches['Фамилия']) -and ($_.initials -eq $testInitials) } `
			;
			$candidate.cn;
		};
	#>
	} `
	| Add-Attribute assistantCn `
	| Add-Attribute secretaryCn `
	;
}