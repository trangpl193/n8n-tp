# YEScale Environment Variables Setup Guide

## 🎯 Tổng quan

n8n selfhost của bạn được build từ source code và sử dụng `dotenv` để load environment variables. Bạn có thể cấu hình API keys theo nhiều cách khác nhau.

## 📁 Cấu trúc hiện tại

Dự án hiện có các file config:
```
F:\Github\n8n-tp\
├── n8n.env                    # Config cơ bản (database, port)
├── n8n-config.env            # Config chi tiết hơn
├── .env                       # File này CHƯA TỒN TẠI - cần tạo
└── packages/cli/bin/n8n       # Executable sử dụng dotenv
```

## 🔧 Cách 1: Tạo file .env (KHUYÊN DÙNG)

### Tạo file .env trong root directory:

```powershell
# Trong PowerShell, chạy từ thư mục F:\Github\n8n-tp
New-Item -Path ".env" -ItemType File -Force
```

Hoặc tạo thủ công file `.env` trong thư mục `F:\Github\n8n-tp\`

### Nội dung file .env:

```bash
# YEScale API Keys for Workflow Fallback
# Thay thế các giá trị YOUR_API_KEY_HERE bằng API keys thực tế

# Grok API Key (từ YEScale account)
YESCALE_GROK_API_KEY=your_grok_api_key_here

# ChatGPT API Key (từ YEScale account)
YESCALE_CHATGPT_API_KEY=your_chatgpt_api_key_here

# Claude API Key (từ YEScale account)
YESCALE_CLAUDE_API_KEY=your_claude_api_key_here

# Optional: Anthropic API Key nếu cần thêm
# YESCALE_ANTHROPIC_API_KEY=your_anthropic_api_key_here
```

## 🔧 Cách 2: Thêm vào file n8n-config.env

Bạn có thể thêm API keys vào file `n8n-config.env` hiện có:

```bash
# Mở file n8n-config.env và thêm vào cuối:
echo "" >> n8n-config.env
echo "# YEScale API Keys" >> n8n-config.env
echo "YESCALE_GROK_API_KEY=your_grok_api_key_here" >> n8n-config.env
echo "YESCALE_CHATGPT_API_KEY=your_chatgpt_api_key_here" >> n8n-config.env
echo "YESCALE_CLAUDE_API_KEY=your_claude_api_key_here" >> n8n-config.env
```

## 🔧 Cách 3: Set Environment Variables (Tạm thời)

### Trong PowerShell:
```powershell
# Set cho session hiện tại
$env:YESCALE_GROK_API_KEY = "your_grok_api_key_here"
$env:YESCALE_CHATGPT_API_KEY = "your_chatgpt_api_key_here"
$env:YESCALE_CLAUDE_API_KEY = "your_claude_api_key_here"

# Verify
echo $env:YESCALE_GROK_API_KEY
```

### Trong CMD:
```cmd
set YESCALE_GROK_API_KEY=your_grok_api_key_here
set YESCALE_CHATGPT_API_KEY=your_chatgpt_api_key_here
set YESCALE_CLAUDE_API_KEY=your_claude_api_key_here
```

## 🔧 Cách 4: Windows System Environment Variables

### Qua Control Panel:
1. Mở `Control Panel` → `System` → `Advanced System Settings`
2. Click `Environment Variables`
3. Trong `User variables` hoặc `System variables`, click `New`
4. Thêm từng biến:
   - Variable name: `YESCALE_GROK_API_KEY`
   - Variable value: `your_actual_api_key`
5. Lặp lại cho các API keys khác
6. Restart PowerShell/CMD để áp dụng

### Qua PowerShell (Permanent):
```powershell
# Set permanent environment variables (cần run as Administrator)
[Environment]::SetEnvironmentVariable("YESCALE_GROK_API_KEY", "your_grok_api_key_here", "User")
[Environment]::SetEnvironmentVariable("YESCALE_CHATGPT_API_KEY", "your_chatgpt_api_key_here", "User")
[Environment]::SetEnvironmentVariable("YESCALE_CLAUDE_API_KEY", "your_claude_api_key_here", "User")
```

## 📋 Lấy YEScale API Keys

### Bước 1: Truy cập YEScale Dashboard
1. Đi tới trang chủ YEScale: `https://yescale.bogia.app`
2. Đăng nhập vào tài khoản của bạn
3. Vào phần `API Keys` hoặc `Settings`

### Bước 2: Tạo API Keys theo Groups
Tạo riêng biệt API keys cho từng group:
- **Grok Group**: Tạo API key có quyền truy cập `grok-3-beta`, `grok-4-0709`
- **ChatGPT Group**: Tạo API key có quyền truy cập `gpt-4o`, `gpt-4o-mini`, `gpt-3.5-turbo`
- **Claude Group**: Tạo API key có quyền truy cập Claude models

### Bước 3: Copy API Keys
Sao chép từng API key và thay thế trong file `.env`

## ✅ Kiểm tra cấu hình

### Kiểm tra Environment Variables:
```powershell
# Trong PowerShell
echo $env:YESCALE_GROK_API_KEY
echo $env:YESCALE_CHATGPT_API_KEY
echo $env:YESCALE_CLAUDE_API_KEY
```

### Test với n8n:
1. Restart n8n server:
   ```powershell
   # Dừng n8n nếu đang chạy (Ctrl+C)
   # Khởi động lại
   cd F:\Github\n8n-tp
   npm run start
   ```

2. Import workflow `YEScale-Fallback-Workflow.json`
3. Activate workflow
4. Test với PowerShell script:
   ```powershell
   .\"workflow template\Test-PowerShell.ps1"
   ```

## 🐛 Troubleshooting

### 1. Environment Variables không được load

**Nguyên nhân**: File `.env` không đúng vị trí hoặc cú pháp sai

**Giải pháp**:
- Đảm bảo file `.env` nằm ở `F:\Github\n8n-tp\.env`
- Không có dấu cách xung quanh dấu `=`
- Không sử dụng quotes trừ khi cần thiết

### 2. API Key invalid

**Nguyên nhân**: API key không đúng hoặc hết hạn

**Giải pháp**:
- Kiểm tra lại API key trên YEScale dashboard
- Verify quota còn lại
- Tạo API key mới nếu cần

### 3. n8n không nhận environment variables

**Nguyên nhân**: n8n cache hoặc không restart

**Giải pháp**:
```powershell
# Dừng hoàn toàn n8n
Stop-Process -Name "node" -Force -ErrorAction SilentlyContinue

# Xóa node_modules/.cache nếu có
Remove-Item -Path "node_modules\.cache" -Recurse -Force -ErrorAction SilentlyContinue

# Restart
npm run start
```

### 4. Permission errors

**Nguyên nhân**: Thiếu quyền ghi file

**Giải pháp**:
- Chạy PowerShell as Administrator
- Kiểm tra quyền truy cập thư mục

## 🔒 Security Best Practices

### 1. Bảo vệ API Keys
- ❌ **KHÔNG** commit file `.env` vào Git
- ✅ Thêm `.env` vào `.gitignore`
- ✅ Sử dụng API keys với quyền tối thiểu
- ✅ Rotate API keys định kỳ

### 2. File Permissions
```powershell
# Set read-only cho owner
icacls ".env" /grant:r "$env:USERNAME:R"
```

### 3. Backup
- Backup API keys ở nơi an toàn
- Đừng lưu trong code hoặc documentation

## 📝 Template file .env hoàn chỉnh

```bash
# =================================
# YEScale API Configuration
# =================================
# Thay thế tất cả "your_xxx_api_key_here" bằng API keys thực tế từ YEScale

# Grok Models API Key
YESCALE_GROK_API_KEY=your_grok_api_key_here

# ChatGPT Models API Key  
YESCALE_CHATGPT_API_KEY=your_chatgpt_api_key_here

# Claude Models API Key
YESCALE_CLAUDE_API_KEY=your_claude_api_key_here

# =================================
# Optional: Additional Configurations
# =================================

# Debug mode (uncomment để enable)
# DEBUG=yescale:*

# Request timeout (ms)
# YESCALE_TIMEOUT=30000

# Max retries per model
# YESCALE_MAX_RETRIES=3
```

## 🚀 Next Steps

1. **Tạo file .env** với API keys thực tế
2. **Restart n8n** để load environment variables
3. **Import workflow** `YEScale-Fallback-Workflow.json`
4. **Test workflow** với script PowerShell
5. **Monitor logs** để verify API calls thành công

## 📞 Support

Nếu gặp vấn đề:
1. Kiểm tra n8n execution logs
2. Verify API keys trên YEScale dashboard
3. Test manual API call với curl/Postman
4. Check network connectivity đến yescale.bogia.app
