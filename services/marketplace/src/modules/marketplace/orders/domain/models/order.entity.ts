export type OrderStatus =
  | "AGUARDANDO_PAGAMENTO"
  | "ENVIANDO"
  | "A_CAMINHO"
  | "FINALIZADO"
  | "CANCELLED";

export type DeliveryMethod = "PICKUP" | "DELIVERY";

export class Order {
  private readonly _id?: string;
  private _userId!: string;
  private _establishmentId?: string;
  private _total!: number;
  private _status!: OrderStatus;
  private _deliveryMethod!: DeliveryMethod;
  private _deliveryAddress?: string;
  private _items!: OrderItemData[];
  private readonly _createdAt?: Date;

  private constructor(id?: string, createdAt?: Date) {
    this._id = id;
    this._createdAt = createdAt;
  }

  get id(): string | undefined { return this._id; }
  get userId(): string { return this._userId; }
  get establishmentId(): string | undefined { return this._establishmentId; }
  get total(): number { return this._total; }
  get status(): OrderStatus { return this._status; }
  get deliveryMethod(): DeliveryMethod { return this._deliveryMethod; }
  get deliveryAddress(): string | undefined { return this._deliveryAddress; }
  get items(): OrderItemData[] { return this._items; }
  get createdAt(): Date | undefined { return this._createdAt; }

  static restore(props?: {
    id?: string;
    userId: string;
    establishmentId?: string | null;
    total: number;
    status: OrderStatus;
    deliveryMethod?: string | null;
    deliveryAddress?: string | null;
    items: OrderItemData[];
    createdAt?: Date;
  }): Order | null {
    if (!props) return null;
    const o = new Order(props.id, props.createdAt);
    o._userId = props.userId;
    o._establishmentId = props.establishmentId ?? undefined;
    o._total = props.total;
    o._status = props.status;
    o._deliveryMethod = (props.deliveryMethod as DeliveryMethod) ?? "PICKUP";
    o._deliveryAddress = props.deliveryAddress ?? undefined;
    o._items = props.items;
    return o;
  }
}

export interface OrderItemData {
  id?: string;
  productId: string;
  quantity: number;
  price: number;
}
