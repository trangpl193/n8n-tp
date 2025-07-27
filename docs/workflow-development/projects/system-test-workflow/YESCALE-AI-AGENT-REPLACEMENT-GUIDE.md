# Hướng Dẫn Thay Thế Google Gemini bằng Yescale API trong AI Agent

## 🎯 **Tổng Quan**

Để thay thế node **"Connect your model"** (Google Gemini) bằng **Yescale API** trong workflow AI Agent, chúng ta có **3 phương án**:

1. **Custom LangChain Node** (Khuyến nghị) ⭐
2. **Code Node Bridge** (Dễ implement)
3. **Subworkflow Pattern** (Flexible)

## 🔍 **Phân Tích Node Hiện Tại**

### **Google Gemini Node:**
```json
{
  "name": "Connect your model",
  "type": "@n8n/n8n-nodes-langchain.lmChatGoogleGemini",
  "parameters": {
    "options": {
      "temperature": 0
    }
  },
  "typeVersion": 1
}
```

### **Connection Pattern:**
```json
"Connect your model": {
  "ai_languageModel": [
    [
      {
        "node": "Your First AI Agent",
        "type": "ai_languageModel",
        "index": 0
      }
    ]
  ]
}
```

### **Chức Năng Cần Thay Thế:**
- ✅ **LangChain Integration** - Tích hợp với LangChain Agent
- ✅ **AI Language Model Output** - Xuất ra `ai_languageModel` type
- ✅ **Temperature Control** - Kiểm soát độ ngẫu nhiên
- ✅ **Credential Management** - Quản lý API key an toàn
- ✅ **Error Handling** - Xử lý lỗi API
- ✅ **Streaming Support** - Hỗ trợ streaming (optional)

## 🚀 **Phương Án 1: Custom LangChain Node** ⭐

### **Ưu Điểm:**
- ✅ **Tích hợp hoàn hảo** với LangChain
- ✅ **Performance tối ưu**
- ✅ **UI/UX giống native nodes**
- ✅ **Type safety**
- ✅ **Credential management**

### **Nhược Điểm:**
- ❌ **Cần compile custom node**
- ❌ **Phức tạp setup**

### **Implementation:**

#### **1. Node Definition:**
```typescript
// File: yescale-langchain.node.ts
export class YescaleLangChainNode implements INodeType {
  description: INodeTypeDescription = {
    displayName: 'Yescale LangChain',
    name: 'yescaleLangChain',
    group: ['langchain'],
    outputs: ['ai_languageModel'],
    credentials: [{ name: 'yescaleApi', required: true }],
    properties: [
      {
        displayName: 'Provider',
        name: 'provider',
        type: 'options',
        options: [
          { name: 'OpenAI', value: 'openai' },
          { name: 'Anthropic', value: 'anthropic' },
          { name: 'Google', value: 'google' }
        ],
        default: 'openai'
      },
      {
        displayName: 'Model',
        name: 'model',
        type: 'string',
        default: 'o3'
      },
      {
        displayName: 'Temperature',
        name: 'temperature',
        type: 'number',
        default: 0.7
      }
    ]
  };

  async execute(this: IExecuteFunctions) {
    const credentials = await this.getCredentials('yescaleApi');
    const yescaleLLM = new YescaleLLM({
      apiKey: credentials.apiKey as string,
      provider: this.getNodeParameter('provider', 0) as string,
      model: this.getNodeParameter('model', 0) as string,
      temperature: this.getNodeParameter('temperature', 0) as number
    });

    return { json: { llm: yescaleLLM } };
  }
}
```

#### **2. LangChain LLM Class:**
```typescript
class YescaleLLM extends BaseLLM {
  async _call(prompt: string): Promise<string> {
    const response = await fetch(`${this.baseUrl}/v1/chat/completions`, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${this.apiKey}`,
        'X-Provider': this.provider,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        model: this.model,
        messages: [{ role: 'user', content: prompt }],
        temperature: this.temperature
      })
    });

    const data = await response.json();
    return data.choices[0].message.content;
  }
}
```

## 🔧 **Phương Án 2: Code Node Bridge**

### **Ưu Điểm:**
- ✅ **Dễ implement** ngay lập tức
- ✅ **Không cần custom node**
- ✅ **Flexible configuration**

### **Nhược Điểm:**
- ❌ **Không native LangChain integration**
- ❌ **Performance kém hơn**

### **Implementation:**

#### **Thay Thế Node:**
```json
{
  "name": "Yescale LangChain Bridge",
  "type": "n8n-nodes-base.code",
  "parameters": {
    "jsCode": "// Yescale LangChain Bridge Implementation"
  }
}
```

#### **JavaScript Code:**
```javascript
// Yescale LangChain Bridge
class YescaleLangChainBridge {
  constructor(apiKey, provider = 'openai', model = 'o3') {
    this.apiKey = apiKey;
    this.provider = provider;
    this.model = model;
    this.temperature = 0.7;
  }

  async call(messages, options = {}) {
    const payload = {
      model: options.model || this.model,
      messages: this.formatMessages(messages),
      temperature: options.temperature ?? this.temperature,
      max_tokens: options.max_tokens || 1000
    };

    const response = await fetch('https://api.yescale.io/v1/chat/completions', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${this.apiKey}`,
        'X-Provider': this.provider
      },
      body: JSON.stringify(payload)
    });

    const data = await response.json();
    return data.choices[0].message.content;
  }

  formatMessages(messages) {
    if (typeof messages === 'string') {
      return [{ role: 'user', content: messages }];
    }
    return messages;
  }
}

// Main execution
const apiKey = $env.YESCALE_API_KEY || 'sk-your-api-key-here';
const provider = $env.YESCALE_PROVIDER || 'openai';
const model = $env.YESCALE_MODEL || 'o3';

const yescale = new YescaleLangChainBridge(apiKey, provider, model);

return [{
  json: {
    yescaleBridge: yescale,
    callMethod: yescale.call.bind(yescale),
    _type: 'yescale_langchain_bridge',
    ready: true
  }
}];
```

## 🔄 **Phương Án 3: Subworkflow Pattern**

### **Workflow Structure:**
```
Chat Trigger → AI Agent Controller
                     ↓
              [Tools & Memory]
                     ↓
              Yescale Subworkflow
```

### **Subworkflow Implementation:**
```json
{
  "name": "Yescale AI Subworkflow",
  "nodes": [
    {
      "name": "Webhook Trigger",
      "type": "n8n-nodes-base.webhook"
    },
    {
      "name": "Process Input",
      "type": "n8n-nodes-base.code"
    },
    {
      "name": "Yescale API Call",
      "type": "n8n-nodes-base.httpRequest"
    },
    {
      "name": "Format Response",
      "type": "n8n-nodes-base.code"
    },
    {
      "name": "Return Response",
      "type": "n8n-nodes-base.respondToWebhook"
    }
  ]
}
```

## 📋 **So Sánh Phương Án**

| Tiêu Chí | Custom Node | Code Bridge | Subworkflow |
|----------|-------------|-------------|-------------|
| **Dễ implement** | ❌ Phức tạp | ✅ Dễ | ✅ Trung bình |
| **Performance** | ✅ Tốt nhất | ❌ Trung bình | ❌ Chậm nhất |
| **LangChain Integration** | ✅ Native | ⚠️ Hack | ❌ Không có |
| **Maintenance** | ✅ Dễ | ⚠️ Trung bình | ❌ Phức tạp |
| **Scalability** | ✅ Tốt | ✅ Tốt | ❌ Hạn chế |
| **Flexibility** | ⚠️ Hạn chế | ✅ Cao | ✅ Rất cao |

## 🎯 **Khuyến Nghị**

### **Production:** Custom LangChain Node ⭐
```bash
# Step-by-step implementation
1. Tạo custom node TypeScript files
2. Compile và install vào n8n
3. Thay thế Google Gemini node
4. Configure Yescale credentials
5. Test workflow functionality
```

### **Development/Testing:** Code Node Bridge
```bash
# Quick implementation
1. Thay thế Google Gemini node bằng Code node
2. Copy/paste JavaScript bridge code
3. Set environment variables
4. Test basic functionality
```

### **Complex Requirements:** Subworkflow Pattern
```bash
# For advanced use cases
1. Tạo dedicated Yescale subworkflow
2. Implement custom logic & error handling
3. Connect via HTTP calls
4. Handle complex routing
```

## 🔧 **Implementation Steps**

### **Step 1: Backup Original Workflow**
```bash
# Export workflow trước khi thay đổi
curl -X GET "http://localhost:5678/api/v1/workflows/export/ID" > backup.json
```

### **Step 2: Replace Google Gemini Node**

#### **Option A: Custom Node**
```json
{
  "name": "Yescale LangChain",
  "type": "yescaleLangChain",
  "parameters": {
    "provider": "openai",
    "model": "o3",
    "temperature": 0.7
  }
}
```

#### **Option B: Code Bridge**
```json
{
  "name": "Yescale Bridge",
  "type": "n8n-nodes-base.code",
  "parameters": {
    "jsCode": "// Bridge implementation code here"
  }
}
```

### **Step 3: Update Connections**
```json
"connections": {
  "Yescale LangChain": {
    "ai_languageModel": [
      [
        {
          "node": "Your First AI Agent",
          "type": "ai_languageModel",
          "index": 0
        }
      ]
    ]
  }
}
```

### **Step 4: Configure Environment Variables**
```bash
# Set trong n8n environment
YESCALE_API_KEY=sk-your-api-key-here
YESCALE_PROVIDER=openai
YESCALE_MODEL=o3
```

### **Step 5: Test Functionality**
```bash
# Test cases
1. Basic chat interaction
2. Tool usage (weather, news)
3. Memory retention
4. Error handling
5. Performance benchmarking
```

## 🚨 **Common Issues & Solutions**

### **Issue 1: LangChain Type Mismatch**
```javascript
// Solution: Ensure proper type casting
const langchainCompatible = {
  _type: 'yescale_llm',
  call: yescale.call.bind(yescale),
  serialize: () => ({ _type: 'yescale' })
};
```

### **Issue 2: API Rate Limiting**
```javascript
// Solution: Add retry logic
async function callWithRetry(payload, maxRetries = 3) {
  for (let i = 0; i < maxRetries; i++) {
    try {
      return await makeAPICall(payload);
    } catch (error) {
      if (i === maxRetries - 1) throw error;
      await new Promise(resolve => setTimeout(resolve, 1000 * (i + 1)));
    }
  }
}
```

### **Issue 3: Memory Context Issues**
```javascript
// Solution: Proper message formatting
function formatConversationHistory(messages) {
  return messages.map(msg => ({
    role: msg.role,
    content: msg.content,
    timestamp: msg.timestamp
  }));
}
```

## 📊 **Performance Comparison**

| Metric | Google Gemini | Yescale (o3) | Yescale (gpt-4o) |
|--------|---------------|--------------|------------------|
| **Response Time** | ~2-3s | ~1-2s | ~2-4s |
| **Token Limit** | 30,720 | 128,000 | 128,000 |
| **Cost per 1K tokens** | $0.075 | ~$0.06 | ~$0.03 |
| **Reliability** | 99.9% | 99.5% | 99.7% |

## 🎯 **Next Steps**

1. **Choose implementation method** based on requirements
2. **Setup Yescale API credentials**
3. **Implement replacement node**
4. **Test thoroughly** with all use cases
5. **Deploy to production** when stable
6. **Monitor performance** and adjust as needed

## 📚 **Resources**

- **Yescale API Documentation:** https://docs.yescale.io
- **n8n Custom Node Guide:** https://docs.n8n.io/integrations/creating-nodes/
- **LangChain Documentation:** https://js.langchain.com/docs/
- **Example Implementation Files:**
  - `yescale-ai-agent-replacement.json`
  - `yescale-langchain-custom-node.ts`

---

**Happy Automating with Yescale! 🚀**
