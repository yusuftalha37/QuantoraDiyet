export type DietTag =
  | 'omnivore' | 'vegetarian' | 'vegan' | 'pescatarian'
  | 'keto' | 'mediterranean' | 'halal' | 'glutenfree';

export type MealType = 'breakfast' | 'lunch' | 'dinner' | 'snack';

export interface Dish {
  id: string;
  type: MealType;
  name: string;
  ingredients: string[];
  recipe: string;
  calories: number;
  protein_g: number;
  carbs_g: number;
  fat_g: number;
  /** Diets this dish is suitable for (omnivore implied for all). */
  suitableFor: DietTag[];
  /** Allergen categories present in the dish. */
  allergens: string[];
}

/**
 * Compact Turkish dish database used by the offline fallback engine. Values
 * are approximate per-serving. It is intentionally small but varied enough to
 * build balanced daily plans without any network call.
 */
export const DISHES: Dish[] = [
  // ---- Breakfast ----
  {
    id: 'b_menemen', type: 'breakfast', name: 'Menemen',
    ingredients: ['yumurta', 'domates', 'biber', 'zeytinyağı', 'tuz'],
    recipe: 'Biberleri zeytinyağında kavur, domatesi ekle, yumurtaları kır ve karıştırarak pişir.',
    calories: 320, protein_g: 18, carbs_g: 12, fat_g: 22,
    suitableFor: ['vegetarian', 'mediterranean', 'halal', 'glutenfree', 'keto'], allergens: ['egg'],
  },
  {
    id: 'b_yulaf', type: 'breakfast', name: 'Yulaf ezmesi ve meyve',
    ingredients: ['yulaf', 'süt', 'muz', 'bal', 'tarçın'],
    recipe: 'Yulafı sütle ısıt, dilimlenmiş muz ve bal ekle, tarçın serp.',
    calories: 350, protein_g: 12, carbs_g: 58, fat_g: 8,
    suitableFor: ['vegetarian', 'mediterranean', 'halal'], allergens: ['dairy', 'gluten'],
  },
  {
    id: 'b_peynir_ekmek', type: 'breakfast', name: 'Peynirli kahvaltı tabağı',
    ingredients: ['beyaz peynir', 'tam buğday ekmeği', 'zeytin', 'domates', 'salatalık'],
    recipe: 'Peynir, zeytin ve sebzeleri tabağa diz, ekmekle servis et.',
    calories: 380, protein_g: 17, carbs_g: 34, fat_g: 20,
    suitableFor: ['vegetarian', 'mediterranean', 'halal'], allergens: ['dairy', 'gluten'],
  },
  {
    id: 'b_vegan_tofu', type: 'breakfast', name: 'Tofu karıştırma',
    ingredients: ['tofu', 'ıspanak', 'biber', 'zerdeçal', 'zeytinyağı'],
    recipe: 'Tofuyu ezip zerdeçalla kavur, ıspanak ve biberi ekleyip pişir.',
    calories: 300, protein_g: 20, carbs_g: 10, fat_g: 18,
    suitableFor: ['vegan', 'vegetarian', 'glutenfree', 'halal', 'keto'], allergens: ['soy'],
  },

  // ---- Lunch / Dinner (mains) ----
  {
    id: 'm_izgara_tavuk', type: 'lunch', name: 'Izgara tavuk ve bulgur pilavı',
    ingredients: ['tavuk göğsü', 'bulgur', 'domates', 'soğan', 'zeytinyağı'],
    recipe: 'Tavuğu baharatla ızgara yap; bulguru soğan ve domatesle pişir.',
    calories: 520, protein_g: 45, carbs_g: 45, fat_g: 16,
    suitableFor: ['mediterranean', 'halal'], allergens: ['gluten'],
  },
  {
    id: 'm_somon', type: 'dinner', name: 'Fırında somon ve sebze',
    ingredients: ['somon', 'brokoli', 'limon', 'zeytinyağı', 'karabiber'],
    recipe: 'Somonu limon ve zeytinyağıyla fırınla; brokoliyi buharda pişir.',
    calories: 480, protein_g: 40, carbs_g: 12, fat_g: 30,
    suitableFor: ['pescatarian', 'mediterranean', 'halal', 'glutenfree', 'keto'], allergens: ['fish'],
  },
  {
    id: 'm_mercimek', type: 'lunch', name: 'Mercimek köftesi ve salata',
    ingredients: ['kırmızı mercimek', 'ince bulgur', 'soğan', 'salça', 'maydanoz'],
    recipe: 'Mercimeği haşla, bulgurla karıştır, soğan ve salça ekle, yoğurup şekil ver.',
    calories: 430, protein_g: 18, carbs_g: 62, fat_g: 10,
    suitableFor: ['vegan', 'vegetarian', 'mediterranean', 'halal'], allergens: ['gluten'],
  },
  {
    id: 'm_nohut', type: 'dinner', name: 'Nohut yemeği ve pirinç',
    ingredients: ['nohut', 'pirinç', 'soğan', 'domates salçası', 'zeytinyağı'],
    recipe: 'Soğanı kavur, salça ve nohudu ekle, pişir; pirinçle servis et.',
    calories: 500, protein_g: 19, carbs_g: 78, fat_g: 12,
    suitableFor: ['vegan', 'vegetarian', 'mediterranean', 'halal', 'glutenfree'], allergens: [],
  },
  {
    id: 'm_kofte', type: 'dinner', name: 'Izgara köfte ve közlenmiş sebze',
    ingredients: ['dana kıyma', 'soğan', 'patlıcan', 'biber', 'baharat'],
    recipe: 'Kıymayı soğan ve baharatla yoğur, köfte yap, ızgarada pişir; sebzeleri közle.',
    calories: 540, protein_g: 38, carbs_g: 14, fat_g: 36,
    suitableFor: ['halal', 'glutenfree', 'keto'], allergens: [],
  },
  {
    id: 'm_sebzeli_makarna', type: 'lunch', name: 'Sebzeli tam buğday makarna',
    ingredients: ['tam buğday makarna', 'kabak', 'domates', 'sarımsak', 'zeytinyağı'],
    recipe: 'Sebzeleri sote et, haşlanmış makarnayla karıştır, zeytinyağı gez.',
    calories: 460, protein_g: 15, carbs_g: 72, fat_g: 12,
    suitableFor: ['vegan', 'vegetarian', 'mediterranean', 'halal'], allergens: ['gluten'],
  },
  {
    id: 'm_zeytinyagli_fasulye', type: 'dinner', name: 'Zeytinyağlı taze fasulye',
    ingredients: ['taze fasulye', 'soğan', 'domates', 'zeytinyağı'],
    recipe: 'Soğanı kavur, fasulye ve domatesi ekle, kısık ateşte pişir.',
    calories: 280, protein_g: 7, carbs_g: 24, fat_g: 18,
    suitableFor: ['vegan', 'vegetarian', 'mediterranean', 'halal', 'glutenfree'], allergens: [],
  },

  // ---- Snacks ----
  {
    id: 's_yogurt', type: 'snack', name: 'Yoğurt ve ceviz',
    ingredients: ['yoğurt', 'ceviz', 'bal'],
    recipe: 'Yoğurdun üzerine ceviz ve bal ekle.',
    calories: 220, protein_g: 10, carbs_g: 16, fat_g: 13,
    suitableFor: ['vegetarian', 'mediterranean', 'halal', 'glutenfree', 'keto'], allergens: ['dairy', 'nuts'],
  },
  {
    id: 's_meyve', type: 'snack', name: 'Mevsim meyvesi',
    ingredients: ['elma', 'portakal'],
    recipe: 'Meyveleri yıka ve dilimle.',
    calories: 120, protein_g: 1, carbs_g: 30, fat_g: 0,
    suitableFor: ['vegan', 'vegetarian', 'pescatarian', 'mediterranean', 'halal', 'glutenfree'], allergens: [],
  },
  {
    id: 's_badem', type: 'snack', name: 'Bir avuç badem',
    ingredients: ['badem'],
    recipe: 'Çiğ bademleri porsiyonla.',
    calories: 170, protein_g: 6, carbs_g: 6, fat_g: 15,
    suitableFor: ['vegan', 'vegetarian', 'pescatarian', 'mediterranean', 'halal', 'glutenfree', 'keto'], allergens: ['nuts'],
  },
  {
    id: 's_humus', type: 'snack', name: 'Humus ve havuç',
    ingredients: ['nohut', 'tahin', 'limon', 'havuç'],
    recipe: 'Nohut, tahin ve limonu ezip püre yap; havuç çubuklarıyla ye.',
    calories: 200, protein_g: 7, carbs_g: 20, fat_g: 11,
    suitableFor: ['vegan', 'vegetarian', 'mediterranean', 'halal', 'glutenfree'], allergens: ['sesame'],
  },

  // ---- Ek kahvaltılar ----
  {
    id: 'b_omlet', type: 'breakfast', name: 'Peynirli omlet',
    ingredients: ['yumurta', 'kaşar peyniri', 'tereyağı', 'maydanoz'],
    recipe: 'Yumurtaları çırp, tereyağında pişir, rendelenmiş kaşarı ekleyip katla.',
    calories: 340, protein_g: 24, carbs_g: 4, fat_g: 26,
    suitableFor: ['vegetarian', 'halal', 'glutenfree', 'keto'], allergens: ['egg', 'dairy'],
  },
  {
    id: 'b_yogurt_granola', type: 'breakfast', name: 'Yoğurt, yulaf ve meyve kâsesi',
    ingredients: ['yoğurt', 'yulaf', 'elma', 'ceviz', 'bal'],
    recipe: 'Yoğurdun üzerine yulaf, doğranmış elma, ceviz ve bal ekle.',
    calories: 380, protein_g: 18, carbs_g: 48, fat_g: 14,
    suitableFor: ['vegetarian', 'mediterranean', 'halal'], allergens: ['dairy', 'gluten', 'nuts'],
  },

  // ---- Ek ana yemekler ----
  {
    id: 'm_tavuklu_salata', type: 'lunch', name: 'Izgara tavuklu yeşil salata',
    ingredients: ['tavuk göğsü', 'marul', 'domates', 'salatalık', 'zeytinyağı', 'limon'],
    recipe: 'Tavuğu ızgara yapıp dilimle; sebzelerle karıştır, zeytinyağı-limon gez.',
    calories: 380, protein_g: 42, carbs_g: 12, fat_g: 18,
    suitableFor: ['mediterranean', 'halal', 'glutenfree', 'keto'], allergens: [],
  },
  {
    id: 'm_mercimek_corba', type: 'lunch', name: 'Mercimek çorbası ve tam buğday ekmeği',
    ingredients: ['kırmızı mercimek', 'soğan', 'havuç', 'patates', 'tam buğday ekmeği'],
    recipe: 'Sebzeleri ve mercimeği haşlayıp blenderdan geçir; ekmekle servis et.',
    calories: 360, protein_g: 16, carbs_g: 58, fat_g: 7,
    suitableFor: ['vegan', 'vegetarian', 'mediterranean', 'halal'], allergens: ['gluten'],
  },
  {
    id: 'm_firin_tavuk_patates', type: 'dinner', name: 'Fırında tavuk ve sebze',
    ingredients: ['tavuk but', 'patates', 'havuç', 'soğan', 'zeytinyağı'],
    recipe: 'Tavuk ve sebzeleri baharatlayıp fırında birlikte pişir.',
    calories: 560, protein_g: 38, carbs_g: 40, fat_g: 26,
    suitableFor: ['halal', 'glutenfree'], allergens: [],
  },
  {
    id: 'm_etli_turlu', type: 'dinner', name: 'Etli sebze türlü',
    ingredients: ['dana eti', 'patlıcan', 'kabak', 'biber', 'domates', 'soğan'],
    recipe: 'Eti kavur, doğranmış sebzeleri ve domatesi ekle, kısık ateşte pişir.',
    calories: 520, protein_g: 34, carbs_g: 26, fat_g: 30,
    suitableFor: ['halal', 'glutenfree'], allergens: [],
  },
  {
    id: 'm_sebzeli_omlet', type: 'dinner', name: 'Sebzeli omlet',
    ingredients: ['yumurta', 'ıspanak', 'biber', 'domates', 'zeytinyağı'],
    recipe: 'Sebzeleri sote et, çırpılmış yumurtayı döküp omlet yap.',
    calories: 300, protein_g: 20, carbs_g: 10, fat_g: 20,
    suitableFor: ['vegetarian', 'mediterranean', 'halal', 'glutenfree', 'keto'], allergens: ['egg'],
  },

  // ---- Ek ara öğünler ----
  {
    id: 's_peynir_tahil', type: 'snack', name: 'Lor peyniri ve tam tahıllı galeta',
    ingredients: ['lor peyniri', 'tam buğday galeta', 'domates'],
    recipe: 'Galetanın üzerine lor ve domates dilimi koy.',
    calories: 180, protein_g: 14, carbs_g: 16, fat_g: 6,
    suitableFor: ['vegetarian', 'mediterranean', 'halal'], allergens: ['dairy', 'gluten'],
  },
  {
    id: 's_smoothie', type: 'snack', name: 'Muzlu süt smoothie',
    ingredients: ['süt', 'muz', 'yulaf', 'tarçın'],
    recipe: 'Hepsini blenderda çek.',
    calories: 240, protein_g: 12, carbs_g: 38, fat_g: 5,
    suitableFor: ['vegetarian', 'mediterranean', 'halal'], allergens: ['dairy', 'gluten'],
  },
];
