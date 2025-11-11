#!/usr/bin/env node
/**
 * Capture console messages from a page
 * Usage: node console-messages.js <url>
 */

const { chromium } = require('playwright');

const url = process.argv[2];

if (!url) {
  console.error('Error: URL is required');
  console.error('Usage: node console-messages.js <url>');
  process.exit(1);
}

(async () => {
  const browser = await chromium.launch({ headless: true });
  const page = await browser.newPage();

  const messages = [];

  // Listen to console messages
  page.on('console', msg => {
    messages.push({
      type: msg.type(),
      text: msg.text(),
      location: msg.location()
    });
  });

  try {
    console.log(`Navigating to: ${url}`);
    await page.goto(url, { waitUntil: 'networkidle' });
    await page.waitForTimeout(2000); // Wait for any delayed console logs

    console.log('\nConsole Messages:');
    console.log(JSON.stringify(messages, null, 2));
  } catch (error) {
    console.error('Error:', error.message);
    process.exit(1);
  } finally {
    await browser.close();
  }
})();
