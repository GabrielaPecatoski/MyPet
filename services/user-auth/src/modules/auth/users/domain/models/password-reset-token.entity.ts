export class PasswordResetToken {
  private _id: string;
  private _userId: string;
  private _token: string;
  private _expiresAt: Date;
  private _usedAt: Date | null;
  private _createdAt: Date;

  private constructor(props: {
    id: string;
    userId: string;
    token: string;
    expiresAt: Date;
    usedAt: Date | null;
    createdAt: Date;
  }) {
    this._id = props.id;
    this._userId = props.userId;
    this._token = props.token;
    this._expiresAt = props.expiresAt;
    this._usedAt = props.usedAt;
    this._createdAt = props.createdAt;
  }

  static restore(props: {
    id?: string;
    userId: string;
    token: string;
    expiresAt: Date;
    usedAt?: Date | null;
    createdAt?: Date;
  }): PasswordResetToken {
    return new PasswordResetToken({
      id: props.id ?? crypto.randomUUID(),
      userId: props.userId,
      token: props.token,
      expiresAt: props.expiresAt,
      usedAt: props.usedAt ?? null,
      createdAt: props.createdAt ?? new Date(),
    });
  }

  get id() {
    return this._id;
  }
  get userId() {
    return this._userId;
  }
  get token() {
    return this._token;
  }
  get expiresAt() {
    return this._expiresAt;
  }
  get usedAt() {
    return this._usedAt;
  }
  get createdAt() {
    return this._createdAt;
  }

  isUsed(): boolean {
    return this._usedAt !== null;
  }

  isExpired(now: Date = new Date()): boolean {
    return this._expiresAt.getTime() <= now.getTime();
  }

  isValid(now: Date = new Date()): boolean {
    return !this.isUsed() && !this.isExpired(now);
  }

  markUsed(): void {
    this._usedAt = new Date();
  }
}
