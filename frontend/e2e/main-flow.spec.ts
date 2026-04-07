import { test, expect } from '@playwright/test';
import { generateTestJWT } from './auth';

const TEST_USER = {
	sub: 'e2e-test-sub',
	email: 'e2e@test.edu',
	hd: 'test.edu',
	user_id: 32,
	role: 'user'
};

test.describe('logged out', () => {
	test('landing page shows hero and features', async ({ page }) => {
		await page.goto('/');

		await expect(page.locator('h1')).toContainText('nemsy');
		await expect(page.getByText('Open Source')).toBeVisible();
		await expect(page.getByText('Sin anuncios', { exact: true })).toBeVisible();
		await expect(page.getByText('Rápido y ligero', { exact: true })).toBeVisible();
	});

	test('shows login button', async ({ page }) => {
		await page.goto('/');

		await expect(page.getByText('Iniciar sesión')).toBeVisible();
	});
});

test.describe('logged in', () => {
	test.beforeEach(async ({ context }) => {
		const jwt = generateTestJWT(TEST_USER);
		await context.addCookies([
			{
				name: 'session_token',
				value: jwt,
				domain: 'localhost',
				path: '/'
			}
		]);
	});

	test('home shows subjects sidebar', async ({ page }) => {
		await page.goto('/');

		await expect(page.getByText('Asignaturas')).toBeVisible();
	});

	test('can navigate to search', async ({ page }) => {
		await page.goto('/search');

		await expect(page.getByRole('heading', { name: 'Búsqueda Global' })).toBeVisible();
		await expect(page.getByPlaceholder('Buscar recursos de toda la plataforma...')).toBeVisible();
	});

	test('search returns results', async ({ page }) => {
		await page.goto('/search');
		await page.waitForLoadState('networkidle');

		const searchInput = page.getByPlaceholder('Buscar recursos de toda la plataforma...');
		await searchInput.click();
		await searchInput.pressSequentially('prueba', { delay: 50 });
		await expect(page.getByText('Recurso de prueba')).toBeVisible({ timeout: 10000 });
	});

	test('can navigate to create page', async ({ page }) => {
		await page.goto('/create');

		await expect(page.getByText('Titulo')).toBeVisible();
		await expect(page.getByText('Asignatura')).toBeVisible();
		await expect(page.getByText('Archivos*')).toBeVisible();
	});

	test('user profile page works', async ({ page }) => {
		await page.goto('/user/e2e-tester');

		await expect(page.getByRole('heading', { name: '@e2e-tester' })).toBeVisible();
		await expect(page.getByText('Recursos compartidos')).toBeVisible();
	});
});
