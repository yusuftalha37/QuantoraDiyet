import { query } from '../db/pool.js';
import type { MealPlan } from '../services/ai/types.js';

export interface SavedPlan {
  id: string;
  mode: string;
  period: string;
  source: string;
  target_calories: number | null;
  plan: MealPlan;
  created_at: Date;
}

export async function savePlan(
  userId: string,
  mode: string,
  period: string,
  source: 'ai' | 'fallback',
  targetCalories: number,
  plan: MealPlan,
): Promise<SavedPlan> {
  const r = await query<SavedPlan>(
    `INSERT INTO meal_plans (user_id, mode, period, source, target_calories, plan)
       VALUES ($1,$2,$3,$4,$5,$6)
     RETURNING id, mode, period, source, target_calories, plan, created_at`,
    [userId, mode, period, source, targetCalories, JSON.stringify(plan)],
  );
  return r.rows[0]!;
}

export async function listPlans(userId: string, limit = 20): Promise<SavedPlan[]> {
  const r = await query<SavedPlan>(
    `SELECT id, mode, period, source, target_calories, plan, created_at
       FROM meal_plans WHERE user_id = $1 ORDER BY created_at DESC LIMIT $2`,
    [userId, limit],
  );
  return r.rows;
}

export async function getPlan(userId: string, id: string): Promise<SavedPlan | null> {
  const r = await query<SavedPlan>(
    `SELECT id, mode, period, source, target_calories, plan, created_at
       FROM meal_plans WHERE user_id = $1 AND id = $2 LIMIT 1`,
    [userId, id],
  );
  return r.rows[0] ?? null;
}
