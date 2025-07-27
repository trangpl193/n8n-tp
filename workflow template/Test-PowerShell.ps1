# YEScale Workflow Test Script cho PowerShell
# Sử dụng cho Windows PowerShell

$webhookUrl = "http://localhost:5678/webhook/yescale-chat"

Write-Host "=== Testing YEScale Workflow ===" -ForegroundColor Green

# Test 1: Basic request
Write-Host "`n1. Basic Request Test:" -ForegroundColor Yellow
$body1 = @{
    message = "Hello, how are you today?"
    temperature = 0.7
    max_tokens = 100
} | ConvertTo-Json

try {
    $response1 = Invoke-RestMethod -Uri $webhookUrl -Method POST -Body $body1 -ContentType "application/json"
    Write-Host "SUCCESS:" -ForegroundColor Green
    Write-Host ($response1 | ConvertTo-Json -Depth 5)
} catch {
    Write-Host "ERROR:" -ForegroundColor Red
    Write-Host $_.Exception.Message
}

# Test 2: Complex prompt
Write-Host "`n2. Complex Prompt Test:" -ForegroundColor Yellow
$body2 = @{
    message = "Explain the difference between machine learning and deep learning in detail."
    temperature = 0.5
    max_tokens = 500
} | ConvertTo-Json

try {
    $response2 = Invoke-RestMethod -Uri $webhookUrl -Method POST -Body $body2 -ContentType "application/json"
    Write-Host "Model used: $($response2.model_used)" -ForegroundColor Cyan
    Write-Host "Attempt number: $($response2.attempt_number)" -ForegroundColor Cyan
    Write-Host "Response length: $($response2.response.Length) characters" -ForegroundColor Cyan
} catch {
    Write-Host "ERROR:" -ForegroundColor Red
    Write-Host $_.Exception.Message
}

# Test 3: Empty request (using defaults)
Write-Host "`n3. Empty Request Test (Default values):" -ForegroundColor Yellow
$body3 = @{} | ConvertTo-Json

try {
    $response3 = Invoke-RestMethod -Uri $webhookUrl -Method POST -Body $body3 -ContentType "application/json"
    Write-Host "SUCCESS with defaults:" -ForegroundColor Green
    Write-Host "Model: $($response3.model_used), Group: $($response3.group_used)"
} catch {
    Write-Host "ERROR:" -ForegroundColor Red
    Write-Host $_.Exception.Message
}

# Test 4: High temperature (creative)
Write-Host "`n4. Creative Request Test (High Temperature):" -ForegroundColor Yellow
$body4 = @{
    message = "Write a short creative story about AI"
    temperature = 0.9
    max_tokens = 300
} | ConvertTo-Json

try {
    $response4 = Invoke-RestMethod -Uri $webhookUrl -Method POST -Body $body4 -ContentType "application/json"
    Write-Host "SUCCESS:" -ForegroundColor Green
    Write-Host "Story length: $($response4.response.Length) characters"
    Write-Host "Tokens used: $($response4.usage.total_tokens)"
} catch {
    Write-Host "ERROR:" -ForegroundColor Red
    Write-Host $_.Exception.Message
}

# Test 5: Performance test with timing
Write-Host "`n5. Performance Test:" -ForegroundColor Yellow
$body5 = @{
    message = "What is artificial intelligence?"
    temperature = 0.7
    max_tokens = 200
} | ConvertTo-Json

$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
try {
    $response5 = Invoke-RestMethod -Uri $webhookUrl -Method POST -Body $body5 -ContentType "application/json"
    $stopwatch.Stop()
    
    Write-Host "SUCCESS:" -ForegroundColor Green
    Write-Host "Response time: $($stopwatch.ElapsedMilliseconds) ms" -ForegroundColor Cyan
    Write-Host "Model used: $($response5.model_used)" -ForegroundColor Cyan
    Write-Host "Attempt: $($response5.attempt_number)/$($response5.total_attempts)" -ForegroundColor Cyan
} catch {
    $stopwatch.Stop()
    Write-Host "ERROR after $($stopwatch.ElapsedMilliseconds) ms:" -ForegroundColor Red
    Write-Host $_.Exception.Message
}

# Test 6: Vietnamese language test
Write-Host "`n6. Vietnamese Language Test:" -ForegroundColor Yellow
$body6 = @{
    message = "Xin chào, bạn có thể giúp tôi hiểu về trí tuệ nhân tạo không?"
    temperature = 0.7
    max_tokens = 300
} | ConvertTo-Json -Depth 10

try {
    $response6 = Invoke-RestMethod -Uri $webhookUrl -Method POST -Body $body6 -ContentType "application/json; charset=utf-8"
    Write-Host "SUCCESS:" -ForegroundColor Green
    Write-Host "Vietnamese response received successfully"
} catch {
    Write-Host "ERROR:" -ForegroundColor Red
    Write-Host $_.Exception.Message
}

# Test 7: Concurrent requests test
Write-Host "`n7. Concurrent Requests Test:" -ForegroundColor Yellow

$jobs = @()
for ($i = 1; $i -le 3; $i++) {
    $body = @{
        message = "Test request number $i - explain quantum computing briefly"
        temperature = 0.7
        max_tokens = 150
    } | ConvertTo-Json
    
    $job = Start-Job -ScriptBlock {
        param($url, $requestBody)
        try {
            $result = Invoke-RestMethod -Uri $url -Method POST -Body $requestBody -ContentType "application/json"
            return @{
                Success = $true
                Model = $result.model_used
                Attempt = $result.attempt_number
                ResponseLength = $result.response.Length
            }
        } catch {
            return @{
                Success = $false
                Error = $_.Exception.Message
            }
        }
    } -ArgumentList $webhookUrl, $body
    
    $jobs += $job
}

# Wait for all jobs to complete
$jobs | Wait-Job | ForEach-Object {
    $result = Receive-Job $_
    if ($result.Success) {
        Write-Host "✓ Request completed - Model: $($result.Model), Attempt: $($result.Attempt), Length: $($result.ResponseLength)" -ForegroundColor Green
    } else {
        Write-Host "✗ Request failed - Error: $($result.Error)" -ForegroundColor Red
    }
    Remove-Job $_
}

Write-Host "`n=== Test Completed ===" -ForegroundColor Green

# Function to test with invalid API key (for fallback testing)
function Test-Fallback {
    Write-Host "`nFallback Test Instructions:" -ForegroundColor Magenta
    Write-Host "To test fallback mechanism:"
    Write-Host "1. Temporarily set an invalid API key for the first group in n8n"
    Write-Host "2. Re-run this test to see fallback in action"
    Write-Host "3. Check the 'attempt_number' in response to verify fallback"
}

Test-Fallback
