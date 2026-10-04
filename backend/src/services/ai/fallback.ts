import type { MealPlanProvider } from './provider.js';
import type { MealPlan, Meal, PlanContext } from './types.js';
import { DISHES, type Dish, type DietTag } from './foods.js';

const DAY_LABELS = ['Pazartesi', 'Salı', 'Çarşamba', 'Perşembe', 'Cuma', 'Cumartesi', 'Pazar'];

/** Turkish-aware normalisation for robust ingredient/allergy matching. */
const norm = (s: string) => s.toLocaleLowerCase('tr').trim();

const ALLERGY_KEYWORDS: Record<string, string[]> = {
  dairy: ['süt', 'peynir', 'yoğurt', 'laktoz', 'tereyağ', 'kaymak', 'ayran', 'lor', 'kaşar'],
  gluten: ['gluten', 'buğday', 'un', 'ekmek', 'makarna', 'bulgur', 'galeta', 'kuskus', 'yulaf'],
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

function pantryCoverage(dish: Dish, pantry: Set<string>): number {
  if (dish.ingredients.length === 0) return 0;
  const have = dish.ingredients.filter((ing) => pantry.has(norm(ing))).length;
  return have / dish.ingredients.length;
}

function toMeal(dish: Dish): Meal {
  return {
    type: dish.type,
    name: dish.name,
    ingredients: dish.ingredients,
    recipe: dish.recipe,
    calories: dish.calories,
    protein_g: dish.protein_g,
    carbs_g: dish.carbs_g,
    fat_g: dish.fat_g,
  };
}

/**
 * Ağ gerektirmeyen "ne pişireyim?" öneri motoru.
 *
 * Her gün için kahvaltı, öğle ve akşam yemeği seçer. Seçim; evdeki malzeme
 * kapsamı, çeşitlilik (günler arası tekrar cezası) ve sevilmeyen yiyecek
 * cezasıyla yapılır. Deterministiktir: aynı girdi aynı öneriyi verir.
 */
export class FallbackProvider implements MealPlanProvider {
  readonly name = 'fallback' as const;

  async generate(ctx: PlanContext): Promise<MealPlan> {
    const allergyCats = allergenCategoriesFor(ctx.allergies);
    const pantry = new Set(ctx.pantry.map(norm));

    const usable = DISHES.filter(
      (d) => suitsDiet(d, ctx.dietType) && !violatesAllergy(d, allergyCats, ctx.allergies),
    );

    const breakfasts = usable.filter((d) => d.type === 'breakfast');
    const mains = usable.filter((d) => d.type === 'lunch' || d.type === 'dinner');

    if (breakfasts.length === 0 || mains.length === 0) {
      throw new Error('Yeterli uygun tarif bulunamadı (diyet/alerji kısıtları çok dar)');
    }

    // Günler arası çeşitlilik için kullanım sayacı.
    const usage = new Map<string, number>();
    const days = [];
    const shopping = new Set<string>();

    for (let i = 0; i < ctx.days; i++) {
      const slots: Array<{ pool: Dish[] }> = [
        { pool: breakfasts },
        { pool: mains },
        { pool: mains },
      ];

      const meals: Meal[] = [];
      const usedToday = new Set<string>();

      for (const slot of slots) {
        const best = this.pickBest(slot.pool, {
          pantry,
          disliked: ctx.dislikedFoods,
          usage,
          excludeIds: usedToday, // aynı gün aynı yemek tekrar etmesin
        });
        if (!best) continue;

        usedToday.add(best.id);
        usage.set(best.id, (usage.get(best.id) ?? 0) + 1);

        meals.push(toMeal(best));
        for (const ing of best.ingredients) {
          if (!pantry.has(norm(ing))) shopping.add(ing);
        }
      }

      days.push({
        day: i + 1,
        label: ctx.period === 'weekly' ? DAY_LABELS[i % 7] : ctx.days === 1 ? 'Bugün' : `Gün ${i + 1}`,
        meals,
        total_calories: 0,
      });
    }

    return {
      summary: `Evindeki malzemelere göre ${ctx.days} günlük, çeşitli ev yemeği önerileri.`,
      target_calories: 0,
      shopping_list: [...shopping].slice(0, 200),
      days,
    };
  }

  /** Evdeki malzeme kapsamı + çeşitlilik − sevilmeyen cezasıyla en iyi yemeği seçer. */
  private pickBest(
    pool: Dish[],
    opts: { pantry: Set<string>; disliked: string[]; usage: Map<string, number>; excludeIds: Set<string> },
  ): Dish | null {
    let best: Dish | null = null;
    let bestScore = -Infinity;

    for (const dish of pool) {
      if (opts.excludeIds.has(dish.id)) continue;

      const pantryCov = pantryCoverage(dish, opts.pantry);
      const varietyPenalty = opts.usage.get(dish.id) ?? 0;
      const dislikePenalty = dislikes(dish, opts.disliked) ? 1 : 0;

      const score = 1.0 * pantryCov - 0.6 * varietyPenalty - 2.0 * dislikePenalty;

      if (score > bestScore) {
        bestScore = score;
        best = dish;
      }
    }
    return best;
  }
}
