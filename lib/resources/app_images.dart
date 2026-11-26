import 'package:flutter/material.dart';
import '../widgets/smart_image.dart';

class AppImages {
  // Local Asset Paths
  static const String assetAzureVista = 'assets/images/azure_vista_resort.jpg';
  static const String assetAlpineGlass = 'assets/images/alpine_glass_loft.jpg';
  static const String assetAzureGrandHero = 'assets/images/azure_grand_resort_hero.jpg';
  static const String assetStandardRoom = 'assets/images/standard_room_bed.jpg';
  static const String assetDeluxeOcean = 'assets/images/deluxe_ocean_suite.jpg';
  static const String assetAmaniKhas = 'assets/images/amani_khas_tent.jpg';
  static const String assetVillaSerenity = 'assets/images/villa_serenity.jpg';
  static const String assetRitzKyoto = 'assets/images/ritz_kyoto.jpg';
  static const String assetVillaSeraphina = 'assets/images/villa_seraphina.jpg';
  static const String assetAzureHaven = 'assets/images/azure_haven_resort.jpg';
  static const String assetSarahJenkins = 'assets/images/sarah_jenkins_avatar.jpg';

  // Network Fallback Image URLs
  static const String azureVistaResort =
      'https://images.unsplash.com/photo-1570077188670-e3a8d69ac5ff?q=80&w=800&auto=format&fit=crop';
  static const String alpineGlassLoft =
      'https://images.unsplash.com/photo-1518780664697-55e3ad937233?q=80&w=800&auto=format&fit=crop';
  static const String azureGrandResortHero =
      'https://images.unsplash.com/photo-1540541338287-41700207dee6?q=80&w=1000&auto=format&fit=crop';
  static const String standardRoomBed =
      'https://images.unsplash.com/photo-1618773928121-c32242e63f39?q=80&w=800&auto=format&fit=crop';
  static const String deluxeOceanSuite =
      'https://images.unsplash.com/photo-1590490360182-c33d57733427?q=80&w=800&auto=format&fit=crop';
  static const String amaniKhasTent =
      'https://images.unsplash.com/photo-1578683010236-d716f9a3f461?q=80&w=800&auto=format&fit=crop';
  static const String villaSerenity =
      'https://images.unsplash.com/photo-1618773928121-c32242e63f39?q=80&w=800&auto=format&fit=crop';
  static const String ritzKyoto =
      'https://images.unsplash.com/photo-1503899036084-c55cdd92da26?q=80&w=800&auto=format&fit=crop';
  static const String villaSeraphina =
      'https://images.unsplash.com/photo-1533105079780-92b9be482077?q=80&w=800&auto=format&fit=crop';
  static const String azureHavenResort =
      'https://images.unsplash.com/photo-1514282401047-d79a71a590e8?q=80&w=800&auto=format&fit=crop';
  static const String sarahJenkinsAvatar =
      'https://images.unsplash.com/photo-1534528741775-53994a69daeb?q=80&w=200&auto=format&fit=crop';

  static final Map<String, String> _assetToNetworkMap = {
    assetAzureVista: azureVistaResort,
    assetAlpineGlass: alpineGlassLoft,
    assetAzureGrandHero: azureGrandResortHero,
    assetStandardRoom: standardRoomBed,
    assetDeluxeOcean: deluxeOceanSuite,
    assetAmaniKhas: amaniKhasTent,
    assetVillaSerenity: villaSerenity,
    assetRitzKyoto: ritzKyoto,
    assetVillaSeraphina: villaSeraphina,
    assetAzureHaven: azureHavenResort,
    assetSarahJenkins: sarahJenkinsAvatar,
  };

  static String? getNetworkFallback(String assetPath) {
    return _assetToNetworkMap[assetPath];
  }

  // Helper builder for smart local asset with network fallback
  static Widget buildImage({
    required String pathOrUrl,
    String? fallbackUrl,
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    BorderRadius? borderRadius,
  }) {
    return SmartImage(
      imagePath: pathOrUrl,
      fallbackUrl: fallbackUrl ?? getNetworkFallback(pathOrUrl),
      width: width,
      height: height,
      fit: fit,
      borderRadius: borderRadius,
    );
  }
}
