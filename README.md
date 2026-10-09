# Simulador de Gramática Regular (GR) — Lazarus

Interface simples seguindo o modelo do simulador de Expressões Regulares: gramática, entrada, botão **Testar** e saída.

## Abrir

1. Abra `SimuladorGR.lpi` no Lazarus.
2. Pressione **F9** para compilar e executar.

## Uso

Insira uma gramática regular **linear à direita**, uma produção por linha. Exemplo:

```text
S -> aA | bS | eps
A -> aS | b
```

- `S` e `A` são não terminais.
- `a` e `b` são terminais.
- `eps` ou `ε` representa a palavra vazia.
- A primeira variável definida é o símbolo inicial.
- Aceita produções `A -> aB`, `A -> a`, `A -> eps`.
- A entrada vazia pode ser digitada como `eps`.

O programa informa se a palavra foi aceita e mostra uma derivação quando possível.

## Arquivos

- `SimuladorGR.lpi` — configuração do Lazarus
- `SimuladorGR.lpr` — programa principal
- `UnitGR.pas` — código Pascal
- `UnitGR.lfm` — interface do formulário

## Observação

Este é um projeto novo de GR, não uma cópia de código do simulador ER. A interface foi adaptada visualmente a partir da captura de tela enviada. O projeto não foi compilado neste ambiente; teste com F9 no Lazarus.
