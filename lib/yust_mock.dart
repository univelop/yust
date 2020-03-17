import 'package:yust/models/yust_doc_setup.dart';
import 'package:yust/yust_service.dart';
import 'package:yust/yust_store.dart';

abstract class YustMock {
  static YustStore _storeMock;
  static YustService _serviceMock;
  static YustDocSetup _userSetupMock;

  static T returnRealOrMock<T>(
    T Function() getMock,
    T real,
  ) {
    assert(getMock != null);

    return getMock() ?? real;
  }

  static YustStore store(YustStore store) =>
      returnRealOrMock<YustStore>(() => _storeMock, store);
  static YustService service(YustService service) =>
      returnRealOrMock<YustService>(() => _serviceMock, service);
  static YustDocSetup userSetup(YustDocSetup userSetup) =>
      returnRealOrMock<YustDocSetup>(() => _userSetupMock, userSetup);

  /// Only inserts new mocks.
  static void injectMock({
    YustStore storeMock,
    YustService serviceMock,
    YustDocSetup userSetupMock,
  }) {
    void replaceIfNotNull<T>(
      void Function(T) setter,
      T value,
    ) {
      assert(setter != null);

      if (value != null) {
        setter(value);
      }
    }

    replaceIfNotNull(
      (YustStore storeMock) => _storeMock = storeMock,
      storeMock,
    );
    replaceIfNotNull(
      (YustService serviceMock) => _serviceMock = serviceMock,
      serviceMock,
    );
    replaceIfNotNull(
      (YustDocSetup userSetupMock) => _userSetupMock = userSetupMock,
      userSetupMock,
    );
  }

  static void removeMock({
    bool storeMock,
    bool serviceMock,
    bool userSetupMock,
  }) {
    void conditionallyRemoveMock(
      void Function() setter,
      bool remove,
    ) {
      remove ??= false;

      if (remove) {
        setter();
      }
    }

    conditionallyRemoveMock(() => _storeMock = null, storeMock);
    conditionallyRemoveMock(() => _serviceMock = null, serviceMock);
    conditionallyRemoveMock(() => _userSetupMock = null, userSetupMock);
  }

  static void removeAllMocks() {
    _storeMock = null;
    _serviceMock = null;
    _userSetupMock = null;
  }

  static bool isMocking() {
    return _storeMock != null || _serviceMock != null || _userSetupMock != null;
  }
}
