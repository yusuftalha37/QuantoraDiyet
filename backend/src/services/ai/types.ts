import { z } from 'zod';

/**
 * Canonical meal-plan shape. Both the LLM provider and the offline fallback
 * engine must produce data matching `mealPlanSchema`, so the rest of the app
 * (and the mobile client) only ever deals with one validated structure.
 */
export const mealSchema = z.object({
  type: z.enum(['breakfast', 'lunch', 'dinner', 'snack']),
  name: z.string().min(1).max(120),
  ingredients: z.array(z.string().min(1).max(120)).max(30),
  recipe: z.string().min(1).max(2000),
  steps: z.array(z.string().min(1).max(400)).max(20).optional(),
  prep_minutes: z.number().int().min(0).max(600).optional(),
  servings: z.number().int().min(1).max(20).optional(),
  calories: z.number().int().min(0).max(4000).default(0),
  protein_g: z.number().min(0).max(400).default(0),
  carbs_g: z.number().min(0).max(600).default(0),
  fat_g: z.number().min(0).max(400).default(0),
});

export const dayPlanSchema = z.object({
  day: z.number().int().min(1).max(31),
  label: z.string().max(40).optional(),
  meals: z.array(mealSchema).min(1).max(6),
  total_calories: z.number().int().min(0).max(8000),
});

export const mealPlanSchema = z.object({
  summary: z.string().max(600),
  target_calories: z.number().int().min(0).max(8000),
  shopping_list: z.array(z.string().min(1).max(120)).max(200).default([]),
  days: z.array(dayPlanSchema).min(1).max(31),
});

export type Meal = z.infer<typeof mealSchema>;
export type DayPlan = z.infer<typeof dayPlanSchema>;
export type MealPlan = z.infer<typeof mealPlanSchema>;

export interface PlanContext {
  mode: 'diet' | 'daily';
  period: 'daily' | 'weekly' | 'monthly';
  days: number;
  targetCalories: number;
  macros: { proteinG: number; carbsG: number; fatG: number };
  dietType: string;
  goal: string;
  allergies: string[];
  dislikedFoods: string[];
  pantry: string[];
  notes?: string;
  locale: 'tr';
}

export function daysForPeriod(period: 'daily' | 'weekly' | 'monthly'): number {
  if (period === 'daily') return 1;
  if (period === 'weekly') return 7;
  return 30;
}
