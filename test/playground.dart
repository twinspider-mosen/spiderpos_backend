void main(List<String> args) {
  print('Welcome to playground!');
  // print("Available Args passed from termianls $args");
  final params = {};

  for (final arg in args) {
    if (arg.startsWith('--') && arg.contains('=')) {
      final parts = arg.substring(2).split('=');
      params[parts[0]] = parts.sublist(1).join('=');
      print(parts);
    }
  }
  print(params);
}
