import { env } from '../config/env.js';
import { logger } from '../config/logger.js';
import { badRequest } from '../utils/errors.js';
import { getProfile, getPantry, type PantryItem } from '../repositories/profile.repo.js';
import { savePlan, type SavedPlan } from '../repositories/mealplan.repo.js';
import { computeTargets } from './nutrition.js';
import { AnthropicProvider } from './ai/anthropic.js';
import { FallbackProvider } from './ai/fallback.js';
import { daysForPeriod, type MealPlan, type PlanContext } from './ai/types.js';
import type { GeneratePlanInput } from '../schemas.js';

const fallback = new FallbackProvider();
const anthropic = new AnthropicProvider();

/**
 * Builds the personalised context, tries the AI provider when configured, and
 * ALWAYS falls back to the deterministic engine on any failure — then persists
 * and returns the plan. The user never sees a hard failure just because the
 * LLM was unavailable.
 */
export async function generatePlan(
  userId: string,
  input: GeneratePlanInput,
): Promise<{ saved: SavedPlan; source: 'ai' | 'fallback' }> {
  const profile = await getProfile(userId);
  if (!profile || !profile.goal) {
    throw badRequest('Önce profil/onboarding bilgilerinizi tamamlayın');
  }

  const targets = computeTargets(profile);
  const pantry: PantryItem[] = input.pantryOverride ?? (await getPantry(userId));

  const ctx: PlanContext = {
    mode: input.mode,
    period: input.period,
    days: daysForPeriod(input.period),
    targetCalories: targets.targetCalories,
    macros: targets.macros,
    dietType: profile.diet_type ?? 'omnivore',
    goal: profile.goal,
    allergies: profile.allergies ?? [],
    dislikedFoods: profile.disliked_foods ?? [],
    pantry: pantry.map((p) => p.name),
    notes: input.notes,
    locale: 'tr',
  };

  let plan: MealPlan;
  let source: 'ai' | 'fallback';

  if (env.AI_PROVIDER === 'anthropic' && env.ANTHROPIC_API_KEY) {
    try {
      plan = await anthropic.generate(ctx);
      source = 'ai';
    } catch (err) {
      logger.warn({ err }, 'AI generation failed, using fallback engine');
      plan = await fallback.generate(ctx);
      source = 'fallback';
    }
  } else {
    plan = await fallback.generate(ctx);
    source = 'fallback';
  }

  const saved = await savePlan(userId, input.mode, input.period, source, targets.targetCalories, plan);
  return { saved, source };
}
