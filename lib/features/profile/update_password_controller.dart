import 'package:filip_at_flutter/features/profile/profile_repository.dart';
import 'package:flutter/foundation.dart';

class UpdatePasswordController extends ChangeNotifier {
  UpdatePasswordController({required ProfileRepository repository})
    : _repository = repository;

  final ProfileRepository _repository;

  bool _submitting = false;
  String? _flowErrorCode;

  bool get submitting => _submitting;
  String? get flowErrorCode => _flowErrorCode;

  Future<bool> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    _flowErrorCode = null;
    _submitting = true;
    notifyListeners();
    try {
      final result = await _repository.changePassword(
        oldPassword: oldPassword,
        newPassword: newPassword,
      );
      if (!result.isSuccess) {
        _flowErrorCode = result.errorCode ?? 'SOMETHING_WENT_WRONG';
        return false;
      }
      return true;
    } catch (_) {
      _flowErrorCode = 'SOMETHING_WENT_WRONG';
      return false;
    } finally {
      _submitting = false;
      notifyListeners();
    }
  }

  void reset() {
    _submitting = false;
    _flowErrorCode = null;
    notifyListeners();
  }
}
