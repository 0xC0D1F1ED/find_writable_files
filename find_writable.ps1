
function Find-WritableFiles {
<#
    .SYNOPSIS

        Discover writable/modifiable files based on the currently logged in user and their groups.
        This script is intended to be used from a low privilege account.

        Author: @dcept905
        
    .EXAMPLE

        PS C:\> Find-WritableFiles C:\ .exe

        Return a list of .exe files in c: and all subfolders that the running user can modify.
    
    .EXAMPLE

        PS C:\> Find-WritableFiles C:\users .dll

        Return a list of .dll files in c:\users and all subfolders that the running user can modify.
#>



  [CmdletBinding()]
    Param(
    [Parameter(Position = 0, Mandatory = $true)]
    [String]
    $location,
    [Parameter(Position = 1, Mandatory = $true)]
    [String]
    $fileExt
    )
  
  $allGroups = New-Object System.Collections.Generic.List[string]
  $whoamiName = whoami
  $allGroups.Add($whoamiName)
  $whoGroups = whoami /groups /fo csv
  $csvGroups = $whoGroups | ConvertFrom-CSV
  foreach($gp in $csvGroups) {
    $allGroups.add($gp."Group Name")
  }  

  Write-Output "********************************************************************************"
  Write-Output "**                           Discovered User Groups                           **"
  Write-Output "********************************************************************************"
  Write-Output ""
  $allGroups

  Write-Output ""
  Write-Output "Getting list of" $fileExt "files in $location. NOTE: Searching entire drives may take a while."
  try {
    $list = get-childitem $location -recurse -ErrorAction silentlycontinue | where {$_.extension -eq $fileExt} | Select FullName
  }
  catch {}

  $results = New-Object System.Collections.Generic.List[string]
  Write-Output "Checking access on files and generating list."
  Write-Output ""
  ForEach($path in $list) {
    try {
      $file = Get-Item -LiteralPath $path.FullName -Force
      ForEach($group in $allGroups) {
        if ((Get-Acl $file).Access | where-object { 
        ($_.IdentityReference -match [Regex]::Escape($group)) -and (($_.FileSystemRights -match "FullControl") -or ($_.FileSystemRights -match "Write") -or ($_.FileSystemRights -match "Modify"))}) {
          $results.add($path.FullName)
          break
        }
      }
    }
    
    catch [Exception] 
    {
      #echo $_.Exception.GetType().FullName, $_.Exception.Message
    }
  }
  
  Write-Output "********************************************************************************"
  Write-Output "**                           List of Writable Files                           **"
  Write-Output "********************************************************************************"
  Write-Output ""
  $results

}
