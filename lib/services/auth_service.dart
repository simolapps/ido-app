import 'api_client.dart';
import 'storage.dart';


class AuthService {
final ApiClient api;
final Storage storage;
AuthService(this.api, this.storage);


Future<Map<String, dynamic>> sendCode(String phone) async {
return api.post('/auth/send_code', {'phone': phone});
}


Future<bool> verifyCode(String phone, String code) async {
final data = await api.post('/auth/verify_code', {
'phone': phone,
'code': code,
});
if (data['success'] == true && data['user'] != null) {
final u = data['user'];
await storage.saveAuth(
masterId: int.parse(u['master_id'].toString()),
phone: u['phone']?.toString() ?? phone,
name: ((u['first_name'] ?? '').toString()).trim(),
access: data['tokens']?['access'],
refresh: data['tokens']?['refresh'],
);
return true;
}
return false;
}


Future<bool> registerProfile(
{required String phone,
required String firstName,
String? lastName,
String? middleName}) async {
final data = await api.post('/auth/register', {
'phone': phone,
'first_name': firstName,
'last_name': lastName,
'middle_name': middleName,
});
if (data['success'] == true && data['user'] != null) {
final u = data['user'];
await storage.saveAuth(
masterId: int.parse(u['master_id'].toString()),
phone: u['phone']?.toString() ?? phone,
name: (u['first_name'] ?? firstName).toString(),
access: data['tokens']?['access'],
refresh: data['tokens']?['refresh'],
);
return true;
}
return false;
}
}