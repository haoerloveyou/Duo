ARCHS = armv7 arm64 arm64e

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = Duo
Duo_FILES = Tweak.xm
Duo_FRAMEWORKS = UIKit
Duo_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 backboardd"

SUBPROJECTS += duoprefs
include $(THEOS_MAKE_PATH)/aggregate.mk
