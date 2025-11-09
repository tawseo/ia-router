import axios from 'axios';
import { Address, RouteSegment, OptimizedRoute } from '../types';

/**
 * Route optimization using OSRM (Open Source Routing Machine)
 */
export class RoutingService {
  private osrmUrl = 'https://router.project-osrm.org';

  /**
   * Calculate optimal route through all addresses
   */
  async optimizeRoute(
    addresses: Address[],
    preserveManualOrder: boolean = false
  ): Promise<OptimizedRoute | null> {
    try {
      const validAddresses = addresses.filter(addr => addr.coordinates);

      if (validAddresses.length < 2) {
        throw new Error('Need at least 2 valid addresses for routing');
      }

      // Handle addresses with fixed positions (1st, last)
      const firstAddr = validAddresses.find(a => a.status === '1st');
      const lastAddr = validAddresses.find(a => a.status === 'last');
      const flexibleAddrs = validAddresses.filter(
        a => a.status !== '1st' && a.status !== 'last'
      );

      let orderedAddresses: Address[];

      if (preserveManualOrder) {
        // Keep manual order but respect 1st/last constraints
        orderedAddresses = [...validAddresses].sort((a, b) => {
          if (a.manualOrder !== undefined && b.manualOrder !== undefined) {
            return a.manualOrder - b.manualOrder;
          }
          return 0;
        });
      } else {
        // Optimize route
        const toOptimize = flexibleAddrs.length > 0 ? flexibleAddrs : validAddresses;
        const optimized = await this.getTripOptimization(toOptimize);

        // Construct final order respecting constraints
        orderedAddresses = [];
        if (firstAddr) orderedAddresses.push(firstAddr);
        orderedAddresses.push(...optimized.filter(a => a.id !== firstAddr?.id && a.id !== lastAddr?.id));
        if (lastAddr) orderedAddresses.push(lastAddr);
      }

      // Calculate route segments
      const segments = await this.calculateRouteSegments(orderedAddresses);

      const totalDistance = segments.reduce((sum, seg) => sum + seg.distance, 0);
      const totalDuration = segments.reduce((sum, seg) => sum + seg.duration, 0);

      return {
        addresses: orderedAddresses,
        segments,
        totalDistance,
        totalDuration,
        optimizedOrder: orderedAddresses.map(a => a.id)
      };
    } catch (error) {
      console.error('Route optimization error:', error);
      return null;
    }
  }

  /**
   * Use OSRM Trip service to optimize waypoint order
   */
  private async getTripOptimization(addresses: Address[]): Promise<Address[]> {
    try {
      const coordinates = addresses
        .map(addr => addr.coordinates)
        .filter((coord): coord is [number, number] => coord !== undefined)
        .map(coord => `${coord[1]},${coord[0]}`) // OSRM uses lon,lat
        .join(';');

      const url = `${this.osrmUrl}/trip/v1/driving/${coordinates}?source=first&roundtrip=false`;

      const response = await axios.get(url);

      if (response.data.code === 'Ok' && response.data.trips.length > 0) {
        const trip = response.data.trips[0];
        const waypointOrder = trip.legs.map((leg: any, idx: number) =>
          idx === 0 ? 0 : idx
        );

        // Reorder addresses based on optimization
        return waypointOrder.map((idx: number) => addresses[idx]);
      }

      return addresses;
    } catch (error) {
      console.error('OSRM trip optimization error:', error);
      return addresses;
    }
  }

  /**
   * Calculate route segments between consecutive addresses
   */
  private async calculateRouteSegments(addresses: Address[]): Promise<RouteSegment[]> {
    const segments: RouteSegment[] = [];

    for (let i = 0; i < addresses.length - 1; i++) {
      const from = addresses[i];
      const to = addresses[i + 1];

      if (!from.coordinates || !to.coordinates) continue;

      const segment = await this.getRouteSegment(from, to);
      if (segment) {
        segments.push(segment);
      }
    }

    return segments;
  }

  /**
   * Get route segment between two addresses
   */
  private async getRouteSegment(
    from: Address,
    to: Address
  ): Promise<RouteSegment | null> {
    try {
      if (!from.coordinates || !to.coordinates) return null;

      const coords = `${from.coordinates[1]},${from.coordinates[0]};${to.coordinates[1]},${to.coordinates[0]}`;
      const url = `${this.osrmUrl}/route/v1/driving/${coords}?overview=full&geometries=geojson`;

      const response = await axios.get(url);

      if (response.data.code === 'Ok' && response.data.routes.length > 0) {
        const route = response.data.routes[0];

        return {
          from,
          to,
          distance: route.distance,
          duration: route.duration,
          geometry: route.geometry.coordinates.map((coord: number[]) => [coord[1], coord[0]])
        };
      }

      return null;
    } catch (error) {
      console.error('Route segment error:', error);
      return null;
    }
  }

  /**
   * Format duration to human-readable string
   */
  formatDuration(seconds: number): string {
    const hours = Math.floor(seconds / 3600);
    const minutes = Math.floor((seconds % 3600) / 60);

    if (hours > 0) {
      return `${hours}h ${minutes}m`;
    }
    return `${minutes}m`;
  }

  /**
   * Format distance to human-readable string
   */
  formatDistance(meters: number): string {
    const miles = meters * 0.000621371;
    return `${miles.toFixed(1)} miles`;
  }
}

export const routingService = new RoutingService();
