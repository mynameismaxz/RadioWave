enum ToastType { info, success, error }

class AppToast {
  const AppToast({
    required this.id,
    required this.message,
    required this.type,
  });

  final int id;
  final String message;
  final ToastType type;
}
