import type { MealPlanProvider } from './provider.js';
import type { MealPlan, Meal, PlanContext } from './types.js';
import { DISHES, type Dish, type DietTag } from './foods.js';

const DAY_LABELS = ['Pazartesi', 'Salı', 'Çarşamba', 'Perşembe', 'Cuma', 'Cumartesi', 'Pazar'];

/** Turkish-aware normalisation for robust ingredient/allergy matching. */
const norm = (s: string) => s.toLocaleLowerCase('tr').trim();

// Map free-text allergy words to the allergen categories used on dishes.
const ALLERGY_KEYWORDS: Record<string, string[]> = {
  dairy: ['süt', 'peynir', 'yoğurt', 'laktoz', 'tereyağ'],
  gluten: ['gluten', 'buğday', 'un', 'ekmek', 'makarna', 'bulgur'],
  egg: ['yumurta'],
  nuts: ['fındık', 'ceviz', 'badem', 'fıstık', 'kuruyemiş'],
  fish: ['balık', 'somon', 'ton'],
  shellfish: ['karides', 'midye', 'kabuklu'],
  sesame: ['susam', 'tahin'],
  soy: ['soya', 'tofu'],
};

function allergenCategoriesFor(allergies: string[]): Set<string> {
  const cats = new Set<string>();
  for (const a of allergies) {
    const n = norm(a);
    for (const [cat, words] of Object.entries(ALLERGY_KEYWORDS)) {
      if (words.some((w) => n.includes(w) || w.includes(n))) cats.add(cat);
    }
  }
  return cats;
}

function violatesAllergy(dish: Dish, allergyCats: Set<string>, rawAllergies: string[]): boolean {
  if (dish.allergens.some((a) => allergyCats.has(a))) return true;
  // Also catch direct ingredient-name matches not covered by categories.
  const ingredients = dish.ingredients.map(norm);
  return rawAllergies.some((a) => {
    const n = norm(a);
    return n.length >= 3 && ingredients.some((ing) => ing.includes(n));
  });
}

function suitsDiet(dish: Dish, dietType: string): boolean {
  if (dietType === 'omnivore') return true;
  return dish.suitableFor.includes(dietType as DietTag);
}

function dislikes(dish: Dish, disliked: string[]): boolean {
  if (disliked.length === 0) return false;
  const hay = norm(dish.name) + ' ' + dish.ingredients.map(norm).join(' ');
  return disliked.some((d) => {
    const n = norm(d);
    return n.length >= 3 && hay.includes(n);
  });
}

function pantryScore(dish: Dish, pantry: Set<string>): number {
  if (pantry.size === 0) return 0;
  return dish.ingredients.reduce((acc, ing) => (pantry.has(norm(ing)) ? acc + 1 : acc), 0);
}

function toMeal(d: Dish): Meal {
  return {
    type: d.type,
    name: d.name,
    ingredients: d.ingredients,
    recipe: d.recipe,
    calories: d.calories,
    protein_g: d.protein_g,
    carbs_g: d.carbs_g,
    fat_g: d.fat_g,
  };
}

/**
 * Deterministic, network-free meal-plan generator. Used when no AI provider is
 * configured or when the AI call fails/returns invalid data, so the product
 * always works — a good fit for low-connectivity conditions too.
 */
export class FallbackProvider implements MealPlanProvider {
  readonly name = 'fallback' as const;

  async generate(ctx: PlanContext): Promise<MealPlan> {
    const allergyCats = allergenCategoriesFor(ctx.allergies);
    const pantry = new Set(ctx.pantry.map(norm));

    const usable = DISHES.filter(
      (d) => suitsDiet(d, ctx.dietType) && !violatesAllergy(d, allergyCats, ctx.allergies),
    );

    // Prefer pantry-matching dishes, but keep disliked ones only as a last resort.
    const ranked = [...usable].sort((a, b) => {
      const dislikeA = dislikes(a, ctx.dislikedFoods) ? 1 : 0;
      const dislikeB = dislikes(b, ctx.dislikedFoods) ? 1 : 0;
      if (dislikeA !== dislikeB) return dislikeA - dislikeB;
      return pantryScore(b, pantry) - pantryScore(a, pantry);
    });

    const breakfasts = ranked.filter((d) => d.type === 'breakfast');
    const mains = ranked.filter((d) => d.type === 'lunch' || d.type === 'dinner');
    const snacks = ranked.filter((d) => d.type === 'snack');

    if (breakfasts.length === 0 || mains.length === 0) {
      throw new Error('Yeterli uygun tarif bulunamadı (diyet/alerji kısıtları çok dar)');
    }

    const days = [];
    const shopping = new Set<string>();

    for (let i = 0; i < ctx.days; i++) {
      // Rotate choices for variety; deterministic (no randomness).
      const breakfast = breakfasts[i % breakfasts.length]!;
      const lunch = mains[i % mains.length]!;
      const dinner = mains[(i + 1 + Math.floor(mains.length / 2)) % mains.length]!;

      const meals: Meal[] = [toMeal(breakfast), toMeal(lunch), toMeal(dinner)];
      let total = breakfast.calories + lunch.calories + dinner.calories;

      // Add snacks until we get within ~150 kcal of target (cap at 6 meals).
      let s = 0;
      while (snacks.length > 0 && total < ctx.targetCalories - 150 && meals.length < 6) {
        const snack = snacks[(i + s) % snacks.length]!;
        meals.push(toMeal(snack));
        total += snack.calories;
        s++;
        if (s > snacks.length) break;
      }

      for (const m of meals) {
        for (const ing of m.ingredients) {
          if (!pantry.has(norm(ing))) shopping.add(ing);
        }
      }

      days.push({
        day: i + 1,
        label: ctx.period === 'weekly' ? DAY_LABELS[i % 7] : `Gün ${i + 1}`,
        meals,
        total_calories: total,
      });
    }

    const summary =
      ctx.mode === 'diet'
        ? `Hedefinize (${ctx.goal}) uygun, günlük ~${ctx.targetCalories} kcal hedefli ${ctx.days} günlük diyet planı.`
        : `Evdeki malzemeleri önceliklendiren, pratik ${ctx.days} günlük yemek planı.`;

    return {
      summary,
      target_calories: ctx.targetCalories,
      shopping_list: [...shopping].slice(0, 200),
      days,
    };
  }
}
