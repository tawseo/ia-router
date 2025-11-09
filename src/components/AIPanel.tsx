import { useState } from 'react';
import { Brain, Sparkles } from 'lucide-react';
import { Address, OptimizedRoute, AIProvider } from '../types';
import { aiService } from '../services/ai';
import './AIPanel.css';

interface AIPanelProps {
  addresses: Address[];
  currentRoute: OptimizedRoute | null;
  onApplySuggestion: (newOrder: string[]) => void;
}

const aiProviders: { id: AIProvider['id']; name: string }[] = [
  { id: 'openai', name: 'ChatGPT' },
  { id: 'gemini', name: 'Gemini' },
  { id: 'deepseek', name: 'DeepSeek' },
  { id: 'qwen', name: 'Qwen' }
];

const AIPanel = ({ addresses, currentRoute, onApplySuggestion }: AIPanelProps) => {
  const [selectedProvider, setSelectedProvider] = useState<AIProvider['id']>('openai');
  const [isProcessing, setIsProcessing] = useState(false);
  const [suggestion, setSuggestion] = useState<string>('');
  const [suggestedOrder, setSuggestedOrder] = useState<string[] | null>(null);

  const handleGetSuggestion = async () => {
    if (!aiService.isProviderConfigured(selectedProvider)) {
      alert(`${aiProviders.find(p => p.id === selectedProvider)?.name} API key not configured. Please add it to your .env file.`);
      return;
    }

    if (addresses.length < 2) {
      alert('Please add at least 2 addresses');
      return;
    }

    setIsProcessing(true);
    setSuggestion('');
    setSuggestedOrder(null);

    try {
      const currentOrder = currentRoute
        ? currentRoute.addresses.map((a, idx) => `${idx + 1}. ${a.rawAddress}`)
        : addresses.map((a, idx) => `${idx + 1}. ${a.rawAddress}`);

      const result = await aiService.getRouteOptimization(
        addresses,
        currentOrder,
        selectedProvider
      );

      if (result) {
        setSuggestion(result.suggestion);
        setSuggestedOrder(result.optimizedOrder || null);
      } else {
        setSuggestion('Could not get AI suggestion. Please check your API key and try again.');
      }
    } catch (error) {
      console.error('AI suggestion error:', error);
      setSuggestion('Error getting AI suggestion. Please try again.');
    } finally {
      setIsProcessing(false);
    }
  };

  const handleApplySuggestion = () => {
    if (suggestedOrder) {
      onApplySuggestion(suggestedOrder);
      setSuggestion('');
      setSuggestedOrder(null);
    }
  };

  return (
    <div className="ai-panel">
      <div className="ai-panel-header">
        <Brain className="ai-icon" />
        <h3>AI Route Assistant</h3>
      </div>

      <p className="ai-description">
        Get AI-powered route optimization suggestions
      </p>

      <div className="ai-provider-select">
        <label htmlFor="provider-select">AI Provider:</label>
        <select
          id="provider-select"
          value={selectedProvider}
          onChange={(e) => setSelectedProvider(e.target.value as AIProvider['id'])}
          disabled={isProcessing}
        >
          {aiProviders.map(provider => (
            <option key={provider.id} value={provider.id}>
              {provider.name}
            </option>
          ))}
        </select>
      </div>

      <button
        className="btn btn-ai"
        onClick={handleGetSuggestion}
        disabled={isProcessing || addresses.length < 2}
      >
        <Sparkles size={16} />
        {isProcessing ? 'Getting Suggestion...' : 'Get AI Suggestion'}
      </button>

      {suggestion && (
        <div className="ai-suggestion">
          <h4>AI Suggestion</h4>
          <div className="suggestion-content">
            <pre>{suggestion}</pre>
          </div>

          {suggestedOrder && (
            <button
              className="btn btn-primary"
              onClick={handleApplySuggestion}
            >
              Apply Suggestion
            </button>
          )}
        </div>
      )}

      <div className="ai-note">
        <small>
          Note: API keys must be configured in your .env file.
          See .env.example for details.
        </small>
      </div>
    </div>
  );
};

export default AIPanel;
