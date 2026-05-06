import { shout } from './utils/string-helper';

export function announceArrival(name: string): string {
  return `Welcome, ${shout(name)}!`;
}
