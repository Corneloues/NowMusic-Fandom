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
    [int]$TimeoutSeconds
)

# Set strict mode for better error detection
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

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
        
        # Additional validation - check if it looks like HTML
        if ($content -notmatch '<html|<!DOCTYPE|<body|<head') {
            Write-Log "Warning: Content does not appear to be HTML" -Level Warning
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
    
    # Fetch the HTML content
    $result = Get-HtmlContent -Url $SourceUrl -Timeout $TimeoutSeconds
    
    # Display results
    Write-Log "=== Fetch Complete ===" -Level Info
    
    if ($result.Success) {
        Write-Log "Successfully fetched HTML content!" -Level Success
        Write-Log "Status Code: $($result.StatusCode)" -Level Success
        Write-Log "Content Length: $($result.Content.Length) characters" -Level Success
        
        # Display first 500 characters as preview
        Write-Log "`n--- Content Preview (first 500 characters) ---" -Level Info
        $preview = $result.Content.Substring(0, [Math]::Min(500, $result.Content.Length))
        Write-Host $preview
        Write-Log "--- End Preview ---`n" -Level Info
        
        # Return success exit code
        exit 0
        
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
