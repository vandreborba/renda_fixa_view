# Renda Fixa View

Analisador de investimentos em renda fixa com agregação de dados por banco, voltado para acompanhamento do limite de cobertura do FGC (Fundo Garantidor de Créditos).

🔗 **Acesse online:** [renda-fixa-view.web.app](https://renda-fixa-view.web.app)

---

## O que faz

- **Carrega** o arquivo de posição detalhada exportado pela XP Investimentos (`.xlsx`).
- **Agrupa** os investimentos por banco emissor e exibe o total investido em cada instituição.
- **Alerta visualmente** quando o saldo em um banco ultrapassa o limite do FGC (R$ 250.000 por CPF por instituição).
- **Lista os vencimentos** dos títulos, agrupados por data, facilitando o planejamento de liquidez.

---

## Como usar

1. Acesse o app pelo navegador ou abra localmente.
2. Exporte a **posição detalhada** da sua carteira de renda fixa pela plataforma da XP Investimentos no formato `.xlsx`.
3. Clique em **Selecionar arquivo** e escolha o arquivo exportado.
4. Analise os painéis:
   - **Por Banco** — soma do saldo por instituição emissora com alerta de limite FGC.
   - **Vencimentos** — listagem dos títulos agrupados por data de vencimento.

> ⚠️ No momento, suporta apenas arquivos exportados pela **XP Investimentos**.

---

## Tecnologias

- [Flutter](https://flutter.dev) — framework de UI multiplataforma
- [Riverpod](https://riverpod.dev) — gerenciamento de estado
- [Firebase Hosting](https://firebase.google.com/products/hosting) — hospedagem do app web
- [excel](https://pub.dev/packages/excel) — leitura de arquivos `.xlsx`

---

## Executar localmente

```bash
# Instalar dependências
flutter pub get

# Rodar no navegador
flutter run -d chrome

# Build para web
flutter build web --release
```

---

## Contribuições

Contribuições são bem-vindas! Abra uma _issue_ ou envie um _pull request_ no repositório:  
👉 [github.com/vandreborba/renda_fixa_view](https://github.com/vandreborba/renda_fixa_view)

---

## Licença

Este projeto é licenciado sob a [GNU General Public License v3.0](https://www.gnu.org/licenses/gpl-3.0.html).  
Qualquer uso ou distribuição do código deve manter a mesma licença e disponibilizar o código-fonte.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
