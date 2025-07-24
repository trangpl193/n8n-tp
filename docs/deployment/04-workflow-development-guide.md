# 04. Workflow Development Guide - Design System Automation

## 🎯 **Mục Tiêu**
Hướng dẫn tạo và phát triển workflows đầu tiên cho design system automation với integration YESCALE.io APIs và metadata management.

---

## 📋 **Prerequisites Checklist**

### **✅ System Ready:**
- [ ] **n8n accessible** at http://192.168.1.100:5678
- [ ] **Admin account created** và logged in
- [ ] **PostgreSQL connected** và healthy
- [ ] **Redis queue working** properly
- [ ] **System performance** optimized

### **🔧 Before Starting:**
```bash
# Verify n8n system health
ssh -i ~/.ssh/n8n_automation_rsa n8nadmin@192.168.1.100
cd ~/n8n-deployment
./monitor-n8n-stack.sh

# Should show all services healthy and responsive
```

---

## 🌐 **Phase 1: n8n Initial Setup**

### **Step 1: First Login & Configuration**

#### **👤 Admin Account Setup:**
```
Access URL: http://192.168.1.100:5678
First-time setup:
- Email: your-email@domain.com
- Password: [Strong password - document securely]
- First name: Design System
- Last name: Manager
```

#### **⚙️ Instance Configuration:**
```bash
# Navigate to Settings → General
Instance Settings:
- Instance name: "Personal Design Automation"
- Timezone: Asia/Ho_Chi_Minh (or your timezone)
- Default locale: en (English)

# Navigate to Settings → Endpoints
Webhook URL: http://192.168.1.100:5678/
```

### **Step 2: YESCALE.io API Setup**

#### **🔑 API Credentials Configuration:**
```bash
# In n8n, go to Credentials → Add credential
# Search for "HTTP Request Auth" or create Generic Auth

Credential Name: YESCALE-API
Type: Header Auth
Header Name: Authorization
Header Value: Bearer YOUR_YESCALE_API_KEY

# Document your YESCALE.io API key safely
```

#### **📝 YESCALE.io Endpoint Configuration:**
```bash
# Common YESCALE.io endpoints for design automation:
Base URL: https://api.yescale.io/v1/

Endpoints:
- Text Generation: /generate/text
- Image Analysis: /analyze/image
- Content Processing: /process/content
- Data Extraction: /extract/data

# Check YESCALE.io documentation for exact endpoints
```

---

## 📊 **Phase 2: Design System Core Workflows**

### **Workflow 1: Design Asset Metadata Extractor**

#### **🎯 Purpose:** 
Extract và standardize metadata từ design files uploaded to shared storage.

#### **📋 Workflow Structure:**
```
Trigger → File Monitor → Extract Metadata → Standardize Format → Store Database → Notify Team
```

#### **🔧 Implementation Steps:**

**Step 1: Create New Workflow**
```bash
# In n8n interface:
1. Click "Add workflow"
2. Name: "Design Asset Metadata Extractor"
3. Description: "Extracts và standardizes metadata from design files"
```

**Step 2: Setup File Monitor Trigger**
```bash
# Add Trigger Node:
Node Type: Webhook
Settings:
- Webhook Name: design-file-upload
- Path: design-upload
- Method: POST
- Response Mode: On Received

# Or use File Trigger if monitoring directory:
Node Type: File Trigger
Settings:
- Path: /path/to/design-files/
- Watch for: New files
- File types: .fig, .sketch, .psd, .ai
```

**Step 3: Metadata Extraction Node**
```bash
# Add Function Node:
Node Type: Code
Name: Extract File Metadata

JavaScript Code:
```javascript
// Extract metadata from uploaded file
const fileData = $json.body;
const fileName = fileData.name;
const fileSize = fileData.size;
const uploadDate = new Date().toISOString();

// Parse filename for project info
const filenameParts = fileName.split('_');
const projectCode = filenameParts[0] || 'UNKNOWN';
const componentType = filenameParts[1] || 'component';
const version = filenameParts[2] || 'v1.0';

// Create standardized metadata
const metadata = {
  id: `${projectCode}_${componentType}_${Date.now()}`,
  fileName: fileName,
  projectCode: projectCode,
  componentType: componentType,
  version: version,
  fileSize: fileSize,
  uploadDate: uploadDate,
  status: 'pending_review',
  tags: [],
  description: '',
  lastModified: uploadDate
};

return { metadata };
```

**Step 4: AI-Enhanced Metadata Processing**
```bash
# Add HTTP Request Node:
Node Type: HTTP Request
Name: YESCALE AI Analysis
Credential: YESCALE-API

Settings:
- Method: POST
- URL: https://api.yescale.io/v1/analyze/design-metadata
- Headers: Content-Type: application/json
- Body (JSON):
{
  "file_name": "{{$json.metadata.fileName}}",
  "component_type": "{{$json.metadata.componentType}}",
  "project_code": "{{$json.metadata.projectCode}}",
  "analysis_type": "design_metadata"
}
```

**Step 5: Database Storage**
```bash
# Add PostgreSQL Node:
Node Type: Postgres
Name: Store Metadata
Credential: n8n-postgres (create if needed)

Operation: Insert
Table: design_assets
Columns:
- id: {{$json.metadata.id}}
- file_name: {{$json.metadata.fileName}}
- project_code: {{$json.metadata.projectCode}}
- component_type: {{$json.metadata.componentType}}
- version: {{$json.metadata.version}}
- file_size: {{$json.metadata.fileSize}}
- upload_date: {{$json.metadata.uploadDate}}
- ai_tags: {{$json.ai_analysis.tags}}
- ai_description: {{$json.ai_analysis.description}}
- status: {{$json.metadata.status}}
```

#### **✅ Testing & Validation:**
```bash
# Test workflow:
1. Click "Execute Workflow" 
2. Send test webhook request:

curl -X POST \
  http://192.168.1.100:5678/webhook/design-upload \
  -H 'Content-Type: application/json' \
  -d '{
    "name": "PROJECT001_button_v1.2.fig",
    "size": 2048,
    "url": "https://example.com/file.fig"
  }'

# Verify results in n8n execution log và database
```

### **Workflow 2: Design System Documentation Generator**

#### **🎯 Purpose:**
Automatically generate và update design system documentation từ component metadata.

#### **📋 Workflow Structure:**
```
Schedule Trigger → Fetch Components → Generate Docs → AI Enhancement → Update Repository
```

#### **🔧 Implementation:**

**Step 1: Scheduled Trigger**
```bash
Node Type: Schedule Trigger
Name: Daily Doc Update
Settings:
- Trigger Rules: Cron Expression
- Cron: 0 9 * * * (9 AM daily)
- Timezone: Asia/Ho_Chi_Minh
```

**Step 2: Component Data Fetcher**
```bash
Node Type: Postgres
Name: Fetch Components
Operation: Select
Query:
SELECT 
  id, file_name, project_code, component_type, 
  version, ai_tags, ai_description, status,
  upload_date
FROM design_assets 
WHERE status = 'approved' 
  AND component_type != 'archive'
ORDER BY project_code, component_type, version DESC
```

**Step 3: Documentation Generator**
```bash
Node Type: Code
Name: Generate Documentation

JavaScript Code:
```javascript
// Group components by project and type
const components = $json;
const grouped = {};

components.forEach(comp => {
  const key = `${comp.project_code}_${comp.component_type}`;
  if (!grouped[key]) {
    grouped[key] = [];
  }
  grouped[key].push(comp);
});

// Generate markdown documentation
let documentation = "# Design System Components\n\n";
documentation += `Generated on: ${new Date().toISOString()}\n\n`;

Object.keys(grouped).forEach(key => {
  const [project, type] = key.split('_');
  const comps = grouped[key];
  
  documentation += `## ${project} - ${type}\n\n`;
  
  comps.forEach(comp => {
    documentation += `### ${comp.file_name}\n`;
    documentation += `- Version: ${comp.version}\n`;
    documentation += `- Description: ${comp.ai_description}\n`;
    documentation += `- Tags: ${comp.ai_tags}\n`;
    documentation += `- Last Updated: ${comp.upload_date}\n\n`;
  });
});

return { documentation, componentCount: components.length };
```

**Step 4: AI Documentation Enhancement**
```bash
Node Type: HTTP Request
Name: AI Doc Enhancement
Credential: YESCALE-API

Settings:
- Method: POST
- URL: https://api.yescale.io/v1/enhance/documentation
- Body:
{
  "content": "{{$json.documentation}}",
  "type": "design_system_docs",
  "enhancement_level": "professional",
  "format": "markdown"
}
```

### **Workflow 3: Email Automation for Design Updates**

#### **🎯 Purpose:**
Notify stakeholders về design updates, new components, và system changes.

#### **📋 Workflow Structure:**
```
Database Change Trigger → Categorize Change → Generate Email → Send Notification
```

#### **🔧 Implementation:**

**Step 1: Database Change Monitor**
```bash
Node Type: Schedule Trigger (Poll every 15 minutes)
Name: Check Design Updates

# Use Code node to check for recent changes
Node Type: Code
Name: Detect Changes

JavaScript Code:
```javascript
// Check for changes in last 15 minutes
const cutoffTime = new Date(Date.now() - 15 * 60 * 1000).toISOString();

// This will connect to PostgreSQL to check recent changes
const query = `
  SELECT * FROM design_assets 
  WHERE upload_date > '${cutoffTime}' 
     OR last_modified > '${cutoffTime}'
  ORDER BY upload_date DESC
`;

return { 
  hasChanges: true, // Will be determined by actual query results
  cutoffTime,
  query 
};
```

**Step 2: Email Template Generator**
```bash
Node Type: Code
Name: Generate Email Content

JavaScript Code:
```javascript
const changes = $json.changes || [];
const changeCount = changes.length;

if (changeCount === 0) {
  return { skip: true };
}

// Generate email content
const subject = `Design System Update - ${changeCount} changes detected`;

let htmlContent = `
<h2>Design System Updates</h2>
<p>Hello,</p>
<p>We have detected ${changeCount} updates to the design system:</p>
<ul>
`;

changes.forEach(change => {
  htmlContent += `
  <li>
    <strong>${change.file_name}</strong> (${change.component_type})
    <br>Project: ${change.project_code}
    <br>Status: ${change.status}
    <br>Updated: ${change.upload_date}
  </li>
  `;
});

htmlContent += `
</ul>
<p>Please review these changes in the design system portal.</p>
<p>Best regards,<br>Design Automation System</p>
`;

return { 
  subject, 
  htmlContent, 
  recipientList: ['team@company.com', 'designer@company.com'] 
};
```

**Step 3: Email Sender**
```bash
Node Type: Email Send
Name: Send Update Notification
Credential: Email-SMTP (configure your email provider)

Settings:
- To: {{$json.recipientList}}
- Subject: {{$json.subject}}
- Text: [Plain text version]
- HTML: {{$json.htmlContent}}
```

---

## 🔄 **Phase 3: Advanced Workflow Patterns**

### **Pattern 1: Error Handling & Retry Logic**

#### **🛡️ Implementation:**
```bash
# Add Error Trigger after each critical node:
Node Type: Error Trigger
Connected to: Main workflow nodes

# Add Retry Logic:
Node Type: Code
Name: Retry Handler

JavaScript Code:
```javascript
const maxRetries = 3;
const currentAttempt = $json.attempt || 1;

if (currentAttempt <= maxRetries) {
  // Log retry attempt
  console.log(`Retry attempt ${currentAttempt} of ${maxRetries}`);
  
  return { 
    retry: true, 
    attempt: currentAttempt + 1,
    delay: currentAttempt * 1000 // Exponential backoff
  };
} else {
  // Max retries exceeded - send alert
  return { 
    retry: false, 
    failed: true, 
    error: 'Max retries exceeded' 
  };
}
```

### **Pattern 2: Workflow Orchestration**

#### **🎭 Master Controller Workflow:**
```bash
# Create orchestrator workflow:
Name: Design System Orchestrator
Purpose: Coordinate multiple workflows based on events

Trigger: Webhook (receives events from various sources)
Logic: Route to appropriate sub-workflows based on event type

Event Types:
- file_upload → Asset Metadata Extractor
- documentation_request → Documentation Generator  
- team_notification → Email Automation
- performance_check → System Monitoring
```

### **Pattern 3: Data Validation & Quality Control**

#### **✅ Validation Nodes:**
```bash
Node Type: Code
Name: Validate Design Asset

JavaScript Code:
```javascript
const asset = $json;
const errors = [];

// Validate required fields
if (!asset.file_name) errors.push('Missing file name');
if (!asset.project_code) errors.push('Missing project code');
if (!asset.component_type) errors.push('Missing component type');

// Validate file naming convention
const namePattern = /^[A-Z]{3,6}_[a-z_]+_v\d+\.\d+\.(fig|sketch|psd)$/;
if (!namePattern.test(asset.file_name)) {
  errors.push('File name does not follow naming convention');
}

// Validate file size (max 50MB)
if (asset.file_size > 50 * 1024 * 1024) {
  errors.push('File size exceeds 50MB limit');
}

return {
  isValid: errors.length === 0,
  errors: errors,
  asset: asset
};
```

---

## 📊 **Phase 4: Performance Optimization**

### **Memory Management:**

#### **🔧 Workflow Optimization:**
```bash
# For large data processing:
1. Use "Split In Batches" node for large datasets
2. Configure batch size: 50-100 items per batch
3. Add delays between batches: 1-2 seconds

# Example batch configuration:
Node Type: Split In Batches
Batch Size: 50
Options: Reset after batch completion
```

### **Database Query Optimization:**

#### **📈 Efficient Queries:**
```sql
-- Index creation for better performance
CREATE INDEX idx_design_assets_project_type 
ON design_assets(project_code, component_type);

CREATE INDEX idx_design_assets_upload_date 
ON design_assets(upload_date);

CREATE INDEX idx_design_assets_status 
ON design_assets(status);

-- Optimized query patterns
SELECT * FROM design_assets 
WHERE upload_date >= CURRENT_DATE - INTERVAL '7 days'
  AND status = 'approved'
ORDER BY upload_date DESC
LIMIT 100;
```

### **API Rate Limiting:**

#### **⚡ YESCALE.io Optimization:**
```bash
# Add rate limiting logic:
Node Type: Code
Name: Rate Limiter

JavaScript Code:
```javascript
const lastCallTime = $context.get('lastApiCall') || 0;
const minInterval = 1000; // 1 second between calls
const now = Date.now();

if (now - lastCallTime < minInterval) {
  const delay = minInterval - (now - lastCallTime);
  await new Promise(resolve => setTimeout(resolve, delay));
}

$context.set('lastApiCall', Date.now());
return $json;
```

---

## 📋 **Phase 5: Testing & Deployment**

### **Workflow Testing Checklist:**

#### **🧪 Test Scenarios:**
- [ ] **Normal operation** - Standard file upload và processing
- [ ] **Error conditions** - Invalid files, API failures, network issues  
- [ ] **Edge cases** - Large files, special characters, concurrent uploads
- [ ] **Performance** - Multiple simultaneous workflows
- [ ] **Data integrity** - Verify all data stored correctly

#### **🔍 Test Data:**
```bash
# Create test files with various scenarios:
Valid: PROJECT001_button_v1.0.fig
Invalid name: random-file.fig  
Large file: test-large-50mb.fig
Special chars: PROJECT_001_button@#$.fig
```

### **Production Deployment:**

#### **📦 Workflow Export/Import:**
```bash
# Export workflows for backup:
1. Select workflow in n8n
2. Click "..." → "Export workflow"
3. Save JSON file to backup location

# Import to another instance:
1. Click "Import from URL or File"
2. Select exported JSON file
3. Verify all credentials and connections
```

#### **🔄 Environment Configuration:**
```bash
# Production vs Development settings:
Development:
- Webhook URLs: http://192.168.1.100:5678/
- Database: Local PostgreSQL
- Logging: Verbose

Production:
- Webhook URLs: https://your-domain.com/
- Database: Production PostgreSQL  
- Logging: Error level only
- Backup: Automated daily backups
```

---

## ✅ **Success Criteria**

### **📊 Workflow Performance Metrics:**
- [ ] **Execution Time:** <30 seconds for metadata extraction
- [ ] **Error Rate:** <1% for normal operations  
- [ ] **API Response:** <5 seconds for YESCALE.io calls
- [ ] **Database Queries:** <1 second average response time
- [ ] **Email Delivery:** <2 minutes for notifications

### **🎯 Business Value Metrics:**
- [ ] **Time Savings:** 10+ hours/week từ automation
- [ ] **Error Reduction:** 90% fewer manual mistakes
- [ ] **Documentation Currency:** Always up-to-date design docs
- [ ] **Team Productivity:** Faster design system adoption
- [ ] **Process Standardization:** Consistent metadata across projects

---

## 🔄 **Troubleshooting Guide**

### **Common Issues:**

#### **Workflow Execution Fails:**
```bash
# Check execution logs:
1. Go to Executions in n8n
2. Click failed execution
3. Review error messages và node outputs

# Common fixes:
- Verify API credentials
- Check database connectivity  
- Validate input data format
- Review node configurations
```

#### **YESCALE.io API Issues:**
```bash
# Debug API calls:
1. Check API key validity
2. Verify endpoint URLs
3. Review request/response in HTTP Request node logs
4. Test API directly with curl:

curl -X POST \
  https://api.yescale.io/v1/test \
  -H 'Authorization: Bearer YOUR_API_KEY' \
  -H 'Content-Type: application/json'
```

#### **Performance Problems:**
```bash
# Monitor resource usage:
ssh -i ~/.ssh/n8n_automation_rsa n8nadmin@192.168.1.100
cd ~/n8n-deployment
./monitor-n8n-stack.sh

# Optimize slow workflows:
1. Add batch processing for large datasets
2. Implement caching for repeated operations
3. Use database indexes for common queries
4. Add delays between API calls
```

---

## 📞 **Next Steps**

### **Immediate Actions:**
1. ✅ **Implement core workflows** (Metadata Extractor, Doc Generator, Email Automation)
2. 📊 **Monitor performance** và optimize as needed
3. 🔄 **Test thoroughly** với real design assets
4. 📚 **Document workflows** cho team knowledge sharing

### **Advanced Development:**
1. 🤖 **Develop custom nodes** cho specialized design tools
2. 🔗 **Integrate additional services** (Slack, Figma API, Git repositories)
3. 📈 **Implement analytics** để track automation effectiveness
4. 🎨 **Build design system dashboard** với real-time metrics

---

*Tài liệu này provides comprehensive guide cho developing design system automation workflows. Start với basic workflows và gradually add complexity based on needs và performance.* 