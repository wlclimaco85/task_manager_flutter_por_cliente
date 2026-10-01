import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../widgets/generic_grid_screen.dart';
import 'cargo_grid_screen.dart';
import 'centro_custo_grid_screen.dart';
import 'departamento_grid_screen.dart';
import 'feriado_grid_screen.dart';
import 'horario_func_grid_screen.dart';
import 'tipo_produto_grid_screen.dart';

class WindowsConfiguracoesAdminScreen extends StatefulWidget {
  final SecurityCheck hasPermission;
  const WindowsConfiguracoesAdminScreen({super.key, required this.hasPermission});

  @override
  State<WindowsConfiguracoesAdminScreen> createState() => _WindowsConfiguracoesAdminScreenState();
}

class _WindowsConfiguracoesAdminScreenState extends State<WindowsConfiguracoesAdminScreen> {
  int _selectedTab = 0;

  late final List<_AdminTab> _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = [
      _AdminTab(icon: FontAwesomeIcons.briefcase, label: "Cargos", screen: WindowsCargoGridScreen(hasPermission: widget.hasPermission)),
      _AdminTab(icon: FontAwesomeIcons.coins, label: "Centro de Custo", screen: WindowsCentroCustoGridScreen(hasPermission: widget.hasPermission)),
      _AdminTab(icon: FontAwesomeIcons.building, label: "Departamentos", screen: WindowsDepartamentoGridScreen(hasPermission: widget.hasPermission)),
      _AdminTab(icon: FontAwesomeIcons.umbrellaBeach, label: "Feriados", screen: WindowsFeriadoGridScreen(hasPermission: widget.hasPermission)),
      _AdminTab(icon: FontAwesomeIcons.clock, label: "Horários", screen: WindowsHorarioFuncGridScreen(hasPermission: widget.hasPermission)),
      _AdminTab(icon: FontAwesomeIcons.tags, label: "Tipos de Produto", screen: WindowsTipoProdutoGridScreen(hasPermission: widget.hasPermission)),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: Colors.green[50],
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              FaIcon(FontAwesomeIcons.gear, size: 18, color: Colors.green[700]),
              const SizedBox(width: 8),
              Text("Configurações Administrativas",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green[800])),
            ],
          ),
        ),
        Container(
          color: Colors.white,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(_tabs.length, (i) {
                final tab = _tabs[i];
                final selected = _selectedTab == i;
                return InkWell(
                  onTap: () => setState(() => _selectedTab = i),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: selected ? Colors.green : Colors.transparent,
                          width: 2,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        FaIcon(tab.icon, size: 14, color: selected ? Colors.green[700] : Colors.grey[600]),
                        const SizedBox(width: 6),
                        Text(tab.label,
                            style: TextStyle(
                              fontSize: 13,
                              color: selected ? Colors.green[700] : Colors.grey[600],
                              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                            )),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
        const Divider(height: 1),
        Expanded(child: _tabs[_selectedTab].screen),
      ],
    );
  }
}

class _AdminTab {
  final FaIconData icon;
  final String label;
  final Widget screen;
  _AdminTab({required this.icon, required this.label, required this.screen});
}
