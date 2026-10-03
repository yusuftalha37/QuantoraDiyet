import type { Request, Response } from 'express';
import { generatePlan } from '../services/mealplan.service.js';
import { listPlans, getPlan } from '../repositories/mealplan.repo.js';
import { computeTargets } from '../services/nutrition.js';
import { getProfile } from '../repositories/profile.repo.js';
import type { GeneratePlanInput } from '../schemas.js';
import { badRequest, notFound } from '../utils/errors.js';

export async function generate(req: Request, res: Response): Promise<void> {
  const { saved, source } = await generatePlan(req.auth!.userId, req.body as GeneratePlanInput);
  res.status(201).json({
    id: saved.id,
    mode: saved.mode,
    period: saved.period,
    source,
    targetCalories: saved.target_calories,
    plan: saved.plan,
    createdAt: saved.created_at,
  });
}

export async function history(req: Request, res: Response): Promise<void> {
  const plans = await listPlans(req.auth!.userId);
  res.json({
    plans: plans.map((p) => ({
      id: p.id,
      mode: p.mode,
      period: p.period,
      source: p.source,
      targetCalories: p.target_calories,
      summary: p.plan.summary,
      days: p.plan.days.length,
      createdAt: p.created_at,
    })),
  });
}

export async function getOne(req: Request, res: Response): Promise<void> {
  const plan = await getPlan(req.auth!.userId, req.params.id as string);
  if (!plan) throw notFound('Plan bulunamadı');
  res.json({
    id: plan.id,
    mode: plan.mode,
    period: plan.period,
    source: plan.source,
    targetCalories: plan.target_calories,
    plan: plan.plan,
    createdAt: plan.created_at,
  });
}

/** Expose the computed calorie/macro targets so the app can show them. */
export async function targets(req: Request, res: Response): Promise<void> {
  const profile = await getProfile(req.auth!.userId);
  if (!profile || !profile.goal) throw badRequest('Önce profil bilgilerinizi tamamlayın');
  res.json(computeTargets(profile));
}
