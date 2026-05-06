import { shout } from './utils/string-helper';

export function emphasize(message: string): string {
  return shout(message) + '!!!';
}
