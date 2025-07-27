import {
	INodeType,
	INodeTypeDescription,
	IExecuteFunctions,
	INodeProperties,
	IDataObject,
} from 'n8n-workflow';

import { BaseLLM } from '@langchain/core/language_models/llms';
import { CallbackManagerForLLMRun } from '@langchain/core/callbacks/manager';

/**
 * Custom Yescale LangChain LLM Implementation
 */
class YescaleLLM extends BaseLLM {
	apiKey: string;
	baseUrl: string;
	provider: string;
	model: string;
	temperature: number;
	maxTokens: number;

	constructor(fields: {
		apiKey: string;
		baseUrl?: string;
		provider?: string;
		model?: string;
		temperature?: number;
		maxTokens?: number;
	}) {
		super({});
		this.apiKey = fields.apiKey;
		this.baseUrl = fields.baseUrl || 'https://api.yescale.io';
		this.provider = fields.provider || 'openai';
		this.model = fields.model || 'o3';
		this.temperature = fields.temperature ?? 0.7;
		this.maxTokens = fields.maxTokens || 1000;
	}

	_llmType(): string {
		return 'yescale';
	}

	async _call(
		prompt: string,
		options: this['ParsedCallOptions'],
		runManager?: CallbackManagerForLLMRun,
	): Promise<string> {
		const payload = {
			model: this.model,
			messages: [
				{
					role: 'user',
					content: prompt,
				},
			],
			temperature: this.temperature,
			max_tokens: this.maxTokens,
			stream: false,
		};

		try {
			const response = await fetch(`${this.baseUrl}/v1/chat/completions`, {
				method: 'POST',
				headers: {
					'Content-Type': 'application/json',
					Authorization: `Bearer ${this.apiKey}`,
					'X-Provider': this.provider,
				},
				body: JSON.stringify(payload),
			});

			if (!response.ok) {
				throw new Error(`Yescale API error: ${response.status} ${response.statusText}`);
			}

			const data = await response.json();

			if (data.choices && data.choices.length > 0) {
				const content = data.choices[0].message.content;

				// Call runManager callback if available
				await runManager?.handleLLMNewToken(content);

				return content;
			}

			throw new Error('No response from Yescale API');
		} catch (error) {
			throw new Error(`Yescale API call failed: ${error.message}`);
		}
	}

	// Serialize for storing/loading
	serialize(): IDataObject {
		return {
			_type: this._llmType(),
			provider: this.provider,
			model: this.model,
			temperature: this.temperature,
			maxTokens: this.maxTokens,
		};
	}

	// Get available models
	async getAvailableModels(): Promise<string[]> {
		try {
			const response = await fetch(`${this.baseUrl}/v1/models`, {
				headers: {
					Authorization: `Bearer ${this.apiKey}`,
					'X-Provider': this.provider,
				},
			});

			if (response.ok) {
				const data = await response.json();
				return data.data?.map((model: any) => model.id) || [];
			}
		} catch (error) {
			console.warn('Could not fetch available models:', error);
		}

		// Fallback models
		return ['o3', 'gpt-4o', 'gpt-4o-mini', 'gpt-3.5-turbo', 'claude-3-sonnet-20240229'];
	}
}

/**
 * n8n Node Definition for Yescale LangChain Integration
 */
export class YescaleLangChainNode implements INodeType {
	description: INodeTypeDescription = {
		displayName: 'Yescale LangChain',
		name: 'yescaleLangChain',
		icon: 'file:yescale.svg',
		group: ['langchain'],
		version: 1,
		description: 'Use Yescale API with LangChain',
		defaults: {
			name: 'Yescale LangChain',
		},
		credentials: [
			{
				name: 'yescaleApi',
				required: true,
			},
		],
		inputs: [],
		outputs: ['ai_languageModel'],
		outputNames: ['Model'],
		properties: [
			{
				displayName: 'Provider',
				name: 'provider',
				type: 'options',
				options: [
					{
						name: 'OpenAI',
						value: 'openai',
					},
					{
						name: 'Anthropic',
						value: 'anthropic',
					},
					{
						name: 'Google',
						value: 'google',
					},
					{
						name: 'Meta',
						value: 'meta',
					},
				],
				default: 'openai',
				description: 'AI provider to use through Yescale',
			},
			{
				displayName: 'Model',
				name: 'model',
				type: 'string',
				default: 'o3',
				description:
					'The model to use. Popular options: o3, gpt-4o, gpt-4o-mini, claude-3-sonnet-20240229',
				placeholder: 'o3',
			},
			{
				displayName: 'Temperature',
				name: 'temperature',
				type: 'number',
				typeOptions: {
					numberPrecision: 1,
					minValue: 0,
					maxValue: 2,
				},
				default: 0.7,
				description: 'Controls randomness in the response. Higher values make output more random.',
			},
			{
				displayName: 'Maximum Tokens',
				name: 'maxTokens',
				type: 'number',
				typeOptions: {
					minValue: 1,
				},
				default: 1000,
				description: 'The maximum number of tokens to generate',
			},
			{
				displayName: 'Options',
				name: 'options',
				type: 'collection',
				placeholder: 'Add Option',
				default: {},
				options: [
					{
						displayName: 'Base URL',
						name: 'baseUrl',
						type: 'string',
						default: 'https://api.yescale.io',
						description: 'Base URL for Yescale API',
					},
					{
						displayName: 'Timeout',
						name: 'timeout',
						type: 'number',
						default: 30000,
						description: 'Timeout in milliseconds',
					},
					{
						displayName: 'Top P',
						name: 'topP',
						type: 'number',
						typeOptions: {
							numberPrecision: 1,
							minValue: 0,
							maxValue: 1,
						},
						default: 1,
						description: 'Controls diversity of response',
					},
				],
			},
		],
	};

	async execute(this: IExecuteFunctions) {
		const credentials = await this.getCredentials('yescaleApi');
		const provider = this.getNodeParameter('provider', 0) as string;
		const model = this.getNodeParameter('model', 0) as string;
		const temperature = this.getNodeParameter('temperature', 0) as number;
		const maxTokens = this.getNodeParameter('maxTokens', 0) as number;
		const options = this.getNodeParameter('options', 0, {}) as IDataObject;

		// Initialize Yescale LLM
		const yescaleLLM = new YescaleLLM({
			apiKey: credentials.apiKey as string,
			baseUrl: (options.baseUrl as string) || 'https://api.yescale.io',
			provider,
			model,
			temperature,
			maxTokens,
		});

		// Return the LangChain-compatible LLM instance
		return {
			json: {
				llm: yescaleLLM,
			},
		};
	}
}

/**
 * Credential Type for Yescale API
 */
export class YescaleApiCredentials {
	name = 'yescaleApi';
	displayName = 'Yescale API';
	documentationUrl = 'https://docs.yescale.io';

	properties: INodeProperties[] = [
		{
			displayName: 'API Key',
			name: 'apiKey',
			type: 'string',
			typeOptions: {
				password: true,
			},
			default: '',
			required: true,
			description: 'Your Yescale API key',
		},
	];
}
