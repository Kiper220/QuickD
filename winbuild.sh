dub build --build=release-nobounds --compiler=ldc --arch=x86_64-pc-windows-msvc && \
cd ./build && \
env /usr/bin/portproton ./quickd.exe
cd ..
