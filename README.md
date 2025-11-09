# IA Router - AI-Powered Route Optimization

An intelligent routing software that uses OpenStreetMap and multiple AI providers to optimize delivery routes for UK addresses.

## Features

- **OpenStreetMap Integration**: Interactive map visualization using Leaflet
- **Bulk Address Input**: Paste multiple UK postcodes or full addresses at once
- **Smart Geocoding**: Automatic geocoding of UK addresses and postcodes
- **Route Optimization**: Uses OSRM (Open Source Routing Machine) for optimal route calculation
- **AI-Powered Suggestions**: Get route optimization suggestions from:
  - ChatGPT (OpenAI)
  - Google Gemini
  - DeepSeek
  - Qwen
- **Delivery Status Assignment**: Mark addresses as:
  - `1st` - Must be first stop
  - `last` - Must be last stop
  - `am` - Morning delivery
  - `pm` - Afternoon delivery
- **Drag & Drop Reordering**: Manually reorder stops with drag-and-drop
- **Automatic Re-routing**: Route recalculates automatically while preserving manual order
- **Route Statistics**: View total distance, duration, and stop count

## Installation

### Prerequisites

- Node.js 18+ and npm/yarn
- API keys for AI providers (optional, but required for AI features)

### Setup

1. Clone the repository:
```bash
git clone <repository-url>
cd ia-router
```

2. Install dependencies:
```bash
npm install
```

3. Configure environment variables:
```bash
cp .env.example .env
```

Edit `.env` and add your API keys:
```env
VITE_OPENAI_API_KEY=your_openai_api_key_here
VITE_GEMINI_API_KEY=your_gemini_api_key_here
VITE_DEEPSEEK_API_KEY=your_deepseek_api_key_here
VITE_QWEN_API_KEY=your_qwen_api_key_here
```

4. Start the development server:
```bash
npm run dev
```

5. Open your browser to `http://localhost:3000`

## Usage

### Adding Addresses

1. Paste UK postcodes or full addresses in the text area (one per line)
2. Click "Add Addresses" to geocode them
3. Wait for geocoding to complete (respects Nominatim rate limits)

Example addresses:
```
SW1A 1AA
10 Downing Street, London
M1 1AE
B1 1AA
```

### Optimizing Routes

1. After addresses are added, click "Optimize Route"
2. The software will calculate the optimal route order
3. View the route on the map with turn-by-turn polylines
4. Check route statistics (distance, duration, stops)

### Assigning Delivery Status

Click on the status badge next to each address to cycle through:
- NONE → 1ST → LAST → AM → PM

The route optimizer respects these constraints:
- Addresses marked `1st` will always be first
- Addresses marked `last` will always be last
- AM/PM designations help the AI provide better suggestions

### Manual Reordering

1. Drag and drop addresses to manually reorder them
2. Enable "Preserve manual order" checkbox
3. Click "Optimize Route" again to recalculate while maintaining your order

### AI Suggestions

1. Select an AI provider from the dropdown
2. Click "Get AI Suggestion"
3. Review the AI's reasoning and suggested route
4. Click "Apply Suggestion" to use the AI's recommended order

## Technology Stack

- **Frontend**: React 18 + TypeScript
- **Build Tool**: Vite
- **Mapping**: Leaflet + React-Leaflet
- **Drag & Drop**: @dnd-kit
- **Geocoding**: Nominatim (OpenStreetMap)
- **Routing**: OSRM (OpenStreetMap)
- **AI Providers**:
  - OpenAI GPT-4
  - Google Gemini
  - DeepSeek
  - Qwen

## API Keys

### OpenAI (ChatGPT)
Get your API key from: https://platform.openai.com/api-keys

### Google Gemini
Get your API key from: https://makersuite.google.com/app/apikey

### DeepSeek
Get your API key from: https://platform.deepseek.com/

### Qwen
Get your API key from: https://dashscope.console.aliyun.com/

## Development

### Project Structure

```
ia-router/
├── src/
│   ├── components/        # React components
│   │   ├── AddressInput.tsx
│   │   ├── AddressList.tsx
│   │   ├── AddressItem.tsx
│   │   ├── RouteMap.tsx
│   │   ├── RouteInfo.tsx
│   │   └── AIPanel.tsx
│   ├── services/          # Business logic
│   │   ├── geocoding.ts   # UK postcode geocoding
│   │   ├── routing.ts     # OSRM route optimization
│   │   └── ai.ts          # AI provider integrations
│   ├── types/             # TypeScript types
│   ├── App.tsx            # Main app component
│   └── main.tsx           # Entry point
├── package.json
├── tsconfig.json
└── vite.config.ts
```

### Building for Production

```bash
npm run build
```

The built files will be in the `dist/` directory.

### Preview Production Build

```bash
npm run preview
```

## Limitations

- **UK Only**: Currently optimized for UK addresses and postcodes
- **Rate Limits**: Nominatim geocoding has a 1-second delay between requests
- **API Costs**: AI features require paid API keys and may incur costs
- **Browser-based**: All processing happens in the browser (no backend)

## Future Enhancements

- [ ] Multi-vehicle routing
- [ ] Time windows for deliveries
- [ ] Export routes to various formats (CSV, GPX, etc.)
- [ ] Offline mode with cached map tiles
- [ ] Support for other countries
- [ ] Route history and saved routes
- [ ] Mobile app version

## License

MIT

## Contributing

Contributions are welcome! Please open an issue or submit a pull request.

## Support

For issues and questions, please open a GitHub issue.
