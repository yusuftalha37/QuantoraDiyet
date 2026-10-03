import { query, withTransaction } from '../db/pool.js';
import type { ProfileInput } from '../schemas.js';

export interface ProfileRow {
  user_id: string;
  sex: string | null;
  birth_year: number | null;
  height_cm: string | null;
  weight_kg: string | null;
  activity_level: string | null;
  goal: string | null;
  diet_type: string | null;
  allergies: string[];
  disliked_foods: string[];
}

export async function upsertProfile(userId: string, p: ProfileInput): Promise<void> {
  await query(
    `INSERT INTO user_profiles
       (user_id, sex, birth_year, height_cm, weight_kg, activity_level, goal, diet_type, allergies, disliked_foods, updated_at)
     VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10, now())
     ON CONFLICT (user_id) DO UPDATE SET
       sex=$2, birth_year=$3, height_cm=$4, weight_kg=$5, activity_level=$6,
       goal=$7, diet_type=$8, allergies=$9, disliked_foods=$10, updated_at=now()`,
    [
      userId, p.sex, p.birthYear, p.heightCm, p.weightKg, p.activityLevel,
      p.goal, p.dietType, p.allergies, p.dislikedFoods,
    ],
  );
}

export async function getProfile(userId: string): Promise<ProfileRow | null> {
  const r = await query<ProfileRow>(`SELECT * FROM user_profiles WHERE user_id = $1`, [userId]);
  return r.rows[0] ?? null;
}

export interface PantryItem {
  name: string;
  quantity?: string;
}

/** Replace the whole pantry atomically with the provided items. */
export async function replacePantry(userId: string, items: PantryItem[]): Promise<void> {
  await withTransaction(async (client) => {
    await client.query(`DELETE FROM pantry_items WHERE user_id = $1`, [userId]);
    for (const it of items) {
      await client.query(
        `INSERT INTO pantry_items (user_id, name, quantity) VALUES ($1, $2, $3)`,
        [userId, it.name, it.quantity ?? null],
      );
    }
  });
}

export async function getPantry(userId: string): Promise<PantryItem[]> {
  const r = await query<{ name: string; quantity: string | null }>(
    `SELECT name, quantity FROM pantry_items WHERE user_id = $1 ORDER BY created_at ASC`,
    [userId],
  );
  return r.rows.map((x) => ({ name: x.name, quantity: x.quantity ?? undefined }));
}
