#!/usr/bin/env node
/**
 * Drag and drop an element
 * Usage: node drag.js <url> <source_selector> <target_selector>
 */

const { chromium } = require('playwright');

const url = process.argv[2];
const sourceSelector = process.argv[3];
const targetSelector = process.argv[4];

if (!url || !sourceSelector || !targetSelector) {
  console.error('Error: URL, source selector, and target selector are required');
  console.error('Usage: node drag.js <url> <source_selector> <target_selector>');
  console.error('Example: node drag.js https://example.com "#draggable" "#droppable"');
  process.exit(1);
}

(async () => {
  const browser = await chromium.launch({ headless: false });
  const page = await browser.newPage();

  try {
    console.log(`Navigating to: ${url}`);
    await page.goto(url, { waitUntil: 'networkidle' });

    console.log(`Waiting for selectors...`);
    await page.waitForSelector(sourceSelector, { timeout: 10000 });
    await page.waitForSelector(targetSelector, { timeout: 10000 });

    console.log(`Dragging ${sourceSelector} to ${targetSelector}`);
    await page.dragAndDrop(sourceSelector, targetSelector);

    console.log('Drag and drop successful');
    await page.waitForTimeout(2000);
  } catch (error) {
    console.error('Error:', error.message);
    process.exit(1);
  } finally {
    await browser.close();
  }
})();
