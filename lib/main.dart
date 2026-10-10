// LOG DE DIAGNÓSTICO TEMPORÁRIO: usa print() de propósito para sair no console
// do navegador. Remover/reduzir verbosidade após localizar a causa do crash.
// ignore_for_file: avoid_print
import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter/gestures.dart' show GestureBinding;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'models/auth_utility.dart';
import 'auth_screens/login_screen.dart';
import 'services/session_expired_handler.dart';
import 'utils/grid_colors.dart';
import 'utils/security_matrix.dart';
import 'utils/app_logger.dart';
import 'utils/boot_recovery.dart';
import 'core/theme/zen_theme.dart';
import 'web/screens/bottom_navbar_screen.dart';



import 'mobile/screens/bottom_navbar_screen.dart';
import 'windows/screens/bottom_navbar_screen.dart';

// Prefixos de log: [BOOT] etapa ok · [BOOT-ERR] falha tolerada · [APP-ERROR] erro de runtime.
void _log(String msg) => print('[BOOT] $msg');
void _logErr(String tag, Object e, [StackTrace? s]) =>
    print('[BOOT-ERR] $tag: $e${s != null ? '\n$s' : ''}');

void main() {
  // runZonedGuarded captura erros assíncronos não tratados em qualquer ponto.
  runZonedGuarded(() {
    WidgetsFlutterBinding.ensureInitialized();
    _log('WidgetsFlutterBinding pronto');

    // Desliga o resampling de eventos de ponteiro (Flutter guarda amostras e
    // as reproduz num callback do scheduler para suavizar toques). O crash
    // reportado pelo cliente ("Null check operator... gestures library...
    // while handling a pointer data packet" e, no mesmo main.dart.js, a
    // MESMA funcao interna disparada via "scheduler library... during a
    // scheduler callback") bate exatamente com esse mecanismo: e reproduzido
    // tanto direto no roteamento do ponteiro quanto num callback do
    // scheduler, que e como o resampler funciona por dentro. Desabilitar
    // troca suavizacao de toque por robustez -- sem perda perceptivel de UX
    // num app de formulario/grid (nao ha animacao de arrastar dependente
    // disso).
    GestureBinding.instance.resamplingEnabled = false;
    _log('resamplingEnabled = false');

    // Terceira camada de captura (faltava): erros que vem do engine/platform
    // channel -- ex.: falhas no roteamento de ponteiro/gesto reportadas pelo
    // GestureBinding ("Null check operator... gestures library... while
    // handling a pointer data packet") passam por aqui, nao por
    // FlutterError.onError (erros de build) nem pelo onError do
    // runZonedGuarded (erros assincronos Dart). Sem essa camada esses erros
    // ficavam sem handler explicito e podiam propagar como excecao JS nao
    // tratada ate o `window` do navegador. Retornar true marca como tratado.
    PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
      print('[APP-ERROR] PlatformDispatcher (engine/gestures): $error');
      print('[APP-ERROR] stack:\n$stack');
      return true;
    };

    // Erros do framework -> console (com biblioteca/contexto/stack, que apontam o widget).
    FlutterError.onError = (FlutterErrorDetails details) {
      print('[APP-ERROR] FlutterError: ${details.exceptionAsString()}');
      print('[APP-ERROR] biblioteca: ${details.library} | contexto: ${details.context}');
      print('[APP-ERROR] stack:\n${details.stack}');
      FlutterError.presentError(details);
    };
    try {
      AppLogger.i.initCapture();
      _log('AppLogger.initCapture ok');
    } catch (e, s) {
      _logErr('AppLogger.initCapture', e, s);
    }

    // Em vez da tela rosa / ErrorWidget mudo, mostra um indicador adaptativo.
    // ErrorWidget.builder é GLOBAL: troca QUALQUER widget que falhe durante o
    // build, em QUALQUER lugar da árvore — não só falha de boot do app
    // inteiro. _BootErrorScreen (MaterialApp+Scaffold completos) só cabe
    // quando o espaço disponível é de tela cheia; num ícone pequeno dentro de
    // um card/popup ela conseguia causar overflow (faixas amarelo/preto) e
    // mostrar so um retangulo vermelho/rosa vazio. _AdaptiveErrorBox decide o
    // tamanho certo via LayoutBuilder. O erro detalhado já sai pelo
    // FlutterError.onError acima — aqui não duplicar.
    ErrorWidget.builder = (FlutterErrorDetails details) {
      print('[APP-ERROR] _AdaptiveErrorBox exibida (detalhes acima via FlutterError).');
      return const _AdaptiveErrorBox();
    };

    _log('runApp bootstrap');
    runApp(const TaskManagerBootstrap());
  }, (error, stack) {
    print('[APP-ERROR] erro não tratado: $error');
    print('[APP-ERROR] stack:\n$stack');
  });
}

Future<bool> _carregarEstadoInicial() async {
  try {
    await initializeDateFormatting('pt_BR', null);
    _log('initializeDateFormatting ok');
  } catch (e, s) {
    _logErr('initializeDateFormatting', e, s);
  }

  try {
    await Hive.initFlutter();
    _log('Hive.initFlutter ok');
  } catch (e, s) {
    _logErr('Hive.initFlutter', e, s);
  }

  // Blindagem: box corrompida não pode derrubar o app antes do runApp.
  try {
    await Hive.openBox('vendas_contingencia');
    _log('openBox vendas_contingencia ok');
  } catch (e, s) {
    _logErr('openBox vendas_contingencia (tentando recriar)', e, s);
    try {
      await Hive.deleteBoxFromDisk('vendas_contingencia');
      await Hive.openBox('vendas_contingencia');
      _log('box vendas_contingencia recriada após corrupção');
    } catch (e2, s2) {
      _logErr('recriação da box vendas_contingencia', e2, s2);
    }
  }

  // Blindagem: sessão corrompida -> limpa e cai para login em vez de crashar.
  bool loggedIn = false;
  try {
    loggedIn = await AuthUtility.isUserLoggedIn();
    _log('isUserLoggedIn = $loggedIn');
  } catch (e, s) {
    _logErr('isUserLoggedIn (limpando sessão)', e, s);
    try {
      await AuthUtility.clearUserInfo();
    } catch (_) {}
    loggedIn = false;
  }

  if (loggedIn) {
    try {
      await ModuloAccess.load();
      _log('ModuloAccess.load ok');
    } catch (e, s) {
      _logErr('ModuloAccess.load', e, s);
    }
  }

  _log('runApp');

  return loggedIn;
}

class TaskManagerBootstrap extends StatefulWidget {
  const TaskManagerBootstrap({super.key});

  @override
  State<TaskManagerBootstrap> createState() => _TaskManagerBootstrapState();
}

class _TaskManagerBootstrapState extends State<TaskManagerBootstrap> {
  bool? _loggedIn;

  @override
  void initState() {
    super.initState();
    _carregarEstadoInicial().then((loggedIn) {
      if (mounted) setState(() => _loggedIn = loggedIn);
    });
  }

  @override
  Widget build(BuildContext context) => TaskManagerApp(loggedIn: _loggedIn);
}

class TaskManagerApp extends StatelessWidget {
  final bool? loggedIn;
  const TaskManagerApp({super.key, required this.loggedIn});

  @override
  Widget build(BuildContext context) {
    Widget home;

    if (loggedIn == null) {
      home = const _BootLoadingScreen();
    } else if (loggedIn!) {
      if (kIsWeb) {
        home = const WebBottomNavBarScreen();
      } else if (defaultTargetPlatform == TargetPlatform.windows) {
        home = const WindowsBottomNavBarScreen();
      } else {
        home = const BottomNavBarScreen();
      }
    } else {
      home = const LoginScreen();
    }

    return MaterialApp(
      navigatorKey: SessionExpiredHandler.navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'Gestão Empresarial - Conta Própria',
      theme: ZenTheme.lightTheme,

      locale: const Locale('pt', 'BR'),
      supportedLocales: const [Locale('pt', 'BR')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: home,
    );
  }
}

/// Tela exibida quando o build de um widget falha (substitui o "fundo rosa" /
/// ErrorWidget padrão). Oferece limpar dados locais e recarregar — caminho de
/// recuperação para cache antigo ou storage corrompido.
/// Substitui qualquer widget que falhe durante o build (ErrorWidget.builder é
/// GLOBAL, então isso pode acontecer num ícone de 24px dentro de um card ou
/// numa tela cheia no boot do app). Decide o tamanho certo via LayoutBuilder
/// em vez de sempre forcar um MaterialApp+Scaffold completo (que conseguia
/// causar overflow/fundo vazio em espacos pequenos — bug reportado como
/// "fundo rosa" num popup do GED e "barra vermelha cortada" no calendario).
class _AdaptiveErrorBox extends StatelessWidget {
  const _AdaptiveErrorBox();

  // Limiares de tamanho (review: nomeados para não exigir reler a cadeia de
  // ifs pra saber o que cada número significa).
  static const double _kTiny = 40;
  static const double _kSmall = 120;
  static const double _kMedium = 300;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final largura = constraints.maxWidth;
        final altura = constraints.maxHeight;
        // math.min direto em vez de List+where+reduce (review: mesma
        // intenção, sem alocar coleção intermediária pra 2 valores).
        final menorLado = math.min(
          largura.isFinite ? largura : double.infinity,
          altura.isFinite ? altura : double.infinity,
        );

        if (menorLado < _kTiny) {
          return const Center(
            child: Icon(Icons.error_outline, size: 16, color: GridColors.error),
          );
        }
        if (menorLado < _kSmall) {
          return const Center(
            child: Tooltip(
              message: 'Erro ao carregar',
              child: Icon(Icons.error_outline, size: 20, color: GridColors.error),
            ),
          );
        }
        if (menorLado < _kMedium) {
          // Column em vez de Row+Flexible: Row com filho flexível dentro de
          // largura ILIMITADA (comum aqui — este branch também é alcançado
          // quando a altura é pequena mas a largura do pai é infinita, ex.
          // dentro de uma Column/ListView sem largura definida) lança
          // "RenderFlex children have non-zero flex but incoming width
          // constraints are unbounded". Column não tem esse problema no eixo
          // cruzado sem filhos Expanded/Flexible.
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.error_outline, size: 28, color: GridColors.error),
                  SizedBox(height: 6),
                  Text('Erro ao carregar',
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          );
        }
        return const _ErroTelaCompleta();
      },
    );
  }
}

/// Versão completa (tela cheia / boot do app): mesmo conteúdo de antes, só
/// renderizada quando o espaço disponível de fato comporta. Sem MaterialApp
/// novo — usa Directionality+Material próprios para herdar o Theme/contexto
/// já existentes em vez de duplicar a árvore do app.
class _ErroTelaCompleta extends StatelessWidget {
  const _ErroTelaCompleta();

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Material(
        color: GridColors.background,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline,
                      size: 56, color: GridColors.error),
                  const SizedBox(height: 16),
                  const Text(
                    'Não foi possível carregar o sistema',
                    textAlign: TextAlign.center,
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Isso costuma ser causado por dados antigos guardados neste '
                    'navegador. Limpe os dados locais e recarregue para resolver.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.black54),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => limparDadosLocaisERecarregar(),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Limpar dados e recarregar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: GridColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 14),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BootLoadingScreen extends StatelessWidget {
  const _BootLoadingScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GridColors.secondary,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x33000000),
                          blurRadius: 24,
                          offset: Offset(0, 12),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.apartment_rounded,
                      color: GridColors.primary,
                      size: 36,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Gestão Empresarial',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Carregando sistema',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: GridColors.textPrimaryMuted,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 28),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: const LinearProgressIndicator(
                      minHeight: 6,
                      backgroundColor: Color(0x33FFFFFF),
                      valueColor:
                          AlwaysStoppedAnimation<Color>(GridColors.primary),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
