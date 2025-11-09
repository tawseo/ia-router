export interface Address {
  id: string;
  rawAddress: string;
  coordinates?: [number, number]; // [lat, lng]
  status?: DeliveryStatus;
  manualOrder?: number;
  geocoded?: boolean;
  error?: string;
}

export type DeliveryStatus = '1st' | 'last' | 'am' | 'pm' | 'none';

export interface RouteSegment {
  from: Address;
  to: Address;
  distance: number;
  duration: number;
  geometry: [number, number][];
}

export interface OptimizedRoute {
  addresses: Address[];
  segments: RouteSegment[];
  totalDistance: number;
  totalDuration: number;
  optimizedOrder: string[]; // address IDs
}

export interface AIProvider {
  id: 'openai' | 'gemini' | 'deepseek' | 'qwen';
  name: string;
  enabled: boolean;
}

export interface AIRouteOptimization {
  provider: AIProvider['id'];
  suggestion: string;
  optimizedOrder?: string[];
  reasoning: string;
}
