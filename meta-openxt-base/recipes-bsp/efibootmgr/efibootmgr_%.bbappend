# Upstream org: rhinstaller -> rhboot. Drop any OE-Core URI and use rhboot/main.
SRC_URI:remove = "git://github.com/rhinstaller/efibootmgr.git;protocol=https;branch=master"
SRC_URI:remove = "git://github.com/rhinstaller/efibootmgr.git;protocol=https;branch=main"
SRC_URI:remove = "git://github.com/rhboot/efibootmgr.git;protocol=https;branch=main"
SRC_URI:prepend = "git://github.com/rhboot/efibootmgr.git;protocol=https;branch=main "
