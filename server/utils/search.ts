import { Service } from '../data/database';

export interface SearchOptions {
  query?: string;
  category?: string;
  subcategory?: string;
  minPrice?: number;
  maxPrice?: number;
  providerId?: string;
  isActive?: boolean;
}

export interface SearchResult extends Service {
  relevanceScore?: number;
}

export function searchServices(services: Service[], options: SearchOptions): Service[] {
  let results = [...services];

  // Filter by active status
  if (options.isActive !== false) {
    results = results.filter(s => s.isActive !== false);
  }

  // Filter by provider
  if (options.providerId) {
    results = results.filter(s => s.providerId === options.providerId);
  }

  // Filter by category
  if (options.category) {
    results = results.filter(s => 
      s.category.toLowerCase() === options.category!.toLowerCase()
    );
  }

  // Filter by subcategory
  if (options.subcategory) {
    results = results.filter(s => 
      s.subcategory?.toLowerCase() === options.subcategory!.toLowerCase()
    );
  }

  // Filter by price range
  if (options.minPrice !== undefined) {
    results = results.filter(s => s.price >= options.minPrice!);
  }

  if (options.maxPrice !== undefined) {
    results = results.filter(s => s.price <= options.maxPrice!);
  }

  // Text search with relevance scoring
  if (options.query) {
    const query = options.query.toLowerCase();
    const scored: SearchResult[] = results.map(service => {
      let score = 0;

      // Name match (highest weight)
      if (service.name.toLowerCase().includes(query)) {
        score += 10;
        if (service.name.toLowerCase().startsWith(query)) {
          score += 5; // Bonus for prefix match
        }
      }

      // Description match
      if (service.description.toLowerCase().includes(query)) {
        score += 3;
      }

      // Tag match
      if (service.tags?.some(tag => tag.toLowerCase().includes(query))) {
        score += 5;
      }

      // Category match
      if (service.category.toLowerCase().includes(query)) {
        score += 2;
      }

      return { ...service, relevanceScore: score };
    });

    // Filter out non-matching results and sort by relevance
    results = scored
      .filter(s => s.relevanceScore! > 0)
      .sort((a, b) => (b.relevanceScore || 0) - (a.relevanceScore || 0))
      .map(({ relevanceScore, ...service }) => service);
  }

  return results;
}
