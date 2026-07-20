// Thin wrapper around String.prototype.toUpperCase().
// Re-exported for "consistency" but adds nothing.
export function shout(s: string): string {
  return s.toUpperCase();
}
