# Included when meta-openxt-ui is part of the product build.

DISTRO_FEATURES_append += " opengl openxt-ui"

PREFERRED_VERSION_dojosdk-native ?= "1.7.12"
PREFERRED_VERSION_dojosdk-native_xenclient-syncui ?= "1.8.1"

PREFERRED_VERSION_network-manager-applet ?= "1.8.22"

PREFERRED_PROVIDER_virtual/java-initial = "cacao-initial"
PREFERRED_PROVIDER_virtual/java-initial-native = "cacao-initial-native"
PREFERRED_PROVIDER_virtual/java-native = "jamvm-native"
PREFERRED_PROVIDER_virtual/javac-native = "ecj-bootstrap-native"
