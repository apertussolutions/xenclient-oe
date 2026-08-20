# OE-Core still points at the old rhinstaller org. Use rhboot/main.
# Do not SRC_URI:remove the rhboot URL after prepending it: :remove is
# applied last and would leave SRC_URI empty (do_unpack then no-ops).
SRC_URI:remove = "git://github.com/rhinstaller/efibootmgr.git;protocol=https;branch=main"
SRC_URI:remove = "git://github.com/rhinstaller/efibootmgr.git;protocol=https;branch=master"
SRC_URI:append = " git://github.com/rhboot/efibootmgr.git;protocol=https;branch=main"
