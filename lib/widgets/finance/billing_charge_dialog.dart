import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/billing_charge_model.dart';
import '../../models/conta_receber_model.dart';
import '../../services/billing_charge_service.dart';

class BillingChargeDialog extends StatefulWidget {
  final ContaReceber conta;

  const BillingChargeDialog({super.key, required this.conta});

  @override
  State<BillingChargeDialog> createState() => _BillingChargeDialogState();
}

class _BillingChargeDialogState extends State<BillingChargeDialog> {
  final _service = BillingChargeService();

  BillingChargeType _selectedType = BillingChargeType.hybrid;
  BillingChargeResult? _result;
  String? _errorMessage;
  bool _isSubmitting = false;
  bool _isRefreshing = false;
  bool _isMarkingReminder = false;

  @override
  void initState() {
    super.initState();
    _loadLatestCharge();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.receipt_long, color: colorScheme.primary),
          const SizedBox(width: 8),
          const Expanded(child: Text('Cobrança, boleto e Pix')),
        ],
      ),
      content: SizedBox(
        width: 620,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildContaResumo(context),
              const SizedBox(height: 16),
              DropdownButtonFormField<BillingChargeType>(
                initialValue: _selectedType,
                decoration: const InputDecoration(
                  labelText: 'Tipo de cobrança',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.payments_outlined),
                ),
                items: BillingChargeType.values
                    .map(
                      (type) => DropdownMenuItem<BillingChargeType>(
                        value: type,
                        child: Text(type.label),
                      ),
                    )
                    .toList(),
                onChanged: _isBusy
                    ? null
                    : (value) {
                        if (value == null) return;
                        setState(() => _selectedType = value);
                      },
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(color: colorScheme.onErrorContainer),
                  ),
                ),
              ],
              if (_isBusy) ...[
                const SizedBox(height: 16),
                const Center(child: CircularProgressIndicator()),
              ],
              if (_result != null) ...[
                const SizedBox(height: 20),
                _buildResultSection(context, _result!),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isBusy ? null : () => Navigator.of(context).pop(),
          child: const Text('Fechar'),
        ),
        if (_result?.billingId.isNotEmpty ?? false)
          OutlinedButton.icon(
            onPressed: _isBusy ? null : _refreshBilling,
            icon: const Icon(Icons.search),
            label: const Text('Consultar cobrança'),
          ),
        if (_result?.billingId.isNotEmpty ?? false)
          OutlinedButton.icon(
            onPressed: _isBusy ? null : _markReminderSent,
            icon: const Icon(Icons.outgoing_mail),
            label: const Text('Marcar envio'),
          ),
        ElevatedButton.icon(
          onPressed: _isBusy ? null : _generateBilling,
          icon: const Icon(Icons.sync_alt),
          label: Text(_result == null ? 'Gerar cobrança' : 'Gerar nova'),
        ),
      ],
    );
  }

  bool get _isBusy => _isSubmitting || _isRefreshing || _isMarkingReminder;

  Widget _buildContaResumo(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final cliente =
        widget.conta.cliente?.nome ?? widget.conta.clienteDev?.nome ?? '-';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.conta.descricao,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              Text('Conta: ${widget.conta.id ?? '-'}'),
              Text('Cliente: $cliente'),
              Text('Valor: R\$ ${widget.conta.valor.toStringAsFixed(2)}'),
              Text('Vencimento: ${_formatDate(widget.conta.dataVencimento)}'),
              Text('Status: ${widget.conta.status.name}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResultSection(BuildContext context, BillingChargeResult result) {
    final colorScheme = Theme.of(context).colorScheme;
    final shouldExpectBoleto = _selectedType == BillingChargeType.boleto ||
        _selectedType == BillingChargeType.hybrid;
    final shouldExpectPix = _selectedType == BillingChargeType.pix ||
        _selectedType == BillingChargeType.hybrid;
    final hasPixDisplayData = (result.pixQrCodeBase64?.isNotEmpty ?? false) ||
        (result.pixCopiaCola?.isNotEmpty ?? false);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Chip(
                avatar: const Icon(Icons.link, size: 18),
                label: Text(
                  'Cobrança ${result.billingId.isEmpty ? '-' : result.billingId}',
                ),
              ),
              Chip(
                avatar: const Icon(Icons.info_outline, size: 18),
                label: Text('Status ${result.status}'),
              ),
              if (result.type != null)
                Chip(
                  avatar: const Icon(Icons.payments_outlined, size: 18),
                  label: Text(result.type!.label),
                ),
            ],
          ),
          const SizedBox(height: 12),
          _buildReminderSection(context, result),
          const SizedBox(height: 12),
          if (result.billingId.isNotEmpty)
            _ReadOnlyField(
              label: 'ID da cobrança',
              value: result.billingId,
              onCopy: () => _copyText(
                context,
                result.billingId,
                'ID da cobrança copiado.',
              ),
            ),
          if (result.linkCobranca?.isNotEmpty ?? false) ...[
            const SizedBox(height: 12),
            _ReadOnlyField(
              label: 'Link de cobrança',
              value: result.linkCobranca!,
              onCopy: () => _copyText(
                context,
                result.linkCobranca!,
                'Link de cobrança copiado.',
              ),
              trailing: IconButton(
                tooltip: 'Abrir link',
                onPressed: () => _openUrl(result.linkCobranca!),
                icon: const Icon(Icons.open_in_new),
              ),
            ),
          ],
          if (result.boletoLink?.isNotEmpty ?? false) ...[
            const SizedBox(height: 12),
            _ReadOnlyField(
              label: 'Link do boleto',
              value: result.boletoLink!,
              onCopy: () => _copyText(
                context,
                result.boletoLink!,
                'Link do boleto copiado.',
              ),
              trailing: IconButton(
                tooltip: 'Abrir boleto',
                onPressed: () => _openUrl(result.boletoLink!),
                icon: const Icon(Icons.open_in_new),
              ),
            ),
          ],
          if (result.linhaDigitavel?.isNotEmpty ?? false) ...[
            const SizedBox(height: 12),
            _ReadOnlyField(
              label: 'Linha digitável',
              value: result.linhaDigitavel!,
              onCopy: () => _copyText(
                context,
                result.linhaDigitavel!,
                'Linha digitável copiada.',
              ),
            ),
          ],
          if (result.codigoBarras?.isNotEmpty ?? false) ...[
            const SizedBox(height: 12),
            _ReadOnlyField(
              label: 'Código de barras',
              value: result.codigoBarras!,
              onCopy: () => _copyText(
                context,
                result.codigoBarras!,
                'Código de barras copiado.',
              ),
            ),
          ],
          if (shouldExpectBoleto && !result.hasBoleto) ...[
            const SizedBox(height: 12),
            Text(
              'Boleto ainda sem linha digitável ou link disponível.',
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
          ],
          if (result.pixCopiaCola?.isNotEmpty ?? false) ...[
            const SizedBox(height: 12),
            _ReadOnlyField(
              label: 'Pix copia e cola',
              value: result.pixCopiaCola!,
              onCopy: () => _copyText(
                context,
                result.pixCopiaCola!,
                'Pix copia e cola copiado.',
              ),
            ),
          ],
          if (shouldExpectPix && !result.hasPix) ...[
            const SizedBox(height: 12),
            Text(
              'Pix ainda sem payload disponível.',
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
          ],
          if (hasPixDisplayData) ...[
            const SizedBox(height: 16),
            Center(child: _buildPixQrCode(context, result)),
          ],
          if (result.warnings.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...result.warnings.map(
              (warning) => Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: colorScheme.onSurfaceVariant,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        warning,
                        style: TextStyle(color: colorScheme.onSurfaceVariant),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildReminderSection(
      BuildContext context, BillingChargeResult result) {
    final colorScheme = Theme.of(context).colorScheme;
    final proximo = result.proximoEnvioEm != null
        ? _formatDateTime(result.proximoEnvioEm!)
        : '-';
    final ultimo = result.ultimoEnvioEm != null
        ? _formatDateTime(result.ultimoEnvioEm!)
        : '-';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Régua de cobrança',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Chip(
                avatar: const Icon(Icons.flag_outlined, size: 18),
                label: Text(_formatEnum(result.etapaRegua)),
              ),
              Chip(
                avatar: const Icon(Icons.schedule, size: 18),
                label: Text(_formatEnum(result.reguaStatus)),
              ),
              Chip(
                avatar: const Icon(Icons.alternate_email, size: 18),
                label: Text(result.canalEnvio ?? '-'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              Text('Próximo envio: $proximo'),
              Text('Último envio: $ultimo'),
              Text('Envios: ${result.quantidadeEnvios}'),
            ],
          ),
          if (result.ultimoErroEnvio?.isNotEmpty ?? false) ...[
            const SizedBox(height: 8),
            Text(
              result.ultimoErroEnvio!,
              style: TextStyle(color: colorScheme.error),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPixQrCode(BuildContext context, BillingChargeResult result) {
    final colorScheme = Theme.of(context).colorScheme;
    Widget child;
    final rawBase64 = result.pixQrCodeBase64;

    if (rawBase64 != null && rawBase64.isNotEmpty) {
      child = Image.memory(
        base64Decode(rawBase64),
        width: 180,
        height: 180,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => const SizedBox(
          width: 180,
          height: 180,
          child: Center(child: Text('QR Pix inválido.')),
        ),
      );
    } else if (result.pixCopiaCola?.isNotEmpty ?? false) {
      child = QrImageView(
        data: result.pixCopiaCola!,
        version: QrVersions.auto,
        size: 180,
        backgroundColor: Colors.white,
      );
    } else {
      child = const SizedBox(
        width: 180,
        height: 180,
        child: Center(child: Text('QR Pix indisponível.')),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: child,
    );
  }

  Future<void> _loadLatestCharge() async {
    final contaId = widget.conta.id;
    if (contaId == null) return;

    setState(() => _isRefreshing = true);
    try {
      final charges = await _service.listByContaReceber(
        contaReceberId: contaId,
        empresaId: widget.conta.empresa.id,
      );
      if (!mounted || charges.isEmpty) return;
      final latest = charges.first;
      setState(() {
        _result = latest;
        if (latest.type != null) {
          _selectedType = latest.type!;
        }
      });
    } catch (_) {
      if (!mounted) return;
    } finally {
      if (mounted) {
        setState(() => _isRefreshing = false);
      }
    }
  }

  Future<void> _generateBilling() async {
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final result = await _service.generateFromContaReceber(
        conta: widget.conta,
        type: _selectedType,
      );

      if (!mounted) return;
      setState(() => _result = result);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cobrança gerada com sucesso.')),
      );
    } on BillingChargeException catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage =
            'Não foi possível gerar a cobrança financeira desta conta.';
      });
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _refreshBilling() async {
    final billingId = _result?.billingId;
    if (billingId == null || billingId.isEmpty) return;

    setState(() {
      _isRefreshing = true;
      _errorMessage = null;
    });

    try {
      final result = await _service.consultCharge(
        billingId: billingId,
        empresaId: widget.conta.empresa.id,
      );

      if (!mounted) return;
      setState(() => _result = result);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Status da cobrança atualizado.')),
      );
    } on BillingChargeException catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Não foi possível consultar esta cobrança.';
      });
    } finally {
      if (mounted) {
        setState(() => _isRefreshing = false);
      }
    }
  }

  Future<void> _markReminderSent() async {
    final billingId = _result?.billingId;
    if (billingId == null || billingId.isEmpty) return;

    setState(() {
      _isMarkingReminder = true;
      _errorMessage = null;
    });

    try {
      final result = await _service.markReminderSent(
        billingId: billingId,
        empresaId: widget.conta.empresa.id,
      );

      if (!mounted) return;
      setState(() => _result = result);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Envio da régua registrado.')),
      );
    } on BillingChargeException catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Não foi possível registrar o envio da régua.';
      });
    } finally {
      if (mounted) {
        setState(() => _isMarkingReminder = false);
      }
    }
  }

  Future<void> _openUrl(String value) async {
    final uri = Uri.tryParse(value);
    if (uri == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Link de cobrança inválido.')),
      );
      return;
    }

    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível abrir o link.')),
      );
    }
  }

  Future<void> _copyText(
    BuildContext context,
    String value,
    String successMessage,
  ) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(successMessage)),
    );
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString().padLeft(4, '0');
    return '$day/$month/$year';
  }

  String _formatDateTime(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '${_formatDate(date)} $hour:$minute';
  }

  String _formatEnum(String? value) {
    if (value == null || value.trim().isEmpty) return '-';
    return value.split('_').map((part) {
      if (part.isEmpty) return part;
      return part[0] + part.substring(1).toLowerCase();
    }).join(' ');
  }
}

class _ReadOnlyField extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onCopy;
  final Widget? trailing;

  const _ReadOnlyField({
    required this.label,
    required this.value,
    required this.onCopy,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            border:
                Border.all(color: Theme.of(context).colorScheme.outlineVariant),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: SelectableText(
                  value,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              IconButton(
                tooltip: 'Copiar',
                onPressed: onCopy,
                icon: const Icon(Icons.copy_all_outlined),
              ),
              if (trailing != null) trailing!,
            ],
          ),
        ),
      ],
    );
  }
}
