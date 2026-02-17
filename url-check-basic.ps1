# url-check.ps1 - EK - 10022025
# Version 04
# This script will return the accessibility of a URL. Execution does not require elevated rights
# A CSV file is required as input (URLList.txt) and the output is written to a CSV file (Bla-Bla-Check-Results.txt). Of course, you can change the file names ;-)
# Adapt $URLListFile, $OutputFile and $LogFile before execution

$URLListFile = "C:\Working\url-check\URLList.txt"
$DateStamp = (Get-Date).ToString("yyyyMMdd_HHmmss")
$OutputFile = "C:\Working\url-check\results\Bla-Bla-Check-Results_$DateStamp.txt"
$LogFile = "C:\Working\url-check\results\url-check-log_$DateStamp.txt"

# Function to log messages
function Log-Message {
    param (
        [string]$Message
    )
    $timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    $logEntry = "$timestamp - $Message"
    Write-Output $logEntry | Out-File $LogFile -Append
}

# Start logging
Log-Message "Script execution started."

# Check if input file exists
if (-Not (Test-Path $URLListFile)) {
    Log-Message "Input file not found: $URLListFile"
    Write-Host "Input file not found: $URLListFile"
    exit
}

$URLList = Get-Content $URLListFile -ErrorAction SilentlyContinue

# For every URL in the list
Foreach($Uri in $URLList) {
    try {
        # For proxy systems
        [System.Net.WebRequest]::DefaultWebProxy = [System.Net.WebRequest]::GetSystemWebProxy()
        [System.Net.WebRequest]::DefaultWebProxy.Credentials = [System.Net.CredentialCache]::DefaultNetworkCredentials

        # Web request
        $req = [system.Net.WebRequest]::Create($uri)
        $res = $req.GetResponse()
        $statusCode = [int]$res.StatusCode
        $resultMessage = "$statusCode, $uri"
    } catch {
        $statusCode = $_.Exception.Response.StatusCode
        $errorMessage = $_.Exception.Message
        $resultMessage = "Error accessing {0}: {1}" -f $uri, $errorMessage
        Log-Message $resultMessage
    }
    $req = $null

    # Writing on the screen
    Write-Host $resultMessage

    # Write results to file
    Write-Output $resultMessage | Out-File $OutputFile -Append

    # Log the result
    Log-Message $resultMessage

    # Disposing response if available
    if ($res) {
        $res.Dispose()
    }
}

# End logging
Log-Message "Script execution completed."
