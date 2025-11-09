import { useState } from 'react';
import './AddressInput.css';

interface AddressInputProps {
  onSubmit: (addresses: string[]) => void;
  isProcessing: boolean;
}

const AddressInput = ({ onSubmit, isProcessing }: AddressInputProps) => {
  const [inputText, setInputText] = useState('');

  const handleSubmit = () => {
    if (!inputText.trim()) {
      alert('Please enter at least one address');
      return;
    }

    // Split by newlines and filter empty lines
    const addresses = inputText
      .split('\n')
      .map(line => line.trim())
      .filter(line => line.length > 0);

    if (addresses.length === 0) {
      alert('Please enter at least one valid address');
      return;
    }

    onSubmit(addresses);
    setInputText('');
  };

  const handlePaste = (e: React.ClipboardEvent<HTMLTextAreaElement>) => {
    // Allow default paste behavior
    setTimeout(() => {
      const textarea = e.currentTarget;
      setInputText(textarea.value);
    }, 0);
  };

  const exampleAddresses = `SW1A 1AA
10 Downing Street, London
M1 1AE
B1 1AA`;

  const loadExample = () => {
    setInputText(exampleAddresses);
  };

  return (
    <div className="address-input">
      <h2>Enter Addresses</h2>
      <p className="help-text">
        Paste UK postcodes or full addresses (one per line)
      </p>

      <textarea
        className="address-textarea"
        value={inputText}
        onChange={(e) => setInputText(e.target.value)}
        onPaste={handlePaste}
        placeholder="Enter addresses, one per line:&#10;SW1A 1AA&#10;10 Downing Street, London&#10;M1 1AE&#10;..."
        rows={10}
        disabled={isProcessing}
      />

      <div className="button-group">
        <button
          className="btn btn-primary"
          onClick={handleSubmit}
          disabled={isProcessing || !inputText.trim()}
        >
          {isProcessing ? 'Processing...' : 'Add Addresses'}
        </button>

        <button
          className="btn btn-secondary"
          onClick={loadExample}
          disabled={isProcessing}
        >
          Load Example
        </button>
      </div>

      {isProcessing && (
        <div className="processing-info">
          <div className="spinner"></div>
          <p>Geocoding addresses... This may take a moment.</p>
        </div>
      )}
    </div>
  );
};

export default AddressInput;
