import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  bool _isLoading = false;
  bool _isLogin = true;

  // Variável inteligente para garantir que o Google inicialize apenas uma vez
  static bool _googleInicializado = false;

  Future<void> _autenticarEmailSenha() async {
    setState(() => _isLoading = true);
    try {
      if (_isLogin) {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _senhaController.text.trim(),
        );
      } else {
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _senhaController.text.trim(),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message ?? 'Erro na autenticação'), backgroundColor: Colors.red.shade400),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- MÁGICA DO GOOGLE SIGN-IN (ATUALIZADA PARA V7.0+) ---
  Future<void> _entrarComGoogle() async {
    setState(() => _isLoading = true);
    try {
      // 1. O novo padrão exige usar a instância global (Singleton)
      final googleSignIn = GoogleSignIn.instance;

      // 2. A versão 7 exige uma inicialização obrigatória antes de tudo
      if (!_googleInicializado) {
        await googleSignIn.initialize();
        _googleInicializado = true;
      }
      
      // 3. O antigo signIn() agora se chama authenticate()
      final GoogleSignInAccount? googleUser = await googleSignIn.authenticate();
      
      // Se o usuário fechar o pop-up sem escolher conta, paramos aqui
      if (googleUser == null) {
        setState(() => _isLoading = false);
        return; 
      }

      // 4. Passo 1 de Segurança: Identidade (Obtém o idToken)
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // 5. Passo 2 de Segurança: Permissões (Obtém o accessToken explicitamente)
      final clientAuth = await googleUser.authorizationClient.authorizeScopes(['email']);

      // 6. Cria a credencial do Firebase com os dois tokens recuperados
      final OAuthCredential credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
        accessToken: clientAuth.accessToken,
      );

      // 7. Loga no Firebase com essa credencial
      await FirebaseAuth.instance.signInWithCredential(credential);

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao logar com Google: $e'), backgroundColor: Colors.red.shade400),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.task_alt, size: 80, color: color.primary),
              const SizedBox(height: 16),
              Text(
                _isLogin ? 'Bem-vindo de volta!' : 'Crie sua conta',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'E-mail',
                  filled: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _senhaController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Senha',
                  filled: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 24),
              if (_isLoading)
                const CircularProgressIndicator()
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ElevatedButton(
                      onPressed: _autenticarEmailSenha,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: color.primary,
                        foregroundColor: color.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: Text(_isLogin ? 'Entrar' : 'Cadastrar', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.g_mobiledata, size: 30),
                      label: const Text('Entrar com Google', style: TextStyle(fontSize: 16)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: _entrarComGoogle, 
                    ),
                  ],
                ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => setState(() => _isLogin = !_isLogin),
                child: Text(
                  _isLogin ? 'Não tem uma conta? Cadastre-se' : 'Já tem conta? Entre aqui',
                  style: TextStyle(color: color.onSurfaceVariant),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}