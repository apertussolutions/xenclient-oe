# surf version
VERSION = 2.0

# Customize below to fit your system

# paths
PREFIX = /usr
MANPREFIX = ${PREFIX}/share/man
LIBPREFIX = ${PREFIX}/lib/surf

GTKINC = `pkg-config --cflags gtk+-3.0 webkit2gtk-4.1 javascriptcoregtk-4.1 x11`
GTKLIB = `pkg-config --libs gtk+-3.0 webkit2gtk-4.1 javascriptcoregtk-4.1 x11`

# includes and libs
# Do not pass empty -I${X11INC}; that eats the next -I from pkg-config.
INCS = -I. ${GTKINC}
LIBS = -lc ${GTKLIB} -lgthread-2.0

# flags
CPPFLAGS += -DVERSION=\"${VERSION}\" -DWEBEXTDIR=\"${LIBPREFIX}\" -D_DEFAULT_SOURCE
CFLAGS += -std=c99 -pedantic -Wall -Os ${INCS} ${CPPFLAGS}
LDFLAGS += ${LIBS}
