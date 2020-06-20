#/bin/sh
## BUILD SCRIPT ##
PROJECT_NAME=hocker
export PROJECT_NAME=hocker
BUILD_TARGET_PLATFORMS="linux/amd64,linux/arm64,linux/arm/v7"
###MODE DECISION

## DEFAULT : one full image to save runner time
MODE=onefullimage
#MODE=featuresincreasing

#export DOCKER_BUILDKIT=1

_oneline() { tr -d '\n' ; } ;
_buildx_arch() { case "$(uname -m)" in aarch64) echo linux/arm64;; x86_64) echo linux/amd64 ;; armv7l|armv7*) echo linux/arm/v7;; armv6l|armv6*) echo linux/arm/v6;;  esac ; } ;

## Colors ;
uncolored="\033[0m" ; black="\033[0;30m" ; blackb="\033[1;30m" ; white="\033[0;37m" ; whiteb="\033[1;37m" ; red="\033[0;31m" ; redb="\033[1;31m" ; green="\033[0;32m" ; greenb="\033[1;32m" ; yellow="\033[0;33m" ; yellowb="\033[1;33m" ; blue="\033[0;34m" ; blueb="\033[1;34m" ; purple="\033[0;35m" ; purpleb="\033[1;35m" ; lightblue="\033[0;36m" ; lightblueb="\033[1;36m" ;  function black {   echo -e "${black}${1}${uncolored}" ; } ;    function blackb {   echo -e "${blackb}";cat;echo -en "${uncolored}" ; } ;   function white {   echo -e "${white}";cat;echo -en "${uncolored}" ; } ;   function whiteb {   echo -e "${whiteb}";cat;echo -en "${uncolored}" ; } ;   function red {   echo -e "${red}";cat;echo -en "${uncolored}" ; } ;   function redb {   echo -e "${redb}";cat;echo -en "${uncolored}" ; } ;   function green {   echo -e "${green}";cat;echo -en "${uncolored}" ; } ;   function greenb {   echo -e "${greenb}";cat;echo -en "${uncolored}" ; } ;   function yellow {   echo -e "${yellow}";cat;echo -en "${uncolored}" ; } ;   function yellowb {   echo -e "${yellowb}";cat;echo -en "${uncolored}" ; } ;   function blue {   echo -e "${blue}";cat;echo -en "${uncolored}" ; } ;   function blueb {   echo -e "${blueb}";cat;echo -en "${uncolored}" ; } ;   function purple {   echo -e "${purple}";cat;echo -en "${uncolored}" ; } ;   function purpleb {   echo -e "${purpleb}";cat;echo -en "${uncolored}" ; } ;   function lightblue {   echo -e "${lightblue}";cat;echo -en "${uncolored}" ; } ;   function lightblueb {   echo -e "${lightblueb}";cat;echo -en "${uncolored}" ; } ;  function echo_black {   echo -e "${black}${1}${uncolored}" ; } ; function echo_blackb {   echo -e "${blackb}${1}${uncolored}" ; } ;   function echo_white {   echo -e "${white}${1}${uncolored}" ; } ;   function echo_whiteb {   echo -e "${whiteb}${1}${uncolored}" ; } ;   function echo_red {   echo -e "${red}${1}${uncolored}" ; } ;   function echo_redb {   echo -e "${redb}${1}${uncolored}" ; } ;   function echo_green {   echo -e "${green}${1}${uncolored}" ; } ;   function echo_greenb {   echo -e "${greenb}${1}${uncolored}" ; } ;   function echo_yellow {   echo -e "${yellow}${1}${uncolored}" ; } ;   function echo_yellowb {   echo -e "${yellowb}${1}${uncolored}" ; } ;   function echo_blue {   echo -e "${blue}${1}${uncolored}" ; } ;   function echo_blueb {   echo -e "${blueb}${1}${uncolored}" ; } ;   function echo_purple {   echo -e "${purple}${1}${uncolored}" ; } ;   function echo_purpleb {   echo -e "${purpleb}${1}${uncolored}" ; } ;   function echo_lightblue {   echo -e "${lightblue}${1}${uncolored}" ; } ;   function echo_lightblueb {   echo -e "${lightblueb}${1}${uncolored}" ; } ;    function colors_list {   echo_black "black";   echo_blackb "blackb";   echo_white "white";   echo_whiteb "whiteb";   echo_red "red";   echo_redb "redb";   echo_green "green";   echo_greenb "greenb";   echo_yellow "yellow";   echo_yellowb "yellowb";   echo_blue "blue";   echo_blueb "blueb";   echo_purple "purple";   echo_purpleb "purpleb";   echo_lightblue "lightblue";   echo_lightblueb "lightblueb"; } ;


case $1 in
  php5|p5)  MODE="onefullimage" ;;
  php7|p7)  MODE="onefullimage" ;;
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
echo -n ":REG_LOGIN[test:init]:" |blue; sleep $(($RANDOM%2));sleep $(($RANDOM%3));docker login  -u ${REGISTRY_USER} -p ${REGISTRY_PASSWORD} ${REGISTRY_HOST} || exit 666 ; docker logout 2>&1 | _oneline |blue
else
  echo no upgr;
fi
echo $(date -u +%s) > /tmp/.dockerbuildenvlastsysupgrade

startdir=$(pwd)
mkdir buildlogs
echo "::GIT"
/bin/sh -c "test -d Hocker || git clone https://github.com/TheFoundation/Hocker.git --recurse-submodules && (cd Hocker ;git pull origin master --recurse-submodules )"
cd Hocker/build/
## end head prep stage
####


_build_docker_buildx() {
        PROJECT_NAME=hocker
        export PROJECT_NAME=hocker
        #echo -n ":REG_LOGIN[test]:";docker login  -u ${REGISTRY_USER} -p ${REGISTRY_PASSWORD} ${REGISTRY_HOST} || true ;docker logout 2>&1 | _oneline
        which apk |grep "/apk" -q && apk add git bash
        #export DOCKER_BUILDKIT=1
        git clone git://github.com/docker/buildx ./docker-buildx
        ##  --platform=local needs experimental docker scope
        /bin/bash -c "docker pull  ${REGISTRY_PROJECT}/${PROJECT_NAME}:buildhelper_buildx || true "
        docker build -t ${REGISTRY_PROJECT}/${PROJECT_NAME}:buildhelper_buildx ./docker-buildx
        docker image ls
        echo -n ":REG_LOGIN[push]:"
        docker login  -u ${REGISTRY_USER} -p ${REGISTRY_PASSWORD} ${REGISTRY_HOST}
        echo -n ":DOCKER:PUSH@"${REGISTRY_PROJECT}/${PROJECT_NAME}:buildhelper_buildx":"
        (docker push ${REGISTRY_PROJECT}/${PROJECT_NAME}:buildhelper_buildx |grep -v -e Waiting$ -e Preparing$ -e "Layer already exists$";docker logout 2>&1 | _oneline |grep -e emov -e redential)  |sed 's/$/ →→ /g;s/Pushed/+/g' |tr -d '\n'
        docker build -o . ./docker-buildx
        test -f buildx && mkdir -p ~/.docker/cli-plugins/ && mv buildx ~/.docker/cli-plugins/docker-buildx && chmod +x ~/.docker/cli-plugins/docker-buildx
    echo ; } ;

_reformat_docker_purge() { sed 's/^deleted: .\+:\([[:alnum:]].\{2\}\).\+\([[:alnum:]].\{2\}\)/\1..\2|/g;s/^\(.\)[[:alnum:]].\{61\}\(.\)/\1.\2|/g' |tr -d '\n' ; } ;

_docker_push() {
        ##docker buildx 2>&1 |grep -q "imagetools" || ( )
        IMAGETAG_SHORT=$1
        echo "↑↑↑UPLOAD↑↑↑"
            docker image ls
        echo -n ":REG_LOGIN[push]:"
            sleep $(($RANDOM%2));sleep  $(($RANDOM%3));docker login  -u ${REGISTRY_USER} -p ${REGISTRY_PASSWORD} ${REGISTRY_HOST}
            echo -n ":DOCKER:PUSH@"${REGISTRY_PROJECT}/${PROJECT_NAME}:${IMAGETAG_SHORT}":"
            (docker push ${REGISTRY_PROJECT}/${PROJECT_NAME}:${IMAGETAG_SHORT} |grep -v -e Waiting$ -e Preparing$ -e "Layer already exists$";docker logout 2>&1 | _oneline)  |sed 's/$/ →→ /g;s/Pushed/+/g' |tr -d '\n'
    echo -n "|" ; } ;
#####################################
_docker_build() {
                IMAGETAG_SHORT="$1"
                IMAGETAG="$2"
                DFILENAME=$3
                TARGETARCH=$4
                ## CALLED WITHOUT FOURTH ARGUMENT , BUILD ONLY NATIVE
                echo $TARGETARCH|tr -d '\n'|wc -c |grep -q ^0$ && TARGETARCH=$(_buildx_arch)
                TARGETARCH_NOSLASH=${TARGETARCH//\//_};
                if $( test -d /etc/apt/  &&  grep ^Acquire::http::Proxy /etc/apt/ -rlq) ;then  proxystring=$(grep ^Acquire::http::Proxy /etc/apt/ -r|cut -d: -f2-|sed 's/Acquire::http::Proxy//g;s/ //g;s/\t//g;s/"//g;s/'"'"'//g;s/;//g');buildstring='--build-arg APT_HTTP_PROXY_URL='$proxystring; else    echo "NO SYSTEM APT PROXY FOUND" ;fi
                start=$(date -u +%s)
                #docker build -t hocker:${IMAGETAG_SHORT} $buildstring -f $FILENAME --rm=false . &> ${startdir}/buildlogs/build-${IMAGETAG}".log"
                ## NO BUILDX ,use standard instructions
                DOCKER_BUILDKIT=0
                do_native_build=no
                if $(docker buildx 2>&1 |grep -q "imagetools" ) ;then
                    echo -n "::build::x"
                else
                    echo -n "::build: NO buildx,DOING MY ARCHITECURE ONLY ";
                    do_native_build=yes
                fi
                ## HAVING BUILDX , builder should escalate for stack incl. armV7 / aarch64 / amd64
                docker buildx 2>&1 |grep -q "imagetools" && ( echo " TRYING MULTIARCH ";
                #echo ${have_buildx} |grep -q =true$ &&  docker buildx create --driver-opt network=host --driver docker-container --use --name mybuilder
                # --driver docker-container --driver-opt network=host
                #echo ${have_buildx} |grep -q =true$ &&  docker buildx create --use --name mybuilder
                #echo ${have_buildx} |grep -q =true$ &&  docker buildx create --append --name mybuilder --platform linux/arm/v7 rpi
                #echo ${have_buildx} |grep -q =true$ &&  docker buildx create --append --name mybuilder --platform linux/aarch64 rpi4
                docker buildx create  --use --name mybuilder 2>&1 | green |_oneline
                docker buildx inspect --bootstrap 2>&1 | yellow | _oneline
                sleep $(($RANDOM%2));sleep  $(($RANDOM%3));docker login  -u ${REGISTRY_USER} -p ${REGISTRY_PASSWORD} ${REGISTRY_HOST} | blue

                echo -ne "DOCKER bUILD, running the following command: \e[1;31m"
                echo docker buildx build  --pull --progress plain --platform=${TARGETARCH} --cache-from hocker:${IMAGETAG_SHORT} -t hocker:${IMAGETAG_SHORT} -o type=registry $buildstring -f "${DFILENAME}"  .
                echo -e "\e[0m\e[1;42m STDOUT and STDERR goes to: "${startdir}/buildlogs/build-${IMAGETAG}.${TARGETARCH_NOSLASH}".buildx.log \e[0m"
                ##docker buildx build --platform=linux/amd64,linux/arm64,linux/arm/v7,darwin
#                docker buildx build  --pull --progress plain --platform=linux/amd64,linux/arm64,linux/arm/v7 --cache-from hocker:${IMAGETAG_SHORT} -t hocker:${IMAGETAG_SHORT} -o type=registry $buildstring -f "${DFILENAME}"  .  &> ${startdir}/buildlogs/build-${IMAGETAG}".log"
## pushing i diretly to registry is not  possible with docker driver

                #docker buildx build  --pull --progress plain --platform=linux/amd64,linux/arm64,linux/arm/v7 --cache-from hocker:${IMAGETAG_SHORT} -t hocker:${IMAGETAG_SHORT} -o type=local,dest=./dockeroutput $buildstring -f "${DFILENAME}"  .  &> ${startdir}/buildlogs/build-${IMAGETAG}".log"
                docker buildx build  --pull --progress plain --platform=${TARGETARCH} --cache-from hocker:${IMAGETAG_SHORT} -t hocker:${IMAGETAG_SHORT} -o type=registry $buildstring -f "${DFILENAME}"  .  &> ${startdir}/buildlogs/build-${IMAGETAG}.${TARGETARCH_NOSLASH}".buildx.log"
                echo ":past:buildx"
                )
                ## CATCHING "buildx docker failure" > possible errors arise from missing qemu / buildkit runs only on x86_64 ( 2020 Q1 )
                if $(grep -q -e 'code = Unknown desc = executor failed running ./bin/sh' -e "runc did not terminate successfully" -e "multiple platforms feature is currently not supported for docker drive"  ${startdir}/buildlogs/build-${IMAGETAG}.${TARGETARCH_NOSLASH}".buildx.log");then
                  ## buildx failed
                  tail -n 15 ${startdir}/buildlogs/build-${IMAGETAG}.${TARGETARCH_NOSLASH}".buildx.log"
                  do_native_build="yes";
                fi
                if $(echo ${TARGETARCH}|grep -q $(_buildx_arch) );then ## native build only works on my arch
                  if $(echo ${do_native_build}|grep -q ^yes$);then
                      echo "::build: NO buildx,DOING MY ARCHITECURE ONLY ";
                     echo -ne "DOCKER bUILD(native), running the following command: \e[1;31m"
                     export DOCKER_BUILDKIT=0
                     echo docker build --cache-from hocker:${IMAGETAG_SHORT} -t hocker:${IMAGETAG_SHORT} $buildstring -f "${DFILENAME}" --rm=false -t ${REGISTRY_PROJECT}/${PROJECT_NAME}:${IMAGETAG_SHORT} .
                     echo -e "\e[0m\e[1;42m STDOUT and STDERR goes to:"/buildlogs/build-${IMAGETAG}".log \e[0m"
                     DOCKER_BUILDKIT=0 docker build --cache-from hocker:${IMAGETAG_SHORT} -t hocker:${IMAGETAG_SHORT} $buildstring -f "${DFILENAME}" --rm=false -t ${REGISTRY_PROJECT}/${PROJECT_NAME}:${IMAGETAG_SHORT} . &> ${startdir}/buildlogs/build-${IMAGETAG}.${TARGETARCH_NOSLASH}".native.log" ;
                     cat ${startdir}/buildlogs/build-${IMAGETAG}.${TARGETARCH_NOSLASH}".native.log" >  ${startdir}/buildlogs/build-${IMAGETAG}.${TARGETARCH_NOSLASH}".log"
                  else
                    echo "using native build log"
                    cat ${startdir}/buildlogs/build-${IMAGETAG}.${TARGETARCH_NOSLASH}".buildx.log" > ${startdir}/buildlogs/build-${IMAGETAG}.${TARGETARCH_NOSLASH}".log" && rm ${startdir}/buildlogs/build-${IMAGETAG}.${TARGETARCH_NOSLASH}".buildx.log"
                  fi
                fi

                ## see here https://github.com/docker/buildx
                ##END BUILD STAGE

    echo -n "|" ;
    tail -n 10 ${startdir}/buildlogs/build-${IMAGETAG}.${TARGETARCH_NOSLASH}".log"| grep -i -e "failed" -e "did not terminate sucessfully" -q && return 0 || return 23 ; } ;

_docker_rm_buildimage() { docker image rm ${REGISTRY_PROJECT}/${PROJECT_NAME}:${1} ${PROJECT_NAME}:${1}  2>&1 | grep -v "Untagged"| _reformat_docker_purge |_oneline ; } ;
#####################################
_docker_purge() {
    IMAGETAG_SHORT=$1
    echo;echo "::.oO0 PURGE 0Oo.::"
    docker image rm ${REGISTRY_PROJECT}/${PROJECT_NAME}:${IMAGETAG_SHORT} hocker:${IMAGETAG_SHORT}  2>&1 | grep -v "Untagged"| _reformat_docker_purge |_oneline
    docker image prune -a -f 2>&1  | _reformat_docker_purge
    echo "→→→";
    docker system prune -a -f 2>&1 | _reformat_docker_purge
    echo ;echo "::IMG"
    docker image ls |sed 's/$/|/g'|tr -d '\n'
    #docker logout 2>&1 | _oneline
    echo -n "|" ; } ;
#####################################
_run_buildwheel() { ## ARG1 Dockerfile-name
runbuildfail=0
DFILENAME=$1
## Prepare env
#   test -f ${DFILENAME} && ( cat  ${DFILENAME} > Dockerfile.current ) || (echo "Dockerfile not found";break)
if $(test -f ${DFILENAME});then echo -n ;else   echo "Dockerfile not found";break;fi

SHORTALIAS=$(basename $(readlink -f ${DFILENAME}))
for current_target in ${BUILD_TARGET_PLATFORMS//,/ };do
echo "::BUILD:PLATFORM:"$current_target"::AIMING..."|red
FEATURESET_MINI_NOMYSQL=$(echo -n|cat ${DFILENAME}|grep -v -e MYSQL -e mysql -e MARIADB -e mariadb|grep ^ARG|grep =true|sed 's/ARG \+//g;s/ //'|cut -d= -f1 |awk '!x[$0]++' |grep INSTALL|sed 's/$/@/g'|tr -d '\n' )
FEATURESET_MINI=$(echo -n|cat ${DFILENAME}|grep ^ARG|grep =true|sed 's/ARG \+//g;s/ //'|cut -d= -f1 |awk '!x[$0]++' |grep INSTALL|sed 's/$/@/g'|tr -d '\n' )
FEATURESET_MAXI=$(echo -n|cat ${DFILENAME}|grep ^ARG|grep =    |sed 's/ARG \+//g;s/ //'|cut -d= -f1 |awk '!x[$0]++' |grep INSTALL|sed 's/$/@/g'|tr -d '\n' )
FEATURESET_MAXI_NOMYSQL=$(echo -n|cat ${DFILENAME}|grep -v -e MYSQL -e mysql -e MARIADB -e mariadb|grep ^ARG|grep =|sed 's/ARG \+//g;s/ //'|cut -d= -f1 |awk '!x[$0]++' |grep INSTALL|sed 's/$/@/g'|tr -d '\n' )



## +++ begin build stage ++++
if [[ "$MODE" == "featuresincreasing" ]];then  ## BUILD 2 versions , a minimal default packages (INSTALL_WHATEVER=true) and a full image     ## IN ORDER OF APPEARANCE in Dockerfile
## 1 mini
##remove INSTALL_part from FEATURESET so all features underscore separated comes up
###1.1 mini nomysql ####CHECK IF DOCKERFILE OFFERS MARIADB  |
        if $(cat ${DFILENAME}|grep -q INSTALL_MARIADB);then
        FEATURESET=${FEATURESET_MINI_NOMYSQL}
        buildstring=$buildstring" "$(echo ${FEATURESET} |sed 's/@/\n/g' | grep -v ^$ | sed 's/ \+$//g;s/^/--build-arg /g;s/$/=true/g'|grep -v MARIADB)" --build-arg INSTALL_MARIADB=false";
        tagstring=$(echo "${FEATURESET}"|cut -d_ -f2 |cut -d= -f1 |awk '{print tolower($0)}') ;
        cleantags=$(echo "$tagstring"|sed 's/^_//g;s/_\+/_/g')
          IMAGETAG=$(echo ${DFILENAME}|sed 's/Dockerfile-//g' |awk '{print tolower($0)}')"_"$cleantags"_"$(date -u +%Y-%m-%d_%H.%M)"_"$(echo $CI_COMMIT_SHA|head -c8);
          IMAGETAG=$(echo "$IMAGETAG"|sed 's/_\+/_/g');
          IMAGETAG_SHORT=${IMAGETAG/_*/}
          IMAGETAG=${IMAGETAG}_NOMYSQL
          IMAGETAG_SHORT=${IMAGETAG_SHORT}_NOMYSQL
             #### since softlinks are eg Dockerfile-php7-bla → Dockerfile-php7.4-bla
             #### we pull also the "dotted" version" before , since they will have exactly the same steps and our "undotted" version does not exist
             SHORTALIAS=$(echo "${SHORTALIAS}"|sed 's/Dockerfile//g;s/^-//g')
             echo -n "TAG: $IMAGETAG | BUILD: $buildstring | PULLING ${SHORTALIAS} IF NOT FOUND |"
             echo -n "docker pull  "${REGISTRY_PROJECT}/${PROJECT_NAME}:${IMAGETAG_SHORT} . " | :: |"
             (docker pull  ${REGISTRY_PROJECT}/${PROJECT_NAME}:${IMAGETAG_SHORT} 2>&1 || true ) |grep -v -e Verifying -e Download|sed 's/Pull.\+/↓/g'|sed 's/\(Waiting\|Checksum\|exists\|complete\|fs layer\)$/→/g'|_oneline
             build_success=no;start=$(date -u +%s)
             _docker_build ${IMAGETAG_SHORT} ${IMAGETAG} ${DFILENAME} ${current_target}
             tail -n 10 ${startdir}/buildlogs/build-${IMAGETAG}".log" | grep -e "^Successfully built " -e DONE || runbuildfail=$(($runbuildfail+100)) && build_succes=yes
             end=$(date -u +%s)
             seconds=$((end-start))
             echo -en "\e[1:42m"
             TZ=UTC printf "FINISHED: %d days %(%H hours %M minutes %S seconds)T\n" $((seconds/86400)) $seconds | tee -a ${startdir}/buildlogs/build-${IMAGETAG}".log"
             if [ "$build_success" == "yes" ];then
               _docker_push ${IMAGETAG_SHORT} ##since pushing to remote does not work , also buildx has to be sent## docker buildx 2>&1 |grep -q "imagetools" ||  _docker_push ${IMAGETAG_SHORT}
             else
               tail -n 13 ${startdir}/buildlogs/build-${IMAGETAG}".log" ;#runbuildfail=$(($runbuildfail+100))
             fi
            _docker_rm_buildimage ${IMAGETAG_SHORT}

        fi ## end if INSTALL_MARIADB
###1.2 mini mysql
      FEATURESET=${FEATURESET_MINI}
      buildstring=$buildstring" "$(echo ${FEATURESET} |sed 's/@/\n/g' | grep -v ^$ | sed 's/ \+$//g;s/^/--build-arg /g;s/$/=true/g'|grep -v MARIADB)" --build-arg INSTALL_MARIADB=true";
      tagstring=$(echo "${FEATURESET}"|cut -d_ -f2 |cut -d= -f1 |awk '{print tolower($0)}') ;
        IMAGETAG=$(echo ${DFILENAME}|sed 's/Dockerfile-//g' |awk '{print tolower($0)}')"_"$cleantags"_"$(date -u +%Y-%m-%d_%H.%M)"_"$(echo $CI_COMMIT_SHA|head -c8);
        IMAGETAG=$(echo "$IMAGETAG"|sed 's/_\+/_/g');IMAGETAG_SHORT=${IMAGETAG/_*/}
        IMAGETAG=${IMAGETAG}_NOMYSQL
        IMAGETAG_SHORT=${IMAGETAG_SHORT}_NOMYSQL
           #### since softlinks are eg Dockerfile-php7-bla → Dockerfile-php7.4-bla
           #### we pull also the "dotted" version" before , since they will have exactly the same steps and our "undotted" version does not exist
           SHORTALIAS=$(echo "${SHORTALIAS}"|sed 's/Dockerfile//g;s/^-//g')
           echo -n "TAG: $IMAGETAG | BUILD: $buildstring | PULLING ${SHORTALIAS} IF NOT FOUND"
           echo -n "docker pull  "${REGISTRY_PROJECT}/${PROJECT_NAME}:${IMAGETAG_SHORT} .
           (docker pull  ${REGISTRY_PROJECT}/${PROJECT_NAME}:${IMAGETAG_SHORT} 2>&1 || true ) |grep -v -e Verifying -e Download|sed 's/Pull.\+/↓/g'|sed 's/\(Waiting\|Checksum\|exists\|complete\|fs layer\)$/→/g'|_oneline
           build_success=no;start=$(date -u +%s)
           _docker_build ${IMAGETAG_SHORT} ${IMAGETAG} ${DFILENAME} ${current_target}
           tail -n 10 ${startdir}/buildlogs/build-${IMAGETAG}".log" | grep -e "^Successfully built " -e DONE || runbuildfail=$(($runbuildfail+100)) && build_succes=yes
           end=$(date -u +%s)
           seconds=$((end-start))
           echo -en "\e[1:42m"
           TZ=UTC printf "FINISHED: %d days %(%H hours %M minutes %S seconds)T\n" $((seconds/86400)) $seconds | tee -a ${startdir}/buildlogs/build-${IMAGETAG}".log"
           if [ "$build_success" == "yes" ];then
             _docker_push ${IMAGETAG_SHORT} ##since pushing to remote does not work , also buildx has to be sent## docker buildx 2>&1 |grep -q "imagetools" ||  _docker_push ${IMAGETAG_SHORT}
           else
             tail -n 13 ${startdir}/buildlogs/build-${IMAGETAG}".log" ;runbuildfail=$(($runbuildfail+100))
           fi
           _docker_rm_buildimage ${IMAGETAG_SHORT}
fi # end if MODE=featuresincreasing

## maxi build gets triggered on featuresincreasing and
##remove INSTALL_part from FEATURESET so all features underscore separated comes up
tagstring=$(echo "${FEATURES}"|cut -d_ -f2 |cut -d= -f1 |awk '{print tolower($0)}') ;
cleantags=$(echo "$tagstring"|sed 's/^_//g;s/_\+/_/g')
if $(echo $MODE|grep -q -e featuresincreasing -e onefullimage) ; then
###2.1 maxi nomysql
      if $(cat ${DFILENAME}|grep -q INSTALL_MARIADB);then
        FEATURESET=${FEATURESET_MAXI_NOMYSQL}
        buildstring=$buildstring" "$(echo ${FEATURESET} |sed 's/@/\n/g' | grep -v ^$ | sed 's/ \+$//g;s/^/--build-arg /g;s/$/=true/g'|grep -v MARIADB)" --build-arg INSTALL_MARIADB=false";
        tagstring=$(echo "${FEATURESET}"|cut -d_ -f2 |cut -d= -f1 |awk '{print tolower($0)}') ;
        cleantags=$(echo "$tagstring"|sed 's/^_//g;s/_\+/_/g')
          IMAGETAG=$(echo ${DFILENAME}|sed 's/Dockerfile-//g' |awk '{print tolower($0)}')"_"$cleantags"_"$(date -u +%Y-%m-%d_%H.%M)"_"$(echo $CI_COMMIT_SHA|head -c8);
          IMAGETAG=$(echo "$IMAGETAG"|sed 's/_\+/_/g');
          IMAGETAG_SHORT=${IMAGETAG/_*/}
          IMAGETAG=${IMAGETAG}_NOMYSQL
          IMAGETAG_SHORT=${IMAGETAG_SHORT}_NOMYSQL
           #### since softlinks are eg Dockerfile-php7-bla → Dockerfile-php7.4-bla
           #### we pull also the "dotted" version" before , since they will have exactly the same steps and our "undotted" version does not exist
           SHORTALIAS=$(echo "${SHORTALIAS}"|sed 's/Dockerfile//g;s/^-//g')
           echo -n "TAG: $IMAGETAG | BUILD: $buildstring | PULLING ${SHORTALIAS} IF NOT FOUND"
           echo -n "docker pull  "${REGISTRY_PROJECT}/${PROJECT_NAME}:${IMAGETAG_SHORT} .
           (docker pull  ${REGISTRY_PROJECT}/${PROJECT_NAME}:${IMAGETAG_SHORT} 2>&1 || true ) |grep -v -e Verifying -e Download|sed 's/Pull.\+/↓/g'|sed 's/\(Waiting\|Checksum\|exists\|complete\|fs layer\)$/→/g'|_oneline
           build_success=no;start=$(date -u +%s)
           _docker_build ${IMAGETAG_SHORT} ${IMAGETAG} ${DFILENAME} ${current_target}
           tail -n 10 ${startdir}/buildlogs/build-${IMAGETAG}".log" | grep -e "^Successfully built " -e DONE || runbuildfail=$(($runbuildfail+100)) && build_succes=yes
           end=$(date -u +%s)
           seconds=$((end-start))
           echo -en "\e[1:42m"
           TZ=UTC printf "FINISHED: %d days %(%H hours %M minutes %S seconds)T\n" $((seconds/86400)) $seconds | tee -a ${startdir}/buildlogs/build-${IMAGETAG}".log"
           if [ "$build_success" == "yes" ];then
             _docker_push ${IMAGETAG_SHORT} ##since pushing to remote does not work , also buildx has to be sent## docker buildx 2>&1 |grep -q "imagetools" ||  _docker_push ${IMAGETAG_SHORT}
           else
             tail -n 13 ${startdir}/buildlogs/build-${IMAGETAG}".log" ;#runbuildfail=$(($runbuildfail+100))
           fi
          _docker_rm_buildimage ${IMAGETAG_SHORT}
      fi

###2.1 maxi mysql
      buildstring=$buildstring" "$(echo ${FEATURESET} |sed 's/@/\n/g' | grep -v ^$ | sed 's/ \+$//g;s/^/--build-arg /g;s/$/=true/g'|grep -v MARIADB)" --build-arg INSTALL_MARIADB=true";
      tagstring=$(echo "${FEATURESET}"|cut -d_ -f2 |cut -d= -f1 |awk '{print tolower($0)}') ;
      FEATURESET=${FEATURESET_MAXI}
        IMAGETAG=$(echo ${DFILENAME}|sed 's/Dockerfile-//g' |awk '{print tolower($0)}')"_"$cleantags"_"$(date -u +%Y-%m-%d_%H.%M)"_"$(echo $CI_COMMIT_SHA|head -c8);
        IMAGETAG=$(echo "$IMAGETAG"|sed 's/_\+/_/g');IMAGETAG_SHORT=${IMAGETAG/_*/}  |
        IMAGETAG=${IMAGETAG}_NOMYSQL
        IMAGETAG_SHORT=${IMAGETAG_SHORT}_NOMYSQL
          #### since softlinks are eg Dockerfile-php7-bla → Dockerfile-php7.4-bla
          #### we pull also the "dotted" version" before , since they will have exactly the same steps and our "undotted" version does not exist
          SHORTALIAS=$(echo "${SHORTALIAS}"|sed 's/Dockerfile//g;s/^-//g')
          echo -n "TAG: $IMAGETAG | BUILD: $buildstring | PULLING ${SHORTALIAS} IF NOT FOUND"
          echo -n "docker pull  "${REGISTRY_PROJECT}/${PROJECT_NAME}:${IMAGETAG_SHORT} .
          (docker pull  ${REGISTRY_PROJECT}/${PROJECT_NAME}:${IMAGETAG_SHORT} 2>&1 || true ) |grep -v -e Verifying -e Download|sed 's/Pull.\+/↓/g'|sed 's/\(Waiting\|Checksum\|exists\|complete\|fs layer\)$/→/g'|_oneline
          build_success=no;start=$(date -u +%s)
          _docker_build ${IMAGETAG_SHORT} ${IMAGETAG} ${DFILENAME} ${current_target}
          tail -n 10 ${startdir}/buildlogs/build-${IMAGETAG}".log" | grep -e "^Successfully built " -e DONE || runbuildfail=$(($runbuildfail+100)) && build_succes=yes
          end=$(date -u +%s)
          seconds=$((end-start))
          echo -en "\e[1:42m"
          TZ=UTC printf "FINISHED: %d days %(%H hours %M minutes %S seconds)T\n" $((seconds/86400)) $seconds | tee -a ${startdir}/buildlogs/build-${IMAGETAG}".log"
          if [ "$build_success" == "yes" ];then
            _docker_push ${IMAGETAG_SHORT} ##since pushing to remote does not work , also buildx has to be sent## docker buildx 2>&1 |grep -q "imagetools" ||  _docker_push ${IMAGETAG_SHORT}
          else
            tail -n 13 ${startdir}/buildlogs/build-${IMAGETAG}".log" ;runbuildfail=$(($runbuildfail+100))
          fi
          _docker_rm_buildimage ${IMAGETAG_SHORT}
fi # end if mode

done # end for current_target in ${BUILD_TARGET_PLATFORMS//,/ };do

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


_build_php5() {
    localbuildfail=0
    for FILENAME in $(ls -1 Dockerfile-php5*|grep -v latest$ |sort -r);do
        echo DOCKERFILE: $FILENAME|yellow
        #test -f Dockerfile.current && rm Dockerfile.current

       _run_buildwheel ${FILENAME}
        if [ "$?" -ne 0 ] ;then localbuildfail=$(($localbuildfail+10));fi
    done
return $localbuildfail ; } ;


_build_php7() {
    localbuildfail=0
    for FILENAME in $(ls -1 Dockerfile-php7* |grep -v latest$ |sort -r);do
        echo DOCKERFILE: $FILENAME|yellow
        #test -f Dockerfile.current && rm Dockerfile.current
       _run_buildwheel ${FILENAME}
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
echo -n "::SYS:PREP=DONE ... " |green
### LAUNCHING ROCKET
echo '+++WELCOME+++'|yellowb|black
echo '|||+++>> SYS: '$(uname -a|yellow)" | binfmt count: "$(ls /proc/sys/fs/binfmt_misc/ |wc -l |blue) " | BUILDX: "$(docker buildx 2>&1 |grep -q "imagetools"  && echo OK || echo NO )" | docker vers. :"$(docker --version|yellow)"| IDentity "$(id -u|blue) " == "$(id -un|yellow)"@"$(hostname -f|red)' | ARGZ : '"$@"'<<+++|||'|green
#test -f Dockerfile.current && rm Dockerfile.current

buildfail=0

case $1 in
  buildx) _build_docker_buildx ;;
  latest)   _build_latest "$@" ;buildfail=$? ;;
  php5|p5)  _build_php5 "$@" ;buildfail=$? ;;
  php7|p7)  _build_php7 "$@" ;buildfail=$? ;;
  rest|aux) _build_aux  "$@" ;buildfail=$? ;;
  **  )     _build_all ; buildfail=$? ; _build_latest ; buildfail=$(($buildfail+$?)) ;;

esac

docker logout 2>&1 | _oneline
test -f Dockerfile && rm Dockerfile

exit $buildfail
