
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/stripe_config.dart';

class StripeService {
static const Map<String, String> _testTokens = {
'4242424242424242' : 'tok_visa',
'4000565656565656' : 'tok_visa_debit',
'5555555555555444' : 'tok_mastercard',
'5200987654324471' : 'tok_mastercard_debit',
'4000000000000002' : 'tok_chargeDeclined',
'4000000000099954' : 'tok_chargeDeclinedInsufficientFunds',
};

static Future<Map<String, dynamic>> processPayment({
required double amount,
required String cardNumber,
required String expMonth,
required String expYear,
required String cvc,
}) async {
final amountInCentavos = (amount * 100).round().toString();
final cleanCard = cardNumber.replaceAll(' ', '');
final token = _testTokens[cleanCard];

if (token == null) {
return {
'success': false,
'error': 'Unknown test card. Use 5555555555555444 (success)',
};
}

try {
final response = await http.post(
Uri.parse('${StripeConfig.apiUrl}/payment_intents'),
headers: {
'Authorization': 'Bearer ${StripeConfig.secretKey}',
'Content-Type': 'application/x-www-form-urlencoded',
},
body: {
'amount': amountInCentavos,
'currency': 'php',
'payment_method_types[]': 'card',
'payment_method_data[type]': 'card',
'payment_method_data[card][token]': token,
'confirm': 'true',
'return_url': 'https://example.com/return',
},
);

final data = jsonDecode(response.body);

if (response.statusCode == 200 || response.statusCode == 201) {
if (data['status'] == 'succeeded') {
return {
'success': true,
'id': data['id'] ?? 'N/A',
// FIX: Convert centavos back to double and ensure it's not null
'amount': (data['amount'] as num? ?? 0).toDouble() / 100,
'data': data,
};
} else {
return {
'success': false,
'error': 'Payment status: ${data['status']}',
'data': data,
};
}
} else {
return {
'success': false,
'error': data['error']?['message'] ?? 'Payment failed with status: ${response.statusCode}',
};
}
} catch (e) {
return {
'success': false,
'error': 'Connection error: ${e.toString()}',
};
}
}
}
