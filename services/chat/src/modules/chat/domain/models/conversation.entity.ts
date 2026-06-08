import { randomUUID } from "crypto";

export class Conversation {
  private _id: string;
  private _bookingId: string;
  private _clientId: string;
  private _establishmentId: string;
  private _lastMessageAt: Date | null;
  private _createdAt: Date;

  private constructor(params: {
    id: string;
    bookingId: string;
    clientId: string;
    establishmentId: string;
    lastMessageAt: Date | null;
    createdAt: Date;
  }) {
    this._id = params.id;
    this._bookingId = params.bookingId;
    this._clientId = params.clientId;
    this._establishmentId = params.establishmentId;
    this._lastMessageAt = params.lastMessageAt;
    this._createdAt = params.createdAt;
  }

  static create(params: {
    bookingId: string;
    clientId: string;
    establishmentId: string;
  }): Conversation {
    return new Conversation({
      id: randomUUID(),
      bookingId: params.bookingId,
      clientId: params.clientId,
      establishmentId: params.establishmentId,
      lastMessageAt: null,
      createdAt: new Date(),
    });
  }

  static restore(params: {
    id: string;
    bookingId: string;
    clientId: string;
    establishmentId: string;
    lastMessageAt: Date | null;
    createdAt: Date;
  }): Conversation {
    return new Conversation(params);
  }

  touch(): void {
    this._lastMessageAt = new Date();
  }

  get id() { return this._id; }
  get bookingId() { return this._bookingId; }
  get clientId() { return this._clientId; }
  get establishmentId() { return this._establishmentId; }
  get lastMessageAt() { return this._lastMessageAt; }
  get createdAt() { return this._createdAt; }
}
