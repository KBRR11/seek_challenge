import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'data/datasources/local/database_helper.dart';
import 'data/repositories/auth_repository_impl.dart';
import 'data/repositories/qr_repository_impl.dart';
import 'presentation/bloc/auth/auth_bloc.dart';
import 'presentation/bloc/qr/qr_bloc.dart';
import 'presentation/pages/splash_page.dart';
import 'package:flutter/services.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Forzar orientación vertical
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // Inicializar dependencias
  final databaseHelper = DatabaseHelper();
  final authRepository = AuthRepositoryImpl();
  final qrRepository = QrRepositoryImpl(databaseHelper);
  
  runApp(MyApp(
    authRepository: authRepository, 
    qrRepository: qrRepository
  ));
}

class MyApp extends StatelessWidget {
  final AuthRepositoryImpl authRepository;
  final QrRepositoryImpl qrRepository;
  
  const MyApp({
    Key? key, 
    required this.authRepository, 
    required this.qrRepository
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (context) => AuthBloc(authRepository),
        ),
        BlocProvider<QrBloc>(
          create: (context) => QrBloc(qrRepository),
        ),
      ],
      child: MaterialApp(
        title: 'QR Scanner App',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
          useMaterial3: true,
        ),
        home: const SplashPage(),
      ),
    );
  }
}