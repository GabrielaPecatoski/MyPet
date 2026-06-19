import { randomUUID } from "node:crypto";

export class Notification {
  private _id: string;
  private _userId: string;
  private _title: string;
  private _body: string;
  private _type: string;
  private _read: boolean;
  private _createdAt: Date;

  private constructor(props: {
    id: string;
    userId: string;
    title: string;
    body: string;
    type: string;
    read: boolean;
    createdAt: Date;
  }) {
    this._id = props.id;
    this._userId = props.userId;
    this._title = props.title;
    this._body = props.body;
    this._type = props.type;
    this._read = props.read;
    this._createdAt = props.createdAt;
  }

  static restore(props: {
    id?: string;
    userId: string;
    title: string;
    body: string;
    type: string;
    read?: boolean;
    createdAt?: Date;
  }): Notification {
    return new Notification({
      id: props.id ?? randomUUID(),
      userId: props.userId,
      title: props.title,
      body: props.body,
      type: props.type,
      read: props.read ?? false,
      createdAt: props.createdAt ?? new Date(),
    });
  }

  get id() {
    return this._id;
  }
  get userId() {
    return this._userId;
  }
  get title() {
    return this._title;
  }
  get body() {
    return this._body;
  }
  get type() {
    return this._type;
  }
  get read() {
    return this._read;
  }
  get createdAt() {
    return this._createdAt;
  }

  markAsRead(): void {
    this._read = true;
  }
}
