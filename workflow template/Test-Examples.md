# YEScale Workflow - Test Examples

## Các ví dụ test để kiểm thử workflow

### 1. Test cơ bản - Chat đơn giản

```bash
curl -X POST http://localhost:5678/webhook/yescale-chat \
  -H "Content-Type: application/json" \
  -d '{
    "message": "Hello, how are you today?",
    "temperature": 0.7,
    "max_tokens": 100
  }'
```

**Expected Response:**
```json
{
  "success": true,
  "model_used": "grok-3-beta",
  "group_used": "grok",
  "attempt_number": 1,
  "total_attempts": 8,
  "response": "Hello! I'm doing well, thank you for asking...",
  "usage": {
    "prompt_tokens": 6,
    "completion_tokens": 25,
    "total_tokens": 31
  },
  "timestamp": "2025-01-27T00:04:43.000Z"
}
```

### 2. Test với prompt phức tạp

```bash
curl -X POST http://localhost:5678/webhook/yescale-chat \
  -H "Content-Type: application/json" \
  -d '{
    "message": "Explain the difference between machine learning and deep learning in detail. Include examples and use cases.",
    "temperature": 0.5,
    "max_tokens": 800
  }'
```

### 3. Test với temperature cao (creative)

```bash
curl -X POST http://localhost:5678/webhook/yescale-chat \
  -H "Content-Type: application/json" \
  -d '{
    "message": "Write a creative short story about a robot discovering emotions",
    "temperature": 0.9,
    "max_tokens": 500
  }'
```

### 4. Test với temperature thấp (factual)

```bash
curl -X POST http://localhost:5678/webhook/yescale-chat \
  -H "Content-Type: application/json" \
  -d '{
    "message": "What is the capital of France? Provide only the answer.",
    "temperature": 0.1,
    "max_tokens": 10
  }'
```

### 5. Test fallback mechanism (simulate failure)

Để test fallback, bạn có thể:

#### a) Dùng API key không hợp lệ cho group đầu tiên
```javascript
// Trong Setup Configuration node, thay đổi tạm thời:
grok: {
  apiKey: 'invalid_key_to_test_fallback',
  models: ['grok-3-beta', 'grok-4-0709']
}
```

#### b) Test với model không tồn tại
```javascript
// Thay đổi model name thành invalid
grok: {
  apiKey: '{{$env.YESCALE_GROK_API_KEY}}',
  models: ['invalid-model-name', 'grok-4-0709']
}
```

### 6. Test với nhiều định dạng input khác nhau

#### Sử dụng field "prompt" thay vì "message"
```bash
curl -X POST http://localhost:5678/webhook/yescale-chat \
  -H "Content-Type: application/json" \
  -d '{
    "prompt": "Explain quantum computing",
    "temperature": 0.7,
    "max_tokens": 300
  }'
```

#### Không có input (sử dụng default)
```bash
curl -X POST http://localhost:5678/webhook/yescale-chat \
  -H "Content-Type: application/json" \
  -d '{}'
```

### 7. Test performance với request dài

```bash
curl -X POST http://localhost:5678/webhook/yescale-chat \
  -H "Content-Type: application/json" \
  -d '{
    "message": "Write a comprehensive analysis of the impact of artificial intelligence on modern society, covering economic, social, ethical, and technological aspects. Discuss both positive and negative implications, provide real-world examples, and suggest potential solutions for addressing the challenges.",
    "temperature": 0.6,
    "max_tokens": 2000
  }'
```

### 8. Test với câu hỏi đa ngôn ngữ

```bash
curl -X POST http://localhost:5678/webhook/yescale-chat \
  -H "Content-Type: application/json" \
  -d '{
    "message": "Xin chào, bạn có thể giúp tôi hiểu về trí tuệ nhân tạo không?",
    "temperature": 0.7,
    "max_tokens": 300
  }'
```

### 9. Test stress - Multiple concurrent requests

```bash
#!/bin/bash
# Script để test concurrent requests

for i in {1..10}; do
  curl -X POST http://localhost:5678/webhook/yescale-chat \
    -H "Content-Type: application/json" \
    -d "{
      \"message\": \"Test request number $i - explain AI\",
      \"temperature\": 0.7,
      \"max_tokens\": 100
    }" &
done

wait
echo "All requests completed"
```

### 10. Test error handling

#### Malformed JSON
```bash
curl -X POST http://localhost:5678/webhook/yescale-chat \
  -H "Content-Type: application/json" \
  -d '{
    "message": "Test",
    "temperature": 0.7,
    "max_tokens": 100,
  }'
```

#### Invalid parameters
```bash
curl -X POST http://localhost:5678/webhook/yescale-chat \
  -H "Content-Type: application/json" \
  -d '{
    "message": "Test",
    "temperature": 2.5,
    "max_tokens": -100
  }'
```

## Python Test Script

```python
import requests
import json
import time
import concurrent.futures

WEBHOOK_URL = "http://localhost:5678/webhook/yescale-chat"

def test_basic_request():
    """Test basic functionality"""
    payload = {
        "message": "Hello, test message",
        "temperature": 0.7,
        "max_tokens": 100
    }
    
    response = requests.post(WEBHOOK_URL, json=payload)
    print(f"Status Code: {response.status_code}")
    print(f"Response: {response.json()}")
    return response.json()

def test_fallback_mechanism():
    """Test with a complex query that might trigger fallback"""
    payload = {
        "message": "Generate a 1000-word essay on quantum mechanics",
        "temperature": 0.8,
        "max_tokens": 2000
    }
    
    start_time = time.time()
    response = requests.post(WEBHOOK_URL, json=payload)
    end_time = time.time()
    
    result = response.json()
    print(f"Request took: {end_time - start_time:.2f} seconds")
    print(f"Model used: {result.get('model_used', 'N/A')}")
    print(f"Attempt number: {result.get('attempt_number', 'N/A')}")
    return result

def test_concurrent_requests(num_requests=5):
    """Test concurrent requests"""
    def make_request(i):
        payload = {
            "message": f"Test request {i}",
            "temperature": 0.7,
            "max_tokens": 50
        }
        return requests.post(WEBHOOK_URL, json=payload)
    
    start_time = time.time()
    with concurrent.futures.ThreadPoolExecutor(max_workers=num_requests) as executor:
        futures = [executor.submit(make_request, i) for i in range(num_requests)]
        results = [future.result() for future in concurrent.futures.as_completed(futures)]
    
    end_time = time.time()
    
    print(f"Completed {num_requests} concurrent requests in {end_time - start_time:.2f} seconds")
    
    for i, response in enumerate(results):
        if response.status_code == 200:
            data = response.json()
            print(f"Request {i}: Model {data.get('model_used', 'N/A')}, Attempt {data.get('attempt_number', 'N/A')}")
        else:
            print(f"Request {i}: Failed with status {response.status_code}")

if __name__ == "__main__":
    print("=== Testing YEScale Workflow ===")
    
    print("\n1. Basic Request Test:")
    test_basic_request()
    
    print("\n2. Fallback Mechanism Test:")
    test_fallback_mechanism()
    
    print("\n3. Concurrent Requests Test:")
    test_concurrent_requests(3)
```

## Test Results Analysis

### Kiểm tra các metrics quan trọng:

1. **Response Time**: Thời gian phản hồi cho mỗi request
2. **Success Rate**: Tỷ lệ thành công của requests
3. **Fallback Frequency**: Tần suất cần dùng fallback models
4. **Model Distribution**: Model nào được sử dụng nhiều nhất
5. **Error Types**: Các loại lỗi phổ biến

### Expected Test Scenarios:

#### Scenario 1: Tất cả models hoạt động bình thường
- Model đầu tiên (grok-3-beta) sẽ được sử dụng
- Response time: 2-5 giây
- Success rate: ~100%

#### Scenario 2: Model đầu tiên fail
- Workflow sẽ fallback sang grok-4-0709
- Response time: 3-8 giây (do retry delay)
- Success rate: ~100%

#### Scenario 3: Cả group grok fail
- Workflow sẽ fallback sang group chatgpt
- Response time: 5-15 giây
- Success rate: ~100%

#### Scenario 4: Tất cả models fail
- Response sẽ trả về error
- Response time: 30-60 giây
- Success rate: 0%

## Monitoring và Logging

### Trong n8n execution logs, cần chú ý:

1. **Setup Configuration**: Check API keys được load đúng
2. **Prepare API Request**: Verify request format
3. **Call YEScale API**: Monitor response times và errors
4. **Handle Failure**: Track failure rates và reasons
5. **Retry Delay**: Monitor retry patterns

### Key metrics để track:

```javascript
// Thêm vào Format Success Response node
const metrics = {
  model_used: originalData.currentModel.model,
  group_used: originalData.currentModel.group,
  attempt_number: originalData.currentAttempt + 1,
  response_time: Date.now() - originalData.startTime,
  success: true
};

// Log to external monitoring system
console.log('WORKFLOW_METRICS:', JSON.stringify(metrics));
```
