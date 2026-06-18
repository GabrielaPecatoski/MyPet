export class FaqItem {
  private readonly _id?: string;
  private _question!: string;
  private _answer!: string;
  private _category!: string;
  private _targetRole!: string;
  private _order!: number;
  private _active!: boolean;
  private _viewCount!: number;
  private readonly _createdAt?: Date;

  private constructor(id?: string, createdAt?: Date) {
    this._id = id;
    this._createdAt = createdAt;
  }

  get id(): string | undefined {
    return this._id;
  }
  get question(): string {
    return this._question;
  }
  get answer(): string {
    return this._answer;
  }
  get category(): string {
    return this._category;
  }
  get targetRole(): string {
    return this._targetRole;
  }
  get order(): number {
    return this._order;
  }
  get active(): boolean {
    return this._active;
  }
  get viewCount(): number {
    return this._viewCount;
  }
  get createdAt(): Date | undefined {
    return this._createdAt;
  }

  withQuestion(v: string) {
    this._question = v;
    return this;
  }
  withAnswer(v: string) {
    this._answer = v;
    return this;
  }
  withCategory(v: string) {
    this._category = v;
    return this;
  }
  withTargetRole(v: string) {
    this._targetRole = v;
    return this;
  }
  withOrder(v: number) {
    this._order = v;
    return this;
  }
  withActive(v: boolean) {
    this._active = v;
    return this;
  }
  incrementViewCount() {
    this._viewCount += 1;
    return this;
  }

  toJSON() {
    return {
      id: this._id,
      question: this._question,
      answer: this._answer,
      category: this._category,
      targetRole: this._targetRole,
      order: this._order,
      active: this._active,
      viewCount: this._viewCount,
      createdAt: this._createdAt,
    };
  }

  static restore(props?: {
    id?: string;
    question: string;
    answer: string;
    category: string;
    targetRole: string;
    order: number;
    active: boolean;
    viewCount: number;
    createdAt?: Date;
  }): FaqItem | null {
    if (!props) return null;
    const f = new FaqItem(props.id, props.createdAt);
    f._question = props.question;
    f._answer = props.answer;
    f._category = props.category;
    f._targetRole = props.targetRole;
    f._order = props.order;
    f._active = props.active;
    f._viewCount = props.viewCount;
    return f;
  }
}
