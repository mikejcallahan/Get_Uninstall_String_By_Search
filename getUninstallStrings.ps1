  #thinking this can be imported into function using invoke-expression for future scripts. debugging interactive sequence for now.
param(
  [Parameter(Mandatory = $false)] [switch]$interactive,
  [Parameter(Mandatory = $false)] [switch]$encapsulated = $false,
  #[Parameter(Mandatory = $true)] [string]$stage,
  [Parameter(Mandatory = $false)][array]$killList,
  [Parameter(Mandatory = $false)] [array]$pclist,
  [Parameter(Mandatory = $false)] [array]$defaultPCList = ".\pclist"
  )

 function CommandHandler {                           # idea is to have this actually invoke the commands. Needs a lot more work to get to that point
 #[CmdletBinding(SupportsShouldProcess)]
  param(
  [Parameter(Mandatory = $false)] [array]$names,
  [Parameter(Mandatory = $false)] [array]$xmsi,
  [Parameter(Mandatory = $false)] [array]$imsi,
  [Parameter(Mandatory = $false)] [array]$noMsi,
  [Parameter(Mandatory = $false)] [switch]$strNo,
  [Parameter(Mandatory = $false)] [switch]$strI,
  [Parameter(Mandatory = $false)] [switch]$strX
  )
    $uStrings = @()
    $names
   <# 
    if($strX){ foreach($block in $xmsi) { $uStrings += $block }
      
    

    if($strI){ if(!($null -eq $strI)) { foreach($block in $imsi) { $uStrings += $block }}


 #return $uStrings  
 
 #>
 }
 
 

 <#-------------------------------------------------
 .DESCRIPTION
 gets software Name (= 'w32_Product.IdentifyingNumber) quickly from registry
 -------------------------------------#>
  function Initialize {
  param( [Parameter(Mandatory = $false)] [array]$killList
  )

  #$global:
  $keys = @(Get-ChildItem 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\')
  #$global:
  $keys2 = @(Get-ChildItem 'HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\')    # might need 2 "\\" for remote runs
  

  [string[]]$ustr = @($keys| ForEach-Object {$_.GetValue('UninstallString')})  #-------------------------
  [string[]]$uname = @($keys | ForEach-Object {$_.GetValue('DisplayName')})    #  64 bit parallel set
                                                                               #-------------------------

  [string[]]$ustr2 = @(($keys2| ForEach-Object {$_.GetValue('UninstallString')})) #-------------------------    
  [string[]]$uname2 = @(($keys2 | ForEach-Object {$_.GetValue('DisplayName')}))   #  32 bit parallel set
                                                                                  #-------------------------

  
   function killSort ([string[]]$killList,[string[]]$unames,[string[]]$ustrs){ 
    <#param( 
    [Parameter(Mandatory = $true)] [array]$killList,
    [Parameter(Mandatory = $true)] [System.Collections.Arraylist]$unames,
    [Parameter(Mandatory = $true)] [System.Collections.Arraylist]$ustrs
    )#>
    $xnames = [System.Collections.Arraylist]@()                           # collects /x strings
    $inames = [System.Collections.Arraylist]@()                           # collects /i strings
    $onames = [System.Collections.Arraylist]@()                           # collects the rest - includes exe strings with parameters
    $imsi = [System.Collections.Arraylist]@()
    $xmsi = [System.Collections.Arraylist]@()
    $noMsi = [System.Collections.Arraylist]@()
    $intNotMsi = [System.Collections.Arraylist]@()
    [string]$timestamp = (get-date -Format 'yyyyMMddhhmmss')
    
    foreach($kill in $killList){ 
      [string]$kill = $kill.toupper()

      for($i=0;$i-lt($ustr.count);$i++) {
        [string]$currentSuspect = ($uname[$i]).toupper()
        [string]$currentSuspect = ($currentSuspect.replace(" ",""))

        if(($currentSuspect).contains($kill)) {
          [string]$currentUString = ($ustr[$i]).toupper()
          [string]$deathCert = ("$currentSuspect" + "$timestamp")
       
          if(($currentUString).contains('MSIEXEC.EXE /X')) {
            $block = (($currentUString).replace('MSIEXEC.EXE ','').replace('/X','/X '))
            $xmsi += ("$block /qn /l*v x$deathCert.log")
            $xnames += $currentSuspect

          }elseif(($currentUString).contains('MSIEXEC.EXE /I')) {    # need to learn CIMProduct or can use /removeall?
            $block = (($currentUString).replace('MSIEXEC.EXE ','').replace('/I','/X ')) #this may not work due to Windows hashing GUID? other stuff
            $imsi += ("$block /qn /l*v x$deathCert.log")
            $inames += $currentSuspect

          }else{
            $nomsi += $currentUString
            $onames += $currentSuspect
          }
       }
     }
   }

   if($xmsi.count -gt 0) { write-host "[MSIEXEC /x STRINGS]"
     for($z=0;$z-lt$xnames.count;$z++) { 
     write-host ("
     $($xnames[$z])
     $($xmsi[$z])
     ")
     }
   }
   if($imsi.count -gt 0) { write-host "[MSIEXEC /i STRINGS (REPLACED /I with /X - MAY NOT WORK - OTHER OPTIONS EXIST)]"
     for($z=0;$z-lt$inames.count;$z++) { 
     write-host ("
     $($inames[$z])
     $($imsi[$z])
     ")
     }
   }
   if($nomsi.count -gt 0) { write-host "[INSTALLER UNINSTALL STRINGS]"
     for($z=0;$z-lt$onames.count;$z++) { 
     write-host ("
     $($onames[$z])
     $($nomsi[$z])
     ")
     }
   }
 }
 <#$unamePass = @() * ($uname.count) - 1

 foreach($n in $uname){for($i=0;$i-lt$uname.count;$i++) {$unamePass[$i] = $uname[$i]}}
 #>
 $uname = $uname + $uname2
 $ustr = $ustr + $ustr2
 $ustr.count
 $uname.count

# killSort($killList,$uname,$ustr)   
 killSort -killList $killList -unames $uname -ustrs $ustr

 #}catch{$error}
  
  
  #killSort -killList $killList -uname $uname2 -ustr $ustr2
}
  <#


 foreach($kill in $killList){ 
   for($i=0;$i-lt($ustr.count);$i++) {
     [string]$suspect = $uname[$i]  
     #[string]$suspect2 = ($uname2[$i]).toupper()
                                                                         
# MSI uninstall strings prep and scriptblock creation. 
#-------(/x)64 bit-----------------------------------------------
 
     if((($suspect).toupper()).contains(($kill).toUpper())) {
       if((([string]$ustr[$i]).toupper()).contains('MSIEXEC.EXE /X')) {
         $block = (((([string]$ustr[$i]).toUpper()).replace('MSIEXEC.EXE ','')).replace('/X','/X '))    

         [string]$time = (get-date -Format 'yyyyMMddhhmmss')
         $suspect = ($suspect.replace(" ",""))
         $deathCert = ("$suspect" + "$time")

         $block = ("$block /qn /l*v $WorkingDir\x$deathCert.log")
         $xmsi += $block
         $xnames += $suspect
       }
     }
   }
 }
#-------(/x)32 bit---------------------------------------------- 
 foreach($kill in $killList){ 
   for($i=0;$i-lt($ustr2.count);$i++) {  
     [string]$suspect2 = $uname2[$i]
     $suspect2 = ($suspect2.toupper())

     if(($suspect2).contains(($kill).toUpper())) {
       if((([string]$ustr2[$i]).toupper()).contains('MSIEXEC.EXE /X')) {
         $block2 = (((([string]$ustr2[$i]).toUpper()).replace('MSIEXEC.EXE ','')).replace('/X','/X '))  

         [string]$time = (get-date -Format 'yyyyMMddhhmmss')
         $suspect2 = ($suspect2.replace(" ",""))
         $deathCert2 = ("$suspect2" + "$time")
     
         $block2 = ("$block2 /qn /l*v $WorkingDir\x$deathCert2.log")
         $xmsi += $block2
         $xnames2 += $uname2[$i]
       }
     }
   }
 }                                                                     
#--------(/i)64bit----------------------------------------------- 
<#                                                                         
  if((([string]$ustr[$i]).toupper()).contains('MSIEXEC.EXE /I')) {                
     $imsi += (([string]$ustr[$i]).toUpper()).replace('MSIEXEC.EXE ','')
     $intImsi

    }else {
     $noMsi += $ustr[$i]
     $onames += $i
    }  
   }#>
 
 <#
 $xmsi += $xnames
 $imsi += $inames
 $noMsi += $onames
 #>

 #$global:xnamesBoth = $xnames + $xnames2
 #>

 #$xnamesBoth = $xnames + $xnames2
 #Write-Host "-----------/x strings-------"
 #$xmsi

<#
  Write-Host "-----------/i strings-------"
  $imsi
   Write-Host "-----------other-------"
    $noMsi
#>

 #$xresult = CommandHandler -names $xnamesBoth -xmsi $xmsi
 #return $xresult
 
 <#
 function initialize {
   $global:softname = ""
 }
 #>

 function InteractiveSearch {
   param(
   [switch]$task1,
   [switch]$task2
   )
 
   [string[]]$interactKillList = @()
   $result = ""
   $strSearch = ""

   function task1 {
   $strSearch = read-host ("
   [UNINSTALL STRING SEARCH]
   SEARCH")
   $interactKillList += $strSearch

     if($interactKillList.count -ne 0) {
       #$result = 
       Initialize -killList $interactKillList
     }
     #return $result
     task1
   }

   
   function task2 {
   $strSearch = $dirParent
   $interactKillList += $strSearch
   write-host ("
   [UNINSTALL STRING SEARCH]
   [SEARCHING] $dirParent
   ")
   $result = Initialize -killList $interactKillList
   return $result
   }

   if($task1){ task1 }
   $choice = read-host ("
   SEARCH AGAIN(Y/N)?
   ")
   if(($choice.toUpper()).contains("Y")) { InteractiveSearch -task1 } else { break }
 }

 #----------------------------------------- BODY ARGS
 if(($interactive) -or (!($encapsulated))) {
   InteractiveSearch -task1
 }

 if($encapsulated) { write-host "nope" }                      # this will require some thinking