#!/usr/bin/env node
/**
 * Navigate to a URL and evaluate JavaScript
 * Usage: node evaluate.js <url> <javascript_code>
 */

const { chromium } = require('playwright');

const url = process.argv[2];
const jsCode = process.argv[3];

if (!url || !jsCode) {
  console.error('Error: URL and JavaScript code are required');
  console.error('Usage: node evaluate.js <url> <javascript_code>');
  console.error('Example: node evaluate.js https://example.com "document.title"');
  process.exit(1);
}

(async () => {
  const browser = await chromium.launch({ headless: true });
  const page = await browser.newPage();

  try {
    console.log(`Navigating to: ${url}`);
    await page.goto(url, { waitUntil: 'networkidle' });

    console.log(`Evaluating: ${jsCode}`);
    const result = await page.evaluate((code) => {
      return eval(code);
    }, jsCode);

    console.log('Result:');
    console.log(JSON.stringify(result, null, 2));
  } catch (error) {
    console.error('Error:', error.message);
    process.exit(1);
  } finally {
    await browser.close();
  }
})();
