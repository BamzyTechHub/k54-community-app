import 'package:local_auth/local_auth.dart';

class BiometricService {
  final LocalAuthentication auth = LocalAuthentication();

    Future<bool> authenticate() async {
  try {
    print("Checking biometrics...");

    final canCheck = await auth.canCheckBiometrics;
    print("canCheckBiometrics = $canCheck");

    final supported = await auth.isDeviceSupported();
    print("isDeviceSupported = $supported");

    final available = await auth.getAvailableBiometrics();
    print("Available biometrics = $available");

    final result = await auth.authenticate(
      localizedReason: "Authenticate to access K54",
      options: const AuthenticationOptions(
        biometricOnly: true,
        stickyAuth: true,
      ),
    );

    print("Authentication result = $result");

    return result;
  } catch (e) {
    print("Biometric Error: $e");
    return false;
  }
}
}