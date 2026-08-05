# UIVM has only root as user; pre-create local conf directories.
dirs755_append_xenclient-uivm = " \
    /root/.gconf \
    /root/.gnome2 \
    /root/.cache \
    /root/.ssh \
"
