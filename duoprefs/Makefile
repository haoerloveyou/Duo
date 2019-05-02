include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = DuoPrefs
DuoPrefs_FILES = MRYRootListController.m
DuoPrefs_INSTALL_PATH = /Library/PreferenceBundles
DuoPrefs_FRAMEWORKS = UIKit
DuoPrefs_PRIVATE_FRAMEWORKS = Preferences
DuoPrefs_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/bundle.mk

internal-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences$(ECHO_END)
	$(ECHO_NOTHING)cp entry.plist $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/DuoPrefs.plist$(ECHO_END)
