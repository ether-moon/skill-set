export type User = { role: "admin" | "member" | "guest" };

export function canManageBilling(user: User): boolean {
  return user.role !== "guest";
}
