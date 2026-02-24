import 'package:equatable/equatable.dart';

class BiometricBinding extends Equatable {
  final String accountId;
  final String? userId;
  final String? email;
  final String? fullName;
  final String? token;

  const BiometricBinding({
    required this.accountId,
    this.userId,
    this.email,
    this.fullName,
    this.token,
  });

  @override
  List<Object?> get props => [accountId, userId, email, fullName, token];
}
