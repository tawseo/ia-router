import axios from 'axios';
import { Address, AIProvider, AIRouteOptimization } from '../types';

/**
 * AI service for route optimization suggestions
 * Supports: OpenAI (ChatGPT), Google Gemini, DeepSeek, Qwen
 */
export class AIService {
  private providers: Record<AIProvider['id'], { apiKey: string; baseUrl: string }> = {
    openai: {
      apiKey: import.meta.env.VITE_OPENAI_API_KEY || '',
      baseUrl: 'https://api.openai.com/v1/chat/completions'
    },
    gemini: {
      apiKey: import.meta.env.VITE_GEMINI_API_KEY || '',
      baseUrl: 'https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent'
    },
    deepseek: {
      apiKey: import.meta.env.VITE_DEEPSEEK_API_KEY || '',
      baseUrl: 'https://api.deepseek.com/v1/chat/completions'
    },
    qwen: {
      apiKey: import.meta.env.VITE_QWEN_API_KEY || '',
      baseUrl: 'https://dashscope.aliyuncs.com/api/v1/services/aigc/text-generation/generation'
    }
  };

  /**
   * Get AI-powered route optimization suggestion
   */
  async getRouteOptimization(
    addresses: Address[],
    currentRoute: string[],
    provider: AIProvider['id']
  ): Promise<AIRouteOptimization | null> {
    try {
      const prompt = this.buildOptimizationPrompt(addresses, currentRoute);

      let response: string;

      switch (provider) {
        case 'openai':
          response = await this.callOpenAI(prompt);
          break;
        case 'gemini':
          response = await this.callGemini(prompt);
          break;
        case 'deepseek':
          response = await this.callDeepSeek(prompt);
          break;
        case 'qwen':
          response = await this.callQwen(prompt);
          break;
        default:
          throw new Error(`Unknown provider: ${provider}`);
      }

      return {
        provider,
        suggestion: response,
        reasoning: response,
        optimizedOrder: this.extractOrderFromResponse(response, addresses)
      };
    } catch (error) {
      console.error(`AI service error (${provider}):`, error);
      return null;
    }
  }

  /**
   * Build prompt for AI route optimization
   */
  private buildOptimizationPrompt(addresses: Address[], currentRoute: string[]): string {
    const addressList = addresses.map((addr, idx) => {
      const status = addr.status !== 'none' ? ` [${addr.status}]` : '';
      const coords = addr.coordinates
        ? ` (${addr.coordinates[0].toFixed(4)}, ${addr.coordinates[1].toFixed(4)})`
        : '';
      return `${idx + 1}. ${addr.rawAddress}${status}${coords}`;
    }).join('\n');

    return `You are a route optimization expert. Analyze the following delivery addresses in the UK and suggest the most efficient route order.

Addresses:
${addressList}

Current route order: ${currentRoute.join(' -> ')}

Constraints:
- Addresses marked [1st] must be first
- Addresses marked [last] must be last
- Addresses marked [am] should be in the morning
- Addresses marked [pm] should be in the afternoon
- Minimize total driving distance and time
- Consider geographic clustering

Please provide:
1. Recommended route order (list address numbers)
2. Brief reasoning for your suggestion
3. Estimated efficiency improvement

Format your response as:
ROUTE: 1,3,2,5,4
REASONING: [your explanation]`;
  }

  /**
   * Call OpenAI API (ChatGPT)
   */
  private async callOpenAI(prompt: string): Promise<string> {
    const config = this.providers.openai;

    if (!config.apiKey) {
      throw new Error('OpenAI API key not configured');
    }

    const response = await axios.post(
      config.baseUrl,
      {
        model: 'gpt-4',
        messages: [
          {
            role: 'system',
            content: 'You are a route optimization expert specializing in UK delivery logistics.'
          },
          {
            role: 'user',
            content: prompt
          }
        ],
        temperature: 0.7,
        max_tokens: 500
      },
      {
        headers: {
          'Authorization': `Bearer ${config.apiKey}`,
          'Content-Type': 'application/json'
        }
      }
    );

    return response.data.choices[0].message.content;
  }

  /**
   * Call Google Gemini API
   */
  private async callGemini(prompt: string): Promise<string> {
    const config = this.providers.gemini;

    if (!config.apiKey) {
      throw new Error('Gemini API key not configured');
    }

    const response = await axios.post(
      `${config.baseUrl}?key=${config.apiKey}`,
      {
        contents: [
          {
            parts: [
              {
                text: prompt
              }
            ]
          }
        ]
      },
      {
        headers: {
          'Content-Type': 'application/json'
        }
      }
    );

    return response.data.candidates[0].content.parts[0].text;
  }

  /**
   * Call DeepSeek API
   */
  private async callDeepSeek(prompt: string): Promise<string> {
    const config = this.providers.deepseek;

    if (!config.apiKey) {
      throw new Error('DeepSeek API key not configured');
    }

    const response = await axios.post(
      config.baseUrl,
      {
        model: 'deepseek-chat',
        messages: [
          {
            role: 'system',
            content: 'You are a route optimization expert specializing in UK delivery logistics.'
          },
          {
            role: 'user',
            content: prompt
          }
        ],
        temperature: 0.7
      },
      {
        headers: {
          'Authorization': `Bearer ${config.apiKey}`,
          'Content-Type': 'application/json'
        }
      }
    );

    return response.data.choices[0].message.content;
  }

  /**
   * Call Qwen API
   */
  private async callQwen(prompt: string): Promise<string> {
    const config = this.providers.qwen;

    if (!config.apiKey) {
      throw new Error('Qwen API key not configured');
    }

    const response = await axios.post(
      config.baseUrl,
      {
        model: 'qwen-plus',
        input: {
          messages: [
            {
              role: 'system',
              content: 'You are a route optimization expert specializing in UK delivery logistics.'
            },
            {
              role: 'user',
              content: prompt
            }
          ]
        },
        parameters: {
          temperature: 0.7
        }
      },
      {
        headers: {
          'Authorization': `Bearer ${config.apiKey}`,
          'Content-Type': 'application/json'
        }
      }
    );

    return response.data.output.text;
  }

  /**
   * Extract route order from AI response
   */
  private extractOrderFromResponse(response: string, addresses: Address[]): string[] | undefined {
    try {
      const routeMatch = response.match(/ROUTE:\s*([0-9,\s]+)/);
      if (routeMatch) {
        const indices = routeMatch[1].split(',').map(s => parseInt(s.trim()) - 1);
        return indices
          .filter(idx => idx >= 0 && idx < addresses.length)
          .map(idx => addresses[idx].id);
      }
    } catch (error) {
      console.error('Error extracting route order:', error);
    }
    return undefined;
  }

  /**
   * Check if provider is configured
   */
  isProviderConfigured(provider: AIProvider['id']): boolean {
    return Boolean(this.providers[provider].apiKey);
  }
}

export const aiService = new AIService();
