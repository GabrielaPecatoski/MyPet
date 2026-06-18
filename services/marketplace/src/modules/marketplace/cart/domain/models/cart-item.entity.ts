export class CartItem {
  private readonly _id?: string;
  private _userId!: string;
  private _productId!: string;
  private _quantity!: number;

  private constructor(id?: string) {
    this._id = id;
  }

  get id(): string | undefined {
    return this._id;
  }
  get userId(): string {
    return this._userId;
  }
  get productId(): string {
    return this._productId;
  }
  get quantity(): number {
    return this._quantity;
  }

  withQuantity(v: number) {
    this._quantity = v;
    return this;
  }

  static restore(props?: {
    id?: string;
    userId: string;
    productId: string;
    quantity: number;
  }): CartItem | null {
    if (!props) return null;
    const c = new CartItem(props.id);
    c._userId = props.userId;
    c._productId = props.productId;
    c._quantity = props.quantity;
    return c;
  }
}
