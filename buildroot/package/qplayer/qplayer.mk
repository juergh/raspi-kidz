################################################################################
#
# qplayer
#
################################################################################

QPLAYER_VERSION = 0.1.0
QPLAYER_SITE = ../../../../qplayer
QPLAYER_SITE_METHOD = local
QPLAYER_DEPENDENCIES = qt5base

define QPLAYER_CONFIGURE_CMDS
    cd $(@D) && $(TARGET_MAKE_ENV) qmake
endef

define QPLAYER_BUILD_CMDS
    $(TARGET_MAKE_ENV) $(MAKE) -C $(@D) all
endef

define QPLAYER_INSTALL_TARGET_CMDS
    $(TARGET_MAKE_ENV) $(MAKE) -C $(@D) install INSTALL_ROOT=$(TARGET_DIR)
endef

$(eval $(generic-package))
