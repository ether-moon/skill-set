import { shout } from './utils/string-helper';
import { MemoryStore, readTenantValue } from './utils/tenant-store';

export function announceArrival(name: string): string {
  return `Welcome, ${shout(name)}!`;
}

export function readForTenant(store: MemoryStore, tenantId: string, key: string): string | undefined {
  return readTenantValue(store, tenantId, key);
}
