/// Keystone API interface.
abstract class KeystoneApiInterface {
  /// Initialize keystone sdk.
  Future<Map<String, dynamic>> intialize();

  /// Authenticates a user with the given [userName], [thirdPartyName], and [token].
  ///
  /// Returns: [ApiResult] with the [ApiResult.success] being true or false.
  Future<Map<String, dynamic>> authenticate({
    required String userName,
    required String thirdPartyName,
    required String token,
    required String environment,
  });

  /// Returns the list of assignments with 1 week window. The return map is
  /// decoded from [ApiResult].
  Future<Map<String, dynamic>> getAssignments();

  /// Connects to the bluetooth device with [keystoneId].
  Future<Map<String, dynamic>> connect({required String keystoneId});

  /// Disconnects the bluetooth device with [keystoneId].
  Future<Map<String, dynamic>> disconnect({required String keystoneId});

  /// Subscribes to the vehicle with module id matching [keystoneId].
  /// This will emit door states, connectable and connection states of the
  /// vehicle. The return map is decoded from [ApiResult].
  Future<Map<String, dynamic>> subscribeToVehicle({required String keystoneId});

  /// Subscribes to the vehicle with module id matching [keystoneId]. The
  /// return map is decoded from [ApiResult].
  Map<String, dynamic> unsubscribeFromVehicle({required String keystoneId});

  /// Performs the action on module with [keystoneId] based on the [actionType].
  /// Currently performs the following based on action type:
  /// - [ActionType.lock] - Locks all the doors of the vehicle.
  /// - [ActionType.unlock] - Unocks all the doors of the vehicle.
  ///
  ///  The return map is decoded from [ApiResult].
  Future<Map<String, dynamic>> performAction({
    required String keystoneId,
    required String actionType,
  });

  /// Log outs the user.
  Future<Map<String, dynamic>> logout();

  /// Shutsdown keystone and releases any resources if applicable.
  Future<Map<String, dynamic>> shutdown();

  /// Listens to errors from keystone
  Map<String, dynamic> subscribeToKeystoneErrors();
}
