funcID=95
for driverPath in `find ./Test/1_DriverCode/ -name "${funcID}_*.c"`
do
    filename=$(echo "$driverPath" | sed 's/.*\///' | sed 's/\.c//')
    bcPath=./Test/2_BCFile/"$filename".bc
    clang -I ~/Graguation_project/Library/klee/include/ -emit-llvm -c "$driverPath" -o "$bcPath"
    smtDir=Test/3_SMT/"$filename"
    funcName=$(echo "$filename" | sed "s/${funcID}_[0-9]\+\(\[[1-5]\]_\)*//")
    klee --libc=uclibc --output-dir="$smtDir" --target-function-name="$funcName" --write-smt2s "$bcPath"
done