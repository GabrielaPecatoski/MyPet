import { Injectable, Logger } from "@nestjs/common";
import { Observable, Subject } from "rxjs";

export interface StreamEvent {
  id: string;
  type: string;
  title: string;
  body: string;
  createdAt: string;
}

@Injectable()
export class NotificationStreamService {
  private readonly logger = new Logger(NotificationStreamService.name);
  private readonly channels = new Map<string, Set<Subject<StreamEvent>>>();

  subscribe(userId: string): {
    stream: Observable<StreamEvent>;
    unsubscribe: () => void;
  } {
    const subject = new Subject<StreamEvent>();
    let set = this.channels.get(userId);
    if (!set) {
      set = new Set();
      this.channels.set(userId, set);
    }
    set.add(subject);
    this.logger.log(`SSE conectado: user=${userId} (${set.size} conexões)`);

    return {
      stream: subject.asObservable(),
      unsubscribe: () => {
        subject.complete();
        const s = this.channels.get(userId);
        if (s) {
          s.delete(subject);
          if (s.size === 0) this.channels.delete(userId);
        }
        this.logger.log(`SSE desconectado: user=${userId}`);
      },
    };
  }

  publish(userId: string, event: StreamEvent): void {
    const set = this.channels.get(userId);
    if (!set) return;
    for (const subject of set) subject.next(event);
  }
}
