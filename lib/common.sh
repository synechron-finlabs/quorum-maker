dockerImage=syneblock/quorum-maker:2.0.2_2.1

RED=$'\e[1;31m'
GREEN=$'\e[1;32m'
YELLOW=$'\e[1;33m'
BLUE=$'\e[1;34m'
PINK=$'\e[1;35m'

COLOR_END=$'\e[0m'

function getInputWithDefault() {
    local msg=$1
    local __defaultValue=$2
    local __resultvar=$3
    local __clr=$4
    
    if [ -z "$__clr" ]; then

        __clr=$RED

    fi

    if [ -z "$__defaultValue" ]; then

       read -p $__clr"$msg: "$COLOR_END __newValue
    else
        read -p $__clr"$msg""[Default:"$__defaultValue"]:"$COLOR_END __newValue
    fi
    
    
    if [ -z "$__newValue" ]; then

        __newValue=$__defaultValue

    fi

    eval $__resultvar="'$__newValue'"
}

function updateProperty() {
    local file=$1
    local key=$2
    local value=$3
  
    if grep -q $key= $file; then        
        sed -i "s/$key=.*/$key=$value/g" $file
    else
        echo "" >> $file
        echo $key=$value >> $file
    fi
    sed -i '/^$/d' $file
}

function displayProgress(){
    local __TOTAL=$1
    local __CURRENT=$2

    let __PER=$__CURRENT*100/$__TOTAL
    
    local __PROG=""

    local __j=0
    while : ; do  

        if [ $__j -lt $__PER ]; then
            __PROG+="#"
        else
            __PROG+=" "
        fi

        if [ $__j -eq 100 ]; then
            break;
        fi
        let "__j+=2"
    done

    echo -ne ' ['${YELLOW}"${__PROG}"${COLOR_END}']'$GREEN'('$__PER'%)'${COLOR_END}'\r'

    if [ $__TOTAL -eq $__CURRENT ]; then
            echo ""
            break;
    fi

}

pushd () {
    command pushd "$@" > /dev/null
}

popd () {
    command popd "$@" > /dev/null
}
