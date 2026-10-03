import type { ProfileRow } from '../repositories/profile.repo.js';

export interface NutritionTargets {
  bmr: number;
  tdee: number;
  targetCalories: number;
  macros: { proteinG: number; carbsG: number; fatG: number };
}

const ACTIVITY_FACTORS: Record<string, number> = {
  sedentary: 1.2,
  light: 1.375,
  moderate: 1.55,
  active: 1.725,
  very_active: 1.9,
};

/**
 * Mifflin-St Jeor BMR → TDEE → goal-adjusted target calories, with a sane
 * macro split. This gives the AI (and the fallback engine) a concrete,
 * personalised calorie budget instead of a generic guess.
 */
export function computeTargets(profile: ProfileRow): NutritionTargets {
  const year = new Date().getFullYear();
  const age = profile.birth_year ? year - profile.birth_year : 30;
  const weight = profile.weight_kg ? Number(profile.weight_kg) : 70;
  const height = profile.height_cm ? Number(profile.height_cm) : 170;

  // Mifflin-St Jeor
  const base = 10 * weight + 6.25 * height - 5 * age;
  const bmr = profile.sex === 'female' ? base - 161 : base + 5;

  const factor = ACTIVITY_FACTORS[profile.activity_level ?? 'moderate'] ?? 1.55;
  const tdee = bmr * factor;

  let target = tdee;
  if (profile.goal === 'lose') target = tdee - 500; // ~0.5 kg/week deficit
  else if (profile.goal === 'gain') target = tdee + 350;

  // Never prescribe dangerously low intake.
  const floor = profile.sex === 'female' ? 1200 : 1500;
  const targetCalories = Math.max(floor, Math.round(target / 10) * 10);

  // Macro split: 30% protein / 40% carbs / 30% fat (adjusted for keto).
  const isKeto = profile.diet_type === 'keto';
  const pPct = isKeto ? 0.25 : 0.3;
  const cPct = isKeto ? 0.1 : 0.4;
  const fPct = isKeto ? 0.65 : 0.3;

  return {
    bmr: Math.round(bmr),
    tdee: Math.round(tdee),
    targetCalories,
    macros: {
      proteinG: Math.round((targetCalories * pPct) / 4),
      carbsG: Math.round((targetCalories * cPct) / 4),
      fatG: Math.round((targetCalories * fPct) / 9),
    },
  };
}
