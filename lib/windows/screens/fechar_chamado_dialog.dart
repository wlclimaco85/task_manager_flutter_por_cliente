import 'package:flutter/material.dart';

import '../../../models/auth_utility.dart';
import '../../../models/chamado_model.dart';
import '../../constants/custom_colors.dart';
import '../../services/chamado_caller.dart';
import '../../utils/grid_texts.dart';

class FecharChamadoDialog extends StatefulWidget {
  final int chamadoId;
  final Chamado? chamado;

  const FecharChamadoDialog({super.key, required this.chamadoId, this.chamado});

  @override
  _FecharChamadoDialogState createState() => _FecharChamadoDialogState();
}

class _FecharChamadoDialogState extends State<FecharChamadoDialog> {
  final _formKey = GlobalKey<FormState>();
  final _solucaoController = TextEditingController();
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Dialog(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Icon(Icons.task_alt, color: colorScheme.primary, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      GridTexts.closeTicket,
                      style: textTheme.titleLarge?.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (!_loading)
                    IconButton(
                      icon: Icon(
                        Icons.close,
                        color: colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 36),
                    ),
                ],
              ),

              const SizedBox(height: 20),

              // Description
              Text(
                GridTexts.solutionPrompt,
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.8),
                ),
              ),

              const SizedBox(height: 20),

              // Form
              Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: _solucaoController,
                      decoration: InputDecoration(
                        labelText: GridTexts.solution,
                        hintText: GridTexts.solutionHint,
                        border: const OutlineInputBorder(),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: colorScheme.outline),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: colorScheme.primary,
                            width: 2,
                          ),
                        ),
                        labelStyle: TextStyle(color: colorScheme.onSurface),
                        floatingLabelStyle: TextStyle(
                          color: colorScheme.primary,
                        ),
                        filled: true,
                        fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                      ),
                      style: TextStyle(color: colorScheme.onSurface),
                      maxLines: 6,
                      minLines: 4,
                      textInputAction: TextInputAction.done,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return GridTexts.solutionRequired;
                        }
                        if (value.length < 15) {
                          return GridTexts.solutionMinLength;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    if (_loading)
                      Center(
                        child: Column(
                          children: [
                            CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                colorScheme.primary,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              GridTexts.closingTicket,
                              style: textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurface.withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // Actions
              if (!_loading)
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        foregroundColor: colorScheme.onSurface.withValues(alpha: 0.7),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                      ),
                      child: const Text(GridTexts.cancel),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                      onPressed: _fecharChamado,
                      child: const Text(
                        GridTexts.confirm,
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _fecharChamado() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _loading = true);

      try {
        final response = await ChamadoCaller().fecharChamado(
          widget.chamadoId,
          _solucaoController.text,
          AuthUtility.userInfo?.data?.id ?? 0,
        );

        if (response) {
          Navigator.of(context).pop(true);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(GridTexts.ticketClosedSuccess),
              backgroundColor: CustomColors().getLightGreenBackground(),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              action: SnackBarAction(
                label: GridTexts.ok,
                textColor: CustomColors().getConfirmButtonColor(),
                onPressed: () {},
              ),
            ),
          );
        } else {
          throw Exception(GridTexts.closeTicketError);
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(GridTexts.genericError(e.toString())),
            backgroundColor: CustomColors().getShowSnackBarError(),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      } finally {
        if (mounted) {
          setState(() => _loading = false);
        }
      }
    }
  }

  @override
  void dispose() {
    _solucaoController.dispose();
    super.dispose();
  }
}
