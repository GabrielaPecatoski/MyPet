export enum BookingExchangeName {
  CREATED = "booking.created.exchange",
  STATUS_UPDATED = "booking.status-updated.exchange",
  COMPLETED = "booking.completed.exchange",
  CANCELED = "booking.canceled.exchange",
  REMINDER = "booking.reminder.exchange",
  TODAY_REMINDER = "booking.today-reminder.exchange",
  PHOTOS_ADDED = "booking.photos-added.exchange",
}

export enum BookingRoutingKey {
  CREATED = "booking.created",
  STATUS_UPDATED = "booking.status-updated",
  COMPLETED = "booking.completed",
  CANCELED = "booking.canceled",
  REMINDER = "booking.reminder",
  TODAY_REMINDER = "booking.today-reminder",
  PHOTOS_ADDED = "booking.photos-added",
}
