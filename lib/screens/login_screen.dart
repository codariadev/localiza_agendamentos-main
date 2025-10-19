import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import '../core/firebase_auth_service.dart';
// ADICIONE A IMPORTAÇÃO DO FIREBASE_SERVICE
import '../core/firebase_service.dart'; 
import 'home_screen.dart';
import 'package:localiza_agendamentos/screens/hig_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _passwordController = TextEditingController();
  final FirebaseAuthService _authService = FirebaseAuthService();
  bool _isLoading = false;
  
  // ADICIONE A DECLARAÇÃO DA VARIÁVEL FALTANTE
  final _firebaseService = FirebaseService(); 

  Future<void> _login() async {
    setState(() => _isLoading = true);
    try {
      final senhaDigitada = _passwordController.text.trim();
      final userData = await _authService.login(senhaDigitada); 

      if (userData == null) {
        _showError('Senha incorreta ou cargo inválido');
      } else {
        final nome = userData['nome'];
        final cargo = userData['cargo'];

        // === PASSO 1: Obter o Token FCM MAIS RECENTE ===
        final fcmToken = await FirebaseMessaging.instance.getToken();
        
        if (fcmToken == null) {
          _showError('Não foi possível obter o Token FCM do dispositivo.');
          return;
        }

        // === PASSO 2: Salvar o Token FCM no banco de dados (Corrige o erro) ===
        await _firebaseService.atualizarDeviceToken(nome, fcmToken);

        // O token que passamos agora é o fcmToken recém-obtido.
        final token = fcmToken; 
        
        if (cargo == 'vendedor') { 
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => HomeScreen(
                nomeVendedor: nome,
                tokenDevice: token, 
              ), 
            ),
          );
        } else { 
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => HigScreen(
                nome: nome,
                tokenDevice: token, 
              ), 
            ),
          );
        }
      }
    } catch (e) {
      _showError('Erro ao fazer login: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Erro'),
        content: Text(msg),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          )
        ],
      ),
    );
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(40.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              Center(
                child: Image.asset(
                  'lib/assets/images/splash.png',
                  width: 200,
                  height: 200,
                  fit: BoxFit.contain,
                ),
              ),
              const Spacer(),
              const SizedBox(height: 40),
              SizedBox(
                width: 320,
                child: TextField(
                  controller: _passwordController,
                  obscureText: true,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color.fromRGBO(241, 124, 39, 1),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Digite sua senha',
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    filled: true,
                    fillColor: Colors.grey[200],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color.fromRGBO(241, 124, 39, 1),
                        width: 2,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color.fromRGBO(241, 124, 39, 1),
                        width: 2,
                      ),
                    ),
                    prefixIcon: const Icon(
                      Icons.lock,
                      color: Color.fromRGBO(241, 124, 39, 1),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: 250,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromRGBO(241, 124, 39, 1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: _isLoading ? null : _login,
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Login',
                          style: TextStyle(fontSize: 18, color: Colors.white),
                        ),
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
      backgroundColor: const Color.fromRGBO(8, 143, 66, 1),
    );
  }
}
