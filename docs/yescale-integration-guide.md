# 🚀 YEScale API Integration & Workflow Setup Guide

**Created:** August 2, 2025  
**Purpose:** Setup YEScale API integration và test workflow cho n8n strangematic.com

---

## 📋 PHÂN TÍCH YESCALE API

### **🔑 API Endpoints Quan Trọng:**

1. **User Information**: `/yescale/user` (GET)
   - Lấy thông tin tài khoản, quota, email
   - Response: quota (chia 500,000 = USD), used_quota, request_count

2. **List API Keys**: `/yescale/apikeylist` (GET)  
   - Danh sách tất cả API keys
   - Response: id, name, status, remain_quota, unlimited_quota

3. **List Models**: `/yescale/models` (GET)
   - Danh sách tất cả models khả dụng
   - Response: model_name, provider_name, price_per_request, uptime, endpoint

### **🔐 Authentication:**
- Header: `Authorization: Bearer YOUR_ACCESS_KEY`
- Base URL: `https://yescale.bogia.app`

---

## 🔧 CẤU HÌNH ENVIRONMENT VARIABLES

### **✅ File `.env.production` đã được cập nhật:**

```bash
# YEScale API Configuration
YESCALE_BASE_URL=https://yescale.bogia.app
YESCALE_ACCESS_KEY=your_yescale_access_key_here    # ← BẠN CẦN ĐIỀN
YESCALE_API_KEY=your_yescale_access_key_here       # ← BẠN CẦN ĐIỀN
YESCALE_ENABLE_FALLBACK=true
YESCALE_QUOTA_THRESHOLD=1000000

# Bot Platform Configuration
TELEGRAM_BOT_TOKEN=your_telegram_bot_token_here    # ← BẠN CẦN ĐIỀN
DISCORD_BOT_TOKEN=your_discord_bot_token_here      # ← BẠN CẦN ĐIỀN
DISCORD_CLIENT_ID=your_discord_client_id_here      # ← BẠN CẦN ĐIỀN
```

### **🎯 CÁC BƯỚC CẦN LÀM:**

1. **Lấy YEScale Access Key:**
   - Đăng nhập vào https://yescale.bogia.app
   - Vào Dashboard → API Keys
   - Copy Access Key
   - Thay thế `your_yescale_access_key_here` trong file .env.production

2. **Cập nhật Bot Tokens:**
   - **Telegram**: Thay `your_telegram_bot_token_here` bằng token thực
   - **Discord**: Thay `your_discord_bot_token_here` bằng token thực
   - **Discord Client ID**: Thay `your_discord_client_id_here` bằng client ID thực

---

## 🤖 KHUYẾN NGHỊ VỀ BOT TOKENS

### **📍 NÊN DÙNG CREDENTIALS TRONG N8N (Không dùng ENV):**

**Lý do:**
- ✅ **Bảo mật cao hơn**: Credentials được mã hóa trong database
- ✅ **Quản lý dễ dàng**: Có thể thay đổi qua n8n UI
- ✅ **Chia sẻ workflow**: Không expose tokens trong file config
- ✅ **Audit trail**: n8n log việc sử dụng credentials

**Cách setup:**
1. Vào n8n Dashboard → Settings → Credentials
2. Tạo credential types:
   - **HTTP Header Auth** cho YEScale (Authorization: Bearer)
   - **Generic Credential** cho Telegram Bot Token
   - **Generic Credential** cho Discord Bot Token

---

## 📄 WORKFLOW ĐÃ TẠO

### **📁 File:** `c:\Github\n8n-tp\workflows\yescale-api-test-workflow.json`

**Chức năng:**
- ✅ Lấy thông tin user YEScale
- ✅ List tất cả API keys
- ✅ List tất cả models khả dụng
- ✅ Format kết quả thành JSON dễ đọc
- ✅ Error handling và troubleshooting guide

**Output mẫu:**
```json
{
  "status": "success",
  "timestamp": "2025-08-02T07:30:00.000Z",
  "yescale_account": {
    "display_name": "Your Name",
    "email": "your@email.com",
    "quota_remaining_usd": "173.29",
    "quota_used_usd": "2.92",
    "request_count": 213527
  },
  "api_keys": {
    "total_count": 3,
    "active_keys": 2,
    "keys_details": [...]
  },
  "available_models": {
    "total_count": 150,
    "active_models": 132,
    "by_category": {
      "Image, Dall-e": [...],
      "Text Generation": [...],
      "Video Models": [...]
    }
  }
}
```

---

## 🎯 HƯỚNG DẪN THỰC HIỆN

### **BƯỚC 1: Cập nhật Environment Variables**

```powershell
# Mở file .env.production và điền thông tin thực
notepad C:\Github\n8n-tp\.env.production

# Tìm và thay thế:
YESCALE_ACCESS_KEY=your_actual_access_key_from_dashboard
TELEGRAM_BOT_TOKEN=your_actual_telegram_bot_token  
DISCORD_BOT_TOKEN=your_actual_discord_bot_token
DISCORD_CLIENT_ID=your_actual_discord_client_id

# Lưu file và đóng
```

### **BƯỚC 2: Restart n8n Service**

```powershell
# Restart PM2 service để load environment mới
pm2 restart strangematic-hub

# Kiểm tra status
pm2 status
pm2 logs strangematic-hub --lines 20
```

### **BƯỚC 3: Setup Credentials trong n8n**

1. **Mở n8n Dashboard:**
   - Truy cập: https://app.strangematic.com
   - Login với credentials

2. **Tạo YEScale Credential:**
   - Vào Settings → Credentials
   - Create → HTTP Header Auth
   - Name: `YEScale Auth Header`
   - Header Name: `Authorization`
   - Header Value: `Bearer YOUR_YESCALE_ACCESS_KEY`

3. **Tạo Bot Credentials:**
   - Create → Generic Credential
   - Name: `Telegram Bot Token`
   - Add field: `token` = `your_telegram_token`
   
   - Create → Generic Credential  
   - Name: `Discord Bot Token`
   - Add field: `token` = `your_discord_token`
   - Add field: `client_id` = `your_discord_client_id`

### **BƯỚC 4: Import Workflow**

1. **Vào n8n Dashboard:**
   - Click "Import from File"
   - Select: `C:\Github\n8n-tp\workflows\yescale-api-test-workflow.json`

2. **Configure Credentials:**
   - Mỗi HTTP Request node cần assign credential
   - Select credential: `YEScale Auth Header`

3. **Test Workflow:**
   - Click "Execute Workflow"
   - Xem kết quả trong Output panel

---

## 🔍 TROUBLESHOOTING

### **❌ Lỗi Authentication:**
```json
{
  "error": "Unauthorized",
  "status": 401
}
```
**Giải pháp:**
- Kiểm tra YEScale Access Key đúng chưa
- Verify format header: `Bearer ACCESS_KEY`
- Check credential configuration trong n8n

### **❌ Lỗi Network:**
```json
{
  "error": "ECONNREFUSED",
  "errno": -4058
}
```
**Giải pháp:**
- Check internet connection
- Verify URL: `https://yescale.bogia.app`
- Check firewall/proxy settings

### **❌ Workflow Import Error:**
```
"Invalid JSON format"
```
**Giải pháp:**
- Verify file integrity: `yescale-api-test-workflow.json`
- Try copy-paste JSON content directly
- Check file encoding (UTF-8)

---

## 📊 KẾT QUẢ MONG ĐỢI

### **✅ Sau khi setup thành công:**

1. **YEScale API Test:**
   - User info hiển thị đầy đủ
   - API keys list với status
   - Models list với categories
   - Quota tracking chính xác

2. **Bot Integration:**
   - Telegram bot credentials ready
   - Discord bot credentials ready
   - Webhook endpoints configured

3. **Next Steps Ready:**
   - Logo generation workflow
   - Content creation workflow  
   - AI chat agent workflow

---

## 🚀 NEXT ACTIONS

### **Sau khi workflow test thành công:**

1. **Tạo Advanced Workflows:**
   - Logo generation với DALL-E
   - Content creation với ChatGPT
   - Multi-platform bot responses

2. **Production Optimization:**
   - Error handling enhancement
   - Cost monitoring implementation
   - Performance caching strategy

3. **Bot Platform Integration:**
   - Webhook setup for Telegram
   - Slash commands for Discord
   - Multi-platform message routing

---

**🎯 Priority Actions:**
1. ✅ Fill in YEScale Access Key
2. ✅ Fill in Bot Tokens  
3. ✅ Restart n8n service
4. ✅ Import and test workflow
5. ✅ Verify all API calls successful

**Estimated Time:** 30-45 minutes
**Expected Result:** Full YEScale API integration operational
