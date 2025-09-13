import 'dart:math';

String generateFirestoreKey() {
  const String chars =
      'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
  const int length = 20;
  final Random random = Random.secure();

  return List.generate(
    length,
    (index) => chars[random.nextInt(chars.length)],
  ).join();
}
