import { Navigation, Clock, MapPin } from 'lucide-react';
import { OptimizedRoute } from '../types';
import { routingService } from '../services/routing';
import './RouteInfo.css';

interface RouteInfoProps {
  route: OptimizedRoute;
}

const RouteInfo = ({ route }: RouteInfoProps) => {
  return (
    <div className="route-info">
      <h3>Route Summary</h3>

      <div className="route-stats">
        <div className="stat-item">
          <MapPin className="stat-icon" />
          <div className="stat-content">
            <div className="stat-label">Stops</div>
            <div className="stat-value">{route.addresses.length}</div>
          </div>
        </div>

        <div className="stat-item">
          <Navigation className="stat-icon" />
          <div className="stat-content">
            <div className="stat-label">Distance</div>
            <div className="stat-value">
              {routingService.formatDistance(route.totalDistance)}
            </div>
          </div>
        </div>

        <div className="stat-item">
          <Clock className="stat-icon" />
          <div className="stat-content">
            <div className="stat-label">Duration</div>
            <div className="stat-value">
              {routingService.formatDuration(route.totalDuration)}
            </div>
          </div>
        </div>
      </div>

      <div className="route-order">
        <h4>Route Order</h4>
        <ol className="route-order-list">
          {route.addresses.map((address, index) => (
            <li key={address.id} className="route-order-item">
              <span className="order-number">{index + 1}</span>
              <span className="order-address">{address.rawAddress}</span>
              {address.status && address.status !== 'none' && (
                <span className={`order-badge status-${address.status}`}>
                  {address.status.toUpperCase()}
                </span>
              )}
            </li>
          ))}
        </ol>
      </div>
    </div>
  );
};

export default RouteInfo;
