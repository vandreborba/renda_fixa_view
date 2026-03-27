# Instruções para o GitHub Copilot

Estas diretrizes devem ser seguidas ao sugerir código neste projeto:

0. ** Proposta do Projeto **

   **Analisador de renda fixa com agregação de dados**
   
   Objetivo Principal: Somatório por bancos para verificar limite FGC.
     

1. **Nomes em Português**
   - Sempre utilize nomes de variáveis, funções, classes e métodos em português.
   - Prefira nomes descritivos e claros, evitando abreviações desnecessárias.
   - **Nomenclatura de Telas**: Todos os nomes de classes de telas devem terminar com "Screen" (ex: `TelaInicialScreen`, `ConfiguracoesScreen`, `SobreScreen`).

2. **Comentários Explicativos**
   - Todo bloco de código, função, classe ou trecho relevante deve conter comentários explicativos em português.
   - Os comentários devem explicar a finalidade, funcionamento e detalhes importantes do código.

3. **Boas Práticas**
   - Siga as convenções do Dart/Flutter para formatação e organização do código.
   - Prefira código limpo, legível e de fácil manutenção.
   - É essencial que os códigos sejam fáceis de serem lidos e compreendidos.

4. **Centralização de Animações**
   - Sempre que for implementar ou sugerir animações, utilize o arquivo `lib/animation/minhas_animacoes.dart`.
   - Caso precise de uma nova animação, adicione a função correspondente neste arquivo.
   - Não implemente animações diretamente em outros arquivos; centralize tudo em `minhas_animacoes.dart` para facilitar manutenção e reutilização.


6. **Organização em Arquivos Auxiliares**
   - Sempre que houver muitas funções utilitárias, crie arquivos com o sufixo `_aux` para separar essas funções.
   - Separar widgets reutilizáveis ou específicos.
   - Essa organização facilita a manutenção, reutilização e leitura do código.

7. **Uso de Tema (Theme.of)**
   - Sempre utilize as cores e fontes do tema do aplicativo Flutter.
   - Para cores, utilize `Theme.of(context).colorScheme`.
   - Para textos, utilize `Theme.of(context).textTheme` (ex: `bodySmall`, `titleLarge`, etc).
   - Isso garante consistência visual, acessibilidade e facilita a manutenção do projeto.

8. **Uso de Ícones - MdiIcons Preferencial**
   - **PREFIRA sempre usar MdiIcons** em vez do Icons padrão do Flutter para maior variedade e consistência visual.
   - **Import obrigatório**: `import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';`
   - **Exemplo**: `Icon(MdiIcons.home)` em vez de `Icon(Icons.home)`.
   - **Benefícios**: Maior variedade de ícones (5000+ ícones), design mais moderno e consistente.
   - **Apenas use Icons padrão** quando o ícone específico não existir no MdiIcons.
   - **Referência**: Consulte https://pictogrammers.com/library/MdiIcons/ para escolher ícones.

10. **Uso Obrigatório do Sistema de Caixas de Diálogo**
   - **SEMPRE use o arquivo `lib/utils_geral/caixa_dialogo.dart`** para exibir qualquer tipo de dialog ou caixa de diálogo.
   - **NUNCA crie dialogs personalizados** usando `showDialog` diretamente, sempre utilize as funções da classe `MinhaCaixaDialogo`.
   - Tipos disponíveis: `exibirCaixaDialogoAjuda`, `exibirCaixaDialogoConfirmacao`, `exibirCaixaDialogoComCampo`, `exibirCaixaDialogoWidget`, `mostrarSnackBar`.
   - Para SnackBars, use sempre `MinhaCaixaDialogo.mostrarSnackBar` em vez de `ScaffoldMessenger.of(context).showSnackBar`.
   - Importe sempre: `import 'package:textos_espiritas/utils_geral/caixa_dialogo.dart';`.


13. **Gerenciamento de Estado com Riverpod Notifier - OBRIGATÓRIO**
   - **SEMPRE use Riverpod Notifier** para gerenciamento de estado quando necessário.
   - **NUNCA use Provider comum, Bloc, ChangeNotifier ou outros gerenciadores de estado**.   
   - Dependência obrigatória: `flutter_riverpod: ^3.0.0` no `pubspec.yaml`.
   - Estrutura padrão: 
     ```dart
     class MyCounter extends Notifier<int> {
       @override
       int build() => 0; // Estado inicial
       
       void increment() {
         state = state + 1; // Atualiza o estado imutável
       }
     }
     
     final myCounterProvider = NotifierProvider<MyCounter, int>(MyCounter.new);
     ```
   - Widgets devem usar `ConsumerWidget` ou `ConsumerStatefulWidget`.
   - Para leitura: `ref.watch(meuProvider)` (escuta mudanças).
   - Para ações: `ref.read(meuProvider.notifier).metodo()` (não reconstrói).
   - App principal deve ter `ProviderScope` na raiz.

14. **Organização de Código com Comentários Secionais**
   - **SEMPRE use comentários organizacionais** para dividir seções lógicas do código.
   - **Formato obrigatório**: `// ==================== NOME DA SEÇÃO ====================`
   - **Aplique em**: funções longas, classes principais, arquivos com múltiplas responsabilidades.
   - **Exemplos**: `// ==================== VALIDAÇÃO DE ENTRADA ====================`, `// ==================== VERIFICAÇÃO DE AUTENTICAÇÃO ====================`, `// ==================== CONFIGURAÇÃO DE WIDGETS ====================`.
   - **Benefícios**: Facilita navegação, melhora legibilidade, organiza responsabilidades do código.
   - **Padrão**: Mínimo de 20 caracteres `=` de cada lado do nome da seção.

15. **Organização de Arquivos por Tipo - OBRIGATÓRIO**
   - **Arquivos PowerShell (.ps1)**: SEMPRE armazenar na pasta `.ps1/` na raiz do projeto
   - **Arquivos Markdown (.md)**: SEMPRE armazenar na pasta `.md/` na raiz do projeto
   - **Benefícios**: Melhor organização, facilita localização e manutenção de arquivos
   - **Exceções**: Apenas arquivos específicos do repositório (README.md, instrucoes_importantes.md) podem ficar na raiz
   - **Aplicar sempre**: Quando criar novos arquivos .ps1 ou .md, colocar nas pastas correspondentes

16. **Substituir `withOpacity` por `.withValue`**
   - Sempre que precisar ajustar a opacidade de uma cor, NÃO use `withOpacity`.
   - Use o método `.alpha(alpha: opacity)` centralizado nas convenções internas do projeto (ex: `minhaCor.withValue(alpha: 0.5)`).
   - Isso garante consistência com utilitários personalizados e facilita buscas/linters.

17. **Usar `debugPrint` em vez de `debugPrint`**
   - NÃO utilize `debugPrint` em nenhum código do projeto para logs de depuração.
   - Sempre utilize `debugPrint` para evitar truncamento de mensagens e permitir melhores práticas de logging em Flutter.
   - Exemplos:
     - INCORRETO: `debugPrint('Mensagem de debug: $valor');`
     - CORRETO: `debugPrint('Mensagem de debug: $valor');`
   - Não se esqueça de importar, quando necessário: `import 'package:flutter/foundation.dart';`.

18. **Manutenção do Arquivo `organizacao.md` - OBRIGATÓRIO**
   - **SEMPRE atualize o arquivo `.md/organizacao.md`** ao criar, renomear, mover ou remover arquivos e pastas do projeto.
   - O arquivo deve descrever a estrutura do projeto com **duas informações por entrada**:
     1. **Pastas**: nome e descrição curta do propósito da pasta (ex: `screens/` — Telas do aplicativo).
     2. **Arquivos**: nome e descrição de uma linha sobre o que o arquivo faz (ex: `viagem_model.dart` — Model de dados de uma viagem).
   - **Formato obrigatório** (exemplo):
     ```
     ## lib/
     - `main.dart` — Ponto de entrada do aplicativo.
     - `models/` — Classes de modelo de dados do domínio.
       - `viagem_model.dart` — Model de dados de uma viagem.
     - `screens/` — Telas do aplicativo.
       - `home_screen.dart` — Tela inicial com resumo do veículo.
     - `providers/` — Providers Riverpod para gerenciamento de estado.
     - `services/` — Serviços de acesso a dados e lógica de negócio.
     - `widgets/` — Widgets reutilizáveis compartilhados entre telas.
     ```
   - **Quando atualizar**: ao criar um novo arquivo ou pasta, ao refatorar/renomear, ao deletar.
   - **Localização**: `.md/organizacao.md` (conforme regra 15).
   - **Benefícios**: Serve como mapa do projeto para o Copilot e para novos desenvolvedores, evitando duplicações e facilitando a navegação.

// INCORRETO - NÃO FAZER:
// Text('Bem-vindo') // ❌ Texto hardcoded
// Colors.blue // ❌ Cor hardcoded
// TextStyle(fontSize: 20) // ❌ Estilo hardcoded
// Icon(Icons.home) // ❌ Use MdiIcons quando possível: Icon(MdiIcons.home)
// Provider<MinhaClasse>(...) // ❌ Provider comum
// BlocProvider<MeuBloc>(...) // ❌ Bloc
```

> Estas instruções são obrigatórias para todas as sugestões automáticas do Copilot neste repositório.