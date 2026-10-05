/// One question and the answer the admin panel gives for it.
///
/// The question is the identity — it is what the list is read by and what an
/// edit is found by — so two FAQs cannot ask the same thing. Whether a given
/// write is allowed is the repository's business, not the model's.
class Faq {
  const Faq({required this.question, required this.answer});

  final String question;
  final String answer;

  Faq copyWith({String? question, String? answer}) =>
      Faq(question: question ?? this.question, answer: answer ?? this.answer);
}
