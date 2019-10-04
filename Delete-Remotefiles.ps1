$limit = ((Get-date).AddDays(-30)).date

$path = "C:\ProgramData\Microsoft\Windows\WER"

write-output "Going to attempt to clean up log files on all Viero servers older than $limit in directory path $path`n"

$ArrayOfVServers = Invoke-DbaQuery -SqlInstance localhost\sql01 -Query 'SELECT SERVERNAME FROM TRACKING..T_ALL_SERVER WHERE SERVERNAME LIKE ''VR%01'' '

write-output "The number of servers the cleanup will be attempted on: $($ArrayOfVServers.Count)`n"

Foreach ($srvr in $ArrayOfVServers){

    $svrName = $($srvr.SERVERNAME)

    write-host "Server Name: $svrName`n"

    $ScriptBlock = {


        $FilesToDelete = Get-ChildItem -Path $Using:Path |  Where-Object {-not $_.PSIsContainer -and $_.CreationTime -lt $Using:Limit} | Select-Object -Property FullName,PSIsContainer,PSComputerName,CreationTime

        $cnt=$FilesToDelete | Measure-Object | Select -ExpandProperty count

        write-host "Number of Files found to be deleted: $cnt`n"

        If ( $cnt -gt 0 ) {

            ForEach ($File in $FilesToDelete) {

                # Add a default delete status of false.  This changes if Remove-Item is successful
                $DeletedStatus = $False
                Try {
                    Remove-Item -Path $File.FullName -Force -ErrorAction Stop -WhatIf
                    # This line will only run if Remove-Item doesn't error
                    $DeletedStatus = $True
                }
                Catch {
                    # So you could capture the actual error here and output it as another property below
                    # or just ignore it and count on figuring out why something didn't delete manually later
                    # The easy step here would be to just add the property right away:

                    $File | Add-Member -Name 'DeletedError' -MemberType NoteProperty -Value $PSItem.Exception.Message
                }

                # You can use Add-Member to add properties to an existing variable.  In this case
                # we add a 'Deleted' property with a value of True or False depending on the Try/Catch
                # above.
                $File | Add-Member -Name 'Deleted' -MemberType NoteProperty -Value $DeletedStatus
                $File
            }
        }
    }



    Invoke-Command -Computername $srvr.SERVERNAME -ScriptBlock $ScriptBlock

}
