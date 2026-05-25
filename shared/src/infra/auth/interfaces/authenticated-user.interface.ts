export interface AuthenticatedUser {
  sub: string;
  email: string;
  name: string;
  role: string;
  permissions: string[];
}
