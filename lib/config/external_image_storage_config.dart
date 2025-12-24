/// External image storage configuration.
///
/// This project previously uploaded images to Firebase Storage. If your Firebase
/// quota is exceeded, you can store images in a non-Firebase provider and keep
/// only the resulting URL in Firestore (e.g. `products.imageUrl`).
///
/// Recommended: Cloudinary unsigned uploads (fast to set up).
/// - Create a Cloudinary account
/// - Create an **Unsigned upload preset**
/// - Put the values below
///
/// SECURITY NOTE:
/// Unsigned presets are public in the client. Restrict the preset in Cloudinary
/// (allowed formats/size/folder) and rotate if abused. For stronger security,
/// use signed uploads via your own backend.
class ExternalImageStorageConfig {
  /// Toggle to enable/disable external image uploading.
  static const bool enabled = true;

  /// Cloudinary cloud name (dashboard: Cloud name).
  static const String cloudinaryCloudName = 'dobjrnkea';

  /// Unsigned upload preset name (Settings -> Upload -> Upload presets).
  static const String cloudinaryUnsignedUploadPreset = 'tuning_products';

  /// Optional folder inside Cloudinary.
  static const String cloudinaryFolder = 'tuning_app/products';
}


