export class PasswordResetToken {
  private _id!: string;
  private _userId!: string;
  private _token!: string;
  private _expiresAt!: Date;
  private _usedAt?: Date;
  private _createdAt!: Date;

  get id(): string { return this._id; }
  get userId(): string { return this._userId; }
  get token(): string { return this._token; }
  get expiresAt(): Date { return this._expiresAt; }
  get usedAt(): Date | undefined { return this._usedAt; }
  get createdAt(): Date { return this._createdAt; }

  withUsedAt(usedAt: Date) { this._usedAt = usedAt; return this; }

  isExpired(): boolean {
    return new Date() > this._expiresAt;
  }

  isAlreadyUsed(): boolean {
    return !!this._usedAt;
  }

  static create(userId: string, token: string, expiresIn: number): PasswordResetToken {
    const instance = new PasswordResetToken();
    instance._userId = userId;
    instance._token = token;
    instance._createdAt = new Date();
    instance._expiresAt = new Date(instance._createdAt.getTime() + expiresIn);
    return instance;
  }

  static restore(props: {
    id: string;
    userId: string;
    token: string;
    expiresAt: Date;
    usedAt?: Date;
    createdAt: Date;
  }): PasswordResetToken {
    const instance = new PasswordResetToken();
    instance._id = props.id;
    instance._userId = props.userId;
    instance._token = props.token;
    instance._expiresAt = props.expiresAt;
    instance._usedAt = props.usedAt;
    instance._createdAt = props.createdAt;
    return instance;
  }
}
