import { useEffect, useMemo } from 'react';
import { MapContainer, TileLayer, Marker, Popup, Polyline, useMap } from 'react-leaflet';
import { LatLngBounds, Icon } from 'leaflet';
import { Address, OptimizedRoute } from '../types';
import 'leaflet/dist/leaflet.css';
import './RouteMap.css';

// Fix for default marker icons in React-Leaflet
import markerIcon2x from 'leaflet/dist/images/marker-icon-2x.png';
import markerIcon from 'leaflet/dist/images/marker-icon.png';
import markerShadow from 'leaflet/dist/images/marker-shadow.png';

delete (Icon.Default.prototype as any)._getIconUrl;
Icon.Default.mergeOptions({
  iconUrl: markerIcon,
  iconRetinaUrl: markerIcon2x,
  shadowUrl: markerShadow,
});

interface RouteMapProps {
  addresses: Address[];
  route: OptimizedRoute | null;
}

// Component to handle map bounds updates
const MapBoundsUpdater = ({ addresses }: { addresses: Address[] }) => {
  const map = useMap();

  useEffect(() => {
    const validCoords = addresses
      .filter(addr => addr.coordinates)
      .map(addr => addr.coordinates!);

    if (validCoords.length > 0) {
      const bounds = new LatLngBounds(validCoords);
      map.fitBounds(bounds, { padding: [50, 50] });
    }
  }, [addresses, map]);

  return null;
};

const RouteMap = ({ addresses, route }: RouteMapProps) => {
  const validAddresses = useMemo(
    () => addresses.filter(addr => addr.coordinates),
    [addresses]
  );

  const center: [number, number] = useMemo(() => {
    if (validAddresses.length > 0 && validAddresses[0].coordinates) {
      return validAddresses[0].coordinates;
    }
    // Default to London
    return [51.5074, -0.1278];
  }, [validAddresses]);

  const routePolylines = useMemo(() => {
    if (!route) return [];

    return route.segments.map((segment, idx) => ({
      id: `segment-${idx}`,
      positions: segment.geometry,
      color: '#3b82f6'
    }));
  }, [route]);

  const displayAddresses = route ? route.addresses : validAddresses;

  return (
    <div className="route-map">
      <MapContainer
        center={center}
        zoom={13}
        style={{ height: '100%', width: '100%' }}
        scrollWheelZoom={true}
      >
        <TileLayer
          attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'
          url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
        />

        <MapBoundsUpdater addresses={validAddresses} />

        {displayAddresses.map((address, index) => {
          if (!address.coordinates) return null;

          const isFirst = address.status === '1st' || index === 0;
          const isLast = address.status === 'last' || index === displayAddresses.length - 1;

          return (
            <Marker
              key={address.id}
              position={address.coordinates}
            >
              <Popup>
                <div className="marker-popup">
                  <div className="popup-header">
                    <strong>Stop {index + 1}</strong>
                    {isFirst && <span className="badge badge-first">First</span>}
                    {isLast && <span className="badge badge-last">Last</span>}
                  </div>
                  <div className="popup-address">{address.rawAddress}</div>
                  {address.status && address.status !== 'none' && (
                    <div className="popup-status">Status: {address.status.toUpperCase()}</div>
                  )}
                </div>
              </Popup>
            </Marker>
          );
        })}

        {routePolylines.map(polyline => (
          <Polyline
            key={polyline.id}
            positions={polyline.positions}
            color={polyline.color}
            weight={4}
            opacity={0.7}
          />
        ))}
      </MapContainer>

      {validAddresses.length === 0 && (
        <div className="map-overlay">
          <p>Add addresses to see them on the map</p>
        </div>
      )}
    </div>
  );
};

export default RouteMap;
