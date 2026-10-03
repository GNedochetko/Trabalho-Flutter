# Trabalho prático — Notícias e GIFs

Aplicativo Flutter simples que consulta a Real-Time News Data pelo RapidAPI
para buscar notícias e o Giphy para buscar GIFs com o mesmo termo.

## Configurar e executar

O Flutter instalado aceita arquivos `.env` diretamente com
`--dart-define-from-file`, sem biblioteca adicional e sem registrar o arquivo
como asset.

1. Crie uma conta no RapidAPI e assine um plano da Real-Time News Data.
2. Teste o endpoint Search no Playground e obtenha sua `X-RapidAPI-Key`.
3. Se `.env` ainda não existir, copie `.env.example` para `.env`:

   ```bash
   cp .env.example .env
   ```

4. Preencha `RAPIDAPI_KEY` e `GIPHY_API_KEY` no `.env`.
   A chave do Giphy que existia no projeto foi preservada no arquivo local.
   `NEWS_COUNTRY=BR` e `NEWS_LANGUAGE=pt` configuram os resultados para o Brasil
   e o idioma português. Não coloque as chaves em arquivos Dart.
5. Execute:

   ```bash
   flutter pub get
   flutter run --dart-define-from-file=.env
   ```

O VS Code também tem uma configuração de execução que passa o `.env`.
Ao mudar uma chave, pare e execute o aplicativo novamente: hot reload não
atualiza os valores recebidos na compilação.

O `.env` é ignorado pelo Git. Esta configuração evita publicar as chaves com
os fontes; elas ainda podem ser extraídas do aplicativo compilado. Para este
trabalho, usamos acesso direto às APIs. Uma aplicação pública precisaria de
um servidor para proteger a chave do RapidAPI.

## Funcionamento

- A HomePage começa com um campo de pesquisa, sem consultar as APIs ao abrir.
- Buscar (ou enviar pelo teclado) consulta notícias e GIFs com o mesmo termo.
- A busca mantém a ordem dos resultados devolvidos pela API de notícias.
  O Search não documenta um parâmetro de ordenação nem um valor de relevância;
  o app não calcula uma classificação própria e não ordena por data.
- A API de notícias recebe `limit=100`. Como Search não documenta offset ou
  token de página, o app guarda a lista e exibe os primeiros cinco itens.
- Carregar mais exibe mais cinco notícias da lista, até terminar os resultados
  disponíveis (o último lote pode ter menos de cinco).
- Cada lote consulta GIFs com `limit=5` e offsets 0, 5, 10 etc. No último lote,
  o limite é a quantidade de notícias restantes. Notícia 1 recebe GIF 1,
  notícia 2 recebe GIF 2 e assim por diante. O GIF ilustra o termo pesquisado.
- Notícias repetidas pelo mesmo link são removidas, preservando a ordem.
- Ver notícia abre a NewsPage com foto, título, fonte, data, autores e resumo.
  Abrir notícia original abre o site da fonte para ler o texto completo:
  o Search fornece um trecho, não o corpo completo da notícia.
- Ver GIF abre a GifPage com imagem, título, autor, classificação e link.
- Limpar remove a pesquisa e os resultados. Uma nova busca também reinicia
  a lista e o pareamento.

## Botões e validações do trabalho

Há três botões principais funcionais: Buscar, Limpar e Carregar mais.
Além deles, existem Ver notícia, Ver GIF, Abrir notícia original e Voltar.

A pesquisa rejeita texto vazio ou só com espaços e limita o termo a 50
caracteres, que é o limite do Giphy. Durante as consultas, o app bloqueia novas
buscas e carregamentos. Também trata falta de chave, erros HTTP, timeout,
resposta inválida, resultados vazios, links inválidos e imagens indisponíveis.
Se o Giphy falhar ou retornar menos GIFs, as notícias continuam visíveis e os
itens sem GIF mostram uma mensagem, sem deslocar os GIFs para outra notícia.

## Organização do código

- `lib/main.dart`: inicia o aplicativo.
- `lib/config/app_config.dart`: lê os valores fornecidos pelo `.env`.
- `lib/service/news_service.dart`: consulta a API de notícias e remove duplicatas.
- `lib/service/giphy_service.dart`: busca os GIFs com limite e offset.
- `lib/view/home_page.dart`: pesquisa, estado, pareamento e lista de resultados.
- `lib/view/news_page.dart`: detalhes e link original da notícia.
- `lib/view/gif_page.dart`: detalhes do GIF.
- `lib/view/widgets/remote_image.dart`: imagem com mensagem em caso de falha.
- `lib/utils/format_date.dart`: converte a data UTC para horário local.

## Verificar

```bash
flutter analyze
flutter test
```

Os testes usam respostas simuladas, sem consumir cota ou usar chaves reais.
Eles verificam os parâmetros das APIs, erros, paginação, pareamento, nova busca
e navegação. Para confirmar a integração ao vivo, preencha a chave do RapidAPI,
execute com `.env` e teste uma pesquisa e Carregar mais no aparelho.

## Documentação consultada

- [Real-Time News Data](https://www.openwebninja.com/api/real-time-news-data)
- [Especificação oficial da API](https://openwebninja.s3.us-east-1.amazonaws.com/portal/openapi/realtime_news_data.yaml)
- [Autenticação RapidAPI](https://docs.rapidapi.com/docs/configuring-api-security)
- [Busca e paginação do Giphy](https://developers.giphy.com/docs/api/endpoint/#search)
