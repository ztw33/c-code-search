#!/bin/bash
parserPath="getSignature/parser"
if [ ! -x "$parserPath" ]; then
    echo "\033[34m====================生成parser====================\033[0m"
    cd getSignature
    make parser
    cd ..
    echo "\033[32m[CodeSearch: SUCCESS] 生成parser成功\033[0m"
fi

if [ $# != 1 ]; then
    echo "\033[31m[CodeSearch: ERROR] 参数个数有误，请输入一个待处理的C文件路径\033[0m"
    exit
fi


echo "\033[34m====================提取函数签名====================\033[0m"
./"$parserPath" $1
funcID=$?
if [ "$funcID" = -1 ]; then
    echo "\033[31m[CodeSearch: ERROR] 提取函数签名时失败\033[0m"
    exit
fi
echo "\033[32m[CodeSearch: SUCCESS] 提取函数签名成功\033[0m"


echo "\033[34m====================生成驱动代码====================\033[0m"
python3 ./generateDriver/generateCode.py "$funcID"
echo "\033[32m[CodeSearch: SUCCESS] 生成驱动代码成功\033[0m"


driverPath="$(find ./Test/1_DriverCode/ -name "${funcID}_*.c")"
echo "\033[34m====================生成路径约束====================\033[0m"
filename=$(echo "$driverPath" | sed 's/.*\///' | sed 's/\.c//')
bcPath=./Test/2_SMT/"$filename".bc
clang -I ~/Graguation_project/Library/klee/include/ -emit-llvm -c "$driverPath" -o "$bcPath"
klee --output-dir=./Test/2_SMT/"$filename" --write-smt2s "$bcPath"
echo "\033[32m[CodeSearch: SUCCESS] 生成路径约束成功\033[0m"
