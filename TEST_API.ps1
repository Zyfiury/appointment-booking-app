# Test API Endpoints - Automated Testing Script
# Run this to verify your Railway deployment works!

param(
    [string]$BaseUrl = "https://accurate-solace-app22.up.railway.app/api"
)

$ErrorActionPreference = "Continue"
$testResults = @()

function Test-Endpoint {
    param(
        [string]$Name,
        [string]$Method = "GET",
        [string]$Endpoint,
        [hashtable]$Headers = @{},
        [object]$Body = $null,
        [string]$ExpectedStatus = "200"
    )
    
    Write-Host "`n[TEST] Testing: $Name" -ForegroundColor Cyan
    Write-Host "   $Method $Endpoint" -ForegroundColor Gray
    
    try {
        $params = @{
            Uri = "$BaseUrl$Endpoint"
            Method = $Method
            Headers = $Headers
            ContentType = "application/json"
            ErrorAction = "Stop"
        }
        
        if ($Body) {
            $params.Body = ($Body | ConvertTo-Json -Depth 10)
        }
        
        $response = Invoke-RestMethod @params
        $statusCode = 200
        
        Write-Host "   [PASS] SUCCESS" -ForegroundColor Green
        $testResults += @{ Name = $Name; Status = "PASS"; Details = "Status: $statusCode" }
        return $response
    }
    catch {
        $statusCode = $_.Exception.Response.StatusCode.value__
        Write-Host "   [FAIL] FAILED: $statusCode" -ForegroundColor Red
        Write-Host "   Error: $($_.Exception.Message)" -ForegroundColor Yellow
        $testResults += @{ Name = $Name; Status = "FAIL"; Details = "Status: $statusCode - $($_.Exception.Message)" }
        return $null
    }
}

Write-Host "`n========================================" -ForegroundColor Blue
Write-Host "   API TESTING SCRIPT" -ForegroundColor Blue
Write-Host "   Base URL: $BaseUrl" -ForegroundColor Blue
Write-Host "========================================`n" -ForegroundColor Blue

# Test 1: Health Check
$health = Test-Endpoint -Name "Health Check" -Endpoint "/health"

# Test 2: Get Services (Public)
$services = Test-Endpoint -Name "Get Services (Public)" -Endpoint "/services"

# Test 3: Register User
$registerBody = @{
    email = "test_$(Get-Date -Format 'yyyyMMddHHmmss')@test.com"
    password = "test123456"
    name = "Test User"
    role = "customer"
}

$registerResponse = Test-Endpoint -Name "Register User" -Method "POST" -Endpoint "/auth/register" -Body $registerBody

if ($registerResponse) {
    $testEmail = $registerBody.email
    $testPassword = $registerBody.password
    
    # Test 4: Login
    $loginBody = @{
        email = $testEmail
        password = $testPassword
    }
    
    $loginResponse = Test-Endpoint -Name "Login" -Method "POST" -Endpoint "/auth/login" -Body $loginBody
    
    if ($loginResponse -and $loginResponse.token) {
        $token = $loginResponse.token
        Write-Host "`n   [TOKEN] Token received: $($token.Substring(0, 20))..." -ForegroundColor Green
        
        # Test 5: Get Services (Authenticated)
        $authHeaders = @{
            Authorization = "Bearer $token"
        }
        
        Test-Endpoint -Name "Get Services (Authenticated)" -Endpoint "/services" -Headers $authHeaders
        
        # Test 6: Get User Profile
        Test-Endpoint -Name "Get User Profile" -Endpoint "/users/me" -Headers $authHeaders
        
        # Test 7: Get Appointments
        Test-Endpoint -Name "Get Appointments" -Endpoint "/appointments" -Headers $authHeaders
    }
}

# Test 8: Invalid Login (Should Fail)
$invalidLogin = @{
    email = "invalid@test.com"
    password = "wrongpassword"
}
Test-Endpoint -Name "Invalid Login (Should Fail)" -Method "POST" -Endpoint "/auth/login" -Body $invalidLogin -ExpectedStatus "401"

# Test 9: Search Services
Test-Endpoint -Name "Search Services" -Endpoint "/services/search?q=test"

# Summary
Write-Host "`n========================================" -ForegroundColor Blue
Write-Host "   TEST SUMMARY" -ForegroundColor Blue
Write-Host "========================================`n" -ForegroundColor Blue

$passed = ($testResults | Where-Object { $_.Status -eq "PASS" }).Count
$failed = ($testResults | Where-Object { $_.Status -eq "FAIL" }).Count
$total = $testResults.Count

Write-Host "Total Tests: $total" -ForegroundColor White
Write-Host "Passed: $passed" -ForegroundColor Green
Write-Host "Failed: $failed" -ForegroundColor $(if ($failed -gt 0) { "Red" } else { "Green" })

Write-Host "`nDetailed Results:" -ForegroundColor Cyan
foreach ($result in $testResults) {
    $color = if ($result.Status -eq "PASS") { "Green" } else { "Red" }
    $icon = if ($result.Status -eq "PASS") { "[PASS]" } else { "[FAIL]" }
    Write-Host "  $icon $($result.Name): $($result.Status)" -ForegroundColor $color
    if ($result.Details) {
        Write-Host "     $($result.Details)" -ForegroundColor Gray
    }
}

Write-Host "`n========================================" -ForegroundColor Blue
if ($failed -eq 0) {
    Write-Host "   [SUCCESS] ALL TESTS PASSED!" -ForegroundColor Green
} else {
    Write-Host "   [WARNING] SOME TESTS FAILED" -ForegroundColor Yellow
    Write-Host "   Check Railway logs and environment variables" -ForegroundColor Yellow
}
Write-Host "========================================`n" -ForegroundColor Blue
