#!/usr/bin/env node
/**
 * Fill multiple form fields at once
 * Usage: node fill-form.js <url> <json_data>
 */

const { chromium } = require('playwright');

const url = process.argv[2];
const jsonData = process.argv[3];

if (!url || !jsonData) {
  console.error('Error: URL and JSON data are required');
  console.error('Usage: node fill-form.js <url> <json_data>');
  console.error('Example: node fill-form.js https://example.com \'{"input[name=email]":"test@example.com","input[name=name]":"John"}\'');
  process.exit(1);
}

let formData;
try {
  formData = JSON.parse(jsonData);
} catch (error) {
  console.error('Error: Invalid JSON data');
  process.exit(1);
}

(async () => {
  const browser = await chromium.launch({ headless: false });
  const page = await browser.newPage();

  try {
    console.log(`Navigating to: ${url}`);
    await page.goto(url, { waitUntil: 'networkidle' });

    console.log('Filling form fields...');
    for (const [selector, value] of Object.entries(formData)) {
      console.log(`  ${selector} = ${value}`);
      await page.waitForSelector(selector, { timeout: 10000 });
      await page.fill(selector, String(value));
    }

    console.log('Form fill successful');
    await page.waitForTimeout(2000);
  } catch (error) {
    console.error('Error:', error.message);
    process.exit(1);
  } finally {
    await browser.close();
  }
})();
