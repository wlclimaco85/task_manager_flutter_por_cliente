import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/services/consulta_cep_service.dart';
import 'package:task_manager_flutter/services/consulta_cnpj_service.dart';

/// Regressao: CEP e CNPJ publicos eram consultados pelo NetworkCaller, que manda Authorization (token do
/// usuario) e cabecalhos de tenant a qualquer URL - vazava o token e a web bloqueava por CORS
/// ("Nao foi possivel consultar o CEP" / ReceitaWS sem dados).
void main() {
  group('ConsultaCnpjService - mapeamento das APIs publicas', () {
    test('ReceitaWS OK vira o contrato dos cadastros', () {
      final d = ConsultaCnpjService.mapearReceitaWs({
        'status': 'OK',
        'nome': 'BRASIL MODA SURF LTDA',
        'fantasia': 'Brasil Moda Surf',
        'logradouro': 'AV A',
        'numero': '10',
        'municipio': 'UBERABA',
        'uf': 'MG',
        'cep': '38.082-243',
        'telefone': '(34) 3333-3333',
        'email': 'a@b.com',
      });
      expect(d!['razaoSocial'], 'BRASIL MODA SURF LTDA');
      expect(d['nomeFantasia'], 'Brasil Moda Surf');
      expect(d['cidade'], 'UBERABA');
      expect(d['estado'], 'MG');
      expect(d['rua'], 'AV A');
    });

    test('ReceitaWS com erro (limite de consultas, CNPJ invalido) ou vazia nao vale', () {
      expect(ConsultaCnpjService.mapearReceitaWs(null), isNull);
      expect(
          ConsultaCnpjService.mapearReceitaWs(
              {'status': 'ERROR', 'message': 'Too many requests, please try again later.'}),
          isNull);
      expect(ConsultaCnpjService.mapearReceitaWs({'status': 'ERROR', 'nome': 'X'}), isNull);
    });

    test('BrasilAPI vira o mesmo contrato, juntando tipo e logradouro e preenchendo o CEP', () {
      final d = ConsultaCnpjService.mapearBrasilApi({
        'razao_social': 'BRASIL MODA SURF LTDA',
        'nome_fantasia': 'Brasil Moda Surf',
        'descricao_tipo_de_logradouro': 'AVENIDA',
        'logradouro': 'DAS FLORES',
        'numero': '100',
        'bairro': 'CENTRO',
        'municipio': 'UBERABA',
        'uf': 'MG',
        'cep': 38082243,
        'ddd_telefone_1': '3433334444',
        'email': 'x@y.com',
        'descricao_situacao_cadastral': 'ATIVA',
      });
      expect(d!['nome'], 'BRASIL MODA SURF LTDA');
      expect(d['rua'], 'AVENIDA DAS FLORES');
      expect(d['cep'], '38082243');
      expect(d['telefone'], '3433334444');
      expect(d['situacao'], 'ATIVA');
      expect(ConsultaCnpjService.mapearBrasilApi({'message': 'CNPJ nao encontrado'}), isNull);
      expect(ConsultaCnpjService.mapearBrasilApi(null), isNull);
    });

    test('consultar/consultarPublico recusam CNPJ que nao tem 14 digitos sem chamar a rede', () async {
      expect(await ConsultaCnpjService.consultar('123'), isNull);
      expect(await ConsultaCnpjService.consultarPublico('12.345'), isNull);
    });
  });

  group('ConsultaCepService - mapeamento', () {
    test('ViaCEP e BrasilAPI geram o mesmo formato', () {
      final v = ConsultaCepService.mapearViaCep({
        'logradouro': 'Rua A',
        'bairro': 'Centro',
        'localidade': 'Uberaba',
        'uf': 'MG',
        'complemento': 'lado par',
      });
      expect(v, {
        'logradouro': 'Rua A',
        'bairro': 'Centro',
        'localidade': 'Uberaba',
        'uf': 'MG',
        'complemento': 'lado par',
      });
      final b = ConsultaCepService.mapearBrasilApi(
          {'street': 'Rua A', 'neighborhood': 'Centro', 'city': 'Uberaba', 'state': 'MG'});
      expect(b!['logradouro'], 'Rua A');
      expect(b['localidade'], 'Uberaba');
      expect(b['uf'], 'MG');
      expect(ConsultaCepService.mapearBrasilApi({'message': 'CEP nao encontrado'}), isNull);
      expect(ConsultaCepService.mapearBrasilApi(null), isNull);
    });

    test('CEP que nao tem 8 digitos nao consulta', () async {
      expect(await ConsultaCepService.consultar('123'), isNull);
    });
  });
}
