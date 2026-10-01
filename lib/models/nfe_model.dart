import 'package:flutter/material.dart';
import '../utils/grid_colors.dart';

// ─── NfeItem ──────────────────────────────────────────────────────────────────
/// Modelo de item da NF-e.
/// NF02: adicionados campos PIS/COFINS, vFrete, vSeg, vDesc, vOutro,
///        indTot, xPed, nItemPed, nFCI, cstIcmsSt, vBcSt, vIcmsSt,
///        cstIpi, aliqIpi, vBcIpi, vIpi, codTribIss, aliqIss, vBcIss, vIss.
class NfeItem {
  int? id;
  String? cProd;
  String? xProd;
  String? ncm;
  String? cfop;
  String? uCom;
  double? qCom;
  double? vUnCom;
  double? vProd;

  // ICMS
  String? cstIcms;
  double? aliqIcms;
  double? vBcIcms;
  double? vIcms;
  // ICMS-ST
  String? cstIcmsSt;
  double? vBcSt;
  double? vIcmsSt;

  // IPI
  String? cstIpi;
  double? aliqIpi;
  double? vBcIpi;
  double? vIpi;

  // ISS
  String? codTribIss;
  double? aliqIss;
  double? vBcIss;
  double? vIss;

  // PIS (NF02)
  String? cstPis;
  double? vBcPis;
  double? pPis;
  double? vPis;
  String? cstPisSt;
  double? vBcPisSt;
  double? pPisSt;
  double? vPisSt;

  // COFINS (NF02)
  String? cstCofins;
  double? vBcCofins;
  double? pCofins;
  double? vCofins;
  String? cstCofinsSt;
  double? vBcCofinsSt;
  double? pCofinsSt;
  double? vCofinsSt;

  // Outros campos de item (NF02)
  String? xPed;
  String? nItemPed;
  double? vFrete;
  double? vSeg;
  double? vDesc;
  double? vOutro;
  String? indTot;
  String? nFCI;

  NfeItem.fromJson(Map<String, dynamic> j) {
    id = j['id'];
    cProd = j['cProd']?.toString();
    xProd = j['xProd']?.toString();
    ncm = j['ncm']?.toString();
    cfop = j['cfop']?.toString();
    uCom = j['uCom']?.toString();
    qCom = (j['qCom'] as num?)?.toDouble();
    vUnCom = (j['vUnCom'] as num?)?.toDouble();
    vProd = (j['vProd'] as num?)?.toDouble();

    cstIcms = j['cstIcms']?.toString();
    aliqIcms = (j['aliqIcms'] as num?)?.toDouble();
    vBcIcms = (j['vBcIcms'] as num?)?.toDouble();
    vIcms = (j['vIcms'] as num?)?.toDouble();
    cstIcmsSt = j['cstIcmsSt']?.toString();
    vBcSt = (j['vBcSt'] as num?)?.toDouble();
    vIcmsSt = (j['vIcmsSt'] as num?)?.toDouble();

    cstIpi = j['cstIpi']?.toString();
    aliqIpi = (j['aliqIpi'] as num?)?.toDouble();
    vBcIpi = (j['vBcIpi'] as num?)?.toDouble();
    vIpi = (j['vIpi'] as num?)?.toDouble();

    codTribIss = j['codTribIss']?.toString();
    aliqIss = (j['aliqIss'] as num?)?.toDouble();
    vBcIss = (j['vBcIss'] as num?)?.toDouble();
    vIss = (j['vIss'] as num?)?.toDouble();

    cstPis = j['cstPis']?.toString();
    vBcPis = (j['vBcPis'] as num?)?.toDouble();
    pPis = (j['pPis'] as num?)?.toDouble();
    vPis = (j['vPis'] as num?)?.toDouble();
    cstPisSt = j['cstPisSt']?.toString();
    vBcPisSt = (j['vBcPisSt'] as num?)?.toDouble();
    pPisSt = (j['pPisSt'] as num?)?.toDouble();
    vPisSt = (j['vPisSt'] as num?)?.toDouble();

    cstCofins = j['cstCofins']?.toString();
    vBcCofins = (j['vBcCofins'] as num?)?.toDouble();
    pCofins = (j['pCofins'] as num?)?.toDouble();
    vCofins = (j['vCofins'] as num?)?.toDouble();
    cstCofinsSt = j['cstCofinsSt']?.toString();
    vBcCofinsSt = (j['vBcCofinsSt'] as num?)?.toDouble();
    pCofinsSt = (j['pCofinsSt'] as num?)?.toDouble();
    vCofinsSt = (j['vCofinsSt'] as num?)?.toDouble();

    xPed = j['xPed']?.toString();
    nItemPed = j['nItemPed']?.toString();
    vFrete = (j['vFrete'] as num?)?.toDouble();
    vSeg = (j['vSeg'] as num?)?.toDouble();
    vDesc = (j['vDesc'] as num?)?.toDouble();
    vOutro = (j['vOutro'] as num?)?.toDouble();
    indTot = j['indTot']?.toString() ?? '1';
    nFCI = j['nFCI']?.toString();
  }

  Map<String, dynamic> toJson() => {
    'id': id, 'cProd': cProd, 'xProd': xProd, 'ncm': ncm, 'cfop': cfop,
    'uCom': uCom, 'qCom': qCom, 'vUnCom': vUnCom, 'vProd': vProd,
    'cstIcms': cstIcms, 'aliqIcms': aliqIcms, 'vBcIcms': vBcIcms, 'vIcms': vIcms,
    'cstIcmsSt': cstIcmsSt, 'vBcSt': vBcSt, 'vIcmsSt': vIcmsSt,
    'cstIpi': cstIpi, 'aliqIpi': aliqIpi, 'vBcIpi': vBcIpi, 'vIpi': vIpi,
    'codTribIss': codTribIss, 'aliqIss': aliqIss, 'vBcIss': vBcIss, 'vIss': vIss,
    'cstPis': cstPis, 'vBcPis': vBcPis, 'pPis': pPis, 'vPis': vPis,
    'cstPisSt': cstPisSt, 'vBcPisSt': vBcPisSt, 'pPisSt': pPisSt, 'vPisSt': vPisSt,
    'cstCofins': cstCofins, 'vBcCofins': vBcCofins, 'pCofins': pCofins, 'vCofins': vCofins,
    'cstCofinsSt': cstCofinsSt, 'vBcCofinsSt': vBcCofinsSt, 'pCofinsSt': pCofinsSt, 'vCofinsSt': vCofinsSt,
    'xPed': xPed, 'nItemPed': nItemPed, 'vFrete': vFrete, 'vSeg': vSeg,
    'vDesc': vDesc, 'vOutro': vOutro, 'indTot': indTot, 'nFCI': nFCI,
  };
}

// ─── Nfe ─────────────────────────────────────────────────────────────────────
/// Modelo de NF-e.
/// NF01: adicionados natOp, indFinal, indPres, cNF, modNFe, tpEmis.
class Nfe {
  int? id;
  String? chave;
  String? numero;
  String? serie;
  String? status;
  String? protocoloAut;
  String? motivoAut;
  String? ambiente;
  String? finalidade;
  String? tipoOperacao;
  String? dhEmi;
  Map<String, dynamic>? empresa;
  Map<String, dynamic>? parceiro;
  Map<String, dynamic>? destinatario;
  List<NfeItem> itens;

  // NF01 — campos obrigatórios do cabeçalho
  String? natOp;    // Natureza da operação (até 60 chars)
  String? indFinal; // S = consumidor final, N = não
  String? indPres;  // 0-9 — presença do comprador
  String? cNF;      // Código numérico da chave (8 dígitos, gerado pelo backend)
  String? modNFe;   // Modelo: 55 = NF-e, 65 = NFC-e
  String? tpEmis;   // Tipo emissão: 1=normal, 2=FS-IA, 3=SCAN, etc.

  Nfe({
    this.id, this.chave, this.numero, this.serie, this.status,
    this.protocoloAut, this.motivoAut, this.ambiente, this.finalidade,
    this.tipoOperacao, this.dhEmi, this.empresa, this.parceiro,
    this.destinatario, this.itens = const [],
    this.natOp, this.indFinal, this.indPres, this.cNF,
    this.modNFe = '55', this.tpEmis = '1',
  });

  factory Nfe.fromJson(Map<String, dynamic> j) {
    return Nfe(
      id: j['id'],
      chave: j['chave']?.toString(),
      numero: j['numero']?.toString(),
      serie: j['serie']?.toString(),
      status: j['status']?.toString(),
      protocoloAut: j['protocoloAut']?.toString(),
      motivoAut: j['motivoAut']?.toString(),
      ambiente: j['ambiente']?.toString(),
      finalidade: j['finalidade']?.toString(),
      tipoOperacao: j['tipoOperacao']?.toString(),
      dhEmi: j['dhEmi']?.toString(),
      empresa: j['empresa'] is Map ? Map<String, dynamic>.from(j['empresa']) : null,
      parceiro: j['parceiro'] is Map ? Map<String, dynamic>.from(j['parceiro']) : null,
      destinatario: j['destinatario'] is Map ? Map<String, dynamic>.from(j['destinatario']) : null,
      itens: (j['itens'] as List? ?? []).whereType<Map>()
          .map((e) => NfeItem.fromJson(Map<String, dynamic>.from(e))).toList(),
      natOp: j['natOp']?.toString(),
      indFinal: j['indFinal']?.toString(),
      indPres: j['indPres']?.toString(),
      cNF: j['cNF']?.toString(),
      modNFe: j['modNFe']?.toString() ?? '55',
      tpEmis: j['tpEmis']?.toString() ?? '1',
    );
  }

  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    'chave': chave, 'numero': numero, 'serie': serie, 'status': status,
    'ambiente': ambiente, 'finalidade': finalidade, 'tipoOperacao': tipoOperacao,
    'dhEmi': dhEmi,
    if (empresa != null) 'empresa': empresa,
    if (parceiro != null) 'parceiro': parceiro,
    if (destinatario != null) 'destinatario': destinatario,
    if (natOp != null) 'natOp': natOp,
    if (indFinal != null) 'indFinal': indFinal,
    if (indPres != null) 'indPres': indPres,
    if (cNF != null) 'cNF': cNF,
    if (modNFe != null) 'modNFe': modNFe,
    if (tpEmis != null) 'tpEmis': tpEmis,
  };

  String get parceiroNome => parceiro?['nome']?.toString() ?? '';
  String get destinatarioNome => destinatario?['nome']?.toString() ?? '';
  String get empresaNome => empresa?['nome']?.toString() ?? '';

  Color get statusColor {
    switch (status?.toUpperCase()) {
      case 'AUTORIZADA': return GridColors.success;
      case 'CANCELADA':  return GridColors.error;
      case 'REJEITADA':  return const Color(0xFFE65100);
      case 'PENDENTE':   return const Color(0xFFF9A825);
      default:           return const Color(0xFF757575);
    }
  }
}
