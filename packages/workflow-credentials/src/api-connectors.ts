import type { Credential } from './credential-manager';

export interface APIConnectorConfig {
  id: string;
  name: string;
  type: string;
  baseUrl: string;
  authentication: AuthenticationConfig;
  rateLimiting?: RateLimitConfig;
  retryPolicy?: RetryPolicyConfig;
  timeout?: number;
  headers?: Record<string, string>;
}

export interface AuthenticationConfig {
  type: 'api-key' | 'oauth2' | 'basic' | 'bearer' | 'custom';
  credentials: string; // Credential ID
  config?: Record<string, unknown>;
}

export interface RateLimitConfig {
  requests: number;
  window: number; // in milliseconds
  strategy: 'fixed' | 'sliding';
}

export interface RetryPolicyConfig {
  maxRetries: number;
  baseDelay: number;
  maxDelay: number;
  backoffStrategy: 'exponential' | 'linear' | 'fixed';
}

export interface APIResponse<T = unknown> {
  success: boolean;
  data?: T;
  error?: string;
  statusCode?: number;
  headers?: Record<string, string>;
  executionTime: number;
}

export class APIConnector {
  private config: APIConnectorConfig;
  private credential: Credential;

  constructor(config: APIConnectorConfig, credential: Credential) {
    this.config = config;
    this.credential = credential;
  }

  async request<T = unknown>(
    endpoint: string,
    options: RequestOptions = {}
  ): Promise<APIResponse<T>> {
    const startTime = Date.now();
    
    try {
      const url = this.buildUrl(endpoint);
      const headers = await this.buildHeaders(options.headers);
      const body = options.body ? JSON.stringify(options.body) : undefined;

      const response = await fetch(url, {
        method: options.method || 'GET',
        headers,
        body,
        signal: AbortSignal.timeout(this.config.timeout || 30000),
      });

      const responseData = await this.parseResponse<T>(response);
      
      const headersObj: Record<string, string> = {};
      response.headers.forEach((value, key) => {
        headersObj[key] = value;
      });

      return {
        success: response.ok,
        data: responseData,
        statusCode: response.status,
        headers: headersObj,
        executionTime: Date.now() - startTime,
      };
    } catch (error) {
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Unknown error',
        executionTime: Date.now() - startTime,
      };
    }
  }

  async get<T = unknown>(endpoint: string, params?: Record<string, string>): Promise<APIResponse<T>> {
    const url = params ? `${endpoint}?${new URLSearchParams(params)}` : endpoint;
    return this.request<T>(url, { method: 'GET' });
  }

  async post<T = unknown>(endpoint: string, data?: unknown): Promise<APIResponse<T>> {
    return this.request<T>(endpoint, { method: 'POST', body: data });
  }

  async put<T = unknown>(endpoint: string, data?: unknown): Promise<APIResponse<T>> {
    return this.request<T>(endpoint, { method: 'PUT', body: data });
  }

  async delete<T = unknown>(endpoint: string): Promise<APIResponse<T>> {
    return this.request<T>(endpoint, { method: 'DELETE' });
  }

  private buildUrl(endpoint: string): string {
    const baseUrl = this.config.baseUrl.replace(/\/+$/, '');
    const cleanEndpoint = endpoint.replace(/^\/+/, '');
    return `${baseUrl}/${cleanEndpoint}`;
  }

  private async buildHeaders(additionalHeaders?: Record<string, string>): Promise<Record<string, string>> {
    const headers: Record<string, string> = {
      'Content-Type': 'application/json',
      ...this.config.headers,
      ...additionalHeaders,
    };

    // Add authentication headers
    switch (this.config.authentication.type) {
      case 'api-key':
        const apiKeyConfig = this.config.authentication.config as { header: string; prefix?: string };
        const apiKey = this.credential.data.apiKey as string;
        headers[apiKeyConfig.header] = apiKeyConfig.prefix ? `${apiKeyConfig.prefix} ${apiKey}` : apiKey;
        break;
      
      case 'bearer':
        const token = this.credential.data.token as string;
        headers['Authorization'] = `Bearer ${token}`;
        break;
      
      case 'basic':
        const username = this.credential.data.username as string;
        const password = this.credential.data.password as string;
        const basicAuth = btoa(`${username}:${password}`);
        headers['Authorization'] = `Basic ${basicAuth}`;
        break;
    }

    return headers;
  }

  private async parseResponse<T>(response: Response): Promise<T> {
    const contentType = response.headers.get('content-type');
    
    if (contentType?.includes('application/json')) {
      return response.json();
    }
    
    return response.text() as T;
  }
}

export interface RequestOptions {
  method?: 'GET' | 'POST' | 'PUT' | 'DELETE' | 'PATCH';
  headers?: Record<string, string>;
  body?: unknown;
}

export class APIConnectorManager {
  private connectors: Map<string, APIConnector> = new Map();
  private configs: Map<string, APIConnectorConfig> = new Map();

  registerConnector(config: APIConnectorConfig, credential: Credential): APIConnector {
    const connector = new APIConnector(config, credential);
    this.connectors.set(config.id, connector);
    this.configs.set(config.id, config);
    return connector;
  }

  getConnector(id: string): APIConnector | null {
    return this.connectors.get(id) || null;
  }

  listConnectors(): APIConnectorConfig[] {
    return Array.from(this.configs.values());
  }

  removeConnector(id: string): void {
    this.connectors.delete(id);
    this.configs.delete(id);
  }
}

// Common API connector configurations
export const COMMON_CONNECTORS = {
  OPENAI: {
    id: 'openai',
    name: 'OpenAI API',
    type: 'openai',
    baseUrl: 'https://api.openai.com/v1',
    authentication: {
      type: 'bearer' as const,
      credentials: 'openai_credential',
    },
    rateLimiting: {
      requests: 60,
      window: 60000,
      strategy: 'sliding' as const,
    },
  },
  ANTHROPIC: {
    id: 'anthropic',
    name: 'Anthropic Claude API',
    type: 'anthropic',
    baseUrl: 'https://api.anthropic.com/v1',
    authentication: {
      type: 'api-key' as const,
      credentials: 'anthropic_credential',
      config: { header: 'x-api-key' },
    },
  },
} as const;
