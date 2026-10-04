import type { MealPlanProvider } from './provider.js';
import type { MealPlan, Meal, PlanContext } from './types.js';
import { DISHES, type Dish, type DietTag, type MealType } from './foods.js';

const DAY_LABELS = ['Pazartesi', 'Salı', 'Çarşamba', 'Perşembe', 'Cuma', 'Cumartesi', 'Pazar'];

/** Hedef kalorinin öğünlere dağılımı. */
const MEAL_SPLIT: Record<MealType, number> = {
  breakfast: 0.25,
  lunch: 0.35,
  dinner: 0.3,
  snack: 0.1,
};

/** Bir porsiyonun ölçeklenebileceği alt/üst sınır (gerçekçi tutmak için). */
const MIN_SCALE = 0.5;
const MAX_SCALE = 2.0;

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

/** Porsiyonu gerçekçi 0.25'lik adımlara yuvarla. */
function roundScale(raw: number): number {
  const clamped = Math.min(MAX_SCALE, Math.max(MIN_SCALE, raw));
  return Math.round(clamped * 4) / 4;
}

function scaledMeal(dish: Dish, scale: number): Meal {
  const name = scale === 1 ? dish.name : `${dish.name} (~${scale} porsiyon)`;
  return {
    type: dish.type,
    name,
    ingredients: dish.ingredients,
    recipe: dish.recipe,
    calories: Math.round(dish.calories * scale),
    protein_g: Math.round(dish.protein_g * scale),
    carbs_g: Math.round(dish.carbs_g * scale),
    fat_g: Math.round(dish.fat_g * scale),
  };
}

interface Candidate {
  dish: Dish;
  scale: number;
  score: number;
}

/**
 * Gelişmiş, ağ gerektirmeyen plan motoru.
 *
 * Her gün için öğünleri kalori bütçesine göre dağıtır; her slot için adayları
 * çok kriterli bir skorla değerlendirir (kalori uyumu, evdeki malzeme kapsamı,
 * günün protein açığını kapatma, çeşitlilik ve sevilmeyen cezası), porsiyonu
 * hedefe göre ölçekler. Deterministiktir: aynı girdi aynı planı verir.
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
    const snacks = usable.filter((d) => d.type === 'snack');

    if (breakfasts.length === 0 || mains.length === 0) {
      throw new Error('Yeterli uygun tarif bulunamadı (diyet/alerji kısıtları çok dar)');
    }

    // Günler arası çeşitlilik için kullanım sayacı.
    const usage = new Map<string, number>();
    const includeSnack = ctx.targetCalories >= 1500;

    const days = [];
    const shopping = new Set<string>();

    for (let i = 0; i < ctx.days; i++) {
      const slots: Array<{ type: MealType; pool: Dish[] }> = [
        { type: 'breakfast', pool: breakfasts },
        { type: 'lunch', pool: mains },
        { type: 'dinner', pool: mains },
      ];
      if (includeSnack && snacks.length > 0) slots.push({ type: 'snack', pool: snacks });

      const meals: Meal[] = [];
      let dayCals = 0;
      let dayProtein = 0;
      const dinnerUsedToday = new Set<string>();

      for (const slot of slots) {
        const slotBudget = ctx.targetCalories * MEAL_SPLIT[slot.type];
        // Günün kalan protein açığı (0'ın altına düşmez) — protein öncelikli seçim.
        const proteinDeficit = Math.max(0, ctx.macros.proteinG - dayProtein);

        const best = this.pickBest(slot.pool, {
          slotBudget,
          pantry,
          disliked: ctx.dislikedFoods,
          usage,
          proteinDeficit,
          proteinTarget: ctx.macros.proteinG,
          excludeIds: dinnerUsedToday, // aynı gün öğle=akşam olmasın
        });
        if (!best) continue;

        dinnerUsedToday.add(best.dish.id);
        usage.set(best.dish.id, (usage.get(best.dish.id) ?? 0) + 1);

        const meal = scaledMeal(best.dish, best.scale);
        meals.push(meal);
        dayCals += meal.calories;
        dayProtein += meal.protein_g;

        for (const ing of best.dish.ingredients) {
          if (!pantry.has(norm(ing))) shopping.add(ing);
        }
      }

      days.push({
        day: i + 1,
        label: ctx.period === 'weekly' ? DAY_LABELS[i % 7] : `Gün ${i + 1}`,
        meals,
        total_calories: dayCals,
      });
    }

    const summary =
      ctx.mode === 'diet'
        ? `Hedefinize (${ctx.goal}) uygun, günlük ~${ctx.targetCalories} kcal ve ~${ctx.macros.proteinG} g protein hedefli ${ctx.days} günlük plan. Öğünler kalori bütçesine göre porsiyonlandı.`
        : `Evdeki malzemeleri önceliklendiren, dengeli ve çeşitli ${ctx.days} günlük yemek planı.`;

    return {
      summary,
      target_calories: ctx.targetCalories,
      shopping_list: [...shopping].slice(0, 200),
      days,
    };
  }

  private pickBest(
    pool: Dish[],
    opts: {
      slotBudget: number;
      pantry: Set<string>;
      disliked: string[];
      usage: Map<string, number>;
      proteinDeficit: number;
      proteinTarget: number;
      excludeIds: Set<string>;
    },
  ): Candidate | null {
    let best: Candidate | null = null;

    for (const dish of pool) {
      if (opts.excludeIds.has(dish.id)) continue;

      const scale = roundScale(opts.slotBudget / dish.calories);
      const scaledCals = dish.calories * scale;
      const scaledProtein = dish.protein_g * scale;

      // 1) Kalori uyumu: slota ne kadar yakın (0..1).
      const calorieFit = 1 - Math.min(1, Math.abs(scaledCals - opts.slotBudget) / opts.slotBudget);

      // 2) Evdeki malzeme kapsamı (0..1).
      const pantryCov = pantryCoverage(dish, opts.pantry);

      // 3) Protein katkısı: günün açığını kapatmaya yarayan protein (0..1).
      const proteinHelp =
        opts.proteinTarget > 0
          ? Math.min(1, scaledProtein / Math.max(1, opts.proteinDeficit || opts.proteinTarget * 0.33))
          : 0;

      // 4) Çeşitlilik cezası: daha önce kaç kez kullanıldı.
      const varietyPenalty = opts.usage.get(dish.id) ?? 0;

      // 5) Sevilmeyen cezası.
      const dislikePenalty = dislikes(dish, opts.disliked) ? 1 : 0;

      const score =
        1.0 * calorieFit +
        0.8 * pantryCov +
        0.5 * proteinHelp -
        0.6 * varietyPenalty -
        2.0 * dislikePenalty;

      if (!best || score > best.score) best = { dish, scale, score };
    }

    return best;
  }
}
