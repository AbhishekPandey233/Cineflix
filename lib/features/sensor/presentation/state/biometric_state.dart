import 'package:equatable/equatable.dart';

enum BiometricStatus { idle, busy, error }

class BiometricState extends Equatable {
  final BiometricStatus status;
  final String? errorMessage;

  const BiometricState({
    this.status = BiometricStatus.idle,
    this.errorMessage,
  });

  BiometricState copyWith({
    BiometricStatus? status,
    String? errorMessage,
  }) {
    return BiometricState(
      status: status ?? this.status,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, errorMessage];
}
