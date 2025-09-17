## WSL1 和 WSL2 共存
[WSL2 踩坑记录](https://blog.ixk.me/post/wsl-2-recording)

## 在 WSL2 上使用 Docker
[WSL 2 上的 Docker 远程容器入门](https://learn.microsoft.com/zh-cn/windows/wsl/tutorials/wsl-containers)

## 使用 QtCreator 和 Docker 快速开发 Qt 应用
### 在主机上创建 Docker 容器模拟目标系统的环境
创建工作目录
```
mkdir -p ~/embedded_docker/work
cd ~/embedded_docker/work/
```

拉取 Dockerfile 文件
```
git clone https://github.com/ziqian-L/qtcreator-with-docker.git
```

启动 Docker，构建容器，名称为 qt-ubuntu-20.04-x86
```
docker build --no-cache --tag "qt-ubuntu-20.04-x86" .
```

构建成功的话，使用`docker images`可以看见
```
REPOSITORY            TAG       IMAGE ID       CREATED        SIZE
qt-ubuntu-20.04-x86   latest    084bb36530bb   18 hours ago   1.32GB
```

如果构建失败可以用以下命令清除docker的缓存
```
docker builder prune
docker system prune
```

### 在容器中编译可以在目标系统使用的 Qt 程序
获取Qt6.5.5
```
cd ~/embedded_docker/work/
wget https://mirrors.ustc.edu.cn/qtproject/official_releases/qt/6.5/6.5.5/src/single/qt-everywhere-opensource-src-6.5.5.tar.xz
```

启动 qt-ubuntu-20.04-x86 容器，将 `~/embedded_docker/work/` 目录挂载到容器内的 /work 目录，方便访问和处理主机上的文件
```
docker run -it --rm -v $PWD:/work qt-ubuntu-20.04-x86
```

进入容器的的目录之后，进入容器的`/work`文件夹，创建 build-qt-6.5.5 文件夹
```
cd /work/
mkdir -p /work/build-qt-6.5.5
```

若出现以下报错，则查看当前用户的 UID 和 GID，若显示的用户组与 Dokerfile 里用户组不匹配，则修改 Dorkerfile 里的 host_uid host_gid，重新编译
```
builder@eb18704f768d:/work$ mkdir build-qt-6.5.5
mkdir: cannot create directory ‘build-qt-6.5.5’: Permission denied

builder@eb18704f768d:/work$ ls -ln
total 770316
drwxr-xr-x  3 1000 1000      4096 9月  16 16:53 qtcreator-with-docker
-rw-r--r--  1 1000 1000 788789252 7月   2 04:02 qt-everywhere-opensource-src-6.5.5.tar.xz
drwxr-xr-x 46 1000 1000      4096 6月  16 15:44 qt-everywhere-src-6.5.5
```

配置qt编译的参数
```
../qt-everywhere-src-6.5.5/configure \
    -opensource -confirm-license -release -strip \
    -prefix /work/qt-6.5.5 \
    -feature-relocatable -rpath \
    -platform linux-g++ \
    -feature-xcb -icu -openssl-runtime \
    -no-gstreamer -no-libudev \
    -nomake examples -nomake tests \
    -skip qtcharts -skip qtgamepad -skip qtlottie -skip qtwayland \
    -skip qt3d -skip qtspeech -skip qtlocation -skip qtpurchasing \
    -skip qtvirtualkeyboard -skip qtwebengine -skip qtwebchannel \
    -skip qtwebglplugin -skip qtwebsockets -skip qtwebview \
    -verbose
```

编译qt，安装qt
```
make -j
make install
```

使用`exit`退出容器，然后进入`~/embedded_docker/work`目录，打包编译好的`Qt6`
```
cd ~/embedded_docker/work
tar czf qt-6.5.5-ubuntu-20.04-x86.tgz qt-6.5.5/
```

打包好的Qt环境，可以在任意的 Ubuntu20.04 的 x86_64 平台上运行，将该压缩包移动到任意目录，执行以下指令
```
sudo tar xf qt-6.5.5-ubuntu-20.04-x86.tgz
```

### 配置主机的  QtCreator，让其可以交叉编译 Qt 源码
https://embeddeduse.com/2020/04/13/docker-builds-from-qtcreator/