<#
.SYNOPSIS
    URL Accessibility Checker - Tests the availability and response time of web URLs.

.DESCRIPTION
    This script checks the accessibility of URLs listed in an input file. It performs HTTP requests
    and returns status codes, response times, and error information. Results are logged to both
    console and output files. The script supports various HTTP methods and certificate validation options.

    FILE LOCATIONS (Relative to Script):
    - Working Directory: .\working\          (Created automatically if missing)
    - URL List File:     .\working\URLList.txt (Template created if missing)
    - Results Directory: .\results\          (Created automatically if missing)
    - Output File:       .\results\URL-Check-Results_YYYYMMDD_HHMMSS.csv
    - Log File:          .\results\url-check-log_YYYYMMDD_HHMMSS.txt

    Features:
    - Response time measurement
    - Multiple HTTP methods (GET, HEAD, POST)
    - Configurable certificate validation
    - Proxy-aware (uses system proxy settings)
    - Comprehensive logging with timestamps
    - Error handling with detailed messages
    - Automatic directory creation
    - Template URL list generation

.PARAMETER URLListFile
    Path to the input file containing URLs (one per line). 
    Default: ".\working\URLList.txt" (relative to script location)

.PARAMETER OutputFile
    Path for the results file. 
    Default: ".\results\URL-Check-Results_YYYYMMDD_HHMMSS.csv" (relative to script location)

.PARAMETER LogFile
    Path for the log file. 
    Default: ".\results\url-check-log_YYYYMMDD_HHMMSS.txt" (relative to script location)

.PARAMETER Method
    HTTP method to use (GET, HEAD, POST). Default: GET

.PARAMETER IgnoreCertErrors
    Switch to ignore SSL/TLS certificate errors. Default: $false

.PARAMETER TimeoutSeconds
    Timeout in seconds for each request. Default: 30

.EXAMPLE
    .\url-check.ps1
    Runs the script with default settings. Will create working\ and results\ folders,
    and generate a template URLList.txt if none exists.

.EXAMPLE
    .\url-check.ps1 -Method HEAD -IgnoreCertErrors -TimeoutSeconds 15
    Uses HEAD requests, ignores certificate errors, with 15-second timeout

.EXAMPLE
    .\url-check.ps1 -URLListFile "C:\custom\path\myurls.txt"
    Checks URLs from custom file (absolute path)

.NOTES
    Version: 05
    Author: EK
    Created: 10022025
    Last Modified: 17022025
    Requires: PowerShell 3.0 or higher

    Input File Format (.\working\URLList.txt):
    - One URL per line
    - Lines starting with # are ignored
    - Empty lines are ignored
    - Include http:// or https:// prefix
    
    Example URLList.txt content:
    # Production URLs
    https://www.google.com
    https://github.com
    # Test URLs
    http://httpbin.org/status/200
    https://api.github.com/zen

.VERSION HISTORY
    01 - Initial version
    02 - Added logging functionality
    03 - Improved error handling
    04 - Added proxy support
    05 - Added response time, HTTP methods, certificate validation, 
         professional naming, and relative paths with auto-creation
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [string]$URLListFile,
    
    [Parameter(Mandatory=$false)]
    [string]$OutputFile,
    
    [Parameter(Mandatory=$false)]
    [string]$LogFile,
    
    [Parameter(Mandatory=$false)]
    [ValidateSet("GET", "HEAD", "POST")]
    [string]$Method = "GET",
    
    [Parameter(Mandatory=$false)]
    [switch]$IgnoreCertErrors,
    
    [Parameter(Mandatory=$false)]
    [int]$TimeoutSeconds = 30
)

# Auto-configure paths based on script location
$ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$WorkingDir = Join-Path $ScriptRoot "working"
$ResultsDir = Join-Path $ScriptRoot "results"

# Create directories if they don't exist
try {
    if (-not (Test-Path $WorkingDir)) {
        New-Item -ItemType Directory -Path $WorkingDir -Force | Out-Null
        Write-Host "Created working directory: $WorkingDir"
    }
    
    if (-not (Test-Path $ResultsDir)) {
        New-Item -ItemType Directory -Path $ResultsDir -Force | Out-Null
        Write-Host "Created results directory: $ResultsDir"
    }
} catch {
    Write-Warning "Could not create directories. Using current directory as fallback."
    $WorkingDir = Get-Location
    $ResultsDir = Get-Location
}

# Set up file paths with timestamps if not provided
$DateStamp = (Get-Date).ToString("yyyyMMdd_HHmmss")

if (-not $URLListFile) {
    $URLListFile = Join-Path $WorkingDir "URLList.txt"
}

if (-not $OutputFile) {
    $OutputFile = Join-Path $ResultsDir "URL-Check-Results_$DateStamp.csv"
}

if (-not $LogFile) {
    $LogFile = Join-Path $ResultsDir "url-check-log_$DateStamp.txt"
}

# Check if input file exists, if not create a template
if (-not (Test-Path $URLListFile)) {
    $template = @"
# URL Check List - Created on $(Get-Date)
# Add one URL per line (include http:// or https://)
# Lines starting with # are ignored
# Empty lines are ignored

# Production URLs
https://www.google.com
https://github.com
https://stackoverflow.com

# Test URLs (uncomment to test)
# http://httpbin.org/status/200
# http://httpbin.org/status/404
# http://httpbin.org/status/500

# API Endpoints
https://api.github.com/zen
https://jsonplaceholder.typicode.com/posts/1

# Add your URLs below this line:
# --------------------------------
"@
    $template | Out-File -FilePath $URLListFile -Encoding UTF8
    Write-Host ""
    Write-Host "Created template URL list at: $URLListFile"
    Write-Host "Please edit this file to add your URLs, then run the script again."
    Write-Host "The script expects one URL per line (e.g., https://example.com)"
    Write-Host ""
    exit
}

# Function to log messages
function Log-Message {
    param (
        [string]$Message,
        [string]$Level = "INFO"
    )
    $timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    $logEntry = "$timestamp [$Level] - $Message"
    Write-Output $logEntry | Out-File $LogFile -Append
}

# Function to write results in CSV format
function Write-Result {
    param (
        [string]$URL,
        [int]$StatusCode,
        [string]$StatusDescription,
        [double]$ResponseTime,
        [string]$ErrorMessage = ""
    )
    
    $result = [PSCustomObject]@{
        Timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
        URL = $URL
        Method = $Method
        StatusCode = if ($StatusCode) { $StatusCode } else { "N/A" }
        StatusDescription = if ($StatusDescription) { $StatusDescription } else { "Error" }
        ResponseTimeMs = if ($ResponseTime) { [math]::Round($ResponseTime, 2) } else { "N/A" }
        ErrorMessage = $ErrorMessage
        IgnoreCertErrors = $IgnoreCertErrors
    }
    
    # Export to CSV (create header if file doesn't exist)
    $exportParams = @{
        Append = $true
        NoTypeInformation = $true
    }
    if (-not (Test-Path $OutputFile)) {
        $result | Export-Csv -Path $OutputFile -NoTypeInformation
    } else {
        $result | Export-Csv -Path $OutputFile @exportParams
    }
    
    # Console output - simple and clean
    if ($ErrorMessage) {
        Write-Host "FAIL: $URL - $ErrorMessage"
    } elseif ($StatusCode -ge 200 -and $StatusCode -lt 300) {
        Write-Host "OK: $URL - $StatusCode ($ResponseTime ms)"
    } elseif ($StatusCode -ge 300 -and $StatusCode -lt 400) {
        Write-Host "REDIRECT: $URL - $StatusCode ($ResponseTime ms)"
    } else {
        Write-Host "ERROR: $URL - $StatusCode ($ResponseTime ms)"
    }
}

# Main script execution
try {
    # Start logging
    Log-Message "Script execution started. Method: $Method, Timeout: ${TimeoutSeconds}s, IgnoreCertErrors: $IgnoreCertErrors"
    Log-Message "Working directory: $WorkingDir"
    Log-Message "URL list file: $URLListFile"
    Log-Message "Output file: $OutputFile"
    Log-Message "Log file: $LogFile"

    Write-Host "URL Check Script Started"
    Write-Host "========================"
    Write-Host "Input file: $URLListFile"
    Write-Host "Output file: $OutputFile"
    Write-Host ""

    # Configure certificate validation if needed
    if ($IgnoreCertErrors) {
        Log-Message "Certificate validation will be bypassed" "WARNING"
        Write-Host "WARNING: Certificate validation is bypassed"
        [System.Net.ServicePointManager]::ServerCertificateValidationCallback = {$true}
    }

    # Read and filter URLs (ignore comments and empty lines)
    $URLList = Get-Content $URLListFile | Where-Object { 
        $_ -match '^https?://' -and $_ -notmatch '^\s*#' 
    }

    if ($URLList.Count -eq 0) {
        throw "No valid URLs found in input file: $URLListFile"
    }

    Log-Message "Found $($URLList.Count) URLs to check"
    Write-Host "Found $($URLList.Count) URLs to check"
    Write-Host ""

    # Configure proxy
    [System.Net.WebRequest]::DefaultWebProxy = [System.Net.WebRequest]::GetSystemWebProxy()
    [System.Net.WebRequest]::DefaultWebProxy.Credentials = [System.Net.CredentialCache]::DefaultNetworkCredentials

    # Process each URL
    $urlNumber = 0
    $successCount = 0
    $failCount = 0
    
    foreach($Uri in $URLList) {
        $urlNumber++
        Write-Progress -Activity "Checking URLs" -Status "Processing $Uri" -PercentComplete (($urlNumber / $URLList.Count) * 100)
        
        $res = $null
        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
        
        try {
            Log-Message "Checking URL $urlNumber/$($URLList.Count): $Uri"
            
            # Create web request
            $req = [System.Net.WebRequest]::Create($Uri)
            $req.Method = $Method
            $req.Timeout = $TimeoutSeconds * 1000
            
            # Add a proper user agent
            $req.UserAgent = "URL-Checker-Script/5.0"
            
            # For POST method, add minimal content
            if ($Method -eq "POST") {
                $req.ContentType = "application/x-www-form-urlencoded"
                $postData = [System.Text.Encoding]::UTF8.GetBytes("check=true")
                $req.ContentLength = $postData.Length
                $requestStream = $req.GetRequestStream()
                $requestStream.Write($postData, 0, $postData.Length)
                $requestStream.Close()
            }
            
            # Get response
            $res = $req.GetResponse()
            $stopwatch.Stop()
            
            $statusCode = [int]$res.StatusCode
            $statusDescription = $res.StatusDescription
            
            # Write successful result
            Write-Result -URL $Uri -StatusCode $statusCode -StatusDescription $statusDescription -ResponseTime $stopwatch.Elapsed.TotalMilliseconds
            
            Log-Message "Success: $Uri - $statusCode ($($stopwatch.Elapsed.TotalMilliseconds)ms)"
            
            if ($statusCode -ge 200 -and $statusCode -lt 300) {
                $successCount++
            } else {
                $failCount++
            }
            
        } catch {
            $stopwatch.Stop()
            
            $statusCode = $null
            $errorMessage = $_.Exception.Message
            
            # Try to extract status code if available
            if ($_.Exception.Response) {
                $statusCode = [int]$_.Exception.Response.StatusCode
                $statusDescription = $_.Exception.Response.StatusDescription
            }
            
            # Write error result
            Write-Result -URL $Uri -StatusCode $statusCode -ResponseTime $stopwatch.Elapsed.TotalMilliseconds -ErrorMessage $errorMessage
            
            Log-Message "Error: $Uri - $errorMessage" "ERROR"
            $failCount++
            
        } finally {
            # Clean up
            if ($res) {
                $res.Dispose()
            }
        }
    }
    
    Write-Progress -Activity "Checking URLs" -Completed
    
    # End logging and display summary
    Log-Message "Script execution completed successfully. Processed $($URLList.Count) URLs"
    
    Write-Host ""
    Write-Host "Summary"
    Write-Host "======="
    Write-Host "Total URLs processed: $($URLList.Count)"
    Write-Host "Successful: $successCount"
    Write-Host "Failed: $failCount"
    Write-Host ""
    Write-Host "Results saved to: $OutputFile"
    Write-Host "Log saved to: $LogFile"
    Write-Host ""

} catch {
    # Handle fatal errors
    Log-Message "Fatal error: $($_.Exception.Message)" "ERROR"
    Write-Host "Fatal error: $($_.Exception.Message)"
    exit 1

} finally {
    # Reset certificate validation if we changed it
    if ($IgnoreCertErrors) {
        [System.Net.ServicePointManager]::ServerCertificateValidationCallback = $null
    }
}