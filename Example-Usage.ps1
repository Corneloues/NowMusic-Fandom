<#
.SYNOPSIS
    Quick example demonstrating the Fetch-HtmlContent.ps1 script behavior.

.DESCRIPTION
    This script shows example output of the Fetch-HtmlContent.ps1 script
    for documentation purposes.
#>

Write-Host "`n========================================" -ForegroundColor Magenta
Write-Host "  Fetch-HtmlContent.ps1 Example" -ForegroundColor Magenta
Write-Host "========================================`n" -ForegroundColor Magenta

Write-Host "This demonstrates how to use the Fetch-HtmlContent.ps1 script." -ForegroundColor Cyan
Write-Host "`nExample 1: Using Environment Variables" -ForegroundColor Yellow
Write-Host "---------------------------------------" -ForegroundColor Yellow
Write-Host 'export SOURCE_URL="https://en.wikipedia.org/wiki/Music"' -ForegroundColor White
Write-Host 'export TIMEOUT_SECONDS=30' -ForegroundColor White
Write-Host 'pwsh -File Fetch-HtmlContent.ps1' -ForegroundColor White

Write-Host "`nExample 2: Using Command-Line Parameters" -ForegroundColor Yellow
Write-Host "---------------------------------------" -ForegroundColor Yellow
Write-Host '.\Fetch-HtmlContent.ps1 -SourceUrl "https://en.wikipedia.org/wiki/Music" -TimeoutSeconds 30' -ForegroundColor White

Write-Host "`nExample 3: In GitHub Actions Workflow" -ForegroundColor Yellow
Write-Host "---------------------------------------" -ForegroundColor Yellow
Write-Host @"
steps:
  - name: Fetch HTML Content
    env:
      SOURCE_URL: `${{ vars.SOURCE_URL }}
      TIMEOUT_SECONDS: `${{ vars.TIMEOUT_SECONDS }}
    run: pwsh -File Fetch-HtmlContent.ps1
"@ -ForegroundColor White

Write-Host "`n`nExpected Output (Success Case):" -ForegroundColor Yellow
Write-Host "---------------------------------------" -ForegroundColor Yellow
Write-Host @"
[2026-01-12 14:30:00] [Info] === HTML Content Fetcher Started ===
[2026-01-12 14:30:00] [Info] Using SOURCE_URL from environment variable
[2026-01-12 14:30:00] [Info] Using TIMEOUT_SECONDS from environment variable
[2026-01-12 14:30:00] [Info] Attempting to fetch HTML from: https://en.wikipedia.org/wiki/Music
[2026-01-12 14:30:00] [Info] Timeout set to: 30 seconds
[2026-01-12 14:30:00] [Info] URL validation passed
[2026-01-12 14:30:01] [Success] HTTP Status Code: 200
[2026-01-12 14:30:01] [Success] Content received successfully. Size: 256789 characters
[2026-01-12 14:30:01] [Info] === Fetch Complete ===
[2026-01-12 14:30:01] [Success] Successfully fetched HTML content!
[2026-01-12 14:30:01] [Success] Status Code: 200
[2026-01-12 14:30:01] [Success] Content Length: 256789 characters

--- Content Preview (first 500 characters) ---
<!DOCTYPE html>
<html class="client-nojs vector-feature-language-in-header-enabled..." lang="en" dir="ltr">
<head>
<meta charset="UTF-8">
<title>Music - Wikipedia</title>
...
--- End Preview ---

Exit Code: 0
"@ -ForegroundColor Gray

Write-Host "`n`nExpected Output (Error Case - Invalid URL):" -ForegroundColor Yellow
Write-Host "---------------------------------------" -ForegroundColor Yellow
Write-Host @"
[2026-01-12 14:35:00] [Info] === HTML Content Fetcher Started ===
[2026-01-12 14:35:00] [Info] Using SOURCE_URL from environment variable
[2026-01-12 14:35:00] [Info] Using TIMEOUT_SECONDS from environment variable
[2026-01-12 14:35:00] [Info] Attempting to fetch HTML from: not-a-valid-url
[2026-01-12 14:35:00] [Info] Timeout set to: 30 seconds
[2026-01-12 14:35:00] [Error] Unexpected error: Invalid URL format: not-a-valid-url
[2026-01-12 14:35:00] [Error] Error details: System.Exception
[2026-01-12 14:35:00] [Info] === Fetch Complete ===
[2026-01-12 14:35:00] [Error] Failed to fetch HTML content
[2026-01-12 14:35:00] [Error] Error: Unexpected error: Invalid URL format: not-a-valid-url

Exit Code: 1
"@ -ForegroundColor Gray

Write-Host "`n`nExpected Output (Timeout Case):" -ForegroundColor Yellow
Write-Host "---------------------------------------" -ForegroundColor Yellow
Write-Host @"
[2026-01-12 14:40:00] [Info] === HTML Content Fetcher Started ===
[2026-01-12 14:40:00] [Info] Using SOURCE_URL from environment variable
[2026-01-12 14:40:00] [Info] Using TIMEOUT_SECONDS from environment variable
[2026-01-12 14:40:00] [Info] Attempting to fetch HTML from: https://slow-server.example.com
[2026-01-12 14:40:00] [Info] Timeout set to: 5 seconds
[2026-01-12 14:40:00] [Info] URL validation passed
[2026-01-12 14:40:05] [Error] Network error: Request timed out after 5 seconds
[2026-01-12 14:40:05] [Info] === Fetch Complete ===
[2026-01-12 14:40:05] [Error] Failed to fetch HTML content
[2026-01-12 14:40:05] [Error] Error: Network error: Request timed out after 5 seconds

Exit Code: 1
"@ -ForegroundColor Gray

Write-Host "`n========================================" -ForegroundColor Magenta
Write-Host "For more information, see README.md" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Magenta
