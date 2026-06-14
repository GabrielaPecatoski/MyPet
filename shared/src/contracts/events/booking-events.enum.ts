export enum BookingExchangeName {
  CREATED = "booking.created.exchange",
  STATUS_UPDATED = "booking.status-updated.exchange",
  COMPLETED = "booking.completed.exchange",
  CANCELED = "booking.canceled.exchange",
  TODAY_REMINDER = "booking.today-reminder.exchange",
}

export enum BookingRoutingKey {
  CREATED = "booking.created",
  STATUS_UPDATED = "booking.status-updated",
  COMPLETED = "booking.completed",
  CANCELED = "booking.canceled",
  TODAY_REMINDER = "booking.today-reminder",
}
