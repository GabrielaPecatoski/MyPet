import { Module } from "@nestjs/common";
import { ChatService } from "./application/services/chat.service";
import {
  CONVERSATION_REPO,
} from "./domain/repositories/conversation-repository.interface";
import {
  MESSAGE_REPO,
} from "./domain/repositories/message-repository.interface";
import { ChatController } from "./infra/controllers/chat.controller";
import { ChatGateway } from "./infra/gateways/chat.gateway";
import { DrizzleConversationRepository } from "./infra/repositories/drizzle-conversation.repository";
import { DrizzleMessageRepository } from "./infra/repositories/drizzle-message.repository";

@Module({
  controllers: [ChatController],
  providers: [
    ChatService,
    ChatGateway,
    { provide: CONVERSATION_REPO, useClass: DrizzleConversationRepository },
    { provide: MESSAGE_REPO, useClass: DrizzleMessageRepository },
  ],
})
export class ChatModule {}
