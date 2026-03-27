// ==================== TELA HOME ====================
// Tela principal do aplicativo. Controla o estado de carregamento
// do arquivo Excel e exibe as abas de análise quando há dados.

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:file_picker/file_picker.dart';

import '../providers/carteira_provider.dart';
import '../utils_geral/abrir_url.dart';
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
      children: const [ResumoPorBancoScreen(), PorVencimentoScreen()],
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

            const SizedBox(height: 12),

            // ==================== SOLICITAR CORRETORA ====================
            // Convida o usuário a contribuir com arquivo de outra corretora
            _BotaoSolicitarCorretora(
              esquemaCores: esquemaCores,
              temaTexto: temaTexto,
            ),

            const SizedBox(height: 32),

            // Botão de seleção centralizado
            FilledButton.icon(
              onPressed: aoSelecionarArquivo,
              icon: const Icon(MdiIcons.fileExcelOutline),
              label: const Text('Selecionar arquivo'),
            ),

            const SizedBox(height: 32),

            // ==================== PROPAGANDA DISCRETA ====================
            // Sorteia um dos apps do desenvolvedor e exibe de forma sutil
            const _PromoAppWidget(),

            const SizedBox(height: 16),

            // ==================== LINK GITHUB ====================
            // Referência ao repositório do projeto no GitHub
            InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () async {
                await abrirUrlExterna(
                  'https://github.com/vandreborba/renda_fixa_view',
                );
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      MdiIcons.github,
                      size: 20,
                      color: esquemaCores.onSurface.withValues(alpha: 0.5),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'vandreborba/renda_fixa_view',
                      style: temaTexto.bodySmall?.copyWith(
                        color: esquemaCores.onSurface.withValues(alpha: 0.5),
                        decoration: TextDecoration.underline,
                        decorationColor: esquemaCores.onSurface.withValues(
                          alpha: 0.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
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

// ==================== SOLICITAR SUPORTE A CORRETORA ====================

/// Botão que abre um diálogo explicando como solicitar suporte a novas corretoras.
class _BotaoSolicitarCorretora extends StatelessWidget {
  final ColorScheme esquemaCores;
  final TextTheme temaTexto;

  const _BotaoSolicitarCorretora({
    required this.esquemaCores,
    required this.temaTexto,
  });

  /// Exibe o diálogo com as instruções de como enviar o arquivo
  void _exibirInstrucoes(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: Icon(MdiIcons.bankPlus, color: esquemaCores.primary, size: 32),
        title: const Text('Suporte a outras corretoras'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Gostaria de ver sua corretora aqui?',
                style: temaTexto.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Para adicionar suporte a novas corretoras, preciso de '
                'um arquivo de exemplo com os dados de posição em renda fixa. '
                'Siga os passos abaixo:',
                style: temaTexto.bodyMedium,
              ),
              const SizedBox(height: 16),
              _ItemPasso(
                numero: '1',
                texto:
                    'Exporte a posição detalhada da sua carteira de renda fixa '
                    'pela plataforma da sua corretora. '
                    'Formatos aceitos: .xlsx, .xls ou .csv.',
              ),
              _ItemPasso(
                numero: '2',
                texto:
                    'Antes de enviar, apague ou substitua por valores fictícios '
                    'quaisquer dados pessoais (nome, CPF, conta). '
                    'Não é necessário enviar dados reais — apenas a estrutura '
                    '(cabeçalhos e algumas linhas de exemplo já são suficientes).',
              ),
              _ItemPasso(
                numero: '3',
                texto:
                    'Abra uma issue no GitHub do projeto informando a corretora '
                    'e anexe o arquivo. Ou envie por e-mail se preferir.',
              ),
              const SizedBox(height: 16),
              Text(
                'Assim que receber o arquivo, analisarei a estrutura e '
                'implementarei o suporte o quanto antes!',
                style: temaTexto.bodySmall?.copyWith(
                  color: esquemaCores.onSurface.withValues(alpha: 0.65),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
        actions: [
          // Botão de e-mail
          TextButton.icon(
            onPressed: () {
              Navigator.of(ctx).pop();
              abrirUrlExterna(
                'mailto:vandreapps@gmail.com'
                '?subject=Suporte%20a%20nova%20corretora'
                '&body=Ol%C3%A1%2C%20gostaria%20de%20solicitar%20suporte%20'
                '%C3%A0%20corretora%3A%20%5Bnome%20da%20corretora%5D%0A%0A'
                'Segue%20em%20anexo%20o%20arquivo%20de%20posi%C3%A7%C3%A3o%20'
                'com%20dados%20ficticios.',
              );
            },
            icon: const Icon(MdiIcons.emailOutline, size: 18),
            label: const Text('Enviar por e-mail'),
          ),
          // Botão do GitHub
          TextButton.icon(
            onPressed: () {
              Navigator.of(ctx).pop();
              abrirUrlExterna(
                'https://github.com/vandreborba/renda_fixa_view/issues',
              );
            },
            icon: const Icon(MdiIcons.github, size: 18),
            label: const Text('Abrir issue no GitHub'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Entendi'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: () => _exibirInstrucoes(context),
      icon: Icon(
        MdiIcons.bankPlus,
        size: 16,
        color: esquemaCores.onSurface.withValues(alpha: 0.55),
      ),
      label: Text(
        'Usar outra corretora? Saiba como contribuir',
        style: temaTexto.bodySmall?.copyWith(
          color: esquemaCores.onSurface.withValues(alpha: 0.55),
        ),
      ),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}

/// Um passo numerado dentro do diálogo de instruções
class _ItemPasso extends StatelessWidget {
  final String numero;
  final String texto;

  const _ItemPasso({required this.numero, required this.texto});

  @override
  Widget build(BuildContext context) {
    final esquemaCores = Theme.of(context).colorScheme;
    final temaTexto = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Círculo com número do passo
          Container(
            width: 22,
            height: 22,
            margin: const EdgeInsets.only(top: 1, right: 10),
            decoration: BoxDecoration(
              color: esquemaCores.primaryContainer,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              numero,
              style: temaTexto.labelSmall?.copyWith(
                color: esquemaCores.onPrimaryContainer,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(child: Text(texto, style: temaTexto.bodyMedium)),
        ],
      ),
    );
  }
}

// ==================== PROPAGANDA DISCRETA ====================

/// Dados de cada app disponível para promoção
class _DadosPromo {
  final String nome;
  final String descricao;
  final IconData icone;
  final String url;

  const _DadosPromo({
    required this.nome,
    required this.descricao,
    required this.icone,
    required this.url,
  });
}

/// Lista dos apps do desenvolvedor para sorteio
const List<_DadosPromo> _appsParaPromo = [
  _DadosPromo(
    nome: 'Calculadora Renda Fixa',
    descricao: 'Simule CDB, LCI, Tesouro Direto e muito mais',
    icone: MdiIcons.calculatorVariant,
    url:
        'https://play.google.com/store/apps/details?id=com.vandre.calculadoradeinvestimentos',
  ),
  _DadosPromo(
    nome: 'Controle de FII',
    descricao: 'Gerencie sua carteira de fundos imobiliários',
    icone: MdiIcons.homeCity,
    url:
        'https://play.google.com/store/apps/details?id=com.vandreapps.controle_fii_2',
  ),
  _DadosPromo(
    nome: 'Organizee – Controle de Estoque',
    descricao: 'Estoque profissional com FIFO, LIFO e Média Ponderada',
    icone: MdiIcons.packageVariant,
    url:
        'https://play.google.com/store/apps/details?id=com.vandreapps.controle_estoque',
  ),
];

/// Widget que sorteia e exibe discretamente um app do desenvolvedor.
/// Aparece na tela de boas-vindas, sem chamar atenção.
class _PromoAppWidget extends StatefulWidget {
  const _PromoAppWidget();

  @override
  State<_PromoAppWidget> createState() => _PromoAppWidgetState();
}

class _PromoAppWidgetState extends State<_PromoAppWidget> {
  // Sorteio feito uma única vez ao montar o widget
  late final _DadosPromo _appSorteado;

  @override
  void initState() {
    super.initState();
    _appSorteado = _appsParaPromo[Random().nextInt(_appsParaPromo.length)];
  }

  @override
  Widget build(BuildContext context) {
    final esquemaCores = Theme.of(context).colorScheme;
    final temaTexto = Theme.of(context).textTheme;

    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () async {
        await abrirUrlExterna(_appSorteado.url);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Ícone do app sorteado
            Icon(
              _appSorteado.icone,
              size: 20,
              color: esquemaCores.primary.withValues(alpha: 0.55),
            ),
            const SizedBox(width: 9),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Rótulo discreto
                Text(
                  'Conheça também',
                  style: temaTexto.labelSmall?.copyWith(
                    color: esquemaCores.onSurface.withValues(alpha: 0.5),
                  ),
                ),
                // Nome do app
                Text(
                  _appSorteado.nome,
                  style: temaTexto.bodyMedium?.copyWith(
                    color: esquemaCores.primary.withValues(alpha: 0.75),
                    decoration: TextDecoration.underline,
                    decorationColor: esquemaCores.primary.withValues(
                      alpha: 0.4,
                    ),
                  ),
                ),
                // Descrição do app
                Text(
                  _appSorteado.descricao,
                  style: temaTexto.bodySmall?.copyWith(
                    color: esquemaCores.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 7),
            Icon(
              MdiIcons.openInNew,
              size: 14,
              color: esquemaCores.primary.withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
    );
  }
}
