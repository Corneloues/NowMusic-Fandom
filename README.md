# NowMusic-Fandom
HTML crawler using PowerShell

## Overview
This project implements a robust HTML content fetcher in PowerShell with comprehensive error handling for web scraping tasks.

## Features
- Fetch HTML content from any URL using `Invoke-WebRequest`
- **Extract specific div elements** from HTML using configurable class selectors
  - Handles nested divs correctly
  - Supports multiple CSS classes in any order
  - Robust regex-based parsing for real-world HTML
- Configurable timeout settings
- Robust error handling for:
  - Network timeouts
  - Bad HTTP status codes
  - Invalid URLs
  - Empty content
  - Connection failures
  - Missing or malformed HTML elements
- Environment variable configuration support
- Comprehensive logging with multiple severity levels
- Command-line parameter support
- Extensive test coverage with unit and integration tests

## Usage

### GitHub Actions Workflow (Recommended)
This repository includes a ready-to-use GitHub Actions workflow that runs the HTML fetcher automatically. The workflow can be:
- **Manually triggered** via the Actions tab with custom URL and timeout parameters
- **Automatically triggered** on pushes and pull requests to the main branch

The workflow uses repository variables `SOURCE_URL` and `TIMEOUT_SECONDS` by default, with fallback to sensible defaults (Wikipedia Music page, 30 second timeout).

To run manually:
1. Go to the "Actions" tab in GitHub
2. Select "Fetch HTML Content" workflow
3. Click "Run workflow"
4. Optionally provide custom URL and timeout values

### Using Environment Variables (For Local Testing)
```bash
export SOURCE_URL="https://example.com"
export TIMEOUT_SECONDS=30
pwsh -File Fetch-HtmlContent.ps1
```

### Using Command-Line Parameters
```powershell
.\Fetch-HtmlContent.ps1 -SourceUrl "https://example.com" -TimeoutSeconds 30
```

### In Custom GitHub Actions
```yaml
- name: Fetch HTML Content
  env:
    SOURCE_URL: ${{ vars.SOURCE_URL }}
    TIMEOUT_SECONDS: ${{ vars.TIMEOUT_SECONDS }}
  run: pwsh -File Fetch-HtmlContent.ps1
```

## Scripts

### Fetch-HtmlContent.ps1
Main script that fetches HTML content from a specified URL and can extract specific content divs.

**Configuration:**
- `SOURCE_URL` (env var or parameter): The URL to fetch content from
- `TIMEOUT_SECONDS` (env var or parameter): HTTP request timeout in seconds (default: 30)
- `TARGET_DIV_CLASS` (env var or parameter): CSS class of the div to extract (default: "mw-content-ltr mw-parser-output")

**Functions:**
- `Get-HtmlContent`: Fetches raw HTML content from a URL with comprehensive error handling
- `Get-TargetDiv`: Extracts a specific div from HTML based on class selector
  - Handles nested divs correctly
  - Supports multiple class names in any order
  - Robust error handling for missing elements and malformed HTML

**Exit Codes:**
- `0`: Success - content fetched successfully
- `1`: Failure - error occurred (check logs for details)

**Output:**
- Detailed logs with timestamps and severity levels
- Preview of fetched content (first 500 characters)
- Content length and HTTP status code

### Test-TargetDivExtraction.ps1
Comprehensive unit tests for the `Get-TargetDiv` function:
- Tests successful extraction with single and multiple classes
- Tests nested div handling
- Tests error handling for missing divs
- Tests malformed HTML handling
- Tests real-world Wikipedia HTML structures
- 11 test cases covering all edge cases

### Test-Integration.ps1
Integration tests that demonstrate end-to-end functionality:
- Fetches HTML from a live URL (requires internet)
- Extracts target div from fetched content
- Validates extracted content correctness
- Includes offline tests with sample HTML

### .github/workflows/fetch-html.yml
GitHub Actions workflow that automates the execution of Fetch-HtmlContent.ps1. Features:
- **Manual trigger** with customizable URL and timeout inputs
- **Automatic triggers** on push/PR to main branch
- Uses repository variables or sensible defaults
- No local PowerShell installation required
- Demonstrates the script in a CI/CD environment

### Demo-FetchHtml.ps1
Demonstration script that runs multiple test scenarios including:
- Valid URL fetching
- Invalid URL handling
- Non-existent domain handling
- HTTP error code handling (404)
- Timeout scenarios

### Validate-Implementation.ps1
Validation script that checks the implementation for:
- Correct PowerShell syntax
- Required functions (Write-Log, Get-HtmlContent, Get-TargetDiv)
- Error handling implementation
- Environment variable support
- URL validation
- Content validation
- Status code handling
- Logging functionality
- TARGET_DIV_CLASS configuration
- HTML parsing and div extraction capabilities

## Error Handling
The script handles various error scenarios:
- **Network errors**: DNS resolution failures, connection timeouts, network unavailability
- **HTTP errors**: 4xx and 5xx status codes with detailed error messages
- **Timeout errors**: Configurable timeout with clear error reporting
- **Invalid URLs**: URL format validation before making requests
- **Empty content**: Validation that response contains actual content

## Example Output
```
[2026-01-12 22:53:32] [Info] === HTML Content Fetcher Started ===
[2026-01-12 22:53:32] [Info] Using SOURCE_URL from environment variable
[2026-01-12 22:53:32] [Info] Using TIMEOUT_SECONDS from environment variable
[2026-01-12 22:53:32] [Info] Attempting to fetch HTML from: https://example.com
[2026-01-12 22:53:32] [Info] Timeout set to: 30 seconds
[2026-01-12 22:53:32] [Info] URL validation passed
[2026-01-12 22:53:33] [Success] HTTP Status Code: 200
[2026-01-12 22:53:33] [Success] Content received successfully. Size: 1256 characters
[2026-01-12 22:53:33] [Info] === Fetch Complete ===
[2026-01-12 22:53:33] [Success] Successfully fetched HTML content!
```

## Requirements
- PowerShell 7.0 or later (cross-platform)
- Internet connectivity for fetching remote content

## Development
To validate the implementation:
```powershell
pwsh -File Validate-Implementation.ps1
```

## License
MIT
