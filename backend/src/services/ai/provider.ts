import type { MealPlan, PlanContext } from './types.js';

export interface MealPlanProvider {
  readonly name: 'ai' | 'fallback';
  generate(ctx: PlanContext): Promise<MealPlan>;
}
