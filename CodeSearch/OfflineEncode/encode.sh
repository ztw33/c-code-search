#!/bin/bash
parserPath="GetSignature/parser"
if [ ! -x "$parserPath" ]; then
    echo "\033[34m====================生成parser====================\033[0m"
    cd GetSignature
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
python3 ./GenerateDriver/generateCode.py "$funcID"
if [ $? = 1 ]; then
    echo "\033[31m[CodeSearch: ERROR] 生成驱动代码时失败\033[0m"
    exit
fi
echo "\033[32m[CodeSearch: SUCCESS] 生成驱动代码成功\033[0m"


echo "\033[34m====================生成路径约束====================\033[0m"
for driverPath in `find ./Test/1_DriverCode/ -name "${funcID}_*.c"`
do
    filename=$(echo "$driverPath" | sed 's/.*\///' | sed 's/\.c//')
    bcPath=./Test/2_BCFile/"$filename".bc
    clang -I ~/Graguation_project/Library/klee/include/ -emit-llvm -c "$driverPath" -o "$bcPath"
    smtDir=Test/3_SMT/"$filename"
    if [ -d "$smtDir" ]; then
        rm -rf "$smtDir"
    fi
    funcName=$(echo "$filename" | sed "s/${funcID}\(_[0-9]\+\[[1-5]\]\)\?\(,[0-9]\+\[[1-5]\]\)*_//")
    klee --libc=uclibc --output-dir="$smtDir" --target-function-name="$funcName" --write-smt2s --max-tests=500 "$bcPath"
done
echo "\033[32m[CodeSearch: SUCCESS] 生成路径约束成功\033[0m"


echo "\033[34m====================路径约束入库====================\033[0m"
for smtDir in `find ./Test/3_SMT/ -name "${funcID}_*"`
do
    python3 ./PCToDB/pcToDB.py "$funcID" "$smtDir"
    if [ $? = 1 ]; then
        echo "\033[31m[CodeSearch: ERROR] 路径约束入库时失败\033[0m"
        exit
    fi
done
echo "\033[32m[CodeSearch: SUCCESS] 路径约束入库成功\033[0m"
