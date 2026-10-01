// Recuperação de boot — limpa dados locais corrompidos e (na web) recarrega.
// Resolve o caso de cache antigo / IndexedDB / localStorage corrompido que
// trava o app numa versão defeituosa.
export 'boot_recovery_stub.dart'
    if (dart.library.html) 'boot_recovery_web.dart';
