# Organização do Projeto — Renda Fixa View

Aplicativo Flutter para análise de investimentos em Renda Fixa e Tesouro Direto,
com somatório por banco e verificação do limite FGC.

---

## Raiz do projeto

- `pubspec.yaml` — Dependências e configuração do projeto Flutter.
- `analysis_options.yaml` — Configurações de análise estática do Dart.
- `README.md` — Descrição geral do projeto.
- `.md/` — Arquivos Markdown do projeto (exceto README.md raiz).
- `.ps1/` — Scripts PowerShell do projeto (reservado para uso futuro).

---

## lib/

- `main.dart` — Ponto de entrada do app. Inicializa o `ProviderScope` e configura o tema verde escuro.

### lib/animation/

- `minhas_animacoes.dart` — Biblioteca centralizada de animações reutilizáveis (transições, fade, barra de progresso animada, escala ao pressionar).

### lib/models/

- `investimento_model.dart` — Model de um investimento individual (CDB, CRA, LFT, LTN etc.), com tipo, banco, posição, taxas, datas e cobertura FGC.
- `resumo_banco_model.dart` — Model de agrupamento por instituição financeira, com total consolidado e cálculo de risco FGC.
- `grupo_vencimento_model.dart` — Model de agrupamento por mês/ano de vencimento, com total consolidado e cálculo de dias restantes.

### lib/parametros/

- `parametros_gerais.dart` — Parâmetros configuráveis do app: limite FGC (R$ 250k), percentuais de alerta, cálculo da escala de cores (verde → vermelho).

### lib/providers/

- `carteira_provider.dart` — Provider Riverpod que gerencia o estado da carteira. Inclui `CarteiraNotifier`, `resumoPorBancoProvider`, `totalGeralProvider`, `rendaFixaProvider`, `tesouroDiretoProvider` e `porVencimentoProvider`.

### lib/screens/

- `home_screen.dart` — Tela principal. Controla o carregamento do arquivo Excel, exibe estado vazio/carregando/erro e as abas de análise.
- `resumo_por_banco_screen.dart` — Aba "Por Banco": lista de cards por instituição com total investido e indicador visual de limite FGC.
- `por_vencimento_screen.dart` — Aba "Vencimentos": investimentos agrupados por mês/ano de vencimento em ordem cronológica, com totais por grupo e badge de dias restantes.

### lib/services/

- `excel_service.dart` — Serviço de parsing do arquivo `.xlsx` da corretora. Extrai investimentos de Renda Fixa e Tesouro Direto, inferindo banco, tipo e cobertura FGC.

### lib/utils_geral/

- `caixa_dialogo.dart` — Utilitário centralizado para exibição de diálogos (`AlertDialog`, confirmação, campo de texto, widget customizado) e SnackBars.
- `formatadores.dart` — Utilitários de formatação: moeda brasileira (BRL), percentual e data em português.

### lib/widgets/

- `card_banco_widget.dart` — Card de uma instituição com nome, total, badge FGC e barra de progresso animada com escala de cores (verde→vermelho conforme limite FGC).

---

## test/

- `widget_test.dart` — Teste básico de inicialização do app.

---

## tmp/

- `PosicaoDetalhada (1).xlsx` — Arquivo Excel de exemplo com posição detalhada da carteira (formato XP Investimentos).
