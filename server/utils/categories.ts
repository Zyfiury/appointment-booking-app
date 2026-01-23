/**
 * Canonical category list for Bookly. All services must use one of these categories.
 * Subcategories are optional but recommended for better discovery.
 */

export const CANONICAL_CATEGORIES = [
  'Barber',
  'Hair',
  'Beauty',
  'Massage',
  'Fitness',
  'Dental',
  'Therapy',
  'Medical',
  'Home Services',
  'Other',
] as const;

export type CanonicalCategory = typeof CANONICAL_CATEGORIES[number];

export const CATEGORY_SUBCATEGORIES: Record<CanonicalCategory, string[]> = {
  Barber: ['Haircut', 'Skin Fade', 'Beard Trim', 'Line-up', 'Buzz Cut', 'Taper', 'Shave'],
  Hair: ['Haircut', 'Color', 'Highlights', 'Perm', 'Extensions', 'Treatment', 'Styling'],
  Beauty: ['Nails', 'Lashes', 'Brows', 'Facial', 'Makeup', 'Waxing', 'Threading'],
  Massage: ['Deep Tissue', 'Sports', 'Swedish', 'Thai', 'Hot Stone', 'Prenatal', 'Reflexology'],
  Fitness: ['Personal Training', 'Yoga', 'Pilates', 'Nutrition', 'Group Class', 'Consultation'],
  Dental: ['Cleaning', 'Teeth Whitening', 'Filling', 'Root Canal', 'Checkup', 'Orthodontics'],
  Therapy: ['Individual', 'Couples', 'Group', 'Consultation', 'Assessment'],
  Medical: ['General Checkup', 'Consultation', 'Vaccination', 'Lab Test', 'Follow-up'],
  'Home Services': ['Plumbing', 'Electrical', 'Cleaning', 'Handyman', 'Landscaping'],
  Other: [],
};

export function isValidCategory(category: string): boolean {
  return CANONICAL_CATEGORIES.includes(category as CanonicalCategory);
}

export function isValidSubcategory(category: string, subcategory: string): boolean {
  const subcategories = CATEGORY_SUBCATEGORIES[category as CanonicalCategory];
  return subcategories ? subcategories.includes(subcategory) : false;
}

export function getSubcategories(category: string): string[] {
  return CATEGORY_SUBCATEGORIES[category as CanonicalCategory] || [];
}
