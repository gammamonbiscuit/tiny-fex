# Using an amd64 distro image as rootfs
FROM --platform=linux/amd64 debian:trixie-slim AS rootfs

# Forcing this image to be only buildable in arm64
FROM --platform=linux/arm64 debian:bookworm-slim AS builder
COPY --from=rootfs / /rootfs

# Things needed for building FEX-Emu, and qemu-user-static for chroot-ing into rootfs
# https://wiki.fex-emu.com/index.php/Development:Setting_up_FEX#Debian.2FUbuntu_dependencies
ARG DEBIAN_FRONTEND=noninteractive \
    CC=clang \
    CXX=clang++
RUN apt-get update && \
    apt install -y git cmake lld clang llvm ninja-build pkg-config libsdl2-dev qtbase5-dev qtdeclarative5-dev qemu-user-static

# Very large repo (~1.8GB), separated layer for better caching
# https://github.com/FEX-Emu/FEX
RUN git clone --depth 1 --recurse-submodules https://github.com/FEX-Emu/FEX.git

# Build FEX-Emu
# https://wiki.fex-emu.com/index.php/Development:Setting_up_FEX#Build_Configuration
RUN cd /FEX && \
    cmake -DCMAKE_INSTALL_PREFIX=/usr -DCMAKE_BUILD_TYPE=Release -DUSE_LINKER=lld -DENABLE_LTO=True -DBUILD_TESTING=False -DENABLE_ASSERTIONS=False -G Ninja . && \
    ninja -j$(nproc)

# Install dependencies in rootfs
# steamcmd: lib32gcc-s1
# https://developer.valvesoftware.com/wiki/SteamCMD#Manually
RUN cd /rootfs && \
    chroot . apt update && \
    chroot . apt install -y lib32gcc-s1

# Clean up
# https://wiki.fex-emu.com/index.php/Development:Setting_up_RootFS#File_deletion
RUN cd /rootfs && \
    rm -rf boot dev home media mnt proc root srv tmp sys opt var/cache/apt var/lib/apt var/lib/dpkg && \
    cd /rootfs/etc && \
    rm -f hosts resolv.conf timezone localtime passwd

# Copy compiled binaries and rootfs to final image
FROM --platform=linux/arm64 debian:trixie-slim AS runner
COPY --from=builder /FEX/Bin /usr/bin
COPY --from=builder /rootfs /rootfs
RUN mkdir /root/.fex-emu
RUN echo '{"Config":{"RootFS":"/rootfs"}}' >/root/.fex-emu/Config.json
ENTRYPOINT ["sh"]