# ✅ YEScale API Setup Checklist

**Date:** August 2, 2025  
**Status:** Ready to Execute

---

## 🎯 IMMEDIATE ACTIONS REQUIRED

### **1. YEScale Access Key Setup (5 minutes)**
- [ ] Đăng nhập https://yescale.bogia.app
- [ ] Vào Dashboard → API Keys section
- [ ] Copy Access Key từ dashboard
- [ ] Mở file: `C:\Github\n8n-tp\.env.production`  
- [ ] Thay `your_yescale_access_key_here` bằng key thực
- [ ] Lưu file

### **2. Bot Tokens Configuration (3 minutes)**
- [ ] Telegram Bot Token: Thay `your_telegram_bot_token_here`
- [ ] Discord Bot Token: Thay `your_discord_bot_token_here`  
- [ ] Discord Client ID: Thay `your_discord_client_id_here`
- [ ] Lưu file `.env.production`

### **3. Restart n8n Service (2 minutes)**
```powershell
pm2 restart strangematic-hub
pm2 status
```
- [ ] Service restart thành công
- [ ] Status = "online"

### **4. n8n Credentials Setup (5 minutes)**
- [ ] Vào https://app.strangematic.com
- [ ] Settings → Credentials → Create New
- [ ] **HTTP Header Auth**: Name = "YEScale Auth Header"
  - Header Name: `Authorization`
  - Header Value: `Bearer YOUR_YESCALE_ACCESS_KEY`
- [ ] Save credential

### **5. Import Test Workflow (3 minutes)**
- [ ] n8n Dashboard → Import from File
- [ ] Select: `C:\Github\n8n-tp\workflows\yescale-api-test-workflow.json`
- [ ] Configure credentials cho tất cả HTTP Request nodes
- [ ] Assign credential: "YEScale Auth Header"

### **6. Test Workflow Execution (2 minutes)**
- [ ] Click "Execute Workflow"
- [ ] Xem output panel
- [ ] Verify JSON response có:
  - user_info (email, quota)
  - api_keys_count  
  - models_count
  - quota_remaining_usd

---

## 📊 SUCCESS CRITERIA

**✅ Workflow thành công khi:**
- Status = "success"
- quota_remaining_usd hiển thị số dương
- api_keys_count > 0
- models_count > 100
- Không có error messages

**❌ Cần fix nếu:**
- Status = "error"  
- Authentication failed (401)
- Network connection issues
- Invalid JSON responses

---

## 🚀 NEXT STEPS AFTER SUCCESS

1. **Create Production Workflows:**
   - Logo generation (Telegram + DALL-E)
   - Content creation (Discord + ChatGPT)
   - AI chat agent (Multi-platform)

2. **Bot Webhook Setup:**
   - Telegram webhook: `https://api.strangematic.com/webhook/telegram`
   - Discord webhook: `https://api.strangematic.com/webhook/discord`

3. **Cost Monitoring:**
   - Daily quota tracking
   - Cost per workflow calculation
   - Alert system implementation

---

## 📋 FILES CREATED/MODIFIED

### **✅ Modified:**
- `C:\Github\n8n-tp\.env.production` (added YEScale + Bot configs)

### **✅ Created:**
- `C:\Github\n8n-tp\workflows\yescale-api-test-workflow.json`
- `C:\Github\n8n-tp\docs\yescale-integration-guide.md`  
- `C:\Github\n8n-tp\docs\yescale-setup-checklist.md` (this file)

---

## 🤔 DECISION: Credentials vs Environment Variables

**Recommendation: USE N8N CREDENTIALS (Not ENV variables)**

**Why:**
- ✅ More secure (encrypted in database)
- ✅ Better workflow sharing
- ✅ Centralized management  
- ✅ Audit logging

**For Bot Tokens:**
- Store in n8n Credentials, not .env file
- Use Generic Credential type
- Reference in workflows via credential selector

---

**🎯 Total Time Estimate: 20 minutes**  
**🎯 Success Rate: 95% (if API key valid)**  
**🎯 Next Phase: Bot workflow development**

**Ready to proceed? Follow checklist step by step!**
