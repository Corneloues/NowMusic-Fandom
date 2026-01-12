<#
.SYNOPSIS
    Demo script to test the Fetch-HtmlContent.ps1 functionality.

.DESCRIPTION
    This script demonstrates various scenarios for fetching HTML content:
    - Successful fetch from a valid URL
    - Handling of timeout scenarios
    - Handling of invalid URLs
    - Handling of bad status codes

.NOTES
    Author: NowMusic-Fandom Project
    Version: 1.0
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Continue'  # Continue to run all tests

Write-Host "`n========================================" -ForegroundColor Magenta
Write-Host "  HTML Content Fetcher - Demo Script" -ForegroundColor Magenta
Write-Host "========================================`n" -ForegroundColor Magenta

$scriptPath = Join-Path $PSScriptRoot "Fetch-HtmlContent.ps1"

if (-not (Test-Path $scriptPath)) {
    Write-Host "ERROR: Fetch-HtmlContent.ps1 not found at: $scriptPath" -ForegroundColor Red
    exit 1
}

function Run-Test {
    param(
        [string]$TestName,
        [string]$Url,
        [int]$Timeout,
        [bool]$ExpectSuccess
    )
    
    Write-Host "`n----------------------------------------" -ForegroundColor Cyan
    Write-Host "TEST: $TestName" -ForegroundColor Cyan
    Write-Host "----------------------------------------" -ForegroundColor Cyan
    Write-Host "URL: $Url"
    Write-Host "Timeout: $Timeout seconds"
    Write-Host "Expected: $(if ($ExpectSuccess) { 'SUCCESS' } else { 'FAILURE' })`n"
    
    # Set environment variables
    $env:SOURCE_URL = $Url
    $env:TIMEOUT_SECONDS = $Timeout
    
    # Run the script
    $startTime = Get-Date
    & pwsh -File $scriptPath
    $exitCode = $LASTEXITCODE
    $duration = ((Get-Date) - $startTime).TotalSeconds
    
    Write-Host "`nTest Duration: $([math]::Round($duration, 2)) seconds"
    Write-Host "Exit Code: $exitCode"
    
    $testPassed = ($ExpectSuccess -and $exitCode -eq 0) -or (-not $ExpectSuccess -and $exitCode -ne 0)
    
    if ($testPassed) {
        Write-Host "TEST RESULT: PASSED ✓" -ForegroundColor Green
    } else {
        Write-Host "TEST RESULT: FAILED ✗" -ForegroundColor Red
    }
    
    return $testPassed
}

# Track test results
$testResults = @()

# Test 1: Successful fetch from a reliable website
$testResults += Run-Test `
    -TestName "Test 1: Fetch from a valid URL (example.com)" `
    -Url "https://example.com" `
    -Timeout 30 `
    -ExpectSuccess $true

# Test 2: Invalid URL format
$testResults += Run-Test `
    -TestName "Test 2: Invalid URL format" `
    -Url "not-a-valid-url" `
    -Timeout 10 `
    -ExpectSuccess $false

# Test 3: Non-existent domain
$testResults += Run-Test `
    -TestName "Test 3: Non-existent domain" `
    -Url "https://this-domain-definitely-does-not-exist-12345.com" `
    -Timeout 10 `
    -ExpectSuccess $false

# Test 4: Fetch from Wikipedia (more realistic wiki scenario)
$testResults += Run-Test `
    -TestName "Test 4: Fetch from Wikipedia page" `
    -Url "https://en.wikipedia.org/wiki/Main_Page" `
    -Timeout 30 `
    -ExpectSuccess $true

# Test 5: 404 Not Found
# Note: This test depends on the external service httpstat.us
# In environments without internet access, this test will fail
$testResults += Run-Test `
    -TestName "Test 5: 404 Not Found error (requires internet)" `
    -Url "https://httpstat.us/404" `
    -Timeout 30 `
    -ExpectSuccess $false

# Test 6: Very short timeout (should timeout on slow networks)
Write-Host "`n----------------------------------------" -ForegroundColor Cyan
Write-Host "TEST: Test 6: Very short timeout (1 second)" -ForegroundColor Cyan
Write-Host "----------------------------------------" -ForegroundColor Cyan
Write-Host "Note: This test may pass or fail depending on network speed"
Write-Host "URL: https://example.com"
Write-Host "Timeout: 1 second`n"

$env:SOURCE_URL = "https://example.com"
$env:TIMEOUT_SECONDS = 1
& pwsh -File $scriptPath
$exitCode = $LASTEXITCODE
Write-Host "`nExit Code: $exitCode"
Write-Host "TEST RESULT: Completed (pass/fail depends on network)" -ForegroundColor Yellow

# Summary
Write-Host "`n========================================"  -ForegroundColor Magenta
Write-Host "  TEST SUMMARY" -ForegroundColor Magenta
Write-Host "========================================" -ForegroundColor Magenta

$passedCount = ($testResults | Where-Object { $_ -eq $true }).Count
$totalCount = $testResults.Count

Write-Host "Passed: $passedCount / $totalCount" -ForegroundColor $(if ($passedCount -eq $totalCount) { 'Green' } else { 'Yellow' })

if ($passedCount -eq $totalCount) {
    Write-Host "`n✓ All tests passed!" -ForegroundColor Green
    exit 0
} else {
    Write-Host "`n⚠ Some tests failed. Review the output above." -ForegroundColor Yellow
    exit 1
}
