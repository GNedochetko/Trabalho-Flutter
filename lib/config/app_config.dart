// Valores recebidos ao executar: flutter run --dart-define-from-file=.env
class AppConfig {
  static const newsApiKey = String.fromEnvironment('RAPIDAPI_KEY');
  static const giphyApiKey = String.fromEnvironment('GIPHY_API_KEY');
  static const newsHost = String.fromEnvironment(
    'NEWS_API_HOST',
    defaultValue: 'real-time-news-data.p.rapidapi.com',
  );
  static const giphyHost = String.fromEnvironment(
    'GIPHY_API_HOST',
    defaultValue: 'api.giphy.com',
  );
  static const country = String.fromEnvironment(
    'NEWS_COUNTRY',
    defaultValue: 'BR',
  );
  static const language = String.fromEnvironment(
    'NEWS_LANGUAGE',
    defaultValue: 'pt',
  );
}
