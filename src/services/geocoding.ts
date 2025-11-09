import axios from 'axios';

export interface GeocodingResult {
  address: string;
  lat: number;
  lon: number;
  displayName: string;
}

/**
 * Geocode UK postcodes and addresses using Nominatim (OpenStreetMap)
 */
export class GeocodingService {
  private baseUrl = 'https://nominatim.openstreetmap.org/search';
  private delay = 1000; // Nominatim requires 1 second between requests

  async geocodeAddress(address: string): Promise<GeocodingResult | null> {
    try {
      // Add delay to respect Nominatim usage policy
      await this.wait(this.delay);

      const params = {
        q: address,
        countrycodes: 'gb', // UK only
        format: 'json',
        limit: 1,
        addressdetails: 1
      };

      const response = await axios.get(this.baseUrl, {
        params,
        headers: {
          'User-Agent': 'IA-Router-App/1.0'
        }
      });

      if (response.data && response.data.length > 0) {
        const result = response.data[0];
        return {
          address: address,
          lat: parseFloat(result.lat),
          lon: parseFloat(result.lon),
          displayName: result.display_name
        };
      }

      return null;
    } catch (error) {
      console.error('Geocoding error:', error);
      return null;
    }
  }

  /**
   * Batch geocode multiple addresses
   */
  async geocodeBatch(addresses: string[]): Promise<Map<string, GeocodingResult>> {
    const results = new Map<string, GeocodingResult>();

    for (const address of addresses) {
      const result = await this.geocodeAddress(address);
      if (result) {
        results.set(address, result);
      }
    }

    return results;
  }

  /**
   * Validate UK postcode format
   */
  isValidUKPostcode(postcode: string): boolean {
    // UK postcode regex pattern
    const pattern = /^([A-Z]{1,2}\d{1,2}[A-Z]?\s?\d[A-Z]{2})$/i;
    return pattern.test(postcode.replace(/\s/g, ''));
  }

  private wait(ms: number): Promise<void> {
    return new Promise(resolve => setTimeout(resolve, ms));
  }
}

export const geocodingService = new GeocodingService();
