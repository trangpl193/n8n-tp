# @n8n/workflow-credentials

Secure credential management system for n8n workflows với enterprise-grade encryption và workflow template integration.

## Features

- 🔒 **Secure Encryption**: AES-256-GCM encryption cho sensitive credentials
- 📋 **Workflow Templates**: Pre-configured templates với credential mapping
- 🔌 **API Connectors**: Standardized API integration với rate limiting
- 🛡️ **Access Control**: Role-based access control và audit logging
- ⚡ **Performance**: Sub-100ms credential retrieval times

## Installation

```bash
npm install @n8n/workflow-credentials
```

## Usage

### Credential Management

```typescript
import { SecureCredentialManager } from '@n8n/workflow-credentials';

const credentialManager = new SecureCredentialManager('your-master-key');

// Store encrypted credential
const credentialId = await credentialManager.store({
  name: 'OpenAI API Key',
  type: 'openai',
  data: {
    apiKey: 'sk-...',
    organization: 'org-...'
  },
  encrypted: true,
  tags: ['ai', 'openai']
});

// Retrieve và decrypt credential
const credential = await credentialManager.retrieve(credentialId);
```

### Workflow Templates

```typescript
import { WorkflowTemplateManager } from '@n8n/workflow-credentials';

const templateManager = new WorkflowTemplateManager();

// Load template
const template = await templateManager.loadTemplate('ai-content-generation');

// Instantiate với credentials
const workflow = await templateManager.instantiateTemplate(
  'ai-content-generation',
  { 
    openai_api: openaiCredential,
    anthropic_api: claudeCredential
  }
);
```

### API Connectors

```typescript
import { APIConnectorManager, COMMON_CONNECTORS } from '@n8n/workflow-credentials';

const connectorManager = new APIConnectorManager();

// Register OpenAI connector
const openaiConnector = connectorManager.registerConnector(
  COMMON_CONNECTORS.OPENAI,
  openaiCredential
);

// Make API calls
const response = await openaiConnector.post('/chat/completions', {
  model: 'gpt-4',
  messages: [{ role: 'user', content: 'Hello!' }]
});
```

## Security

- **AES-256-GCM**: Symmetric encryption với authentication
- **Key Derivation**: PBKDF2 với salt cho key derivation
- **Access Control**: Role-based permissions
- **Audit Logging**: Complete access audit trail

## Integration với n8n

Package này được thiết kế để integrate seamlessly với n8n workflow engine:

- Automatic credential injection vào workflow nodes
- Template-based workflow generation
- Secure credential storage trong PostgreSQL
- Integration với n8n credential system

## License

SEE LICENSE IN LICENSE.md
