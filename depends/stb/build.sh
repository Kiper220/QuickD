#!/bin/bash
mkdir build
cd build
cmake ../
cmake --build .
mv libstb.a ../libstb.a
cd ..
rm -rf build
