import { env } from '../../config/env.js';
import { logger } from '../../config/logger.js';
import type { MealPlanProvider } from './provider.js';
import { mealPlanSchema, type MealPlan, type PlanContext } from './types.js';
import { SYSTEM_PROMPT, buildUserPrompt } from './prompt.js';

const API_URL = 'https://api.anthropic.com/v1/messages';

/**
 * Anthropic-backed provider. The API key lives only here (server-side), never
 * in the mobile app. Output is extracted and strictly schema-validated before
 * it is trusted; any deviation throws so the caller can fall back.
 */
export class AnthropicProvider implements MealPlanProvider {
  readonly name = 'ai' as const;

  async generate(ctx: PlanContext): Promise<MealPlan> {
    if (!env.ANTHROPIC_API_KEY) throw new Error('ANTHROPIC_API_KEY not configured');

    const controller = new AbortController();
    const timer = setTimeout(() => controller.abort(), env.AI_TIMEOUT_MS);

    try {
      const res = await fetch(API_URL, {
        method: 'POST',
        signal: controller.signal,
        headers: {
          'content-type': 'application/json',
          'x-api-key': env.ANTHROPIC_API_KEY,
          'anthropic-version': '2023-06-01',
        },
        body: JSON.stringify({
          model: env.AI_MODEL,
          max_tokens: env.AI_MAX_TOKENS,
          temperature: 0.7,
          system: SYSTEM_PROMPT,
          messages: [{ role: 'user', content: buildUserPrompt(ctx) }],
        }),
      });

      if (!res.ok) {
        const text = await res.text().catch(() => '');
        logger.warn({ status: res.status, body: text.slice(0, 300) }, 'Anthropic API non-OK');
        throw new Error(`Anthropic API error ${res.status}`);
      }

      const data = (await res.json()) as { content?: Array<{ type: string; text?: string }> };
      const text = (data.content ?? [])
        .filter((b) => b.type === 'text' && typeof b.text === 'string')
        .map((b) => b.text as string)
        .join('\n')
        .trim();

      if (!text) throw new Error('Empty AI response');
      return parseAndValidate(text);
    } finally {
      clearTimeout(timer);
    }
  }
}

/** Extract the JSON object from the model text and validate it against schema. */
function parseAndValidate(text: string): MealPlan {
  let jsonText = text;
  // Strip accidental code fences.
  jsonText = jsonText.replace(/^```(?:json)?/i, '').replace(/```$/i, '').trim();
  // Fall back to the outermost braces if extra prose leaked in.
  const first = jsonText.indexOf('{');
  const last = jsonText.lastIndexOf('}');
  if (first > 0 || last < jsonText.length - 1) {
    if (first >= 0 && last > first) jsonText = jsonText.slice(first, last + 1);
  }

  const parsed: unknown = JSON.parse(jsonText);
  return mealPlanSchema.parse(parsed);
}
