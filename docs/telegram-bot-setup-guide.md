# Hướng dẫn Cấu hình Telegram YEScale Bot

## 📋 Tổng quan

Workflow này tự động hóa việc trả lời chat Telegram với thông tin về YEScale API keys và models. Bot có thể hiểu cả tiếng Việt và tiếng Anh.

## 🚀 Các Workflow đã tạo

1. **telegram-yescale-bot-workflow.json** - Workflow cơ bản
2. **telegram-yescale-bot-clean.json** - Workflow tối ưu (khuyến nghị)
3. **telegram-yescale-bot-advanced-fixed.json** - Workflow nâng cao đã sửa (đầy đủ tính năng)
4. ~~telegram-yescale-bot-advanced-workflow.json~~ - Workflow có lỗi JSON (không sử dụng)

## ⚙️ Cấu hình cần thiết

### 1. Telegram Bot Credentials
Tạo credentials trong n8n với thông tin:
- **Name**: `Telegram Bot API`
- **ID**: `telegram-bot-credentials`
- **Bot Token**: Token bot Telegram của bạn

### 2. YEScale API Credentials
Tạo HTTP Header Auth credentials:
- **Name**: `YEScale Auth Header`
- **ID**: `yescale-auth-header`
- **Header Name**: `Access-Key`
- **Header Value**: YEScale Access Key của bạn

### 3. Webhook Setup
- Bot sẽ tự động tạo webhook endpoint
- Webhook ID: `telegram-yescale-bot-v2`

## 🤖 Chức năng Bot

### Nhận diện ngôn ngữ tự nhiên:

#### 📋 Xem danh sách API Keys:
- `api`, `apis`, `list api`
- `danh sách api`, `xem api`
- `show me the apis`, `available apis`
- `api nào`, `có api gì`

#### 🧠 Xem danh sách Models:
- `model`, `models`, `list model`
- `danh sách model`, `xem model`
- `show me models`, `available models`
- `model nào`, `có model gì`

#### ❓ Trợ giúp:
- `help`, `hướng dẫn`, `guide`
- `start`, `/start`, `bắt đầu`
- `hello`, `hi`, `xin chào`

## 📊 Định dạng Response

### API Keys Response:
```
🔑 **API Keys có sẵn:**

1. **API Name**
   • ✅ Hoạt động
   • Quota: $50.00

2. **Another API**
   • ❌ Không hoạt động
   • Quota: ♾️ Không giới hạn

📊 **Tổng:** 5 API keys (3 hoạt động)
```

### Models Response:
```
🤖 **Models có sẵn:**

**📂 Language Models:**
   1. `gpt-4` (OpenAI)
   2. `claude-3` (Anthropic)
   3. `gemini-pro` (Google)

**📂 Image Models:**
   1. `dall-e-3` (OpenAI)
   2. `midjourney` (Midjourney)

📊 **Tổng:** 25 models hoạt động
```

## 🔧 Cài đặt

### 1. Import Workflow
```bash
# Copy file workflow vào n8n
cp telegram-yescale-bot-clean.json /path/to/n8n/workflows/
```

### 2. Cấu hình Credentials
1. Vào n8n UI → Credentials
2. Tạo "Telegram" credential với bot token
3. Tạo "HTTP Header Auth" credential với YEScale access key

### 3. Activate Workflow
1. Import workflow vào n8n
2. Cấu hình credentials cho các nodes
3. Activate workflow
4. Test bằng cách gửi message qua Telegram

### 4. Test Commands
Gửi các message sau để test:
- `api` - Xem API keys
- `models` - Xem models  
- `help` - Xem hướng dẫn

## 🛠️ Troubleshooting

### Lỗi kết nối YEScale:
- Kiểm tra Access Key trong credentials
- Verify network connectivity tới yescale.bogia.app

### Bot không phản hồi:
- Kiểm tra Telegram bot token
- Verify webhook đã được setup
- Check workflow activation status

### Lỗi parse message:
- Kiểm tra regex patterns trong các IF nodes
- Test với các message đơn giản trước

## 📈 Mở rộng

### Thêm chức năng mới:
1. Thêm IF node để detect command mới
2. Thêm HTTP Request node cho API call
3. Thêm response formatting node
4. Connect với Send Response node

### Cải thiện NLP:
- Thêm nhiều regex patterns
- Support thêm ngôn ngữ
- Thêm context awareness

## 🔐 Security

- Access Key được store an toàn trong n8n credentials
- Bot token được encrypt
- Không log sensitive data
- Rate limiting có thể được thêm vào

## 📞 Support

- **Email**: admin@strangematic.com
- **Documentation**: [YEScale API Docs](https://im06lq19wz.apifox.cn/doc-7023075)
- **GitHub**: Repository này

---

*Phát triển bởi **Strangematic** - Intelligent Automation Solutions*
