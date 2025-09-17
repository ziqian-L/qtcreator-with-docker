# Copyright 2020, Burkhard Stubert (DBA Embedded Use)

# 使用 Ubuntu 20.04 作为基础镜像
FROM ubuntu:20.04

# 设置时区环境变量，避免在安装过程中交互式提示
ENV TZ=Asia/Shanghai
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# 设置清华源以加速 apt-get 更新和安装
RUN sed -i 's/archive.ubuntu.com/mirrors.tuna.tsinghua.edu.cn/g' /etc/apt/sources.list && \
    sed -i 's/security.ubuntu.com/mirrors.tuna.tsinghua.edu.cn/g' /etc/apt/sources.list

# 更新软件包列表并安装必要的软件包
RUN apt-get -y update && apt-get -y upgrade && \
    apt-get -y install \
    build-essential perl python3 git \
    '^libxcb.*-dev' libx11-xcb-dev libglu1-mesa-dev libxrender-dev libxi-dev '^libxkbcommon.*' \
    libssl-dev libxcursor-dev libxcomposite-dev libxdamage-dev libxrandr-dev libdbus-1-dev \
    libfontconfig1-dev libcap-dev libxtst-dev libpulse-dev libudev-dev libpci-dev libnss3-dev \
    libasound2-dev libxss-dev libegl-dev gperf bison \
    libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev \
    flex libicu-dev dpkg cmake zip unzip

# 移除不必要的软件包（与 Ubuntu 18.04 一致）
RUN apt-get -y purge libxcb-xinerama0-dev libxcb-xinerama0 || true

# 禁用 dash，使用 bash 作为默认 shell
RUN which dash &> /dev/null && (\
    echo "dash dash/sh boolean false" | debconf-set-selections && \
    DEBIAN_FRONTEND=noninteractive dpkg-reconfigure dash) || \
    echo "跳过 dash 重配置（不适用）"

# 安装并配置中文语言环境
RUN apt-get -y install locales
# 生成中文UTF-8区域设置
RUN locale-gen zh_CN.UTF-8 && update-locale LC_ALL=zh_CN.UTF-8 LANG=zh_CN.UTF-8
ENV LANG=zh_CN.UTF-8
ENV LC_ALL=zh_CN.UTF-8
ENV LANGUAGE=zh_CN:zh:en_US:en

# 设置容器内用户名
ENV USER_NAME=builder

# 构建参数：主机用户ID和组ID（用于文件权限映射）
ARG host_uid=1000
ARG host_gid=1000

# 创建与主机用户ID匹配的用户和组
RUN groupadd -g $host_gid $USER_NAME && useradd -g $host_gid -m -s /bin/bash -u $host_uid $USER_NAME

# 切换到非 root 用户并设置工作目录
USER $USER_NAME

# 设置工作目录
WORKDIR /work
