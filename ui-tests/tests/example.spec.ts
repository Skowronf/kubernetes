import { test, expect } from '@playwright/test';

test('should open owners page', async ({ page }) => {

  await page.goto('http://localhost:8080/owners');

  await expect(page).toHaveTitle(/PetClinic|Owners/);

  await expect(page.locator('body')).toContainText('Owners');
});
