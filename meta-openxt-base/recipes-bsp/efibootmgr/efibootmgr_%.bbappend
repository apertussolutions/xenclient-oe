# Upstream moved rhinstaller -> rhboot; "master" branch is gone (use main).
SRC_URI_remove = "git://github.com/rhinstaller/efibootmgr.git;protocol=https;branch=master"
SRC_URI_prepend = "git://github.com/rhboot/efibootmgr.git;protocol=https;branch=main "
