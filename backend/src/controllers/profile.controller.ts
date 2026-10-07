import type { Request, Response } from 'express';
import { getProfile, upsertProfile, getPantry, replacePantry } from '../repositories/profile.repo.js';
import { findUserById, deleteUser } from '../repositories/user.repo.js';
import type { ProfileInput, PantrySetInput } from '../schemas.js';
import { notFound } from '../utils/errors.js';

export async function me(req: Request, res: Response): Promise<void> {
  const user = await findUserById(req.auth!.userId);
  if (!user) throw notFound('Kullanıcı bulunamadı');
  const profile = await getProfile(user.id);
  res.json({
    user: { id: user.id, email: user.email, displayName: user.display_name },
    profile: profile
      ? {
          sex: profile.sex,
          birthYear: profile.birth_year,
          heightCm: profile.height_cm != null ? Number(profile.height_cm) : null,
          weightKg: profile.weight_kg != null ? Number(profile.weight_kg) : null,
          activityLevel: profile.activity_level,
          goal: profile.goal,
          dietType: profile.diet_type,
          allergies: profile.allergies,
          dislikedFoods: profile.disliked_foods,
        }
      : null,
    onboardingComplete: profile != null && profile.goal != null,
  });
}

export async function saveProfile(req: Request, res: Response): Promise<void> {
  await upsertProfile(req.auth!.userId, req.body as ProfileInput);
  res.status(204).send();
}

export async function getPantryItems(req: Request, res: Response): Promise<void> {
  const items = await getPantry(req.auth!.userId);
  res.json({ items });
}

export async function savePantry(req: Request, res: Response): Promise<void> {
  const { items } = req.body as PantrySetInput;
  await replacePantry(req.auth!.userId, items);
  res.status(204).send();
}

/** Hesabı ve tüm verilerini kalıcı olarak siler (Google Play zorunluluğu). */
export async function deleteAccount(req: Request, res: Response): Promise<void> {
  await deleteUser(req.auth!.userId);
  res.status(204).send();
}
