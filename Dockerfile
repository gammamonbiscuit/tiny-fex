FROM --platform=linux/amd64 alpine:3.23 AS rootfs
FROM --platform=linux/arm64 alpine:3.23 AS builder