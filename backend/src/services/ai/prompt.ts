import type { PlanContext } from './types.js';

/**
 * The AI is constrained hard: it must respond with ONLY JSON matching our
 * schema, must respect allergies/diet, and must prefer pantry ingredients.
 * Keeping the contract explicit is what makes the output reliably parseable.
 */
export const SYSTEM_PROMPT = `Sen QuantoraDiyet uygulamasının beslenme planlama motorusun.
Türkçe, gerçekçi ve uygulanabilir yemek planları üretirsin.

KATI KURALLAR:
- Yanıtın SADECE geçerli JSON olacak. JSON dışında tek bir karakter bile yazma (açıklama, markdown, kod bloğu işareti yok).
- Kullanıcının alerjisi olan hiçbir malzemeyi ASLA kullanma.
- Kullanıcının diyet türüne (vegan, vejetaryen, keto, glutensiz, helal vb.) kesinlikle uy.
- Mümkün oldukça kullanıcının evinde bulunan malzemeleri kullan; eksikleri shopping_list'e ekle.
- Günlük toplam kaloriyi hedefe yakın tut (±%10).
- Her öğün için gerçekçi makro (protein/karbonhidrat/yağ) ve kalori değerleri ver.
- Tarifler kısa ve adım adım, Türkçe olsun.

JSON ŞEMASI:
{
  "summary": "kısa genel açıklama",
  "target_calories": <tam sayı>,
  "shopping_list": ["eksik malzeme", ...],
  "days": [
    {
      "day": <1..31>,
      "label": "Gün etiketi (örn. Pazartesi)",
      "meals": [
        {
          "type": "breakfast|lunch|dinner|snack",
          "name": "yemek adı",
          "ingredients": ["malzeme", ...],
          "recipe": "adım adım tarif",
          "calories": <tam sayı>,
          "protein_g": <sayı>, "carbs_g": <sayı>, "fat_g": <sayı>
        }
      ],
      "total_calories": <tam sayı>
    }
  ]
}`;

export function buildUserPrompt(ctx: PlanContext): string {
  const modeText =
    ctx.mode === 'diet'
      ? 'Hedef odaklı bir DİYET planı (kalori/makro hedeflerine sıkı uyum)'
      : 'Günlük, pratik yemek planı (ev yemeği ağırlıklı)';

  return [
    `İstek türü: ${modeText}.`,
    `Süre: ${ctx.days} gün (${ctx.period}).`,
    `Günlük hedef kalori: ${ctx.targetCalories} kcal.`,
    `Makro hedefleri: protein ${ctx.macros.proteinG} g, karbonhidrat ${ctx.macros.carbsG} g, yağ ${ctx.macros.fatG} g.`,
    `Hedef: ${ctx.goal}. Diyet türü: ${ctx.dietType}.`,
    `Alerjiler (asla kullanma): ${ctx.allergies.length ? ctx.allergies.join(', ') : 'yok'}.`,
    `Sevilmeyen yiyecekler (mümkünse kaçın): ${ctx.dislikedFoods.length ? ctx.dislikedFoods.join(', ') : 'yok'}.`,
    `Evdeki malzemeler: ${ctx.pantry.length ? ctx.pantry.join(', ') : 'belirtilmedi'}.`,
    ctx.notes ? `Ek not: ${ctx.notes}` : '',
    `Lütfen ${ctx.days} günlük planı yukarıdaki JSON şemasına birebir uygun üret. Sadece JSON döndür.`,
  ]
    .filter(Boolean)
    .join('\n');
}
