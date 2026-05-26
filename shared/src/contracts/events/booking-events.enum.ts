export enum BookingExchangeName {
  CREATED = "booking.created.exchange",
  STATUS_UPDATED = "booking.status-updated.exchange",
  COMPLETED = "booking.completed.exchange",
  CANCELED = "booking.canceled.exchange",
}

export enum BookingRoutingKey {
  CREATED = "booking.created",
  STATUS_UPDATED = "booking.status-updated",
  COMPLETED = "booking.completed",
  CANCELED = "booking.canceled",
}
