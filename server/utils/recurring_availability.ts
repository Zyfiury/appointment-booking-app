import { Availability } from '../data/database';

export interface RecurringAvailabilityTemplate {
  id: string;
  providerId: string;
  name: string; // e.g., "Weekdays 9-5", "Weekend Hours"
  daysOfWeek: string[]; // ['monday', 'tuesday', ...]
  startTime: string; // HH:MM
  endTime: string; // HH:MM
  breaks?: string[]; // ['12:00-13:00']
  isActive: boolean;
}

export function applyTemplateToAvailability(
  template: RecurringAvailabilityTemplate
): Omit<Availability, 'id'>[] {
  return template.daysOfWeek.map(dayOfWeek => ({
    providerId: template.providerId,
    dayOfWeek,
    startTime: template.startTime,
    endTime: template.endTime,
    breaks: template.breaks || [],
    isAvailable: template.isActive,
  }));
}

export const defaultTemplates: Omit<RecurringAvailabilityTemplate, 'id' | 'providerId'>[] = [
  {
    name: 'Weekdays 9-5',
    daysOfWeek: ['monday', 'tuesday', 'wednesday', 'thursday', 'friday'],
    startTime: '09:00',
    endTime: '17:00',
    breaks: ['12:00-13:00'],
    isActive: true,
  },
  {
    name: 'Weekend 10-6',
    daysOfWeek: ['saturday', 'sunday'],
    startTime: '10:00',
    endTime: '18:00',
    breaks: [],
    isActive: true,
  },
  {
    name: 'Full Week 8-8',
    daysOfWeek: ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'],
    startTime: '08:00',
    endTime: '20:00',
    breaks: ['12:00-13:00'],
    isActive: true,
  },
];
