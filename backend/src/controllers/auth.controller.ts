import type { Request, Response } from 'express';
import * as authService from '../services/auth.service.js';

function ua(req: Request): string | null {
  const v = req.headers['user-agent'];
  return typeof v === 'string' ? v.slice(0, 255) : null;
}

export async function register(req: Request, res: Response): Promise<void> {
  const { email, password, displayName } = req.body as {
    email: string; password: string; displayName: string;
  };
  const result = await authService.register(email, password, displayName, ua(req));
  res.status(201).json(result);
}

export async function login(req: Request, res: Response): Promise<void> {
  const { email, password } = req.body as { email: string; password: string };
  const result = await authService.login(email, password, ua(req));
  res.json(result);
}

export async function google(req: Request, res: Response): Promise<void> {
  const { idToken } = req.body as { idToken: string };
  const result = await authService.loginWithGoogle(idToken, ua(req));
  res.json(result);
}

export async function refresh(req: Request, res: Response): Promise<void> {
  const { refreshToken } = req.body as { refreshToken: string };
  const result = await authService.refresh(refreshToken, ua(req));
  res.json(result);
}

export async function logout(req: Request, res: Response): Promise<void> {
  const { refreshToken } = req.body as { refreshToken: string };
  await authService.logout(refreshToken);
  res.status(204).send();
}

export async function logoutAll(req: Request, res: Response): Promise<void> {
  await authService.logoutEverywhere(req.auth!.userId);
  res.status(204).send();
}
