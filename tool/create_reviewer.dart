import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  final url = Uri.parse('https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=AIzaSyB21H7Nvb67yddWT1dzFV68pVDOxI15qfg');
  final res = await http.post(
    url,
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'email': 'google.reviewer@segurcel.app',
      'password': 'ReviewerPass2026!',
      'returnSecureToken': true,
    }),
  );
  print(res.body);
}
