# YEScale API Configuration

## Base Information
- **Base URL**: `https://yescale.bogia.app`
- **Authentication**: Bearer Token (ACCESS_KEY)
- **Content-Type**: `application/json`

## API Groups và Models

### Group: ChatGPT
**API Key Group**: `chatgpt`
**Available Models**:
- `gpt-4o`
- `gpt-4o-mini`
- `gpt-4-turbo`
- `gpt-3.5-turbo`

### Group: Claude
**API Key Group**: `claude`
**Available Models**:
- `claude-3-5-sonnet-20241022`
- `claude-3-5-haiku-20241022`
- `claude-3-opus-20240229`

### Group: Gemini
**API Key Group**: `gemini`
**Available Models**:
- `gemini-2.0-flash-exp`
- `gemini-1.5-pro`
- `gemini-1.5-flash`

### Group: Grok (Example từ user)
**API Key Group**: `grok`
**Available Models**:
- `grok-3-beta`
- `grok-4-0709`

## API Endpoints

### Chat Completion (Non-streaming)
```
POST /v1/chat/completions
```

### Chat Completion (Streaming)
```
POST /v1/chat/completions
```
*Note: Thêm `"stream": true` vào request body*

### List Models
```
GET /yescale/models/list
Authorization: Bearer {ACCESS_KEY}
```

### Get User Info
```
GET /yescale/user
Authorization: Bearer {ACCESS_KEY}
```

## Request Format (Chat Completion)

```json
{
  "model": "gpt-4o",
  "messages": [
    {
      "role": "user",
      "content": "Hello, how are you?"
    }
  ],
  "temperature": 0.7,
  "max_tokens": 1000,
  "stream": false
}
```

## Response Format

### Success Response
```json
{
  "id": "chatcmpl-xxx",
  "object": "chat.completion",
  "created": 1234567890,
  "model": "gpt-4o",
  "choices": [
    {
      "index": 0,
      "message": {
        "role": "assistant",
        "content": "Hello! I'm doing well, thank you for asking."
      },
      "finish_reason": "stop"
    }
  ],
  "usage": {
    "prompt_tokens": 10,
    "completion_tokens": 15,
    "total_tokens": 25
  }
}
```

### Error Response
```json
{
  "error": {
    "message": "The model is currently unavailable",
    "type": "server_error",
    "code": "model_unavailable"
  }
}
```

## Fallback Strategy

1. **Primary Model**: Thử model đầu tiên trong group
2. **Secondary Model**: Nếu primary fail, thử model thứ 2
3. **Cross-Group Fallback**: Nếu tất cả model trong group fail, thử group khác
4. **Final Error**: Nếu tất cả fail, trả về thông báo lỗi

## Rate Limits & Quotas

- Quota được tính bằng credits (500,000 = $1 USD)
- Check quota qua endpoint `/yescale/user`
- Giới hạn request rate tùy theo plan
