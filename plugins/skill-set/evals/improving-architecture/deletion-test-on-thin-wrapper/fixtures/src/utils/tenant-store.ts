type RecordValue = { tenantId: string; value: string };

export class MemoryStore {
  constructor(private records: Map<string, RecordValue>) {}

  load(key: string): RecordValue | undefined {
    return this.records.get(key);
  }
}

export function readTenantValue(store: MemoryStore, tenantId: string, key: string): string | undefined {
  const record = store.load(key);
  if (!record) return undefined;
  if (record.tenantId !== tenantId) throw new Error('Tenant mismatch');
  return record.value;
}
