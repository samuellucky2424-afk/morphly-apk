import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_gateway.dart';

class ReferenceImageService {
  const ReferenceImageService({this.gateway = const SupabaseGateway()});

  final SupabaseGateway gateway;

  Future<String> upload(File image) async {
    final userId = gateway.userId;
    final extension = image.path.split('.').last.toLowerCase();
    final safeExtension = extension.length <= 5 ? extension : 'jpg';
    final path =
        '$userId/reference-${DateTime.now().millisecondsSinceEpoch}.$safeExtension';

    await gateway.client.storage.from('reference-images').upload(
          path,
          image,
          fileOptions: const FileOptions(
            cacheControl: '3600',
            upsert: false,
          ),
        );
    return path;
  }
}
