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

### Using Environment Variables (Recommended for GitHub Actions)
```bash
export SOURCE_URL="https://example.com"
export TIMEOUT_SECONDS=30
pwsh -File Fetch-HtmlContent.ps1
```

### Using Command-Line Parameters
```powershell
.\Fetch-HtmlContent.ps1 -SourceUrl "https://example.com" -TimeoutSeconds 30
```

### In GitHub Actions
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
