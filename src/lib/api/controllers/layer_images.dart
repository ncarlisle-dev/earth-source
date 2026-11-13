import '../services/network_service.dart';

/// Controller (?) that stores a cached list of project layer images.
class LayerImages {
  /// Privately-named constructor to prevent other modules from creating a 
  /// new layer image cache.
  LayerImages._();

  /// Static instance of the layer image cache.
  static LayerImages? instance;

  /// Image strings stored in the cache, keyed by layer ID.
  final Map<String, String> _cachedImages = {};

  /// Retrieves the LayerImages instance if already initialized; if not, 
  /// creates an instance
  static Future<LayerImages> getInstance() async
  {
    if (instance != null) return instance!;

    instance = LayerImages._();
    return instance!;
  }

  /// Adds the string representing an image to the cache and returns the string
  Future<String> addImage(String layerId, String image) async
  {
    _cachedImages[layerId] = image;
    return image;
  }

  /// Attempts to return an image string from the cache; if it is not already
  /// present, fetches it from the database, adds it to the cache, and returns
  /// it.
  Future<String> getImageByLayerId(String projectId, String layerId) async {
    if (_cachedImages.containsKey(layerId)) return _cachedImages[layerId]!;

    final networkService = await NetworkService.getInstance();

    final image = await networkService.fetchLayerImage(projectId, layerId);
    _cachedImages[layerId] = image;
    return image;
  }
}
