<#
.SYNOPSIS
    Fetches HTML content from a specified URL with robust error handling.

.DESCRIPTION
    This script downloads raw HTML content from a wiki URL using environment variables
    for configuration. It includes comprehensive error handling for timeouts, bad status
    codes, and empty results.

.PARAMETER SourceUrl
    The URL to fetch HTML content from. If not provided, uses the SOURCE_URL environment variable.

.PARAMETER TimeoutSeconds
    The timeout in seconds for the HTTP request. If not provided, uses the TIMEOUT_SECONDS environment variable.
    Default is 30 seconds if neither parameter nor environment variable is set.

.EXAMPLE
    .\Fetch-HtmlContent.ps1
    Fetches HTML using environment variables SOURCE_URL and TIMEOUT_SECONDS

.EXAMPLE
    .\Fetch-HtmlContent.ps1 -SourceUrl "https://example.com" -TimeoutSeconds 60
    Fetches HTML from the specified URL with a 60-second timeout

.NOTES
    Author: NowMusic-Fandom Project
    Version: 1.0
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [string]$SourceUrl,
    
    [Parameter(Mandatory=$false)]
    [int]$TimeoutSeconds,
    
    [Parameter(Mandatory=$false)]
    [string]$TargetDivClass
)

# Set strict mode for better error detection
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Configuration - Target div class for extraction
# This can be overridden by the -TargetDivClass parameter or TARGET_DIV_CLASS environment variable
$script:TARGET_DIV_CLASS = "mw-content-ltr mw-parser-output"

function Write-Log {
    <#
    .SYNOPSIS
        Writes a log message with timestamp and severity level.
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$Message,
        
        [Parameter(Mandatory=$false)]
        [ValidateSet('Info', 'Warning', 'Error', 'Success')]
        [string]$Level = 'Info'
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $color = switch ($Level) {
        'Info'    { 'Cyan' }
        'Warning' { 'Yellow' }
        'Error'   { 'Red' }
        'Success' { 'Green' }
    }
    
    Write-Host "[$timestamp] [$Level] $Message" -ForegroundColor $color
}

function Get-HtmlContent {
    <#
    .SYNOPSIS
        Fetches HTML content from a URL with comprehensive error handling.
    
    .DESCRIPTION
        Downloads raw HTML content using Invoke-WebRequest with proper timeout
        handling, status code validation, and content verification.
    
    .PARAMETER Url
        The URL to fetch content from.
    
    .PARAMETER Timeout
        The timeout in seconds for the HTTP request.
    
    .OUTPUTS
        PSCustomObject with properties: Success (bool), Content (string), StatusCode (int), Error (string)
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$Url,
        
        [Parameter(Mandatory=$true)]
        [int]$Timeout
    )
    
    Write-Log "Attempting to fetch HTML from: $Url" -Level Info
    Write-Log "Timeout set to: $Timeout seconds" -Level Info
    
    # Initialize result object
    $result = [PSCustomObject]@{
        Success = $false
        Content = $null
        StatusCode = $null
        Error = $null
        Url = $Url
    }
    
    try {
        # Validate URL format
        if (-not [System.Uri]::IsWellFormedUriString($Url, [System.UriKind]::Absolute)) {
            throw "Invalid URL format: $Url"
        }
        
        Write-Log "URL validation passed" -Level Info
        
        # Perform the web request with timeout
        $response = Invoke-WebRequest -Uri $Url -TimeoutSec $Timeout -UseBasicParsing -ErrorAction Stop
        
        $result.StatusCode = $response.StatusCode
        Write-Log "HTTP Status Code: $($response.StatusCode)" -Level Success
        
        # Validate status code
        if ($response.StatusCode -lt 200 -or $response.StatusCode -ge 300) {
            throw "Bad HTTP status code: $($response.StatusCode)"
        }
        
        # Extract content
        $content = $response.Content
        
        # Validate content is not empty
        if ([string]::IsNullOrWhiteSpace($content)) {
            throw "Received empty content from URL"
        }
        
        Write-Log "Content received successfully. Size: $($content.Length) characters" -Level Success
        
        # Additional validation - check if it looks like HTML (optional validation)
        # Note: This is a heuristic check and may not catch all valid HTML documents
        if ($content -notmatch '(?i)(<html|<!DOCTYPE|<body|<head|<?xml)') {
            Write-Log "Warning: Content may not be HTML (no standard HTML tags detected)" -Level Warning
        }
        
        $result.Success = $true
        $result.Content = $content
        
    } catch [System.Net.WebException] {
        $errorMessage = "Network error: $($_.Exception.Message)"
        
        if ($_.Exception.InnerException -and $_.Exception.InnerException.Message) {
            $errorMessage += " - $($_.Exception.InnerException.Message)"
        }
        
        # Check for specific timeout error
        if ($_.Exception.Message -match 'timeout|timed out') {
            $errorMessage = "Request timed out after $Timeout seconds"
        }
        
        $result.Error = $errorMessage
        Write-Log $errorMessage -Level Error
        
    } catch [Microsoft.PowerShell.Commands.HttpResponseException] {
        $errorMessage = "HTTP error: $($_.Exception.Message)"
        
        if ($_.Exception.Response) {
            $result.StatusCode = [int]$_.Exception.Response.StatusCode
            $errorMessage += " (Status Code: $($result.StatusCode))"
        }
        
        $result.Error = $errorMessage
        Write-Log $errorMessage -Level Error
        
    } catch {
        $errorMessage = "Unexpected error: $($_.Exception.Message)"
        $result.Error = $errorMessage
        Write-Log $errorMessage -Level Error
        Write-Log "Error details: $($_.Exception.GetType().FullName)" -Level Error
    }
    
    return $result
}

function Get-TargetDiv {
    <#
    .SYNOPSIS
        Extracts a specific div from HTML content based on class name.
    
    .DESCRIPTION
        Parses HTML content and extracts the div element with the specified class.
        Uses regex-based parsing for reliability with potentially malformed HTML.
        Implements comprehensive error handling for missing elements and edge cases.
    
    .PARAMETER HtmlContent
        The HTML content to parse.
    
    .PARAMETER TargetDivClass
        The class name of the div to extract. Can contain multiple classes separated by spaces.
    
    .OUTPUTS
        PSCustomObject with properties: Success (bool), Content (string), Error (string)
    
    .EXAMPLE
        Get-TargetDiv -HtmlContent $html -TargetDivClass "mw-content-ltr mw-parser-output"
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$HtmlContent,
        
        [Parameter(Mandatory=$true)]
        [string]$TargetDivClass
    )
    
    Write-Log "Attempting to extract div with class: $TargetDivClass" -Level Info
    
    # Initialize result object
    $result = [PSCustomObject]@{
        Success = $false
        Content = $null
        Error = $null
    }
    
    try {
        # Validate input
        if ([string]::IsNullOrWhiteSpace($HtmlContent)) {
            throw "HTML content is empty or null"
        }
        
        if ([string]::IsNullOrWhiteSpace($TargetDivClass)) {
            throw "Target div class is empty or null"
        }
        
        Write-Log "HTML content size: $($HtmlContent.Length) characters" -Level Info
        
        # Escape special regex characters in class names
        $escapedClasses = ($TargetDivClass -split '\s+') | ForEach-Object { [regex]::Escape($_) }
        
        # Build a regex pattern that matches a div with all specified classes
        # This pattern allows classes in any order and additional classes
        # Example: For "mw-content-ltr mw-parser-output", it creates:
        # (?=.*\bmw-content-ltr\b)(?=.*\bmw-parser-output\b).*?
        $classPatterns = $escapedClasses | ForEach-Object { "(?=.*\b$_\b)" }
        $classPattern = ($classPatterns -join '') + '.*?'
        
        # Pattern to match the opening div tag with the target classes
        # Matches: <div class="..." where class attribute contains all target classes
        # Using verbose construction for clarity
        $divTag = '<div'
        $whitespace = '\s+'
        $anyAttrs = '[^>]*'
        $classAttr = 'class\s*=\s*'
        $quote = '["' + "']"  # Matches both " and '
        $endTag = '>'
        
        $openDivPattern = $divTag + $whitespace + $anyAttrs + $classAttr + $quote + $classPattern + $quote + $anyAttrs + $endTag
        
        Write-Log "Searching for div with regex pattern" -Level Info
        
        # Find all opening div tags that match
        $matches = [regex]::Matches($HtmlContent, $openDivPattern, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
        
        if ($matches.Count -eq 0) {
            throw "No div found with class: $TargetDivClass"
        }
        
        if ($matches.Count -gt 1) {
            Write-Log "Warning: Found $($matches.Count) divs with the target class. Extracting the first one." -Level Warning
        }
        
        # Get the position of the first match
        $startPos = $matches[0].Index
        $openingTag = $matches[0].Value
        
        Write-Log "Found opening div tag at position $startPos" -Level Info
        
        # Now we need to find the matching closing </div> tag
        # We'll count opening and closing div tags to handle nested divs
        $divCount = 1
        $currentPos = $startPos + $openingTag.Length
        $endPos = -1
        
        # Scan through the HTML to find the matching closing tag
        while ($currentPos -lt $HtmlContent.Length -and $divCount -gt 0) {
            # Look for next div tag (opening or closing)
            # Opening divs can be: <div>, <div , <div\t, <div\n, <div>
            # We need to find '<div' followed by whitespace, '>', or another attribute character
            $nextOpenDiv = -1
            $searchPos = $currentPos
            while ($searchPos -lt $HtmlContent.Length) {
                $tempPos = $HtmlContent.IndexOf('<div', $searchPos, [System.StringComparison]::OrdinalIgnoreCase)
                if ($tempPos -eq -1) {
                    break
                }
                # Check if the next character after '<div' is valid (whitespace, '>', or end of string)
                if ($tempPos + 4 -ge $HtmlContent.Length) {
                    # End of content, this is valid
                    $nextOpenDiv = $tempPos
                    break
                }
                $nextChar = $HtmlContent[$tempPos + 4]
                if ($nextChar -match '[\s>]') {
                    # Valid opening div tag
                    $nextOpenDiv = $tempPos
                    break
                }
                # Not a valid div tag, continue searching
                $searchPos = $tempPos + 4
            }
            
            $nextCloseDiv = $HtmlContent.IndexOf('</div>', $currentPos, [System.StringComparison]::OrdinalIgnoreCase)
            
            # If no more closing divs found, the HTML is malformed
            if ($nextCloseDiv -eq -1) {
                throw "Malformed HTML: No matching closing </div> tag found"
            }
            
            # Determine which comes first
            if ($nextOpenDiv -ne -1 -and $nextOpenDiv -lt $nextCloseDiv) {
                # Found another opening div before the closing one
                $divCount++
                $currentPos = $nextOpenDiv + 4  # Move past '<div'
            } else {
                # Found a closing div
                $divCount--
                if ($divCount -eq 0) {
                    # This is our matching closing tag
                    $endPos = $nextCloseDiv + 6  # Include '</div>'
                } else {
                    $currentPos = $nextCloseDiv + 6  # Move past '</div>'
                }
            }
        }
        
        if ($endPos -eq -1) {
            throw "Could not find matching closing tag for div"
        }
        
        # Extract the div content
        $divContent = $HtmlContent.Substring($startPos, $endPos - $startPos)
        
        # Validate extracted content
        if ([string]::IsNullOrWhiteSpace($divContent)) {
            throw "Extracted div content is empty"
        }
        
        Write-Log "Successfully extracted div. Size: $($divContent.Length) characters" -Level Success
        
        $result.Success = $true
        $result.Content = $divContent
        
    } catch {
        $errorMessage = "Error extracting div: $($_.Exception.Message)"
        $result.Error = $errorMessage
        Write-Log $errorMessage -Level Error
    }
    
    return $result
}

# Main execution block
try {
    Write-Log "=== HTML Content Fetcher Started ===" -Level Info
    
    # Get configuration from parameters or environment variables
    if ([string]::IsNullOrWhiteSpace($SourceUrl)) {
        $SourceUrl = $env:SOURCE_URL
        if ([string]::IsNullOrWhiteSpace($SourceUrl)) {
            throw "SOURCE_URL is not provided. Please set the SOURCE_URL environment variable or pass -SourceUrl parameter."
        }
        Write-Log "Using SOURCE_URL from environment variable" -Level Info
    } else {
        Write-Log "Using SOURCE_URL from parameter" -Level Info
    }
    
    if ($TimeoutSeconds -eq 0) {
        if ($env:TIMEOUT_SECONDS) {
            $TimeoutSeconds = [int]$env:TIMEOUT_SECONDS
            Write-Log "Using TIMEOUT_SECONDS from environment variable" -Level Info
        } else {
            $TimeoutSeconds = 30
            Write-Log "Using default timeout of 30 seconds" -Level Warning
        }
    } else {
        Write-Log "Using TIMEOUT_SECONDS from parameter" -Level Info
    }
    
    # Validate timeout value
    if ($TimeoutSeconds -le 0) {
        throw "TIMEOUT_SECONDS must be a positive integer. Got: $TimeoutSeconds"
    }
    
    # Get TargetDivClass from parameter, environment variable, or use default
    if ([string]::IsNullOrWhiteSpace($TargetDivClass)) {
        if ($env:TARGET_DIV_CLASS) {
            $TargetDivClass = $env:TARGET_DIV_CLASS
            Write-Log "Using TARGET_DIV_CLASS from environment variable" -Level Info
        } else {
            $TargetDivClass = $script:TARGET_DIV_CLASS
            Write-Log "Using default TARGET_DIV_CLASS: $TargetDivClass" -Level Info
        }
    } else {
        Write-Log "Using TARGET_DIV_CLASS from parameter" -Level Info
    }
    
    # Fetch the HTML content
    $result = Get-HtmlContent -Url $SourceUrl -Timeout $TimeoutSeconds
    
    # Display results
    Write-Log "=== Fetch Complete ===" -Level Info
    
    if ($result.Success) {
        Write-Log "Successfully fetched HTML content!" -Level Success
        Write-Log "Status Code: $($result.StatusCode)" -Level Success
        Write-Log "Content Length: $($result.Content.Length) characters" -Level Success
        
        # Extract target div from the fetched HTML
        Write-Log "`n=== Extracting Target Div ===" -Level Info
        $divResult = Get-TargetDiv -HtmlContent $result.Content -TargetDivClass $TargetDivClass
        
        if ($divResult.Success) {
            Write-Log "Successfully extracted target div!" -Level Success
            Write-Log "Extracted Content Length: $($divResult.Content.Length) characters" -Level Success
            
            # Display first 500 characters of extracted content as preview
            Write-Log "`n--- Extracted Content Preview (first 500 characters) ---" -Level Info
            $preview = $divResult.Content.Substring(0, [Math]::Min(500, $divResult.Content.Length))
            Write-Host $preview
            Write-Log "--- End Preview ---`n" -Level Info
            
            # Return success exit code
            exit 0
        } else {
            Write-Log "Failed to extract target div" -Level Error
            Write-Log "Error: $($divResult.Error)" -Level Error
            Write-Log "Falling back to full HTML content preview" -Level Warning
            
            # Display first 500 characters of full HTML as fallback
            Write-Log "`n--- Full HTML Content Preview (first 500 characters) ---" -Level Info
            $preview = $result.Content.Substring(0, [Math]::Min(500, $result.Content.Length))
            Write-Host $preview
            Write-Log "--- End Preview ---`n" -Level Info
            
            # Return error exit code since div extraction failed
            exit 1
        }
        
    } else {
        Write-Log "Failed to fetch HTML content" -Level Error
        Write-Log "Error: $($result.Error)" -Level Error
        
        if ($result.StatusCode) {
            Write-Log "Status Code: $($result.StatusCode)" -Level Error
        }
        
        # Return error exit code
        exit 1
    }
    
} catch {
    Write-Log "Fatal error: $($_.Exception.Message)" -Level Error
    Write-Log "Stack trace: $($_.ScriptStackTrace)" -Level Error
    exit 1
}
