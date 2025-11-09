import { useState, useCallback, useEffect } from 'react';
import { Address, OptimizedRoute, AIProvider } from './types';
import { geocodingService } from './services/geocoding';
import { routingService } from './services/routing';
import { aiService } from './services/ai';
import AddressInput from './components/AddressInput';
import AddressList from './components/AddressList';
import RouteMap from './components/RouteMap';
import RouteInfo from './components/RouteInfo';
import AIPanel from './components/AIPanel';
import './App.css';

function App() {
  const [addresses, setAddresses] = useState<Address[]>([]);
  const [optimizedRoute, setOptimizedRoute] = useState<OptimizedRoute | null>(null);
  const [isProcessing, setIsProcessing] = useState(false);
  const [preserveManualOrder, setPreserveManualOrder] = useState(false);

  const handleAddressesSubmit = async (rawAddresses: string[]) => {
    setIsProcessing(true);

    try {
      // Create address objects
      const newAddresses: Address[] = rawAddresses.map((raw, idx) => ({
        id: `addr-${Date.now()}-${idx}`,
        rawAddress: raw.trim(),
        status: 'none',
        manualOrder: idx
      }));

      // Geocode addresses
      const geocodeResults = await geocodingService.geocodeBatch(
        newAddresses.map(a => a.rawAddress)
      );

      // Update addresses with coordinates
      const geocodedAddresses = newAddresses.map(addr => {
        const result = geocodeResults.get(addr.rawAddress);
        if (result) {
          return {
            ...addr,
            coordinates: [result.lat, result.lon] as [number, number],
            geocoded: true
          };
        }
        return {
          ...addr,
          geocoded: false,
          error: 'Could not geocode address'
        };
      });

      setAddresses(geocodedAddresses);
    } catch (error) {
      console.error('Error processing addresses:', error);
    } finally {
      setIsProcessing(false);
    }
  };

  const handleOptimizeRoute = async () => {
    if (addresses.length < 2) {
      alert('Please add at least 2 addresses');
      return;
    }

    setIsProcessing(true);

    try {
      const route = await routingService.optimizeRoute(addresses, preserveManualOrder);
      if (route) {
        setOptimizedRoute(route);
      } else {
        alert('Could not optimize route. Please check addresses.');
      }
    } catch (error) {
      console.error('Route optimization error:', error);
      alert('Error optimizing route');
    } finally {
      setIsProcessing(false);
    }
  };

  const handleAddressReorder = useCallback((reorderedAddresses: Address[]) => {
    // Update manual order
    const updated = reorderedAddresses.map((addr, idx) => ({
      ...addr,
      manualOrder: idx
    }));
    setAddresses(updated);

    // Re-optimize with manual order preserved
    if (optimizedRoute && preserveManualOrder) {
      setPreserveManualOrder(true);
      setTimeout(() => {
        routingService.optimizeRoute(updated, true).then(route => {
          if (route) setOptimizedRoute(route);
        });
      }, 100);
    }
  }, [optimizedRoute, preserveManualOrder]);

  const handleStatusChange = useCallback((addressId: string, status: Address['status']) => {
    setAddresses(prev =>
      prev.map(addr =>
        addr.id === addressId ? { ...addr, status } : addr
      )
    );
  }, []);

  const handleClearAll = () => {
    setAddresses([]);
    setOptimizedRoute(null);
    setPreserveManualOrder(false);
  };

  return (
    <div className="app">
      <header className="app-header">
        <h1>IA Router</h1>
        <p>AI-Powered Route Optimization for UK Deliveries</p>
      </header>

      <div className="app-container">
        <div className="left-panel">
          <AddressInput
            onSubmit={handleAddressesSubmit}
            isProcessing={isProcessing}
          />

          {addresses.length > 0 && (
            <>
              <AddressList
                addresses={addresses}
                onReorder={handleAddressReorder}
                onStatusChange={handleStatusChange}
              />

              <div className="control-panel">
                <label className="checkbox-label">
                  <input
                    type="checkbox"
                    checked={preserveManualOrder}
                    onChange={(e) => setPreserveManualOrder(e.target.checked)}
                  />
                  Preserve manual order
                </label>

                <button
                  className="btn btn-primary"
                  onClick={handleOptimizeRoute}
                  disabled={isProcessing || addresses.length < 2}
                >
                  {isProcessing ? 'Optimizing...' : 'Optimize Route'}
                </button>

                <button
                  className="btn btn-secondary"
                  onClick={handleClearAll}
                >
                  Clear All
                </button>
              </div>

              {optimizedRoute && (
                <RouteInfo route={optimizedRoute} />
              )}
            </>
          )}
        </div>

        <div className="right-panel">
          <RouteMap
            addresses={addresses}
            route={optimizedRoute}
          />

          <AIPanel
            addresses={addresses}
            currentRoute={optimizedRoute}
            onApplySuggestion={(newOrder) => {
              const reordered = newOrder.map(id => addresses.find(a => a.id === id)!);
              handleAddressReorder(reordered);
            }}
          />
        </div>
      </div>
    </div>
  );
}

export default App;
