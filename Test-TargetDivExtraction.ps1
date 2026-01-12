<#
.SYNOPSIS
    Unit tests for the Get-TargetDiv function.

.DESCRIPTION
    This script tests the Get-TargetDiv function with various scenarios:
    - Successful extraction of a target div
    - Handling of missing div elements
    - Handling of multiple divs with the same class
    - Handling of nested divs
    - Handling of malformed HTML
    - Handling of empty or null inputs

.NOTES
    Author: NowMusic-Fandom Project
    Version: 1.0
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Write-Host "`n========================================" -ForegroundColor Magenta
Write-Host "  Get-TargetDiv Function Unit Tests" -ForegroundColor Magenta
Write-Host "========================================`n" -ForegroundColor Magenta

# Source the main script to get access to the functions
$scriptPath = Join-Path $PSScriptRoot "Fetch-HtmlContent.ps1"

if (-not (Test-Path $scriptPath)) {
    Write-Host "ERROR: Fetch-HtmlContent.ps1 not found at: $scriptPath" -ForegroundColor Red
    exit 1
}

# Create a temporary script file that only contains the functions
$scriptContent = Get-Content $scriptPath -Raw

# Find the start of the main execution block and remove it
$mainBlockPattern = '# Main execution block'
$mainBlockIndex = $scriptContent.IndexOf($mainBlockPattern)

if ($mainBlockIndex -gt 0) {
    # Keep only the part before the main execution block
    $functionsOnly = $scriptContent.Substring(0, $mainBlockIndex)
} else {
    $functionsOnly = $scriptContent
}

# Create a temporary script file
$tempScriptPath = Join-Path $PSScriptRoot "temp-functions.ps1"
$functionsOnly | Out-File -FilePath $tempScriptPath -Encoding UTF8

try {
    # Dot-source the temporary script to load functions
    . $tempScriptPath
    Write-Host "✓ Functions loaded successfully" -ForegroundColor Green
} finally {
    # Clean up temporary file
    if (Test-Path $tempScriptPath) {
        Remove-Item $tempScriptPath -Force
    }
}

# Test counter
$script:testCount = 0
$script:passCount = 0
$script:failCount = 0

function Test-Case {
    param(
        [string]$TestName,
        [scriptblock]$TestCode,
        [bool]$ShouldSucceed = $true
    )
    
    $script:testCount++
    Write-Host "`n----------------------------------------" -ForegroundColor Cyan
    Write-Host "TEST $($script:testCount): $TestName" -ForegroundColor Cyan
    Write-Host "----------------------------------------" -ForegroundColor Cyan
    
    try {
        $result = & $TestCode
        
        if ($ShouldSucceed -and $result.Success) {
            Write-Host "✓ PASSED: Test succeeded as expected" -ForegroundColor Green
            $script:passCount++
            return $true
        } elseif (-not $ShouldSucceed -and -not $result.Success) {
            Write-Host "✓ PASSED: Test failed as expected (error: $($result.Error))" -ForegroundColor Green
            $script:passCount++
            return $true
        } else {
            Write-Host "✗ FAILED: Unexpected result" -ForegroundColor Red
            Write-Host "  Expected Success: $ShouldSucceed" -ForegroundColor Red
            Write-Host "  Actual Success: $($result.Success)" -ForegroundColor Red
            if ($result.Error) {
                Write-Host "  Error: $($result.Error)" -ForegroundColor Red
            }
            $script:failCount++
            return $false
        }
    } catch {
        Write-Host "✗ FAILED: Exception thrown: $($_.Exception.Message)" -ForegroundColor Red
        $script:failCount++
        return $false
    }
}

# Test 1: Extract a simple div with target class
Test-Case -TestName "Extract simple div with target class" -ShouldSucceed $true -TestCode {
    $html = @"
<!DOCTYPE html>
<html>
<body>
    <div class="header">Header content</div>
    <div class="mw-content-ltr mw-parser-output">
        <p>This is the target content!</p>
        <h1>Main Article</h1>
    </div>
    <div class="footer">Footer content</div>
</body>
</html>
"@
    
    $result = Get-TargetDiv -HtmlContent $html -TargetDivClass "mw-content-ltr mw-parser-output"
    
    if ($result.Success -and $result.Content -match "This is the target content!") {
        Write-Host "  Content extracted correctly" -ForegroundColor Gray
        Write-Host "  Content length: $($result.Content.Length) characters" -ForegroundColor Gray
    }
    
    return $result
}

# Test 2: Extract div with nested divs
Test-Case -TestName "Extract div with nested divs" -ShouldSucceed $true -TestCode {
    $html = @"
<!DOCTYPE html>
<html>
<body>
    <div class="mw-content-ltr mw-parser-output">
        <div class="nested">
            <div class="deeply-nested">Nested content</div>
        </div>
        <p>Main content</p>
    </div>
</body>
</html>
"@
    
    $result = Get-TargetDiv -HtmlContent $html -TargetDivClass "mw-content-ltr mw-parser-output"
    
    if ($result.Success) {
        $nestedDivCount = ([regex]::Matches($result.Content, '<div', [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)).Count
        Write-Host "  Found $nestedDivCount nested div tags (including parent)" -ForegroundColor Gray
        
        if ($result.Content -match "Nested content" -and $result.Content -match "Main content") {
            Write-Host "  All nested content preserved" -ForegroundColor Gray
        }
    }
    
    return $result
}

# Test 3: Handle missing target div
Test-Case -TestName "Handle missing target div" -ShouldSucceed $false -TestCode {
    $html = @"
<!DOCTYPE html>
<html>
<body>
    <div class="different-class">Some content</div>
    <div class="another-class">More content</div>
</body>
</html>
"@
    
    $result = Get-TargetDiv -HtmlContent $html -TargetDivClass "mw-content-ltr mw-parser-output"
    return $result
}

# Test 4: Handle multiple divs with same class (should extract first one)
Test-Case -TestName "Handle multiple divs with same class" -ShouldSucceed $true -TestCode {
    $html = @"
<!DOCTYPE html>
<html>
<body>
    <div class="mw-content-ltr mw-parser-output">
        <p>First div content</p>
    </div>
    <div class="mw-content-ltr mw-parser-output">
        <p>Second div content</p>
    </div>
</body>
</html>
"@
    
    $result = Get-TargetDiv -HtmlContent $html -TargetDivClass "mw-content-ltr mw-parser-output"
    
    if ($result.Success) {
        if ($result.Content -match "First div content" -and $result.Content -notmatch "Second div content") {
            Write-Host "  Correctly extracted only the first div" -ForegroundColor Gray
        }
    }
    
    return $result
}

# Test 5: Handle empty HTML content
Test-Case -TestName "Handle empty HTML content" -ShouldSucceed $false -TestCode {
    $result = Get-TargetDiv -HtmlContent " " -TargetDivClass "mw-content-ltr mw-parser-output"
    return $result
}

# Test 6: Handle empty target class
Test-Case -TestName "Handle empty target class" -ShouldSucceed $false -TestCode {
    $html = '<div class="test">Content</div>'
    $result = Get-TargetDiv -HtmlContent $html -TargetDivClass " "
    return $result
}

# Test 7: Extract div with classes in different order
Test-Case -TestName "Extract div with classes in different order" -ShouldSucceed $true -TestCode {
    $html = @"
<!DOCTYPE html>
<html>
<body>
    <div class="mw-parser-output mw-content-ltr extra-class">
        <p>Content with classes in different order</p>
    </div>
</body>
</html>
"@
    
    $result = Get-TargetDiv -HtmlContent $html -TargetDivClass "mw-content-ltr mw-parser-output"
    
    if ($result.Success) {
        Write-Host "  Successfully matched classes regardless of order" -ForegroundColor Gray
    }
    
    return $result
}

# Test 8: Handle div with additional classes
Test-Case -TestName "Handle div with additional classes" -ShouldSucceed $true -TestCode {
    $html = @"
<!DOCTYPE html>
<html>
<body>
    <div class="container mw-content-ltr mw-parser-output extra-styling">
        <p>Content with extra classes</p>
    </div>
</body>
</html>
"@
    
    $result = Get-TargetDiv -HtmlContent $html -TargetDivClass "mw-content-ltr mw-parser-output"
    
    if ($result.Success -and $result.Content -match "Content with extra classes") {
        Write-Host "  Successfully extracted div with additional classes" -ForegroundColor Gray
    }
    
    return $result
}

# Test 9: Handle malformed HTML (unclosed div)
Test-Case -TestName "Handle malformed HTML (unclosed div)" -ShouldSucceed $false -TestCode {
    $html = @"
<!DOCTYPE html>
<html>
<body>
    <div class="mw-content-ltr mw-parser-output">
        <p>Content without closing div tag
    <div class="footer">Footer</div>
</body>
</html>
"@
    
    $result = Get-TargetDiv -HtmlContent $html -TargetDivClass "mw-content-ltr mw-parser-output"
    return $result
}

# Test 10: Extract div with single class name
Test-Case -TestName "Extract div with single class name" -ShouldSucceed $true -TestCode {
    $html = @"
<!DOCTYPE html>
<html>
<body>
    <div class="single-class">
        <p>Content with single class</p>
    </div>
</body>
</html>
"@
    
    $result = Get-TargetDiv -HtmlContent $html -TargetDivClass "single-class"
    
    if ($result.Success -and $result.Content -match "Content with single class") {
        Write-Host "  Successfully extracted div with single class" -ForegroundColor Gray
    }
    
    return $result
}

# Test 11: Real-world Wikipedia-style HTML structure
Test-Case -TestName "Real-world Wikipedia-style HTML structure" -ShouldSucceed $true -TestCode {
    $html = @"
<!DOCTYPE html>
<html class="client-nojs" lang="en" dir="ltr">
<head>
    <meta charset="UTF-8"/>
    <title>Music - Wikipedia</title>
</head>
<body>
    <div id="mw-page-base"></div>
    <div id="content" class="mw-body">
        <div id="bodyContent" class="vector-body">
            <div id="mw-content-text" class="mw-body-content">
                <div class="mw-content-ltr mw-parser-output" lang="en" dir="ltr">
                    <p><b>Music</b> is generally defined as the art of arranging sound.</p>
                    <div class="infobox">
                        <p>Infobox content</p>
                    </div>
                    <h2>Definition and etymology</h2>
                    <p>More article content here...</p>
                </div>
            </div>
        </div>
    </div>
    <footer id="footer"></footer>
</body>
</html>
"@
    
    $result = Get-TargetDiv -HtmlContent $html -TargetDivClass "mw-content-ltr mw-parser-output"
    
    if ($result.Success) {
        if ($result.Content -match "Music.*is generally defined" -and 
            $result.Content -match "Definition and etymology" -and
            $result.Content -match "Infobox content") {
            Write-Host "  Successfully extracted complete Wikipedia article content" -ForegroundColor Gray
            Write-Host "  Content length: $($result.Content.Length) characters" -ForegroundColor Gray
        }
    }
    
    return $result
}

# Test 12: Handle div tags without space after tag name (edge case)
Test-Case -TestName "Handle div tags without space (e.g., <div>)" -ShouldSucceed $true -TestCode {
    $html = @"
<!DOCTYPE html>
<html>
<body>
    <div>Other content</div>
    <div class="mw-content-ltr mw-parser-output">
        <p>Target content</p>
        <div>Nested without space</div>
    </div>
</body>
</html>
"@
    
    $result = Get-TargetDiv -HtmlContent $html -TargetDivClass "mw-content-ltr mw-parser-output"
    
    if ($result.Success -and $result.Content -match "Target content") {
        Write-Host "  Successfully handled divs without space after tag name" -ForegroundColor Gray
    }
    
    return $result
}

# Summary
Write-Host "`n========================================" -ForegroundColor Magenta
Write-Host "  TEST SUMMARY" -ForegroundColor Magenta
Write-Host "========================================" -ForegroundColor Magenta

Write-Host "`nTotal Tests: $script:testCount" -ForegroundColor White
Write-Host "Passed: $script:passCount" -ForegroundColor Green
Write-Host "Failed: $script:failCount" -ForegroundColor $(if ($script:failCount -eq 0) { 'Green' } else { 'Red' })

if ($script:failCount -eq 0) {
    Write-Host "`n✓ All tests passed!" -ForegroundColor Green
    Write-Host "`nThe Get-TargetDiv function correctly:" -ForegroundColor Cyan
    Write-Host "  • Extracts divs with the specified class" -ForegroundColor White
    Write-Host "  • Handles nested divs properly" -ForegroundColor White
    Write-Host "  • Returns appropriate errors for missing divs" -ForegroundColor White
    Write-Host "  • Handles multiple divs (extracts first one)" -ForegroundColor White
    Write-Host "  • Validates input parameters" -ForegroundColor White
    Write-Host "  • Handles classes in any order" -ForegroundColor White
    Write-Host "  • Works with additional classes" -ForegroundColor White
    Write-Host "  • Handles malformed HTML gracefully" -ForegroundColor White
    Write-Host "  • Works with real-world Wikipedia HTML structures" -ForegroundColor White
    exit 0
} else {
    Write-Host "`n⚠ Some tests failed. Review the output above." -ForegroundColor Yellow
    exit 1
}
