#/bin/bash
## BUILD SCRIPT ##
#limit datasize 1000M || ulimit -v 1048576 -u 1048576 -d 1048576 -s 1048576 || true

## should the image be pushed if only native build worked and buildx failed ?
ALLOW_SINGLE_ARCH_UPLOAD=NO
export ALLOW_SINGLE_ARCH_UPLOAD=NO

## quicken up settings ( in gitlab CI only  set REGISTRY_USER and REGISTRY_PASSWORD
PROJECT_NAME=hocker
export PROJECT_NAME=hocker

export CI_REGISTRY=docker.io
CI_REGISTRY=docker.io

export REGISTRY_HOST=docker.io
REGISTRY_HOST=docker.io

export REGISTRY_PROJECT=thefoundation
REGISTRY_PROJECT=thefoundation

#BUILD_TARGET_PLATFORMS="linux/amd64,linux/arm64,linux/arm/v7,darwin"
#BUILD_TARGET_PLATFORMS="linux/amd64,linux/arm64,linux/arm/v7"
BUILD_TARGET_PLATFORMS="linux/amd64,linux/arm64"

###MODE DECISION
## DEFAULT : one full image to save runner time
MODE=onefullimage
#MODE=featuresincreasing

## BUILD SINGLE LAYER IMAGE
MERGE_LAYERS=NO

#export DOCKER_BUILDKIT=1

_oneline() { tr -d '\n' ; } ;
_buildx_arch() { case "$(uname -m)" in aarch64) echo linux/arm64;; x86_64) echo linux/amd64 ;; armv7l|armv7*) echo linux/arm/v7;; armv6l|armv6*) echo linux/arm/v6;;  esac ; } ;

_reformat_docker_purge() { sed 's/^deleted: .\+:\([[:alnum:]].\{2\}\).\+\([[:alnum:]].\{2\}\)/\1..\2|/g;s/^\(.\)[[:alnum:]].\{61\}\(.\)/\1.\2|/g' |tr -d '\n' ; } ;

## Colors ;
uncolored="\033[0m" ; black="\033[0;30m" ; blackb="\033[1;30m" ; white="\033[0;37m" ; whiteb="\033[1;37m" ; red="\033[0;31m" ; redb="\033[1;31m" ; green="\033[0;32m" ; greenb="\033[1;93m" ; yellow="\033[0;33m" ; yellowb="\033[1;33m" ; blue="\033[0;34m" ; blueb="\033[1;34m" ; purple="\033[0;35m" ; purpleb="\033[1;35m" ; lightblue="\033[0;36m" ; lightblueb="\033[1;36m" ;  function black {   echo -en "${black}${1}${uncolored}" ; } ;    function blackb {   echo -en "${blackb}";cat;echo -en "${uncolored}" ; } ;   function white {   echo -en "${white}";cat;echo -en "${uncolored}" ; } ;   function whiteb {   echo -en "${whiteb}";cat;echo -en "${uncolored}" ; } ;   function red {   echo -en "${red}";cat;echo -en "${uncolored}" ; } ;   function redb {   echo -en "${redb}";cat;echo -en "${uncolored}" ; } ;   function green {   echo -en "${green}";cat;echo -en "${uncolored}" ; } ;   function greenb {   echo -en "${greenb}";cat;echo -en "${uncolored}" ; } ;   function yellow {   echo -en "${yellow}";cat;echo -en "${uncolored}" ; } ;   function yellowb {   echo -en "${yellowb}";cat;echo -en "${uncolored}" ; } ;   function blue {   echo -en "${blue}";cat;echo -en "${uncolored}" ; } ;   function blueb {   echo -en "${blueb}";cat;echo -en "${uncolored}" ; } ;   function purple {   echo -en "${purple}";cat;echo -en "${uncolored}" ; } ;   function purpleb {   echo -en "${purpleb}";cat;echo -en "${uncolored}" ; } ;   function lightblue {   echo -en "${lightblue}";cat;echo -en "${uncolored}" ; } ;   function lightblueb {   echo -en "${lightblueb}";cat;echo -en "${uncolored}" ; } ;  function echo_black {   echo -en "${black}${1}${uncolored}" ; } ; function echo_blackb {   echo -en "${blackb}${1}${uncolored}" ; } ;   function echo_white {   echo -en "${white}${1}${uncolored}" ; } ;   function echo_whiteb {   echo -en "${whiteb}${1}${uncolored}" ; } ;   function echo_red {   echo -en "${red}${1}${uncolored}" ; } ;   function echo_redb {   echo -en "${redb}${1}${uncolored}" ; } ;   function echo_green {   echo -en "${green}${1}${uncolored}" ; } ;   function echo_greenb {   echo -en "${greenb}${1}${uncolored}" ; } ;   function echo_yellow {   echo -en "${yellow}${1}${uncolored}" ; } ;   function echo_yellowb {   echo -en "${yellowb}${1}${uncolored}" ; } ;   function echo_blue {   echo -en "${blue}${1}${uncolored}" ; } ;   function echo_blueb {   echo -en "${blueb}${1}${uncolored}" ; } ;   function echo_purple {   echo -en "${purple}${1}${uncolored}" ; } ;   function echo_purpleb {   echo -en "${purpleb}${1}${uncolored}" ; } ;   function echo_lightblue {   echo -en "${lightblue}${1}${uncolored}" ; } ;   function echo_lightblueb {   echo -en "${lightblueb}${1}${uncolored}" ; } ;    function colors_list {   echo_black "black";   echo_blackb "blackb";   echo_white "white";   echo_whiteb "whiteb";   echo_red "red";   echo_redb "redb";   echo_green "green";   echo_greenb "greenb";   echo_yellow "yellow";   echo_yellowb "yellowb";   echo_blue "blue";   echo_blueb "blueb";   echo_purple "purple";   echo_purpleb "purpleb";   echo_lightblue "lightblue";   echo_lightblueb "lightblueb"; } ;

_clock() { echo -n WALLCLOCK : |redb ;echo  $( date -u "+%F %T" ) |yellow ; } ;

case $1 in
  php5|p5)  MODE="onefullimage" ;;
  php72|p72|php72_nomysql|p72_nomysql)  MODE="featuresincreasing" ;;
  php74|p74|php74_nomysql|p74_nomysql)  MODE="featuresincreasing" ;;
  rest|aux) MODE="onefullimage" ;;
  ""  )     MODE="featuresincreasing" ;;  ## empty , build all
  **  )     MODE="featuresincreasing" ;;  ## out of range , build all

esac
##

buildargs="";
echo -n "::SYS:PREP"|yellow

if [ "$(date -u +%s)" -ge  "$(($(cat /tmp/.dockerbuildenvlastsysupgrade|sed 's/^$/0/g')+3600))" ] ;then
  echo -n "+↑UPGR↑+|"|blue
  which apt-get 2>/dev/null |grep -q apt-get && apt-get update &>/dev/null || true
  which apk     2>/dev/null |grep -q apk  && apk update &>/dev/null  || true
  echo -n "+↑PROG↑+|"|yellow
  ##alpine
  which git 2>/dev/null |grep -q git || which apk       2>/dev/null |grep -q apk && apk add git util-linux bash && apk add jq || true
  which apk       2>/dev/null |grep -q apk && apk add git util-linux bash qemu-aarch64 qemu-x86_64 qemu-i386 qemu-arm || true
  ##deb
  (which git 2>/dev/null |grep -q git || which apt-get   2>/dev/null |grep -q "/apt-get" && apt-get install -y git bash && apt-get -y install jq || true ) | red
  which apt-get   2>/dev/null |grep -q apt-get && ( apt-get install -y binfmt-support 2>&1|| true ) |blue
  ( which apt-get   2>/dev/null |grep -q "/apt-get" && ( dpkg --get-selections|grep -v deinst|grep -e qemu-user-stat -e qemu-user-binfmt  ) | grep -q -e qemu-user-stat -e  qemu-user-binfmt || apt-get install -y  qemu-user-static || apt-get install -y  qemu-user-binfmt || true ) |blue
( echo -n ":REG_LOGIN[test:init]:" |blue; sleep $(($RANDOM%2));sleep $(($RANDOM%3));docker login  -u ${REGISTRY_USER} -p ${REGISTRY_PASSWORD} ${REGISTRY_HOST} 2>&1 || exit 666 ; docker logout 2>&1  ) |grep -i -v warning |blue  | _oneline
else
  echo " → no upgr (1h threshold)→"|green
fi
echo $(date -u +%s) > /tmp/.dockerbuildenvlastsysupgrade

startdir=$(pwd)
mkdir buildlogs || mv buildlogs/*log /tmp/ || true
echo -n "::GIT"|red|whiteb
/bin/sh -c "test -d Hocker || git clone https://github.com/TheFoundation/Hocker.git --recurse-submodules && (cd Hocker ;git pull origin master --recurse-submodules )"|green|whiteb
cd Hocker/build/
## end head prep stage
####


_build_docker_buildx() {
        cd ${startdir}
        PROJECT_NAME=hocker
        export PROJECT_NAME=hocker
        pwd |green
        echo -n ":REG_LOGIN[buildx]:"|blue;( docker login  -u ${REGISTRY_USER} -p ${REGISTRY_PASSWORD} ${REGISTRY_HOST} 2>&1  || true |grep -v -i -e assword -e  redential| _oneline ) ; (docker logout 2>&1 | grep emoving)| _oneline 
        which apk |grep "/apk" -q && apk add git bash
        #export DOCKER_BUILDKIT=1
        git clone git://github.com/docker/buildx ./docker-buildx
        ##  --platform=local needs experimental docker scope
        /bin/bash -c "docker pull  ${REGISTRY_PROJECT}/${PROJECT_NAME}:buildhelper_buildx || true " 2>/dev/null
        docker pull  ${REGISTRY_PROJECT}/${PROJECT_NAME}:buildhelper_buildx || true | _oneline
        docker build -t ${REGISTRY_PROJECT}/${PROJECT_NAME}:buildhelper_buildx ./docker-buildx
        docker image ls|blue |_oneline
        echo -n ":REG_LOGIN[push]:"
        docker login  -u ${REGISTRY_USER} -p ${REGISTRY_PASSWORD} ${REGISTRY_HOST} |blue |grep -v -i "edential helper" |_oneline
        echo -n ":DOCKER:PUSH@"${REGISTRY_PROJECT}/${PROJECT_NAME}:buildhelper_buildx":"
        (docker push ${REGISTRY_PROJECT}/${PROJECT_NAME}:buildhelper_buildx |grep -v -e Waiting$ -e Preparing$ -e "Layer already exists$";docker logout 2>&1 | _oneline |grep -v -e emov -e redential)  |sed 's/$/ →→ /g;s/Pushed/+/g' |tr -d '\n'
        docker build -o . ./docker-buildx
        echo "after build"|blue
        pwd;ls
        test -f buildx && mkdir -p ~/.docker/cli-plugins/ && cp buildx ~/.docker/cli-plugins/docker-buildx && chmod +x ~/.docker/cli-plugins/docker-buildx
    echo ; } ;


_docker_pull_multiarch() {  PULLTAG="$1"; echo -n "↓↓PULL(multiarch)→→"|green
    for curtag in ${PULLTAG} $(DOCKER_CLI_EXPERIMENTAL=enabled  docker buildx imagetools inspect "${PULLTAG}" 2>&1 |grep Name|cut -d: -f2- |sed 's/ //g'|grep @) ;do
    
        echo -n "docker pull   ${curtag} | :: |" | blue
        (docker pull  ${curtag} 2>&1 || true ) |grep -v -e Verifying -e Download|grep -v -i helper |sed 's/Pull.\+/↓/g'|sed 's/\(Waiting\|Checksum\|exists\|complete\|fs layer\)$/→/g'|_oneline

    done
    echo -n ; }  ;

_docker_push() {
    ##docker buildx 2>&1 |grep -q "imagetools" || ( )
    IMAGETAG_SHORT=$1
    export DOCKER_BUILDKIT=0

    echo -n "↑↑↑UPLOAD↑↑↑ "|yellow;_clock
    docker image ls|blue
    echo -n ":REG_LOGIN[push]:"
    sleep $(($RANDOM%2));sleep  $(($RANDOM%3));docker login  -u ${REGISTRY_USER} -p ${REGISTRY_PASSWORD} ${REGISTRY_HOST}
    echo -n ":DOCKER:PUSH@"${REGISTRY_PROJECT}/${PROJECT_NAME}:${IMAGETAG_SHORT}":"|blue
    (docker push ${REGISTRY_PROJECT}/${PROJECT_NAME}:${IMAGETAG_SHORT} |grep -v -e Waiting$ -e Preparing$ -e "Layer already exists$";docker logout 2>&1 | _oneline)  |sed 's/$/ →→ /g;s/Pushed/+/g' |tr -d '\n'|yellow
    echo -n "|" ; } ;
_docker_build() {
        echo  "::builder::main( $@ ) ";_clock
        buildstring="" ## rebuilt from features
        IMAGETAG_SHORT="$1"
        IMAGETAG="$2"
        DFILENAME="$3"
        #MYFEATURESET="$4"
        MYBUILDSTRING=$(echo -n "$4"  |base64 -d | _oneline)
        TARGETARCH="$5"
        ## CALLED WITHOUT FIFTH ARGUMENT , BUILD ONLY NATIVE
        echo $TARGETARCH|tr -d '\n'|wc -c |grep -q ^0$ && TARGETARCH=$(_buildx_arch)
        TARGETARCH_NOSLASH=${TARGETARCH//\//_};
        TARGETARCH_NOSLASH=${TARGETARCH_NOSLASH//,/_}
    ##### DETECT APT PROXY        
        echo -n ":searching proxy..."|red
        ### if somebody/someone/(CI)  was so nice and set up an docker-container named "apt-cacher-ng" which uses standard exposed port 3142 , use it
        #if echo $(docker inspect --format='{{(index (index .NetworkSettings.Ports "3142/tcp") 0).HostPort}}' apt-cacher-ng || true ) |grep "3142"  ; then
    ## APT CACHE DOCKER
        if echo $(docker ps -a |grep apt-cacher-ng)|grep "3142/tcp";then
            if [ "${CI_COMMIT_SHA}" = "00000000" ] ; then ### fails on gitlab-runners 
          BUILDER_APT_HTTP_PROXY_LINE='http://'$( docker inspect --format='{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' apt-cacher-ng |head -n1)':3142/' ;fi
        fi
        if [ "x" = "x${BUILDER_APT_HTTP_PROXY_LINE}" ] ; then
            echo "==NO OVERRIDE APT PROXYSET"
        else
            echo "==USING APT PROXY STRING:"${BUILDER_APT_HTTP_PROXY_LINE} ; buildstring='--build-arg APT_HTTP_PROXY_URL='${BUILDER_APT_HTTP_PROXY_LINE}' '; 
        fi
    #APT CACHE IN /etc/
        if $( test -d /etc/apt/  &&  grep ^Acquire::http::Proxy /etc/apt/ -rlq) ;then  echo -n "have proxy:";
                proxystring=$(grep ^Acquire::http::Proxy /etc/apt/ -r|cut -d: -f2-|sed 's/Acquire::http::Proxy//g;s/ //g;s/\t//g;s/"//g;s/'"'"'//g;s/;//g');
                buildstring='--build-arg APT_HTTP_PROXY_URL='${proxystring}; 
        else
            echo "NO SYSTEM APT PROXY FOUND" ;
        fi
        buildstring=${MYBUILDSTRING}" "${buildstring}
        start=$(date -u +%s)
        ## NO BUILDX ,use standard instructions
        DOCKER_BUILDKIT=0
        echo;_clock
        echo -n "TAG: $IMAGETAG | BUILD: $buildstring | PULLING ${REGISTRY_PROJECT}/${PROJECT_NAME}:${IMAGETAG_SHORT} IF NOT FOUND | "|yellow
        _docker_pull_multiarch ${REGISTRY_PROJECT}/${PROJECT_NAME}:${IMAGETAG_SHORT}
        _docker_pull_multiarch $(cat ${DFILENAME}|grep ^FROM|sed 's/^FROM//g' |cut -d" " f1 |cut -f1)
        echo;_clock


        #buildstring=$buildstring" "$(echo $MYEATURESET|sed 's/@/=true --build-arg /g'|sed 's/ --build-arg//g;s/^/ --build-arg /g'|sed 's/^ --build-arg $//g' |_oneline);
        echo -n "→FEATURES  : "|blue;echo -n "${MYBUILDSTRING}";
        echo -n "→BUILD ARGS: "|blue;echo $buildstring
        _clock
        native_build_failed=yes
        buildx_failed=no
        ## BUILDX does not support squash
        #if [ "${MERGE_LAYERS}" = "YES" ] ; then
        #        buildstring=${buildstring}" --squash "
        #fi

        ## HAVING BUILDX , builder should escalate for stack e.g. armV7 / aarch64 / amd64
            if $(docker buildx 2>&1 |grep -q "imagetools") ;then
                echo " TRYING MULTIARCH ";
                #echo ${have_buildx} |grep -q =true$ &&  docker buildx create --buildkitd-flags '--allow-insecure-entitlement network.host' --driver-opt network=host --driver docker-container --use --name mybuilder ; echo ${have_buildx} |grep -q =true$ &&  docker buildx create --use --name mybuilder; echo ${have_buildx} |grep -q =true$ &&  docker buildx create --append --name mybuilder --platform=linux/aarch64 rpi4
                # --driver docker-container --driver-opt network=host 
                echo RECREATING  buildx HELPER
                (echo -n buildx:rm: ;
                docker buildx rm mybuilder|red | _oneline ; 
                echo -n buildx:create: ;
                docker buildx create  --buildkitd-flags '--allow-insecure-entitlement network.host' --use --driver-opt network=host  --name mybuilder 2>&1 | blueb | _oneline ;
                docker buildx inspect --bootstrap 2>&1 |redb ) # | yellow|_oneline|grep -A4 -B4  ${TARGETARCH} && arch_ok=yes
                arch_ok=yes 
                if [ "$arch_ok" = "yes" ] ;then echo "arch_ok" for $TARGETARCH
                ## RANDOMIZE LOGIN TIME ; SO MULTIPLE RUNNERS DON't TRIGGER POSSIBLE BOT/DDOS-PREVENTION SCRIPTS
                sleep $(($RANDOM%2));sleep  $(($RANDOM%3));docker login  -u ${REGISTRY_USER} -p ${REGISTRY_PASSWORD} ${REGISTRY_HOST} 2>&1 |grep -v  "WARN" | blue |_oneline ;echo
                echo -ne "d0ck³r buildX , running the following command ( first to daemon , then Registry):"|yellow|blueb;echo -ne "\e[1;31m"
                echo docker buildx build  --output=type=image                      --pull --progress plain --network=host --memory-swap -1 --memory 1024 --platform=${TARGETARCH} --cache-from ${REGISTRY_PROJECT}/${PROJECT_NAME}:${IMAGETAG_SHORT} -t  ${REGISTRY_PROJECT}/${PROJECT_NAME}:${IMAGETAG_SHORT} $buildstring -f "${DFILENAME}"  . | yellowb
                echo -e "\e[0m\e[1;42m STDOUT and STDERR goes to: "${startdir}/buildlogs/build-${IMAGETAG}.${TARGETARCH_NOSLASH}".buildx.log \e[0m"
                ##docker buildx build --platform=linux/amd64,linux/arm64,linux/arm/v7,darwin --cache-from ${REGISTRY_PROJECT}/${PROJECT_NAME}:${IMAGETAG_SHORT} -t  ${REGISTRY_PROJECT}/${PROJECT_NAME}:${IMAGETAG_SHORT} -o type=registry $buildstring -f "${DFILENAME}"  .  &> ${startdir}/buildlogs/build-${IMAGETAG}.${TARGETARCH_NOSLASH}".log"
                #docker buildx build  --pull --progress plain --platform=linux/amd64,linux/arm64,linux/arm/v7 --cache-from ${REGISTRY_PROJECT}/${PROJECT_NAME}:${IMAGETAG_SHORT} -t ${REGISTRY_PROJECT}/${PROJECT_NAME}:${IMAGETAG_SHORT} -o type=local,dest=./dockeroutput $buildstring -f "${DFILENAME}"  .  &> ${startdir}/buildlogs/build-${IMAGETAG}.${TARGETARCH_NOSLASH}".log"
                #--cache-from type=local,src=/root/buildcache/ --cache-to type=local,dest=/root/buildcache/ 
## :MAIN: BUILDX RUN
            echo "::BUILDX:2reg"   | tee -a ${startdir}/buildlogs/build-${IMAGETAG}.${TARGETARCH_NOSLASH}".buildx.log"
                time docker buildx build  --output=type=registry,push=true  --push  --pull --progress plain --network=host --memory-swap -1 --memory 1024 --platform=${TARGETARCH} --cache-from ${REGISTRY_PROJECT}/${PROJECT_NAME}:${IMAGETAG_SHORT} -t  ${REGISTRY_PROJECT}/${PROJECT_NAME}:${IMAGETAG_SHORT} $buildstring -f "${DFILENAME}"  .  2>&1 |tee  -a ${startdir}/buildlogs/build-${IMAGETAG}.${TARGETARCH_NOSLASH}".buildx.log"|grep -e CACHED -e ^$ -e '\[linux/' -e '[0-9]\]' -e 'internal]' -e DONE -e fail -e error -e Error -e ERROR |awk '!x[$0]++'|green

            echo "::BUILDX:2daemon"| tee -a ${startdir}/buildlogs/build-${IMAGETAG}.${TARGETARCH_NOSLASH}".buildx.log"
                time docker buildx build  --output=type=image                      --pull --progress plain --network=host --memory-swap -1 --memory 1024 --platform=${TARGETARCH} --cache-to=type=inline  --cache-from ${REGISTRY_PROJECT}/${PROJECT_NAME}:${IMAGETAG_SHORT} -t  ${REGISTRY_PROJECT}/${PROJECT_NAME}:${IMAGETAG_SHORT}  $buildstring -f "${DFILENAME}"  .  2>&1 |tee -a ${startdir}/buildlogs/build-${IMAGETAG}.${TARGETARCH_NOSLASH}".buildx.log" |grep -e CACHED -e ^$ -e '\[linux/' -e '[0-9]\]' -e 'internal]' -e DONE -e fail -e error -e Error -e ERROR|awk '!x[$0]++'|green

            echo -n ":past:buildx"|green|whiteb;tail -n6 ${startdir}/buildlogs/build-${IMAGETAG}.${TARGETARCH_NOSLASH}".buildx.log"|grep -v "exporting config sha256" |yellow
            fi # end if buildx has TARGETARCH
        fi # end if buildx

        _clock
        if $( grep -q -e "failed to solve" -e "no builder.*found" -e 'code = Unknown desc = executor failed running' -e "runc did not terminate successfully" -e "multiple platforms feature is currently not supported for docker drive"  ${startdir}/buildlogs/build-${IMAGETAG}.${TARGETARCH_NOSLASH}".buildx.log" 2>/dev/null );then
            echo -n "::build:catch:BUILDX FAILED grep statemnt:"|red;echo "log:"|blue
            tail -n 80  ${startdir}/buildlogs/build-${IMAGETAG}.${TARGETARCH_NOSLASH}".buildx.log" 
### docker build native start
        ##  "buildx docker failure" > possible errors often arise from missing qemu / buildkit runs only on x86_64 ( 2020 Q1 ) 
        echo "BUILDING NATIVE SINCE BUILDX FAILED --   DOING MY ARCHITECURE ONLY"
        if $(echo ${TARGETARCH}|grep -q $(_buildx_arch) );then ## native build only works on current arch
            ## DO WE HAVE BUILDX
            if $(docker buildx 2>&1 |grep -q "imagetools" ) ;then  
                echo -n "::build::x" ;
                echo -ne "d0ck³r buildX , running the following command ( to daemon):"|yellow|blueb;echo -ne "\e[1;31m"
                docker pull ${REGISTRY_PROJECT}/${PROJECT_NAME}:${IMAGETAG_SHORT}  2>&1  | _oneline
                echo docker buildx build  --output=type=image --pull --progress plain --network=host --memory-swap -1 --memory 1024 --platform=$(_buildx_arch) --cache-to=type=inline  --cache-from ${REGISTRY_PROJECT}/${PROJECT_NAME}:${IMAGETAG_SHORT} -t  ${REGISTRY_PROJECT}/${PROJECT_NAME}:${IMAGETAG_SHORT} $buildstring -f "${DFILENAME}"  . | yellowb
                echo -e "\e[0m\e[1;42m STDOUT and STDERR goes to: "${startdir}/buildlogs/build-${IMAGETAG}.${TARGETARCH_NOSLASH}".native.log \e[0m"
## :NATIVE: BUILDX RUN
        _clock
        echo "::BUILDX:native:2daemon"| tee -a ${startdir}/buildlogs/build-${IMAGETAG}.${TARGETARCH_NOSLASH}".native.log"
            time docker buildx build  --output=type=image                     --pull --progress plain --network=host --memory-swap -1 --memory 1024 --platform=$(_buildx_arch) --cache-to=type=inline   --cache-from ${REGISTRY_PROJECT}/${PROJECT_NAME}:${IMAGETAG_SHORT} -t  ${REGISTRY_PROJECT}/${PROJECT_NAME}:${IMAGETAG_SHORT}  $buildstring -f "${DFILENAME}"  .  2>&1 |tee -a ${startdir}/buildlogs/build-${IMAGETAG}.${TARGETARCH_NOSLASH}".native.log" |awk '!x[$0]++'|green
            else
                echo -n "::build: NO buildx: "; do_native_build=yes;
                echo "::build: DOING MY ARCHITECURE ONLY ";_buildx_arch
                echo -ne "DOCKER bUILD(native), running the following command: \e[1;31m"
                export DOCKER_BUILDKIT=0
                echo docker build --cache-from ${REGISTRY_PROJECT}/${PROJECT_NAME}:${IMAGETAG_SHORT} -t hocker:${IMAGETAG_SHORT} $buildstring -f "${DFILENAME}" --rm=false -t ${REGISTRY_PROJECT}/${PROJECT_NAME}:${IMAGETAG_SHORT} .
                echo -e "\e[0m\e[1;42m STDOUT and STDERR goes to:" ${startdir}/buildlogs/build-${IMAGETAG}.${TARGETARCH_NOSLASH}".log"
                DOCKER_BUILDKIT=0 time docker build --cache-from ${REGISTRY_PROJECT}/${PROJECT_NAME}:${IMAGETAG_SHORT} -t hocker:${IMAGETAG_SHORT} $buildstring -f "${DFILENAME}" --rm=false -t ${REGISTRY_PROJECT}/${PROJECT_NAME}:${IMAGETAG_SHORT} . 2>&1 |tee -a ${startdir}/buildlogs/build-${IMAGETAG}.${TARGETARCH_NOSLASH}".native.log" |awk '!x[$0]++'|green 
                echo -n "VERIFYING NATIVE BUILD";docker image ls|blue
                grep -i -e "uccessfully built " -e  "writing image" -e "exporting layers"  -e "exporting config" ${startdir}/buildlogs/build-${IMAGETAG}.${TARGETARCH_NOSLASH}".native.log" && native_build_failed=no
                #if [ "${native_build_failed}" = "no" ] ; then echo OK ;else echo NATIVE BUILD FAILED ; exit 333 ;fi
        
                ###PUSH ONLY NATIVE ARCH IF ALLOW_SINGLE_ARCH_UPLOAD is YES
                if [ "${ALLOW_SINGLE_ARCH_UPLOAD}" = "YES" ] ; then 
                    echo -n "::PUSH::NATIVE_ARCH"|yellow
                    tail -n 10 ${startdir}/buildlogs/build-${IMAGETAG}.${TARGETARCH_NOSLASH}".native.log"| grep -q -e "uccessfully built " -e DONE -e "exporting config" && _docker_push ${IMAGETAG_SHORT} 
                fi # allow single arch
            fi ##if buildx present else 
            
        fi ## if buildx arch
        _clock

        fi ##buildx failed
        echo "::build:creating merged log"|green
        cat ${startdir}/buildlogs/build-${IMAGETAG}.${TARGETARCH_NOSLASH}".native.log" >  ${startdir}/buildlogs/build-${IMAGETAG}.${TARGETARCH_NOSLASH}".log" && rm ${startdir}/buildlogs/build-${IMAGETAG}.${TARGETARCH_NOSLASH}".native.log"
        test -f ${startdir}/buildlogs/build-${IMAGETAG}.${TARGETARCH_NOSLASH}".buildx.log" && cat  ${startdir}/buildlogs/build-${IMAGETAG}.${TARGETARCH_NOSLASH}".buildx.log" > ${startdir}/buildlogs/build-${IMAGETAG}.${TARGETARCH_NOSLASH}".log" && rm ${startdir}/buildlogs/build-${IMAGETAG}.${TARGETARCH_NOSLASH}".buildx.log"
        ## see here https://github.com/docker/buildx
        ##END BUILD STAGE
        _clock
        echo -n "|" ;
        test -f ${startdir}/buildlogs/build-${IMAGETAG}.${TARGETARCH_NOSLASH}".log" && echo there is a log in ${startdir}/buildlogs/build-${IMAGETAG}.${TARGETARCH_NOSLASH}".log"
        echo -n "|::END BUILDER::|" ;_clock
        tail -n 10 ${startdir}/buildlogs/build-${IMAGETAG}.${TARGETARCH_NOSLASH}".log" 2>/dev/null| grep -i -e "failed" -e "did not terminate sucessfully" -q || return 0 && return 23 ; } ;
## END docker_build


_docker_rm_buildimage() { docker image rm ${REGISTRY_PROJECT}/${PROJECT_NAME}:${1} ${PROJECT_NAME}:${1}  2>&1 | grep -v "Untagged"| _reformat_docker_purge |_oneline ; } ;
#####################################
_docker_purge() {
    IMAGETAG_SHORT=$1
    echo;echo -n "::.oO0 PURGE 0Oo.::"
     ( docker image rm ${REGISTRY_PROJECT}/${PROJECT_NAME}:${IMAGETAG_SHORT} hocker:${IMAGETAG_SHORT}  2>&1 | grep -v "Untagged"| _reformat_docker_purge
    docker image prune -a -f  --filter 'label!=qemu*' 2>&1  | _reformat_docker_purge|red
    echo -n "→→→";
    docker system prune -a -f --filter 'label!=qemu*' 2>&1 | _reformat_docker_purge |red ) | _oneline
    echo ;echo "::IMG:"|blue
    docker image ls |tail -n+2 |sed 's/$/|/g'|tr -d '\n'|yellow
    #docker logout 2>&1 | _oneline
    echo -n "|" ; } ;
#####################################
_run_buildwheel() { ## ARG1 Dockerfile-name ## ARG2 Empty or NOMYSQL
runbuildfail=0
DFILENAME=$1
## Prepare env
#   test -f ${DFILENAME} && ( cat  ${DFILENAME} > Dockerfile.current ) || (echo "Dockerfile not found";break)
if $(test -f ${DFILENAME});then echo -n ;else   echo "Dockerfile not found";break;fi

SHORTALIAS=$(basename $(readlink -f ${DFILENAME}))



## for current_target in ${BUILD_TARGET_PLATFORMS//,/ };do

for current_target in ${BUILD_TARGET_PLATFORMS};do

TARGETARCH_NOSLASH=${current_target//\//_};
TARGETARCH_NOSLASH=${TARGETARCH_NOSLASH//,/_}
echo "::BUILD:PLATFORM:"$current_target"::AIMING..."|red
FEATURESET_MINI_NOMYSQL=$(echo -n|cat ${DFILENAME}|grep -v -e MYSQL -e mysql -e MARIADB -e mariadb|grep ^ARG|grep =true|sed 's/ARG \+//g;s/ //'|cut -d= -f1 |awk '!x[$0]++' |grep INSTALL|sed 's/$/@/g'|tr -d '\n' )
FEATURESET_MINI=$(echo -n|cat ${DFILENAME}|grep ^ARG|grep =true|sed 's/ARG \+//g;s/ //'|cut -d= -f1 |awk '!x[$0]++' |grep INSTALL|sed 's/$/@/g'|tr -d '\n' )
FEATURESET_MAXI=$(echo -n|cat ${DFILENAME}|grep ^ARG|grep =    |sed 's/ARG \+//g;s/ //'|cut -d= -f1 |awk '!x[$0]++' |grep INSTALL|sed 's/$/@/g'|tr -d '\n' )
FEATURESET_MAXI_NOMYSQL=$(echo -n|cat ${DFILENAME}|grep -v -e MYSQL -e mysql -e MARIADB -e mariadb|grep ^ARG|grep =|sed 's/ARG \+//g;s/ //'|cut -d= -f1 |awk '!x[$0]++' |grep INSTALL|sed 's/$/@/g'|tr -d '\n' )

echo "BUILDMODE:" $MODE

## +++ begin build stage ++++
if [[ "$MODE" == "featuresincreasing" ]];then  ## BUILD 2 versions , a minimal default packages (INSTALL_WHATEVER=true) and a full image     ## IN ORDER OF APPEARANCE in Dockerfile

echo "featuresinc"
## 1 mini
##remove INSTALL_part from FEATURESET so all features underscore separated comes up
if [[ "$2" == "NOMYSQL"  ]];then
echo "NOMYSQL"
###1.1 mini nomysql ####CHECK IF DOCKERFILE OFFERS MARIADB  |
    if [ 0 -lt  "$(cat ${DFILENAME}|grep INSTALL_MARIADB|wc -l)" ];then
        echo "MARIADB FOUND IN DOCKERFILE 1.1 @ ${current_target}"
        FEATURESET=${FEATURESET_MINI_NOMYSQL}
        buildstring=$(echo ${FEATURESET} |sed 's/@/\n/g' | grep -v ^$ | sed 's/ \+$//g;s/^/--build-arg /g;s/$/=true /g'|grep -v MARIADB|_oneline)" --build-arg INSTALL_MARIADB=false ";
        #tagstring=$(echo "${FEATURESET}"|cut -d_ -f2 |cut -d= -f1 |awk '{print tolower($0)}') ;
        tagstring=""
        cleantags=""
        #cleantags=$(echo "$tagstring"|sed 's/@/_/g'|sed 's/^_//g;s/_\+/_/g') | _oneline
        IMAGETAG=$(echo ${DFILENAME}|sed 's/Dockerfile-//g' |awk '{print tolower($0)}')"-"$cleantags"_"$(date -u +%Y-%m-%d_%H.%M)"_"$(echo $CI_COMMIT_SHA|head -c8);
        IMAGETAG=$(echo "$IMAGETAG"|sed 's/_\+/_/g;s/_$//g');IMAGETAG=${IMAGETAG/-_/_};IMAGETAG_SHORT=${IMAGETAG/_*/}
        IMAGETAG=${IMAGETAG}_NOMYSQL
        IMAGETAG_SHORT=${IMAGETAG_SHORT}_NOMYSQL
        #### since softlinks are eg Dockerfile-php7-bla → Dockerfile-php7.4-bla
        #### we pull also the "dotted" version" before , since they will have exactly the same steps and our "undotted" version does not exist
        SHORTALIAS=$(echo "${SHORTALIAS}"|sed 's/Dockerfile//g;s/^-//g')
        build_success=no;start=$(date -u +%s)
        seconds=$((end-start))
        echo -en "\e[1:42m";
        TZ=UTC printf "1.1 FINISHED: %d days %(%H hours %M minutes %S seconds)T\n" $((seconds/86400)) $seconds | tee -a ${startdir}/buildlogs/build-${IMAGETAG}.${TARGETARCH_NOSLASH}".log"
        build64=" "$(echo $buildstring|base64 | _oneline)" "; _docker_build ${IMAGETAG_SHORT} ${IMAGETAG}  ${DFILENAME} ${build64} ${current_target}
        end=$(date -u +%s)
        seconds=$((end-start))
        echo -en "\e[1:42m";
        TZ=UTC printf "1.2 FINISHED: %d days %(%H hours %M minutes %S seconds)T\n" $((seconds/86400)) $seconds | tee -a ${startdir}/buildlogs/build-${IMAGETAG}.${TARGETARCH_NOSLASH}".log"
        echo "VERIFY BUILDx LOG: "${startdir}/buildlogs/build-${IMAGETAG}.${TARGETARCH_NOSLASH}".log" 
        if $(grep -q -e "uccessfully built" -e DONE -e "pushing layers" -e done -e "exporting manifest list" ${startdir}/buildlogs/build-${IMAGETAG}.${TARGETARCH_NOSLASH}".log") ;then 
            build_success=yes ;
        else
            runbuildfail=$((${runbuildfail}+100)) 
        fi
        
        if [ "$build_success" = "yes" ];then
            echo "BUILD SUCESSFUL(acccording to logs)"|green
        else
            echo BUILD FAILED ;tail -n 13 ${startdir}/buildlogs/build-${IMAGETAG}.${TARGETARCH_NOSLASH}".log" ;runbuildfail=$(($runbuildfail+100))
        fi
        _docker_rm_buildimage ${IMAGETAG_SHORT} 2>/dev/null | _oneline || true   
    fi
else ## NOMYSQL

###1.2 mini mysql
      echo "1.2"
      FEATURESET=${FEATURESET_MINI}
      buildstring=$(echo ${FEATURESET} |sed 's/@/\n/g' | grep -v ^$ | sed 's/ \+$//g;s/^/--build-arg /g;s/$/=true /g'|grep -v MARIADB|_oneline)" --build-arg INSTALL_MARIADB=true ";
      tagstring="" ; ## nothing , aka "the standard"
      #cleantags=$(echo "$tagstring"|sed 's/@/_/g'|sed 's/^_//g;s/_\+/_/g') | _oneline
      cleantags=""
      IMAGETAG=$(echo ${DFILENAME}|sed 's/Dockerfile-//g' |awk '{print tolower($0)}')"-"$cleantags"_"$(date -u +%Y-%m-%d_%H.%M)"_"$(echo $CI_COMMIT_SHA|head -c8);
      IMAGETAG=$(echo "$IMAGETAG"|sed 's/_\+/_/g;s/_$//g');IMAGETAG=${IMAGETAG/-_/_};IMAGETAG_SHORT=${IMAGETAG/_*/}
      IMAGETAG_SHORT=${IMAGETAG_SHORT}
      #### since softlinks are eg Dockerfile-php7-bla → Dockerfile-php7.4-bla
      #### we pull also the "dotted" version" before , since they will have exactly the same steps and our "undotted" version does not exist
      SHORTALIAS=$(echo "${SHORTALIAS}"|sed 's/Dockerfile//g;s/^-//g')
      build_success=no;start=$(date -u +%s)
       build64=" "$(echo $buildstring|base64 | _oneline)" "; _docker_build ${IMAGETAG_SHORT} ${IMAGETAG}  ${DFILENAME} ${build64} ${current_target}
      end=$(date -u +%s)
      seconds=$((end-start))
      echo -en "\e[1:42m";
      TZ=UTC printf "1.2 FINISHED: %d days %(%H hours %M minutes %S seconds)T\n" $((seconds/86400)) $seconds | tee -a ${startdir}/buildlogs/build-${IMAGETAG}.${TARGETARCH_NOSLASH}".log"
      echo "VERIFY BUILD LOG: "${startdir}/buildlogs/build-${IMAGETAG}.${TARGETARCH_NOSLASH}".log" 
      if $(grep -q -e "uccessfully built" -e "pushing layers" -e done -e "exporting manifest list" ${startdir}/buildlogs/build-${IMAGETAG}.${TARGETARCH_NOSLASH}".log") ;then 
          build_success=yes ;
      else
          runbuildfail=$((${runbuildfail}+100)) 
      fi
        if [ "$build_success" = "yes" ];then
            echo "BUILD SUCESSFUL(acccording to logs)"|green
        else
          echo BUILD FAILED ;tail -n 13 ${startdir}/buildlogs/build-${IMAGETAG}.${TARGETARCH_NOSLASH}".log" ;runbuildfail=$(($runbuildfail+100))
        fi
        _docker_rm_buildimage ${IMAGETAG_SHORT} 2>/dev/null | _oneline || true   

fi ## END IF NOMYSQL


fi # end if MODE=featuresincreasing



## maxi build gets triggered on featuresincreasing and onefullimage
##remove INSTALL_part from FEATURESET so all features underscore separated comes up
tagstring=$(echo "${FEATURES}"|cut -d_ -f2 |cut -d= -f1 |awk '{print tolower($0)}') ;
cleantags=$(echo "$tagstring"|sed 's/^_//g;s/_\+/_/g')
if $(echo $MODE|grep -q -e featuresincreasing -e onefullimage) ; then
echo -n "FULL"
if [[ "$2" == "NOMYSQL"  ]];then
echo "NOMYSQL"
###2.1 maxi nomysql
    if [ 0 -lt  "$(cat ${DFILENAME}|grep INSTALL_MARIADB|wc -l)" ];then
          echo "MARIADB FOUND IN DOCKERFILE 2.1"
        FEATURESET=${FEATURESET_MAXI_NOMYSQL}
        buildstring=$(echo ${FEATURESET} |sed 's/@/\n/g' | grep -v ^$ | sed 's/ \+$//g;s/^/--build-arg /g;s/$/=true /g'|grep -v MARIADB|_oneline)" --build-arg INSTALL_MARIADB=false ";
        tagstring=$(echo "${FEATURESET}"|sed 's/@/\n/g'|cut -d_ -f2 |cut -d= -f1 |sed 's/$/_/g'|awk '{print tolower($0)}' | _oneline |sed 's/_\+$//g') ;
        cleantags=$(echo "$tagstring"|sed 's/@/_/g'|sed 's/^_//g;s/_\+/_/g'|sed 's/_/-/g' | _oneline)
        IMAGETAG=$(echo ${DFILENAME}|sed 's/Dockerfile-//g' |awk '{print tolower($0)}')"-"$cleantags"_"$(date -u +%Y-%m-%d_%H.%M)"_"$(echo $CI_COMMIT_SHA|head -c8);
        IMAGETAG=$(echo "$IMAGETAG"|sed 's/_\+/_/g;s/_$//g');IMAGETAG=${IMAGETAG/-_/_};IMAGETAG_SHORT=${IMAGETAG/_*/}
        IMAGETAG=${IMAGETAG}_NOMYSQL
        IMAGETAG_SHORT=${IMAGETAG_SHORT}_NOMYSQL
        #### since softlinks are eg Dockerfile-php7-bla → Dockerfile-php7.4-bla
        #### we pull also the "dotted" version" before , since they will have exactly the same steps and our "undotted" version does not exist
        SHORTALIAS=$(echo "${SHORTALIAS}"|sed 's/Dockerfile//g;s/^-//g')
        build_success=no;start=$(date -u +%s)
        build64=" "$(echo $buildstring|base64 | _oneline)" "; _docker_build ${IMAGETAG_SHORT} ${IMAGETAG}  ${DFILENAME} ${build64} ${current_target}
        end=$(date -u +%s)
        seconds=$((end-start))
        echo -en "\e[1:42m";
        TZ=UTC printf "1.2 FINISHED: %d days %(%H hours %M minutes %S seconds)T\n" $((seconds/86400)) $seconds | tee -a ${startdir}/buildlogs/build-${IMAGETAG}.${TARGETARCH_NOSLASH}".log"
        echo "VERIFY BUILD LOG: "${startdir}/buildlogs/build-${IMAGETAG}.${TARGETARCH_NOSLASH}".log" 
        if $(grep -q -e "uccessfully built" -e "pushing layers" -e done -e "exporting manifest list" ${startdir}/buildlogs/build-${IMAGETAG}.${TARGETARCH_NOSLASH}".log") ;then 
            build_success=yes ;
        else
            runbuildfail=$((${runbuildfail}+100)) 
        fi
        if [ "$build_success" = "yes" ];then
            echo "BUILD SUCESSFUL(acccording to logs)"|green
        else
          echo BUILD FAILED ;tail -n 13 ${startdir}/buildlogs/build-${IMAGETAG}.${TARGETARCH_NOSLASH}".log" ;runbuildfail=$(($runbuildfail+100))
        fi
        _docker_rm_buildimage ${IMAGETAG_SHORT} 2>/dev/null | _oneline || true   
    fi
else ## NOMYSQL
echo MYSQL
###2.1 maxi mysql
    FEATURESET=${FEATURESET_MAXI}
    buildstring=$(echo ${FEATURESET} |sed 's/@/\n/g' | grep -v ^$ | sed 's/ \+$//g;s/^/--build-arg /g;s/$/=true /g'|grep -v MARIADB|_oneline)" --build-arg INSTALL_MARIADB=true ";
    tagstring=$(echo "${FEATURESET}"|sed 's/@/\n/g'|cut -d_ -f2 |cut -d= -f1 |sed 's/$/_/g'|awk '{print tolower($0)}' | _oneline |sed 's/_\+$//g') ;
    cleantags=$(echo "$tagstring"|sed 's/@/_/g'|sed 's/^_//g;s/_\+/_/g'|sed 's/_/-/g' | _oneline)
    IMAGETAG=$(echo ${DFILENAME}|sed 's/Dockerfile-//g' |awk '{print tolower($0)}')"-"$cleantags"_"$(date -u +%Y-%m-%d_%H.%M)"_"$(echo $CI_COMMIT_SHA|head -c8);
    IMAGETAG=$(echo "$IMAGETAG"|sed 's/_\+/_/g;s/_$//g');IMAGETAG=${IMAGETAG/-_/_};IMAGETAG_SHORT=${IMAGETAG/_*/}
    IMAGETAG_SHORT=${IMAGETAG_SHORT}
    #### since softlinks are eg Dockerfile-php7-bla → Dockerfile-php7.4-bla
    #### we pull also the "dotted" version" before , since they will have exactly the same steps and our "undotted" version does not exist
    SHORTALIAS=$(echo "${SHORTALIAS}"|sed 's/Dockerfile//g;s/^-//g')
    build_success=no;start=$(date -u +%s)
    build64=" "$(echo $buildstring|base64 | _oneline)" "; _docker_build ${IMAGETAG_SHORT} ${IMAGETAG}  ${DFILENAME} ${build64} ${current_target}
    end=$(date -u +%s)
    seconds=$((end-start))
    echo -en "\e[1:42m";
    TZ=UTC printf "1.2 FINISHED: %d days %(%H hours %M minutes %S seconds)T\n" $((seconds/86400)) $seconds | tee -a ${startdir}/buildlogs/build-${IMAGETAG}.${TARGETARCH_NOSLASH}".log"
    echo "VERIFY BUILD LOG: "${startdir}/buildlogs/build-${IMAGETAG}.${TARGETARCH_NOSLASH}".log" 
    if $(grep -q -e "uccessfully built" -e DONE -e "pushing layers" -e done -e "exporting manifest list" ${startdir}/buildlogs/build-${IMAGETAG}.${TARGETARCH_NOSLASH}".log") ;then 
      build_success=yes ;
    else
      runbuildfail=$((${runbuildfail}+100)) 
    fi
    if [ "$build_success" = "yes" ];then
        echo "BUILD SUCESSFUL(acccording to logs)"|green
    else
      echo BUILD FAILED ;tail -n 13 ${startdir}/buildlogs/build-${IMAGETAG}.${TARGETARCH_NOSLASH}".log" ;runbuildfail=$(($runbuildfail+100))
    fi
        _docker_rm_buildimage ${IMAGETAG_SHORT} 2>/dev/null | _oneline || true   
fi # end if mode

fi ## if NOMYSQL
done # end for current_target in ${BUILD_TARGET_PLATFORMS//,/ };do
_docker_purge|_reformat_docker_purge|red
return $runbuildfail ; } ;


### END BUILD WHEL DEFINITION

_build_latest() {
    localbuildfail=0
    for FILENAME in $(ls -1 Dockerfile*latest |sort -r);do
        echo DOCKERFILE: $FILENAME|yellow
        #test -f Dockerfile.current && rm Dockerfile.current
       _run_buildwheel ${FILENAME}
        if [ "$?" -ne 0 ] ;then localbuildfail=$(($localbuildfail+10000));fi
    done
return $localbuildfail ; } ;

_build_latest_nomysql() {
    localbuildfail=0
    for FILENAME in $(ls -1 Dockerfile*latest |sort -r);do
        echo DOCKERFILE: $FILENAME|yellow
        #test -f Dockerfile.current && rm Dockerfile.current
       _run_buildwheel ${FILENAME} NOMYSQL
        if [ "$?" -ne 0 ] ;then localbuildfail=$(($localbuildfail+10000));fi
    done
return $localbuildfail ; } ;

_build_php5() {
    localbuildfail=0
    for FILENAME in $(ls -1 Dockerfile-php5*|grep -v latest$ |sort -r);do
        echo DOCKERFILE: $FILENAME|yellow
        #test -f Dockerfile.current && rm Dockerfile.current

       _run_buildwheel ${FILENAME}
        if [ "$?" -ne 0 ] ;then localbuildfail=$(($localbuildfail+10));fi
    done
return $localbuildfail ; } ;


_build_php72() {
    localbuildfail=0
    for FILENAME in $(ls -1 Dockerfile-php7.2* |grep -v latest$ |sort -r);do
        echo DOCKERFILE: $FILENAME|yellow
        #test -f Dockerfile.current && rm Dockerfile.current
       _run_buildwheel ${FILENAME} 
        if [ "$?" -ne 0 ] ;then localbuildfail=$(($localbuildfail+100));fi
    done
return $localbuildfail ; } ;



_build_php72_nomysql() {
    localbuildfail=0
    for FILENAME in $(ls -1 Dockerfile-php7.2* |grep -v latest$ |sort -r);do
        echo DOCKERFILE: $FILENAME|yellow
        #test -f Dockerfile.current && rm Dockerfile.current
       _run_buildwheel ${FILENAME} NOMYSQL
        if [ "$?" -ne 0 ] ;then localbuildfail=$(($localbuildfail+100));fi
    done
return $localbuildfail ; } ;


_build_php74() {
    localbuildfail=0
    for FILENAME in $(ls -1 Dockerfile-php7.4* |grep -v latest$ |sort -r);do
        echo DOCKERFILE: $FILENAME|yellow
        #test -f Dockerfile.current && rm Dockerfile.current
       _run_buildwheel ${FILENAME} 
        if [ "$?" -ne 0 ] ;then localbuildfail=$(($localbuildfail+100));fi
    done
return $localbuildfail ; } ;



_build_php74_nomysql() {
    localbuildfail=0
    for FILENAME in $(ls -1 Dockerfile-php7.4* |grep -v latest$ |sort -r);do
        echo DOCKERFILE: $FILENAME|yellow
        #test -f Dockerfile.current && rm Dockerfile.current
       _run_buildwheel ${FILENAME} NOMYSQL
        if [ "$?" -ne 0 ] ;then localbuildfail=$(($localbuildfail+100));fi
    done
return $localbuildfail ; } ;


_build_aux() {
    localbuildfail=0
    for FILENAME in $(ls -1 Dockerfile-*|grep -v Dockerfile-php|grep -v latest$  |sort -r);do
        echo DOCKERFILE: $FILENAME|yellow
        #test -f Dockerfile.current && rm Dockerfile.current
       _run_buildwheel ${FILENAME}
        if [ "$?" -ne 0 ] ;then localbuildfail=$(($localbuildfail+1000));fi
    done
return $localbuildfail ; } ;

_build_all() {
    localbuildfail=0
    for FILENAME in $(ls -1 Dockerfile-*|grep -v latest$ |sort -r);do
        echo DOCKERFILE: $FILENAME |yellow
        #test -f Dockerfile.current && rm Dockerfile.current
       _run_buildwheel ${FILENAME}
        if [ "$?" -ne 0 ] ;then localbuildfail=$(($localbuildfail+1000000));fi
    done
return $localbuildfail ; } ;


## AFTER FUNCTIONS
### LAUNCHING ROCKET
echo -n "::SYS:PREP=DONE ... " |green ;echo '+++WELCOME+++'|blue |yellowb
(echo '|||+++>> SYS: '$(uname -a|yellow)" | binfmt count: "$(ls /proc/sys/fs/binfmt_misc/ |wc -l |blue) " | BUILDX: "$(docker buildx 2>&1 |grep -q "imagetools"  && echo OK || echo NO )" |";echo "| Docker vers. : "$(docker --version|yellow)"| IDentity :  "$(id -u|blue) " == "$(id -un|yellow)"@"$(hostname -f|red)' | ARGZ : '"$@"' <<+++|||' )|green
#test -f Dockerfile.current && rm Dockerfile.current

buildfail=0

case $1 in
  buildx) _build_docker_buildx ;;
  latest)   _build_latest "$@" ;buildfail=$? ;;
  latest_nomysql)   _build_latest_nomysql "$@" ;buildfail=$? ;;
  php5|p5)  _build_php5 "$@" ;buildfail=$? ;;
  php72|p72)  _build_php72 "$@" ;buildfail=$? ;;
  php72_nomysql|p7_nomysql)  _build_php72_nomysql "$@" ;buildfail=$? ;;
  php74|p74)  _build_php74 "$@" ;buildfail=$? ;;
  php74_nomysql|p74_nomysql)  _build_php74_nomysql "$@" ;buildfail=$? ;;
  rest|aux) _build_aux  "$@" ;buildfail=$? ;;
  **  )     _build_all ; buildfail=$? ; _build_latest ; buildfail=$(($buildfail+$?)) ;;

esac

docker buildx rm mybuilder|red
docker logout 2>&1 | _oneline
test -f Dockerfile && rm Dockerfile
echo "#############################"|blue
echo -n "exiting with:"|yellow ;echo $buildfail 
echo "##############################"|blue
exit $buildfail
