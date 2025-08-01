import type { Credential } from './credential-manager';

export interface WorkflowTemplate {
  id: string;
  name: string;
  description: string;
  category: string;
  tags: string[];
  version: string;
  requiredCredentials: RequiredCredential[];
  workflow: WorkflowDefinition;
  metadata: Record<string, unknown>;
}

export interface RequiredCredential {
  name: string;
  type: string;
  required: boolean;
  description: string;
}

export interface WorkflowDefinition {
  nodes: WorkflowNode[];
  connections: Record<string, NodeConnection[]>;
}

export interface WorkflowNode {
  id: string;
  type: string;
  position: [number, number];
  parameters: Record<string, unknown>;
  credentials?: Record<string, string>;
}

export interface NodeConnection {
  node: string;
  type: string;
  index: number;
}

export class WorkflowTemplateManager {
  private templates: Map<string, WorkflowTemplate> = new Map();

  async loadTemplate(templateId: string): Promise<WorkflowTemplate | null> {
    return this.templates.get(templateId) || null;
  }

  async saveTemplate(template: WorkflowTemplate): Promise<void> {
    this.templates.set(template.id, template);
  }

  async listTemplates(category?: string): Promise<WorkflowTemplate[]> {
    const templates = Array.from(this.templates.values());
    
    if (category) {
      return templates.filter(t => t.category === category);
    }
    
    return templates;
  }

  async instantiateTemplate(
    templateId: string, 
    credentials: Record<string, Credential>
  ): Promise<WorkflowDefinition> {
    const template = await this.loadTemplate(templateId);
    
    if (!template) {
      throw new Error(`Template ${templateId} not found`);
    }

    // Validate required credentials
    for (const reqCred of template.requiredCredentials) {
      if (reqCred.required && !credentials[reqCred.name]) {
        throw new Error(`Required credential ${reqCred.name} not provided`);
      }
    }

    // Clone workflow definition và inject credentials
    const workflow: WorkflowDefinition = JSON.parse(JSON.stringify(template.workflow));
    
    // Inject credentials into nodes
    for (const node of workflow.nodes) {
      if (node.credentials) {
        for (const [credKey, credName] of Object.entries(node.credentials)) {
          if (credentials[credName]) {
            node.credentials[credKey] = credentials[credName].id;
          }
        }
      }
    }

    return workflow;
  }

  generateTemplateId(name: string): string {
    return `template_${name.toLowerCase().replace(/\s+/g, '_')}_${Date.now()}`;
  }
}

// Predefined template categories
export const TEMPLATE_CATEGORIES = {
  AI_ML: 'AI & Machine Learning',
  CLOUD: 'Cloud Services',
  DATA: 'Data & Analytics', 
  COMMUNICATION: 'Communication',
  DEVOPS: 'Development & DevOps',
} as const;

export type TemplateCategory = typeof TEMPLATE_CATEGORIES[keyof typeof TEMPLATE_CATEGORIES];
