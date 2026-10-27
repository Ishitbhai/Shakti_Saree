/// A question a customer sent in, as the Help & Support screen lists it.
///
/// Read-only: the `support` collection holds a subject and a message and
/// nothing to reply with, so the panel shows what came in and who sent it.
class SupportTicket {
  const SupportTicket({
    required this.id,
    required this.customer,
    required this.subject,
    required this.message,
    this.createdAt,
  });

  final String id;

  /// Who sent it, by name where their account has one.
  final String customer;

  final String subject;
  final String message;
  final DateTime? createdAt;
}
