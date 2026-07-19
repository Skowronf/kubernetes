import { test, expect } from '@playwright/test';

test('should open owners page', async ({ page }) => {

  await page.goto('http://petclinic.local/owners');

  await expect(page).toHaveTitle(/PetClinic|Owners/);

  await expect(page.locator('body')).toContainText('Owners');
});

test('should open owners page 1', async ({ page }) => {

  await page.goto('http://petclinic.local/owners');

  await expect(page).toHaveTitle(/PetClinic|Owners/);

  await expect(page.locator('body')).toContainText('Owners');
});


test('should open owners page 2', async ({ page }) => {

  await page.goto('http://petclinic.local/owners');

  await expect(page).toHaveTitle(/PetClinic|Owners/);

  await expect(page.locator('body')).toContainText('Owners');
});

test('should open owners page 3', async ({ page }) => {

  await page.goto('http://petclinic.local/owners');

  await expect(page).toHaveTitle(/PetClinic|Owners/);

  await expect(page.locator('body')).toContainText('Owners');
});

test('should open owners page 4', async ({ page }) => {

  await page.goto('http://petclinic.local/owners');

  await expect(page).toHaveTitle(/PetClinic|Owners/);

  await expect(page.locator('body')).toContainText('Owners');
});

test('should open owners page 5', async ({ page }) => {

  await page.goto('http://petclinic.local/owners');

  await expect(page).toHaveTitle(/PetClinic|Owners/);

  await expect(page.locator('body')).toContainText('Owners');
});
