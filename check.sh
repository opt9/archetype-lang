#! /bin/bash

BIN=./src/_build/default/compiler.exe
NB_ERR="0"



for i in tests/*.cml; do
    printf '%-50s' $i
    $BIN $i > /dev/null 2> /dev/null
    RET=`echo $?`
    if [ ${RET} -eq 0 ]; then
	echo -e "\033[32m OK \033[0m"
    else
	echo -e "\033[31m KO \033[0m"
        NB_ERR=$((${NB_ERR} + 1))
    fi
done

if [ ${NB_ERR} -eq 0 ]; then
    echo "all cml files compile."
else
    echo -e "\033[31mErrors : ${NB_ERR} \033[0m"
fi