# YEScale Fallback Workflow - Setup Guide

## Tổng quan
Workflow này tạo ra một API endpoint với cơ chế fallback thông minh cho YEScale API. Khi một model fail, nó sẽ tự động thử model khác theo thứ tự ưu tiên.

## Cấu trúc Workflow

### Flow chính:
1. **Webhook** → Nhận request từ client
2. **Setup Configuration** → Cấu hình groups và models
3. **Prepare API Request** → Chuẩn bị request cho model hiện tại
4. **Call YEScale API** → Gọi API YEScale
5. **Check API Response** → Kiểm tra response thành công/thất bại
6. **Success Path**: Format response và trả về
7. **Failure Path**: Thử model tiếp theo hoặc trả về lỗi cuối

## Cách cài đặt

### 1. Import Workflow
1. Mở n8n interface (http://localhost:5678)
2. Click "Import from File"
3. Chọn file `YEScale-Fallback-Workflow.json`
4. Click "Import"

### 2. Cấu hình Environment Variables
Thêm các biến môi trường vào n8n:

```bash
# Trong file .env hoặc cấu hình n8n
YESCALE_GROK_API_KEY=your_grok_api_key_here
YESCALE_CHATGPT_API_KEY=your_chatgpt_api_key_here
YESCALE_CLAUDE_API_KEY=your_claude_api_key_here
```

### 3. Cấu hình Groups và Models
Trong node "Setup Configuration", bạn có thể chỉnh sửa:

```javascript
const config = {
  baseUrl: 'https://yescale.bogia.app',
  groups: {
    grok: {
      apiKey: '{{$env.YESCALE_GROK_API_KEY}}',
      models: ['grok-3-beta', 'grok-4-0709']
    },
    chatgpt: {
      apiKey: '{{$env.YESCALE_CHATGPT_API_KEY}}',
      models: ['gpt-4o', 'gpt-4o-mini', 'gpt-3.5-turbo']
    },
    claude: {
      apiKey: '{{$env.YESCALE_CLAUDE_API_KEY}}',
      models: ['claude-3-5-sonnet-20241022', 'claude-3-5-haiku-20241022']
    }
  }
};
```

### 4. Activate Workflow
1. Click "Activate" toggle ở góc trên bên phải
2. Workflow sẽ tạo webhook endpoint

## Cách sử dụng

### 1. Endpoint URL
Sau khi activate, webhook sẽ có URL dạng:
```
http://localhost:5678/webhook/yescale-chat
```

### 2. Request Format
```bash
curl -X POST http://localhost:5678/webhook/yescale-chat \
  -H "Content-Type: application/json" \
  -d '{
    "message": "Explain quantum computing in simple terms",
    "temperature": 0.7,
    "max_tokens": 1000
  }'
```

### 3. Response Format

#### Thành công:
```json
{
  "success": true,
  "model_used": "grok-3-beta",
  "group_used": "grok",
  "attempt_number": 1,
  "total_attempts": 8,
  "response": "Quantum computing is a revolutionary technology...",
  "usage": {
    "prompt_tokens": 10,
    "completion_tokens": 150,
    "total_tokens": 160
  },
  "timestamp": "2025-01-27T00:00:00.000Z"
}
```

#### Thất bại:
```json
{
  "success": false,
  "error": "All models failed",
  "attempts_made": 8,
  "total_attempts": 8,
  "last_error": "Model unavailable",
  "timestamp": "2025-01-27T00:00:00.000Z"
}
```

## Tính năng nâng cao

### 1. Fallback Logic
- Thử models theo thứ tự: grok → chatgpt → claude
- Trong mỗi group, thử models theo thứ tự ưu tiên
- Exponential backoff delay giữa các lần retry

### 2. Error Handling
- Xử lý lỗi từ API provider
- Xử lý lỗi network/timeout
- Logging chi tiết các lần thử

### 3. Monitoring
- Theo dõi usage của từng model
- Tracking success/failure rates
- Performance metrics

## Customization

### Thêm Model Group mới:
```javascript
// Trong Setup Configuration node
anthropic: {
  apiKey: '{{$env.YESCALE_ANTHROPIC_API_KEY}}',
  models: ['claude-3-opus', 'claude-3-sonnet']
}
```

### Thay đổi Retry Logic:
```javascript
// Trong Retry Delay node
const delay = Math.min(500 * Math.pow(1.5, data.currentAttempt), 3000);
```

### Custom Response Format:
```javascript
// Trong Format Success Response node
return {
  status: "success",
  data: response.choices[0].message.content,
  metadata: {
    model: originalData.currentModel.model,
    tokens: response.usage.total_tokens
  }
};
```

## Troubleshooting

### 1. Webhook không hoạt động
- Kiểm tra workflow đã được activate
- Kiểm tra port n8n (mặc định 5678)
- Kiểm tra firewall settings

### 2. API Keys không hoạt động
- Verify environment variables đã được set
- Kiểm tra API keys có valid không
- Kiểm tra quota/limits của YEScale account

### 3. Models fail liên tục
- Kiểm tra YEScale service status
- Verify model names chính xác
- Kiểm tra request format

### 4. Performance issues
- Giảm số models trong fallback chain
- Tăng timeout settings
- Optimize retry delays

## Logs và Debugging

### Xem execution logs:
1. Vào workflow executions tab
2. Click vào execution để xem chi tiết
3. Check từng node để debug

### Console logs:
- Node "Handle Failure" sẽ log failed attempts
- Node "Retry Delay" sẽ log retry timing

## Security Notes

- API keys được store trong environment variables
- Không expose API keys trong response
- Sử dụng HTTPS trong production
- Rate limiting để tránh abuse

## Production Deployment

1. Setup reverse proxy (nginx/cloudflare)
2. Configure proper SSL certificates
3. Set up monitoring và alerting
4. Backup workflow configuration
5. Setup proper logging system
