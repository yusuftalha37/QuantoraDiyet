import { z } from 'zod';

/**
 * All request shapes in one place. Schemas strip unknown keys and enforce
 * bounds so no oversized or unexpected input reaches business logic.
 */

// Strong-but-usable password policy: length + character variety.
export const passwordSchema = z
  .string()
  .min(10, 'Parola en az 10 karakter olmalı')
  .max(128, 'Parola çok uzun')
  .refine((p) => /[a-z]/.test(p), 'En az bir küçük harf içermeli')
  .refine((p) => /[A-Z]/.test(p), 'En az bir büyük harf içermeli')
  .refine((p) => /[0-9]/.test(p), 'En az bir rakam içermeli');

export const emailSchema = z.string().trim().toLowerCase().email('Geçerli bir e-posta girin').max(254);

export const registerSchema = z
  .object({
    email: emailSchema,
    password: passwordSchema,
    displayName: z.string().trim().min(2, 'İsim en az 2 karakter').max(60),
  })
  .strict();

export const loginSchema = z
  .object({
    email: emailSchema,
    password: z.string().min(1).max(128),
  })
  .strict();

export const refreshSchema = z
  .object({ refreshToken: z.string().min(10).max(512) })
  .strict();

export const googleSchema = z
  .object({ idToken: z.string().min(10).max(4096) })
  .strict();

// ---- Profile / onboarding ----
export const profileSchema = z
  .object({
    sex: z.enum(['male', 'female', 'other']),
    birthYear: z.number().int().min(1900).max(new Date().getFullYear()),
    heightCm: z.number().min(50).max(260),
    weightKg: z.number().min(20).max(400),
    activityLevel: z.enum(['sedentary', 'light', 'moderate', 'active', 'very_active']),
    goal: z.enum(['lose', 'maintain', 'gain']),
    dietType: z.enum([
      'omnivore', 'vegetarian', 'vegan', 'pescatarian', 'keto', 'mediterranean', 'halal', 'glutenfree',
    ]),
    allergies: z.array(z.string().trim().min(1).max(40)).max(30).default([]),
    dislikedFoods: z.array(z.string().trim().min(1).max(40)).max(30).default([]),
  })
  .strict();

const pantryItemSchema = z.object({
  name: z.string().trim().min(1).max(60),
  quantity: z.string().trim().max(40).optional(),
});

export const pantrySetSchema = z
  .object({ items: z.array(pantryItemSchema).max(100) })
  .strict();

// ---- Meal plan generation ----
export const generatePlanSchema = z
  .object({
    mode: z.enum(['diet', 'daily']),
    period: z.enum(['daily', 'weekly', 'monthly']),
    // Optionally override pantry for this one request without saving it.
    pantryOverride: z.array(pantryItemSchema).max(100).optional(),
    notes: z.string().trim().max(500).optional(),
  })
  .strict();

export type RegisterInput = z.infer<typeof registerSchema>;
export type LoginInput = z.infer<typeof loginSchema>;
export type ProfileInput = z.infer<typeof profileSchema>;
export type PantrySetInput = z.infer<typeof pantrySetSchema>;
export type GeneratePlanInput = z.infer<typeof generatePlanSchema>;
