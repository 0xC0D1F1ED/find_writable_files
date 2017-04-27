# find_writable_files

find_writable.ps1 is a powershell script I created as a result of a recent pentest engagement I was on.  This particular engagement involved testing a kiosk that blocked the execution of cmd.exe and powershell.exe for non-admin users.  Additionally white-listing was in place to restrict the applications that could be run and the locations they could be run from.  The usual tricks of launching powershell from a batch file or putting modified versions of PS/CMD on the host were not successful.  

I ended up making use of @SubTee's research to run PowerUp by creating a .cs code stub to run a PS script, compiling with csc.exe and executing it using installutil.exe.  This process is well documented on the Black Hills Infosec blog here: http://www.blackhillsinfosec.com/?p=5257

I still had several test cases to run from the provided low privilege user account on the kiosk, and not being able to get an interactive shell in that context was a huge pain in the ass.  I ended up trying to find an executable that was both white-listed AND modifiable from a low privilege user context.  The scripts and tools I used didn't return any results, but later manual inspection of the main kiosk application binary with icacls revealed that I was able to modify it.  Trying to figure out why the tools I used had not identified this I realized that the method these tools were using to determine whether a file could be modified or not was flawed.  All of the tools I had used were executing some variation of the following code snippet taken from the Get-ModifiableFile function in PowerUp.ps1 located at: https://github.com/PowerShellEmpire/PowerTools/blob/master/PowerUp/PowerUp.ps1

...

            try {
                # expand any %VARS%
                $FilePath = [System.Environment]::ExpandEnvironmentVariables($_)
                
                # try to open the file for writing, immediately closing it
                $File = Get-Item -Path $FilePath -Force
                $Stream = $File.OpenWrite()
                $Null = $Stream.Close()
                $FilePath
            }
	    catch {}

...

This is also the solution that comes up on stackoverflow, etc. when googling for how to do this.  The problem with this code is that if the file is in use, as it was in my case with the kiosk application running, this code results in an access denied exception when attempting to open the file and doesn't get recorded as one that can be modified.  In my particular case this was literally the only white-listed file I could modify from a low privilege context.  As a result I've created my own script that checks what groups the user running the script belongs to, searches for files with a specific extension, and checks the actual file ACL to determine whether the user belongs to any groups that have either "Full Control", "Write" or "Modify" rights.

Once I found that file I was able to make some minor edits to powershell.exe in a hex editor so that the hash wouldn't match the official powershell.exe file and simply replace the application binary with mine and get a shell bypassing the restrictions on the kiosk.

NOTE: This should be obvious, but this script is meant to be run from a low privielege account, not an Administrator account.