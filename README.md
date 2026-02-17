# url-check
Robust and simple PowerShell script to check the accessibility and response time of web URLs.

A lightweight PowerShell script for monitoring website availability and response times. Perfect for system administrators and DevOps professionals who need to validate endpoint accessibility.

## ✨ Features

- **HTTP Method Support** - GET, HEAD, and POST requests
- **Response Time Measurement** - Track performance metrics
- **Certificate Validation** - Option to ignore SSL/TLS errors
- **Proxy Awareness** - Automatic system proxy integration
- **Comprehensive Logging** - Timestamped execution logs
- **Structured Output** - CSV format for easy analysis
- **Zero Configuration** - Auto-creates required files and folders
- **No Admin Rights** - Runs with standard user permissions

📋 Prerequisites
Windows PowerShell 3.0 or higher
Internet connectivity (for external URL checks)
No administrative privileges required

## 📝 Usage
# Quick Health Check (HEAD Method)
.\url-check.ps1 -Method HEAD
# Ignore Certificate Errors
.\url-check.ps1 -IgnoreCertErrors
# Custom Timeout
.\url-check.ps1 -TimeoutSeconds 15
# Combine Parameters
.\url-check.ps1 -Method HEAD -IgnoreCertErrors -TimeoutSeconds 10

## ⚙️ Parameters
| Parameter |	Description	| Default |
|-----------|-------------|---------|
| -URLListFile |	Path to URL list file	| .\URLList.txt |
| -OutputFile	| Path for CSV results	| .\results\URL-Check-Results_*.csv |
| -LogFile	| Path for log file	| .\results\url-check-log_*.txt |
| -Method	| HTTP method (GET, HEAD, POST)	| GET |
| -IgnoreCertErrors	| Bypass SSL certificate validation	| False |
| -TimeoutSeconds	| Request timeout in seconds	| 30 |

## 📊 Output Format
# URL List Template (URLList.txt)
TXT
# Add one URL per line (include http:// or https://)
# Lines starting with # are ignored
https://www.google.com
https://github.com
https://api.github.com/zen
# CSV Results (results\URL-Check-Results_*.csv)
CSV
Timestamp,URL,Method,StatusCode,StatusDescription,ResponseTimeMs,ErrorMessage,IgnoreCertErrors
2025-02-17 14:30:45,https://google.com,GET,200,OK,125.45,,False
2025-02-17 14:30:46,https://nonexistent.site,GET,N/A,Error,5000.00,The remote name could not be resolved,False
# Log File (results\url-check-log_*.txt)
TXT
2025-02-17 14:30:45 [INFO] - Script execution started. Method: GET, Timeout: 30s
2025-02-17 14:30:45 [INFO] - Success: https://google.com - 200 (125.45ms)
2025-02-17 14:30:46 [ERROR] - Error: https://nonexistent.site - The remote name could not be resolved

## Version History
| Version	| Date	| Changes |
|---------|-------|---------|
| v1.0.5	| 2025-02-17	| Enhanced with response time, HTTP methods, certificate validation |
| v1.0.4	| 2025-02-10	| Added proxy support and improved error handling |
| v1.0.3	| 2025-01-15	| Enhanced logging and error recovery |
| v1.0.2	| 2025-01-10	| Added comprehensive logging |
| v1.0.1	| 2025-01-05	| Initial public release |

