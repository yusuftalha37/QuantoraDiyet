import { Router } from 'express';
import { z } from 'zod';
import { asyncHandler } from '../utils/http.js';
import { validate } from '../middleware/validate.js';
import { requireAuth } from '../middleware/auth.js';
import { authLimiter, aiLimiter } from '../middleware/rateLimit.js';
import {
  registerSchema, loginSchema, refreshSchema, googleSchema, profileSchema, pantrySetSchema, generatePlanSchema,
} from '../schemas.js';
import * as auth from '../controllers/auth.controller.js';
import * as profile from '../controllers/profile.controller.js';
import * as plans from '../controllers/mealplan.controller.js';

export const apiRouter = Router();

const idParam = z.object({ id: z.string().uuid('Geçersiz kimlik') });

// ---- Auth ----
apiRouter.post('/auth/register', authLimiter, validate(registerSchema), asyncHandler(auth.register));
apiRouter.post('/auth/login', authLimiter, validate(loginSchema), asyncHandler(auth.login));
apiRouter.post('/auth/google', authLimiter, validate(googleSchema), asyncHandler(auth.google));
apiRouter.post('/auth/refresh', validate(refreshSchema), asyncHandler(auth.refresh));
apiRouter.post('/auth/logout', validate(refreshSchema), asyncHandler(auth.logout));
apiRouter.post('/auth/logout-all', requireAuth, asyncHandler(auth.logoutAll));

// ---- Profile / onboarding ----
apiRouter.get('/me', requireAuth, asyncHandler(profile.me));
apiRouter.delete('/me', requireAuth, asyncHandler(profile.deleteAccount));
apiRouter.patch('/profile', requireAuth, validate(profileSchema), asyncHandler(profile.saveProfile));
apiRouter.get('/pantry', requireAuth, asyncHandler(profile.getPantryItems));
apiRouter.patch('/pantry', requireAuth, validate(pantrySetSchema), asyncHandler(profile.savePantry));

// ---- Meal plans ----
apiRouter.get('/targets', requireAuth, asyncHandler(plans.targets));
apiRouter.post('/plans', requireAuth, aiLimiter, validate(generatePlanSchema), asyncHandler(plans.generate));
apiRouter.get('/plans', requireAuth, asyncHandler(plans.history));
apiRouter.get('/plans/:id', requireAuth, validate(idParam, 'params'), asyncHandler(plans.getOne));
