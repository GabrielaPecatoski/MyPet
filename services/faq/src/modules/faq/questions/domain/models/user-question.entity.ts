export type QuestionStatus = "PENDENTE" | "RESPONDIDA" | "FECHADA";

export class UserQuestion {
  private readonly _id?: string;
  private _userId!: string;
  private _userName!: string;
  private _userRole!: string;
  private _question!: string;
  private _answer?: string;
  private _status!: QuestionStatus;
  private readonly _createdAt?: Date;
  private _answeredAt?: Date;

  private constructor(id?: string, createdAt?: Date) {
    this._id = id;
    this._createdAt = createdAt;
  }

  get id(): string | undefined {
    return this._id;
  }
  get userId(): string {
    return this._userId;
  }
  get userName(): string {
    return this._userName;
  }
  get userRole(): string {
    return this._userRole;
  }
  get question(): string {
    return this._question;
  }
  get answer(): string | undefined {
    return this._answer;
  }
  get status(): QuestionStatus {
    return this._status;
  }
  get createdAt(): Date | undefined {
    return this._createdAt;
  }
  get answeredAt(): Date | undefined {
    return this._answeredAt;
  }

  withAnswer(answer: string) {
    this._answer = answer;
    this._status = "RESPONDIDA";
    this._answeredAt = new Date();
    return this;
  }
  close() {
    this._status = "FECHADA";
    return this;
  }

  toJSON() {
    return {
      id: this._id,
      userId: this._userId,
      userName: this._userName,
      userRole: this._userRole,
      question: this._question,
      answer: this._answer,
      status: this._status,
      createdAt: this._createdAt,
      answeredAt: this._answeredAt,
    };
  }

  static restore(props?: {
    id?: string;
    userId: string;
    userName: string;
    userRole: string;
    question: string;
    answer?: string;
    status: QuestionStatus;
    createdAt?: Date;
    answeredAt?: Date;
  }): UserQuestion | null {
    if (!props) return null;
    const q = new UserQuestion(props.id, props.createdAt);
    q._userId = props.userId;
    q._userName = props.userName;
    q._userRole = props.userRole;
    q._question = props.question;
    q._answer = props.answer;
    q._status = props.status;
    q._answeredAt = props.answeredAt;
    return q;
  }
}
