# ****************************************************************************************************
# Program: 1) Identify list of active and inactive remote servers.
#          2) Identify list of installed McAfee products and versions installed on each remote server.
#          3) Identify list of hard drive space in percentage % & available space for each active server
#          4) Identify WMIBIOS information for each active server
#          5) Identify list of RAM allocated to each active server
# 
# Setup
# Scheduled Task
# program/script: %SystemRoot%\system32\WindowsPowerShell\v1.0\powershell.exe
# argument: -NoExit c:\\Alvin\Document\Powershell\Powershell_scripts\get_server_status_outfile.ps1 | out-file -filepath "C:\outfile.txt" -append
# 
# Remaining
#          1) Export process & add time stamp (partial))
#          2) Scsi
#          3) Single server request or group requests.
#          4) Firewall on - exception for connection.
#          5) identify Free RAM (done)
#          6) Create config file to list the parameters. (benefit: change config file instead of source code)
#          7) Need *.DAT version of McAfee displayed. (done)
# ****************************************************************************************************

#Firewall 
#Import-Module NetSecurity
 
#Config
$config= Get-Content C:\DailyOps\Config\DailyOps_config.cfg
 
#VARIABLES
$startdatetime = Get-Date
$enddatetime = Get-Date
#$stream = [System.IO.StreamWriter] "C:\Alvin\Test\output_file.txt"
$computers    = Get-Content C:\Alvin\Test1.txt 
#$computers    = Get-Content C:\Alvin\Test1_array.txt 
$ErrorActionPreference= 'silentlycontinue'
$active_count   = 0
$inactive_count = 0
$hd_threshold_limit = 10
$step=$args[0]
$DeviceType=3
$cn = Get-ADComputer -Properties operatingsystem -Filter
#$cred = Get-Credential -Credential AMERICAS\agotanco

#outfile time stamp
$OutFileTime = Get-Date -format "MM-dd-yyyy_hh-mm-ss"

#outfile Path
$path = "C:\DailyOps\"

#FUNCTIONS
	  
	   #Get WMIBIOS Info
	   function Get-WMIBIOS-Info{
	   param($computer)
	   $computer | Foreach-Object {Get-Wmiobject -computername $computer win32_bios}
	   }
	   
	   #Get OPerating System
	   function Get-OS{
	   param($computer)
	   
	   $OS = (Get-WmiObject -Class Win32_OperatingSystem -computer $computer).caption
	   #Write-Host "Operating System:" $OS
	   "Operating System:" + $OS
	   
	   }
	   
	   #Get IP Address
	   function Get-IP-Addr{
	   param($computer)
	   
	   $colItems = Get-WmiObject Win32_NetworkAdapterConfiguration -Namespace "root\CIMV2" -Computername $computer | where{$_.IPEnabled -eq "True"}

		foreach($objItem in $colItems){
		  Write-Host "DNS Domain:"  $objItem.DNSDomain    -foregroundcolor "magenta"
		  Write-Host "IP4 Address:" $objItem.IPAddress[0] -foregroundcolor "magenta"
		  Write-Host "IP6 Address:" $objItem.IPAddress[1] -foregroundcolor "magenta"
		  Write-Host "MAC Address:" $objItem.MACAddress   -foregroundcolor "magenta"
		 }
	   }
    
	
	   #Get Hard Drive Space 
	   function Get-DiskInfo
	   {
			param($computer)
	  
			Function Get-ColorSplat    
			{   # Create color Splats         
				$C1 = @{ForegroundColor="Green";BackgroundColor="DarkGreen"}         
				$C2 = @{ForegroundColor="Yellow";BackgroundColor="DarkYellow"}         
				$C3 = @{ForegroundColor="White";BackgroundColor="DarkRed"}         
				$C4 = @{ForegroundColor="Blue";BackgroundColor="Gray"}           
				
				# Create color constants in the previous scope.         
				New-Variable -Name "Good" -Value $C1 -Scope 1         
				New-Variable -Name "Problem" -Value $C2 -Scope 1         
				New-Variable -Name "Bad" -Value $C3 -Scope 1         
				New-Variable -Name "Header" -Value $C4 -Scope 1     
			} # End: Get-ColorSplat       
		
			Function Write-ColorOutput    
			{           
				Param($DiskInfo)           
				
				# Display the headers.         
				# Write-host "DiskInfo | FreeSpaceGB | PercentFreeSpace"    
				"DiskInfo | FreeSpaceGB | PercentFreeSpace | Status "  	
                "---------------------------------------------------"				
				
				# Display the data.         
				ForEach ($D in $DiskInfo)         
				{             
				
						$DeviceID = $D.DeviceID.PadRight(6)             
						$FSGB = $D.FreeSpaceGB.ToString().PadRight(6).Remove(5)             
						$PFS = $D.PercentFS.ToString().PadRight(6).Remove(5)               
						
						If ($D.PercentFS -ge 80)             
						{ #Write-Host "$($DeviceID)   | $($FSGB)       | $($PFS)" @Good 
						  "$($DeviceID)   | $($FSGB)       | $($PFS) %          | Good "  
						}   
						ElseIf (($D.PFS -eq 0) -and ($D.FSGB -eq 0))
						{ #Write-Host "$($DeviceID)   | $($FSGB)       | $($PFS)" @Good 
						  "$($DeviceID)   | $($FSGB)       | $($PFS) %          | NA " 
						} 
						ElseIf (($D.PercentFS -lt 80) -and ($D.PercentFS -GE 60))             
						{ #Write-Host "$($DeviceID)   | $($FSGB)       | $($PFS)" @Problem 
						  "$($DeviceID)   | $($FSGB)       | $($PFS) %          | Moderate " 
						}   
						ElseIf (($D.PercentFS -lt 60) -and ($D.PercentFS -GE 20))             
						{ #Write-Host "$($DeviceID)   | $($FSGB)       | $($PFS)" 
						  "$($DeviceID)   | $($FSGB)       | $($PFS) %          | Warning " 
						}   						
						Else             
						{ #Write-Host "$($DeviceID)   | $($FSGB)       | $($PFS)" @Bad 
						  "$($DeviceID)   | $($FSGB)       | $($PFS) %          | Bad "
						}           
				}     
			}       
		
		# Get the color splats     
			Get-ColorSplat      
		    
			# get Hard Disk info and filter fixed drives only.
			$DiskInfo = Get-WmiObject Win32_LogicalDisk -filter "DriveType='3'" -ComputerName $computer | Select-Object -Property DeviceID, @{Name="FreeSpaceGB";Expression={$_.Freespace/1GB}}, @{Name="PercentFS";Expression={($_.FreeSpace/$_.Size)*100}}        
		
			If (!$PassThru) {Write-ColorOutput -DiskInfo $DiskInfo}      
			Else {Write-Output $DiskInfo} 
		}
	   
       #Get Ram Memory for remote computers
       function Get-RAM-Memory{
	   param ($computer)	
	   
	   #$colItems = get-wmiobject -class "Win32_ComputerSystem" -namespace "root\CIMV2" -computername $computer
	   $colItems = (get-wmiobject Win32_PhysicalMemory -namespace "root\CIMV2" -computername $computer | Measure-Object -Property Capacity -Sum).Sum/1gb
       $freeRam  =  get-wmiobject -class "Win32_OperatingSystem" -namespace "root\CIMV2" -computername $computer 


	        "TotalPhysRAM_GB | FreeRAMSpace | PercentFreeSpace "  	
			
			foreach ($objItem in $colItems){
				$PhysRAM += $objItem
			}
			
			foreach ($objItem1 in $freeRam){
			$RemainRAM +=   ([math]::round(($objItem1.FreePhysicalMemory / 1024 / 1024), 2))
			}
			 
			"$($PhysRAM)         |       $($RemainRAM)  "
		}
    
	   #Get SCSI devices 
	   function Get-SCSI-Device{
	   param ($computer, $DeviceType)
	   
	   # Get the  WMI objects           
		   $Win32_LogicalDisk = Get-WmiObject -Class Win32_LogicalDisk @Parameters | Where-Object {$_.DeviceID -like $DeviceID}           
		   $Win32_LogicalDiskToPartition = Get-WmiObject -Class Win32_LogicalDiskToPartition @Parameters            
		   $Win32_DiskDriveToDiskPartition = Get-WmiObject -Class Win32_DiskDriveToDiskPartition @Parameters            
		   $Win32_DiskDrive = Get-WmiObject -Class Win32_DiskDrive @Parameters  
		   
		   
		   # Search the SCSI Lun Unit for the disk           
		   $Win32_LogicalDisk |             
		   ForEach-Object 
		   {               
				if ($_)               
				{                 
					$LogicalDisk = $_                 
					$LogicalDiskToPartition = $Win32_LogicalDiskToPartition | Where-Object {$_.Dependent -eq $LogicalDisk.Path}                 
					if ($LogicalDiskToPartition)                 
						{$DiskDriveToDiskPartition = $Win32_DiskDriveToDiskPartition | Where-Object {$_.Dependent -eq $LogicalDiskToPartition.Antecedent}  
							if ($DiskDriveToDiskPartition)                   
								{$DiskDrive = $Win32_DiskDrive | Where-Object {$_.__Path -eq $DiskDriveToDiskPartition.Antecedent}                     
									if ($DiskDrive)                     
										{                       
											# Return the results                       
											New-Object -TypeName PSObject -Property @{
											Computer = $Computer                        
											DeviceID = $LogicalDisk.DeviceID                         
											SCSIBus =  $DiskDrive.SCSIBus                         
											SCSIPort = $DiskDrive.SCSIPort                         
											SCSITargetId = $DiskDrive.SCSITargetId                         
											SCSILogicalUnit = $DiskDrive.SCSILogicalUnit                       
											}                     
										}	           
								}                 
						}
				}	
			}
	   
	   
	   $scsi_device = Get-ScsiLun -VMHost $computer -LunType disk
	   
	   Write-Host "SCSI devices ($scsi_device) exist" -foregroundcolor YELLOW
	   
	   
	   }
       
	   #Get VM Machine total per Physical Host
	   function Get-Machine-Total{
	   param ($computer)
	   
	   }
	  
       #Get Firewall rule
	   function Get-Firewall-Rule{
	   param ($computer)
	   
	   $CIM = New-CimSession -ComputerName $computer -Name FirewallMachines #-Credential $cred
	   
       #New-NetFirewallRule -Name Allow_Ping -DisplayName "Allow Ping" -Description "Packet Internet Groper ICMPv4" -Protocol ICMPv4 -IcmpType 8 -Enabled True -Profile Any -Action Allow -CimSession $cim

       #Get-NetFirewallRule -DisplayName "Allow Ping" -CimSession $cim | Select PSComputerName, name, enabled, profile, action |Format-Table -AutoSize

	   #Test-Connection -ComputerName $cim.computername -BufferSize 15 -Count 1

       write-host "Firewall Rule for $CIM"
	 
	   }
	  
       #Get existing McAfee versions on each server
	   function Get-McAfeeVersion { 
       param ($computer) 
	   
	   $ProductVer = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey('LocalMachine',$computer).OpenSubKey('SOFTWARE\McAfee\DesktopProtection').GetValue('szProductVer') 
	   $DatVer = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey('LocalMachine',$Computer).OpenSubKey('SOFTWARE\McAfee\AVEngine').GetValue('AVDatVersion')
	   
	   #$regexists= $ProductVer.Substring(0,74) # not reading correctly??
	   $regexists= [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey('LocalMachine',$computer)
	   
	   if ($regexists -ne $null){
	     #Write-Host "McAfee Product version: $ProductVer" -foregroundcolor YELLOW
         #Write-Host "McAfee DAT version: $DatVer" -foregroundcolor YELLOW
		 
		 "McAfee Product version: " + $ProductVer
         "McAfee DAT version: " + $DatVer 
		 }
	   else
		{
		 #Write-Warning "$computer: McAfee not Installed"  -ErrorAction $ErrorActionPreference
		 
		 "McAfee not Installed "  # -ErrorAction + $ErrorActionPreference
		 
		}
	   }
      
	   
#MAIN	   
  
if([IO.Directory]::Exists($path))
{
	#DO Nothing
}
else
{
New-Item -ItemType directory -Path C:\DailyOps
}
$OutFile = 'C:\DailyOps\Daily_Report_'+$OutFileTime+".txt"

  
  
  if ($step -eq $null)
  {
          
		  $inactive_comp = @()
		  "Start Date: " + $startdatetime.ToShortDateString()
		  "Start Time: " + $startdatetime.ToShortTimeString()
		  
		  foreach ($computer in $computers) 
		  {
		  
		  'processing... ' + $computer + ' start'
		  


		  
		   $active=Test-Connection -ComputerName $computer -Count 1 -ErrorAction $ErrorActionPreference
		   		
		   if ($active.statuscode -eq 0)
			  {
			   #write-host $computer is reachable -foregroundcolor GREEN
			   '*************** ' + $computer + ' ***************'  | Out-File $OutFile  -Append -Force -width 120 
			   '*************** ACTIVE ***************'  | Out-File $OutFile  -Append -Force -width 120 
			   
			   Get-OS                $computer | Out-File $OutFile  -Append -Force -width 120 
			   Get-McAfeeVersion     $computer | Out-File $OutFile  -Append -Force -width 120 
			   #Get-Firewall-Rule     $computer
			   #Get-WMIBIOS-Info      $computer
			   #Get-IP-Addr           $computer
			   #Get-SCSI-Device       $computer $DeviceType
			   #Get-Hard-Drive-Memory $computer
			   Get-RAM-Memory        $computer | Out-File $OutFile  -Append -Force -width 120 
			   Get-DiskInfo          $computer | Out-File $OutFile  -Append -Force -width 120 
			   
			   $active_count=$active_count + 1
			   #$stream.WriteLine($computer)
			   
			  
			  }
		   else
			  { #write-host $computer is unreachable -foregroundcolor RED
			    
		      '+++++++++++++++ ' + $computer + ' +++++++++++++++'  | Out-File $OutFile  -Append -Force -width 120 
			  '+++++++++++++++ NOT-ACTIVE +++++++++++++++'         | Out-File $OutFile  -Append -Force -width 120 
			  $inactive_count = $inactive_count + 1
			  $stream.WriteLine($computer)
			  #$inactive_comp += "`r`n" + $computer |  Out-File $OutFile  -Append -Force -width 120 
			  $inactive_comp += $computer #|  Out-File $OutFile  -Append -Force -width 120 
			  }
			  
			  'processing... ' + $computer + ' complete'
		  }
		  #write-host '=============================================================='
		  #write-host 'Total Active Machines: '    $active_count   -foregroundcolor GREEN 
		  #write-host 'Total In-Active Machines: ' $inactive_count -foregroundcolor RED
		  #write-host 'Inactive Computers:'        $inactive_comp[0..$inactive_count] -foregroundcolor RED
		  
		   '==============================================================' | Out-File $OutFile  -Append -Force -width 120 
		   'Total Active Machines: '  +  $active_count | Out-File $OutFile  -Append -Force -width 120 
		   'Total In-Active Machines: ' + $inactive_count |  Out-File $OutFile  -Append -Force -width 120
		   #'Inactive Computers:'      +  $inactive_comp[0..$inactive_count] | Out-File $OutFile  -Append -Force -width 120
		   'Inactive Computers:'      +  $inactive_comp[0..$inactive_count] #| Out-File $OutFile  -Append -Force -width 120
		   "End Date: " + $enddatetime.ToShortDateString() | Out-File $OutFile  -Append -Force -width 120
		   "End Time: " + $enddatetime.ToShortTimeString() | Out-File $OutFile  -Append -Force -width 120 
		   
		  
		  #export to file
		  
		
		  
		  #$stream.close()
		  
  }
  else
  {
		  #write-host 'selected single server'
		  'selected single server'
  }
  

