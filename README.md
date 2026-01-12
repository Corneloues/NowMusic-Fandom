# NowMusic-Fandom
HTML crawler using PowerShell

## Overview
This project implements a robust HTML content fetcher in PowerShell with comprehensive error handling for web scraping tasks.

## Features
- Fetch HTML content from any URL using `Invoke-WebRequest`
- Configurable timeout settings
- Robust error handling for:
  - Network timeouts
  - Bad HTTP status codes
  - Invalid URLs
  - Empty content
  - Connection failures
- Environment variable configuration support
- Comprehensive logging with multiple severity levels
- Command-line parameter support

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
Main script that fetches HTML content from a specified URL.

**Configuration:**
- `SOURCE_URL` (env var or parameter): The URL to fetch content from
- `TIMEOUT_SECONDS` (env var or parameter): HTTP request timeout in seconds (default: 30)

**Exit Codes:**
- `0`: Success - content fetched successfully
- `1`: Failure - error occurred (check logs for details)

**Output:**
- Detailed logs with timestamps and severity levels
- Preview of fetched content (first 500 characters)
- Content length and HTTP status code

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
- Required functions
- Error handling implementation
- Environment variable support
- URL validation
- Content validation
- Status code handling
- Logging functionality

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
