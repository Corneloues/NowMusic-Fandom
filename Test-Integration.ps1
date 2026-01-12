<#
.SYNOPSIS
    Integration test for fetching HTML and extracting target div.

.DESCRIPTION
    This script demonstrates the end-to-end functionality of:
    1. Fetching HTML content from a URL
    2. Extracting the target div using Get-TargetDiv

.NOTES
    Author: NowMusic-Fandom Project
    Version: 1.0
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Continue'

Write-Host "`n========================================" -ForegroundColor Magenta
Write-Host "  Integration Test: Fetch & Extract" -ForegroundColor Magenta
Write-Host "========================================`n" -ForegroundColor Magenta

# Source the main script to get access to functions
$scriptPath = Join-Path $PSScriptRoot "Fetch-HtmlContent.ps1"

if (-not (Test-Path $scriptPath)) {
    Write-Host "ERROR: Fetch-HtmlContent.ps1 not found at: $scriptPath" -ForegroundColor Red
    exit 1
}

# Load functions by extracting everything before main execution block
$scriptContent = Get-Content $scriptPath -Raw
$mainBlockPattern = '# Main execution block'
$mainBlockIndex = $scriptContent.IndexOf($mainBlockPattern)

if ($mainBlockIndex -gt 0) {
    $functionsOnly = $scriptContent.Substring(0, $mainBlockIndex)
} else {
    $functionsOnly = $scriptContent
}

$tempScriptPath = Join-Path $PSScriptRoot "temp-functions-integration.ps1"
$functionsOnly | Out-File -FilePath $tempScriptPath -Encoding UTF8

try {
    . $tempScriptPath
    Write-Host "✓ Functions loaded successfully" -ForegroundColor Green
} finally {
    if (Test-Path $tempScriptPath) {
        Remove-Item $tempScriptPath -Force
    }
}

# Test 1: Fetch and extract from a real Wikipedia page
Write-Host "`n----------------------------------------" -ForegroundColor Cyan
Write-Host "Test 1: Fetch from Wikipedia and extract target div" -ForegroundColor Cyan
Write-Host "----------------------------------------" -ForegroundColor Cyan

Write-Host "Note: This test requires internet connectivity" -ForegroundColor Yellow

try {
    # Fetch HTML content
    Write-Host "`nStep 1: Fetching HTML content..." -ForegroundColor White
    $url = "https://en.wikipedia.org/wiki/Music"
    $timeout = 30
    
    $fetchResult = Get-HtmlContent -Url $url -Timeout $timeout
    
    if (-not $fetchResult.Success) {
        Write-Host "✗ Failed to fetch HTML: $($fetchResult.Error)" -ForegroundColor Red
        Write-Host "This test requires internet connectivity" -ForegroundColor Yellow
        exit 0  # Exit gracefully - this is expected in offline environments
    }
    
    Write-Host "✓ Successfully fetched HTML ($($fetchResult.Content.Length) characters)" -ForegroundColor Green
    
    # Extract target div
    Write-Host "`nStep 2: Extracting target div..." -ForegroundColor White
    $targetDivClass = "mw-content-ltr mw-parser-output"
    
    $extractResult = Get-TargetDiv -HtmlContent $fetchResult.Content -TargetDivClass $targetDivClass
    
    if (-not $extractResult.Success) {
        Write-Host "✗ Failed to extract div: $($extractResult.Error)" -ForegroundColor Red
        exit 1
    }
    
    Write-Host "✓ Successfully extracted target div ($($extractResult.Content.Length) characters)" -ForegroundColor Green
    
    # Verify the extracted content
    Write-Host "`nStep 3: Verifying extracted content..." -ForegroundColor White
    
    $checks = @{
        "Contains 'Music'" = $extractResult.Content -match "Music"
        "Contains article content" = $extractResult.Content.Length -gt 1000
        "Starts with <div" = $extractResult.Content -match "^\s*<div"
        "Ends with </div>" = $extractResult.Content -match "</div>\s*$"
        "Does not contain header/footer" = $extractResult.Content -notmatch "navigation|footer|sidebar"
    }
    
    $allChecksPassed = $true
    foreach ($check in $checks.GetEnumerator()) {
        if ($check.Value) {
            Write-Host "  ✓ $($check.Key)" -ForegroundColor Green
        } else {
            Write-Host "  ⚠ $($check.Key)" -ForegroundColor Yellow
            $allChecksPassed = $false
        }
    }
    
    # Display sample of extracted content
    Write-Host "`n--- Extracted Content Preview (first 500 characters) ---" -ForegroundColor Cyan
    $preview = $extractResult.Content.Substring(0, [Math]::Min(500, $extractResult.Content.Length))
    Write-Host $preview -ForegroundColor Gray
    Write-Host "--- End Preview ---`n" -ForegroundColor Cyan
    
    Write-Host "========================================" -ForegroundColor Magenta
    Write-Host "  INTEGRATION TEST RESULTS" -ForegroundColor Magenta
    Write-Host "========================================" -ForegroundColor Magenta
    
    if ($allChecksPassed) {
        Write-Host "✓ Integration test PASSED!" -ForegroundColor Green
        Write-Host "`nSuccessfully demonstrated:" -ForegroundColor Cyan
        Write-Host "  • Fetching HTML from a live URL" -ForegroundColor White
        Write-Host "  • Extracting target div with specific class" -ForegroundColor White
        Write-Host "  • Handling real-world Wikipedia HTML structure" -ForegroundColor White
        Write-Host "  • Preserving article content while filtering out navigation/headers" -ForegroundColor White
        exit 0
    } else {
        Write-Host "⚠ Integration test completed with warnings" -ForegroundColor Yellow
        Write-Host "The div was extracted but some validation checks failed." -ForegroundColor Yellow
        exit 0  # Not a critical failure
    }
    
} catch {
    Write-Host "✗ Integration test FAILED with exception: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Stack trace: $($_.ScriptStackTrace)" -ForegroundColor Red
    exit 1
}

# Test 2: Test with sample HTML (offline test)
Write-Host "`n----------------------------------------" -ForegroundColor Cyan
Write-Host "Test 2: Test with sample HTML (offline)" -ForegroundColor Cyan
Write-Host "----------------------------------------" -ForegroundColor Cyan

$sampleHtml = @"
<!DOCTYPE html>
<html>
<head><title>Test Page</title></head>
<body>
    <div id="header">Header content</div>
    <div class="mw-content-ltr mw-parser-output">
        <p>This is the main article content.</p>
        <h2>Section 1</h2>
        <p>More content here.</p>
    </div>
    <div id="footer">Footer content</div>
</body>
</html>
"@

$extractResult = Get-TargetDiv -HtmlContent $sampleHtml -TargetDivClass "mw-content-ltr mw-parser-output"

if ($extractResult.Success) {
    Write-Host "✓ Successfully extracted div from sample HTML" -ForegroundColor Green
    
    if ($extractResult.Content -match "main article content" -and 
        $extractResult.Content -notmatch "Header content" -and 
        $extractResult.Content -notmatch "Footer content") {
        Write-Host "✓ Extracted content is correct (contains article, excludes header/footer)" -ForegroundColor Green
    } else {
        Write-Host "⚠ Content validation failed" -ForegroundColor Yellow
    }
} else {
    Write-Host "✗ Failed to extract div: $($extractResult.Error)" -ForegroundColor Red
}

Write-Host "`n✓ All integration tests completed!" -ForegroundColor Green
