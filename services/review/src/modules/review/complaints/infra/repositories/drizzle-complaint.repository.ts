import { Complaint, type ComplaintStatus } from "@review/complaints/domain/models/complaint.entity";
import type { ComplaintRepository } from "@review/complaints/domain/repositories/complaint-repository.interface";
import { complaintsSchema } from "@review/complaints/infra/database/schemas/complaint.schema";
import { Injectable } from "@nestjs/common";
import { DrizzleService } from "@shared/infra/database/drizzle.service";
import { eq } from "drizzle-orm";

@Injectable()
export class DrizzleComplaintRepository implements ComplaintRepository {
  constructor(private readonly drizzleService: DrizzleService) {}

  async create(c: Complaint): Promise<void> {
    await this.drizzleService.db.insert(complaintsSchema).values({
      establishmentId: c.establishmentId,
      userId: c.userId,
      userName: c.userName,
      bookingId: c.bookingId,
      subject: c.subject,
      description: c.description,
      category: c.category,
      status: c.status,
      response: c.response,
      createdAt: new Date(),
      updatedAt: new Date(),
    });
  }

  async update(c: Complaint): Promise<void> {
    await this.drizzleService.db
      .update(complaintsSchema)
      .set({ status: c.status, response: c.response, updatedAt: new Date() })
      .where(eq(complaintsSchema.id, c.id!));
  }

  async delete(id: string): Promise<void> {
    await this.drizzleService.db.delete(complaintsSchema).where(eq(complaintsSchema.id, id));
  }

  async findById(id: string): Promise<Complaint | null> {
    const [row] = await this.drizzleService.db.select().from(complaintsSchema).where(eq(complaintsSchema.id, id)).limit(1);
    return row ? Complaint.restore({ ...row, status: row.status as ComplaintStatus, bookingId: row.bookingId ?? undefined, response: row.response ?? undefined }) : null;
  }

  async findAll(status?: string): Promise<Complaint[]> {
    const rows = status
      ? await this.drizzleService.db.select().from(complaintsSchema).where(eq(complaintsSchema.status, status))
      : await this.drizzleService.db.select().from(complaintsSchema);
    return rows.map((r) => Complaint.restore({ ...r, status: r.status as ComplaintStatus, bookingId: r.bookingId ?? undefined, response: r.response ?? undefined })!);
  }

  async findByEstablishmentId(establishmentId: string): Promise<Complaint[]> {
    const rows = await this.drizzleService.db.select().from(complaintsSchema).where(eq(complaintsSchema.establishmentId, establishmentId));
    return rows.map((r) => Complaint.restore({ ...r, status: r.status as ComplaintStatus, bookingId: r.bookingId ?? undefined, response: r.response ?? undefined })!);
  }
}
