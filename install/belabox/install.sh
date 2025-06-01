#!/usr/bin/env bash

set -e

WORKSPACE=moblink-rust-install
REPO="datagutt/moblink-rust"

# Parse command line arguments
VERSION=""
while [ $# -gt 0 ]; do
	case $1 in
	-v | --version)
		VERSION="$2"
		shift 2
		;;
	*)
		echo "Unknown option: $1"
		exit 1
		;;
	esac
done

# If version is not specified, get latest release tag name from GitHub API
if [ -z "$VERSION" ]; then
	LATEST_TAG=$(wget -qO- https://api.github.com/repos/$REPO/releases/latest | grep -Po '"tag_name": "\K.*?(?=")')
	VERSION=${LATEST_TAG#v}
else
	# Add 'v' prefix if not present
	case "$VERSION" in
	v*) LATEST_TAG="$VERSION" ;;
	*) LATEST_TAG="v$VERSION" ;;
	esac
fi

LATEST_RELEASE_URL="https://github.com/$REPO/releases/download/$LATEST_TAG"
LATEST_RELEASE_SOURCE_CODE_URL="https://github.com/$REPO/archive/refs/tags/$LATEST_TAG.tar.gz"

# Detect architecture and OS version
ARCH=$(uname -m)
case $ARCH in
x86_64)
	TARGET="x86_64-unknown-linux-gnu"
	;;
aarch64)
	# Check if we're on Ubuntu 18.04 or older to use MUSL for better compatibility
	if command -v lsb_release >/dev/null 2>&1; then
		DISTRO=$(lsb_release -si)
		VERSION_ID=$(lsb_release -sr)
		if [ "$DISTRO" = "Ubuntu" ] && [ "$(echo "$VERSION_ID" | cut -d. -f1)" -le 18 ]; then
			echo "Detected Ubuntu $VERSION_ID - using statically linked MUSL binary for compatibility"
			TARGET="aarch64-unknown-linux-musl"
		else
			TARGET="aarch64-unknown-linux-gnu"
		fi
	else
		# Check /etc/os-release as fallback
		if [ -f /etc/os-release ]; then
			. /etc/os-release
			if [ "$ID" = "ubuntu" ] && [ "${VERSION_ID%%.*}" -le 18 ]; then
				echo "Detected Ubuntu $VERSION_ID - using statically linked MUSL binary for compatibility"
				TARGET="aarch64-unknown-linux-musl"
			else
				TARGET="aarch64-unknown-linux-gnu"
			fi
		else
			# Default to MUSL for maximum compatibility when we can't detect the OS
			echo "Cannot detect OS version - using statically linked MUSL binary for maximum compatibility"
			TARGET="aarch64-unknown-linux-musl"
		fi
	fi
	;;
*)
	echo "Unsupported architecture: $ARCH"
	exit 1
	;;
esac

rm -rf $WORKSPACE
mkdir $WORKSPACE
cd $WORKSPACE

echo "- Stopping moblink systemd services (if running)"
systemctl stop moblink-streamer || true
systemctl stop moblink-relay-service || true

echo "- Downloading moblink binaries"
wget -q --show-progress "$LATEST_RELEASE_URL/moblink-relay-$TARGET"
wget -q --show-progress "$LATEST_RELEASE_URL/moblink-relay-service-$TARGET"
wget -q --show-progress "$LATEST_RELEASE_URL/moblink-streamer-$TARGET"

echo "- Downloading moblink systemd service files"
wget -q --show-progress "$LATEST_RELEASE_SOURCE_CODE_URL"
tar -xzf "$LATEST_TAG.tar.gz"
cp moblink-rust-$VERSION/install/belabox/systemd/moblink-relay-service.service /etc/systemd/system/
cp moblink-rust-$VERSION/install/belabox/systemd/moblink-streamer.service /etc/systemd/system/

echo "- Making moblink binaries executable and moving them to /usr/local/bin"
chmod +x moblink-relay-$TARGET moblink-relay-service-$TARGET moblink-streamer-$TARGET
mv moblink-relay-$TARGET /usr/local/bin/moblink-relay
mv moblink-relay-service-$TARGET /usr/local/bin/moblink-relay-service
mv moblink-streamer-$TARGET /usr/local/bin/moblink-streamer

echo "- Enabling and starting moblink systemd services"
systemctl enable moblink-streamer
systemctl start moblink-streamer

systemctl enable moblink-relay-service
systemctl start moblink-relay-service

cd ..
rm -rf $WORKSPACE

echo "- Done!"
