# Upstream moved rhinstaller -> rhboot; "master" branch is gone (use main).
SRC_URI:remove = "git://github.com/rhinstaller/efibootmgr.git;protocol=https;branch=master"
SRC_URI:prepend = "git://github.com/rhboot/efibootmgr.git;protocol=https;branch=main "
