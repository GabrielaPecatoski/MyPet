import { randomUUID } from "crypto";

export type SenderRole = "CLIENTE" | "VENDEDOR";

export class Message {
  private _id: string;
  private _conversationId: string;
  private _senderId: string;
  private _senderRole: SenderRole;
  private _content: string;
  private _readAt: Date | null;
  private _createdAt: Date;

  private constructor(params: {
    id: string;
    conversationId: string;
    senderId: string;
    senderRole: SenderRole;
    content: string;
    readAt: Date | null;
    createdAt: Date;
  }) {
    this._id = params.id;
    this._conversationId = params.conversationId;
    this._senderId = params.senderId;
    this._senderRole = params.senderRole;
    this._content = params.content;
    this._readAt = params.readAt;
    this._createdAt = params.createdAt;
  }

  static create(params: {
    conversationId: string;
    senderId: string;
    senderRole: SenderRole;
    content: string;
  }): Message {
    return new Message({
      id: randomUUID(),
      conversationId: params.conversationId,
      senderId: params.senderId,
      senderRole: params.senderRole,
      content: params.content,
      readAt: null,
      createdAt: new Date(),
    });
  }

  static restore(params: {
    id: string;
    conversationId: string;
    senderId: string;
    senderRole: SenderRole;
    content: string;
    readAt: Date | null;
    createdAt: Date;
  }): Message {
    return new Message(params);
  }

  markAsRead(): void {
    this._readAt = new Date();
  }

  get id() { return this._id; }
  get conversationId() { return this._conversationId; }
  get senderId() { return this._senderId; }
  get senderRole() { return this._senderRole; }
  get content() { return this._content; }
  get readAt() { return this._readAt; }
  get createdAt() { return this._createdAt; }
}
