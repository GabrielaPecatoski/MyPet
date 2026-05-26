import type { Complaint } from "@review/complaints/domain/models/complaint.entity";

export const COMPLAINT_REPOSITORY = Symbol("COMPLAINT_REPOSITORY");

export interface ComplaintRepository {
  create(complaint: Complaint): Promise<void>;
  update(complaint: Complaint): Promise<void>;
  delete(id: string): Promise<void>;
  findById(id: string): Promise<Complaint | null>;
  findAll(status?: string): Promise<Complaint[]>;
  findByEstablishmentId(establishmentId: string): Promise<Complaint[]>;
}
