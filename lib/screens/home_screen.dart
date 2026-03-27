// ==================== TELA HOME ====================
// Tela principal do aplicativo. Controla o estado de carregamento
// do arquivo Excel e exibe as abas de análise quando há dados.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:file_picker/file_picker.dart';

import '../providers/carteira_provider.dart';
import '../utils_geral/caixa_dialogo.dart';
import '../screens/resumo_por_banco_screen.dart';
import '../screens/por_vencimento_screen.dart';

/// Tela principal do aplicativo de análise de renda fixa.
/// Permite carregar um arquivo Excel e exibe as abas de análise.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  // Controlador das abas (expansível para futuras abas)
  late TabController _controladorAbas;

  /// Títulos e ícones das abas disponíveis
  static final List<({String titulo, IconData icone})> _abas = [
    (titulo: 'Por Banco', icone: MdiIcons.bank),
    (titulo: 'Vencimentos', icone: MdiIcons.calendarClock),
  ];

  @override
  void initState() {
    super.initState();
    _controladorAbas = TabController(length: _abas.length, vsync: this);
  }

  @override
  void dispose() {
    _controladorAbas.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final estadoCarteira = ref.watch(carteiraProvider);
    final esquemaCores = Theme.of(context).colorScheme;

    return Scaffold(
      // ==================== APP BAR ====================
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Renda Fixa',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            if (estadoCarteira.nomeArquivo != null)
              Text(
                estadoCarteira.nomeArquivo!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: esquemaCores.onPrimary.withValues(alpha: 0.7),
                ),
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
        actions: [
          // Botão de recarregar/trocar arquivo
          if (estadoCarteira.temDados)
            IconButton(
              icon: const Icon(MdiIcons.fileRefreshOutline),
              tooltip: 'Carregar outro arquivo',
              onPressed: _selecionarArquivo,
            ),
          // Indicador de carregamento
          if (estadoCarteira.carregando)
            const Padding(
              padding: EdgeInsets.all(12),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
        ],
        // Abas (apenas quando há dados)
        bottom: estadoCarteira.temDados
            ? TabBar(
                controller: _controladorAbas,
                tabs: _abas
                    .map((aba) => Tab(icon: Icon(aba.icone), text: aba.titulo))
                    .toList(),
              )
            : null,
      ),

      // ==================== CORPO PRINCIPAL ====================
      body: _construirCorpo(estadoCarteira),

    );
  }

  // ==================== CONSTRUÇÃO DO CORPO ====================

  /// Decide qual widget mostrar baseado no estado atual
  Widget _construirCorpo(CarteiraState estado) {
    // Carregando
    if (estado.carregando) {
      return const _TelaCarregando();
    }

    // Erro
    if (estado.erro != null) {
      return _TelaErro(mensagem: estado.erro!, aoTentar: _selecionarArquivo);
    }

    // Sem dados: tela de boas-vindas
    if (!estado.temDados) {
      return _TelaBoasVindas(aoSelecionarArquivo: _selecionarArquivo);
    }

    // Dados carregados: exibe abas
    return TabBarView(
      controller: _controladorAbas,
      children: const [
        ResumoPorBancoScreen(),
        PorVencimentoScreen(),
      ],
    );
  }

  // ==================== SELEÇÃO DE ARQUIVO ====================

  /// Abre o seletor de arquivo .xlsx e carrega os dados no provider
  Future<void> _selecionarArquivo() async {
    try {
      final resultado = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
        withData: true,
        dialogTitle: 'Selecionar posição detalhada (.xlsx)',
      );

      if (resultado == null || resultado.files.isEmpty) {
        // Usuário cancelou
        return;
      }

      final arquivo = resultado.files.first;

      if (arquivo.bytes == null) {
        if (mounted) {
          MinhaCaixaDialogo.mostrarSnackBar(
            context,
            'Não foi possível ler o arquivo selecionado',
            tipo: 'erro',
          );
        }
        return;
      }

      // Carrega no provider
      await ref
          .read(carteiraProvider.notifier)
          .carregarArquivo(arquivo.bytes!, arquivo.name);

      // Verificar se houve erro após carregamento
      if (mounted) {
        final estadoAtualizado = ref.read(carteiraProvider);
        if (estadoAtualizado.erro != null) {
          MinhaCaixaDialogo.mostrarSnackBar(
            context,
            estadoAtualizado.erro!,
            tipo: 'erro',
          );
        } else if (estadoAtualizado.temDados) {
          final total = estadoAtualizado.investimentos.length;
          MinhaCaixaDialogo.mostrarSnackBar(
            context,
            '$total investimentos carregados com sucesso!',
            tipo: 'sucesso',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        MinhaCaixaDialogo.mostrarSnackBar(
          context,
          'Erro ao selecionar arquivo: ${e.toString()}',
          tipo: 'erro',
        );
      }
    }
  }
}

// ==================== TELA DE BOAS-VINDAS ====================

/// Exibida quando nenhum arquivo foi carregado ainda
class _TelaBoasVindas extends StatelessWidget {
  /// Callback acionado ao pressionar o botão de seleção de arquivo
  final VoidCallback aoSelecionarArquivo;

  const _TelaBoasVindas({required this.aoSelecionarArquivo});

  @override
  Widget build(BuildContext context) {
    final esquemaCores = Theme.of(context).colorScheme;
    final temaTexto = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Ícone principal
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: esquemaCores.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                MdiIcons.chartTimelineVariant,
                size: 64,
                color: esquemaCores.onPrimaryContainer,
              ),
            ),

            const SizedBox(height: 28),

            Text(
              'Renda Fixa',
              style: temaTexto.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: esquemaCores.onSurface,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 12),

            Text(
              'Carregue o arquivo de posição detalhada para começar.',
              style: temaTexto.bodyMedium?.copyWith(
                color: esquemaCores.onSurface.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 8),

            // Aviso de suporte apenas XP
            Text(
              'No momento, suporta apenas arquivos da XP.',
              style: temaTexto.bodySmall?.copyWith(
                color: esquemaCores.onSurface.withValues(alpha: 0.5),
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 32),

            // Botão de seleção centralizado
            FilledButton.icon(
              onPressed: aoSelecionarArquivo,
              icon: const Icon(MdiIcons.fileExcelOutline),
              label: const Text('Selecionar arquivo'),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== TELA DE CARREGAMENTO ====================

/// Exibida durante o processamento do arquivo
class _TelaCarregando extends StatelessWidget {
  const _TelaCarregando();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 20),
          Text(
            'Processando arquivo...',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== TELA DE ERRO ====================

/// Exibida quando ocorre erro no carregamento do arquivo
class _TelaErro extends StatelessWidget {
  final String mensagem;
  final VoidCallback aoTentar;

  const _TelaErro({required this.mensagem, required this.aoTentar});

  @override
  Widget build(BuildContext context) {
    final esquemaCores = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              MdiIcons.alertCircleOutline,
              size: 64,
              color: esquemaCores.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Erro ao carregar arquivo',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: esquemaCores.error,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              mensagem,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: esquemaCores.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: aoTentar,
              icon: const Icon(MdiIcons.fileExcelOutline),
              label: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }
}
