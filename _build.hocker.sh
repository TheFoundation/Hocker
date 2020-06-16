#/bin/sh


PROJECT_NAME=hocker
export PROJECT_NAME=hocker
###MODE DECISION

## DEFAULT : one full image to save runner time 
MODE=onefullimage
#MODE=allfeaturesincreasing

        export DOCKER_BUILDKIT=1


case $1 in
  php5|p5)  MODE="onefullimage" ;; 
  php7|p7)  MODE="onefullimage" ;;
  rest|aux) MODE="onefullimage" ;;
  ""  )     MODE="allfeaturesincreasing" ;;  ## empty , build all
  **  )     MODE="allfeaturesincreasing" ;;  ## out of range , build all


esac
##

_build_docker_buildx() { 
        PROJECT_NAME=hocker
        export PROJECT_NAME=hocker
        #echo -n ":REG_LOGIN[test]:"
        #docker login  -u ${REGISTRY_USER} -p ${REGISTRY_PASSWORD} ${REGISTRY_HOST} || true 
        #docker logout
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
        (docker push ${REGISTRY_PROJECT}/${PROJECT_NAME}:buildhelper_buildx |grep -v -e Waiting$ -e Preparing$ -e "Layer already exists$";docker logout 2>&1 |grep -e emov -e redential)  |sed 's/$/ →→ /g;s/Pushed/+/g' |tr -d '\n'
        docker build -o . ./docker-buildx

    echo ; } ;

_reformat_docker_purge() { sed 's/^deleted: .\+:\([[:alnum:]].\{2\}\).\+\([[:alnum:]].\{2\}\)/\1..\2|/g;s/^\(.\)[[:alnum:]].\{61\}\(.\)/\1.\2|/g' |tr -d '\n' ; } ;
    
_docker_push() { 
        ##docker buildx 2>&1 |grep -q "imagetools" || ( )
        IMAGETAG_SHORT=$1
        echo "↑↑↑UPLOAD↑↑↑"
            docker image ls
        echo -n ":REG_LOGIN[push]:"
            sleep $(($RANDOM%13));sleep  $(($RANDOM%23));docker login  -u ${REGISTRY_USER} -p ${REGISTRY_PASSWORD} ${REGISTRY_HOST}
            echo -n ":DOCKER:PUSH@"${REGISTRY_PROJECT}/${PROJECT_NAME}:${IMAGETAG_SHORT}":"
            (docker push ${REGISTRY_PROJECT}/${PROJECT_NAME}:${IMAGETAG_SHORT} |grep -v -e Waiting$ -e Preparing$ -e "Layer already exists$";docker logout)  |sed 's/$/ →→ /g;s/Pushed/+/g' |tr -d '\n'
    echo -n "|" ; } ;
#####################################
_docker_build() {
                IMAGETAG_SHORT="$1"
                IMAGETAG="$2"
                
                start=$(date -u +%s)
                #docker build -t hocker:${IMAGETAG_SHORT} $buildstring -f $FILENAME --rm=false . &> ${startdir}/buildlogs/build-${IMAGETAG}".log"
                ## NO BUILDX ,use standard instructions
                docker buildx 2>&1 |grep -q "imagetools" || ( echo "::build: NO buildx,DOING MY ARCHITECURE ONLY ";
                echo -ne "DOCKER bUILD, running the following command: \e[1;31m"
                echo docker build --cache-from hocker:${IMAGETAG_SHORT} -t hocker:${IMAGETAG_SHORT} $buildstring -f "Dockerfile.current" --rm=false -t ${REGISTRY_PROJECT}/${PROJECT_NAME}:${IMAGETAG_SHORT} .
                echo -e "\e[0m\e[1;42m STDOUT and STDERR goes to: "buildlogs/build-${IMAGETAG_SHORT}".log \e[0m"
                    docker build --cache-from hocker:${IMAGETAG_SHORT} -t hocker:${IMAGETAG_SHORT} $buildstring -f "Dockerfile.current" --rm=false -t ${REGISTRY_PROJECT}/${PROJECT_NAME}:${IMAGETAG_SHORT} . &> ${startdir}/buildlogs/build-${IMAGETAG}".log"
                )
                ## HAVING BUILDX , builder should escalate for stack incl. armV7 / aarch64 / amd64 
                docker buildx 2>&1 |grep -q "imagetools" && ( echo "::build: buildx FOUND , TRYING MULTIARCH "; 
                # check if docker buildx i available , then prepare it
                have_buildx=nope
                docker buildx 2>&1  |grep -q "imagetools" && have_buildx=true
                
                #echo ${have_buildx} |grep -q =true$ &&  docker buildx create --driver-opt network=host --driver docker-container --use --name mybuilder
                # --driver docker-container --driver-opt network=host 
                #echo ${have_buildx} |grep -q =true$ &&  docker buildx create --use --name mybuilder
                #echo ${have_buildx} |grep -q =true$ &&  docker buildx create --append --name mybuilder --platform linux/arm/v7 rpi
                #echo ${have_buildx} |grep -q =true$ &&  docker buildx create --append --name mybuilder --platform linux/aarch64 rpi4
                echo ${have_buildx} |grep -q =true$ && docker buildx create --use
                echo ${have_buildx} |grep -q =true$ && docker buildx inspect --bootstrap
                
                echo -ne "DOCKER bUILD, running the following command: \e[1;31m"
                echo docker buildx build  --pull --progress plain --platform=linux/amd64,linux/arm64,linux/arm/v7 --cache-from hocker:${IMAGETAG_SHORT} -t hocker:${IMAGETAG_SHORT} -o type=registry $buildstring -f "Dockerfile.current"  .
                echo -e "\e[0m\e[1;42m STDOUT and STDERR goes to: "buildlogs/build-${IMAGETAG}".log \e[0m" 
                ##docker buildx build --platform=linux/amd64,linux/arm64,linux/arm/v7,darwin
#                docker buildx build  --pull --progress plain --platform=linux/amd64,linux/arm64,linux/arm/v7 --cache-from hocker:${IMAGETAG_SHORT} -t hocker:${IMAGETAG_SHORT} -o type=registry $buildstring -f "Dockerfile.current"  .  &> ${startdir}/buildlogs/build-${IMAGETAG}".log"
## pushing i diretly to registry is not  possible with docker driver
                mkdir  dockeroutput
                
                docker buildx build  --pull --progress plain --platform=linux/amd64,linux/arm64,linux/arm/v7 --cache-from hocker:${IMAGETAG_SHORT} -t hocker:${IMAGETAG_SHORT} -o type=local,dest=./dockeroutput $buildstring -f "Dockerfile.current"  .  &> ${startdir}/buildlogs/build-${IMAGETAG}".log"
                ## CATCHING "buildx docker failure"
                grep "multiple platforms feature is currently not supported for docker drive" ${startdir}/buildlogs/build-${IMAGETAG}".log" && ( echo "::build: NO buildx,DOING MY ARCHITECURE ONLY ";
                echo -ne "DOCKER bUILD, running the following command: \e[1;31m"
                echo docker build --cache-from hocker:${IMAGETAG_SHORT} -t hocker:${IMAGETAG_SHORT} $buildstring -f "Dockerfile.current" --rm=false -t ${REGISTRY_PROJECT}/${PROJECT_NAME}:${IMAGETAG_SHORT} .
                echo -e "\e[0m\e[1;42m STDOUT and STDERR goes to:"/buildlogs/build-${IMAGETAG_SHORT}".log \e[0m"
                    docker build --cache-from hocker:${IMAGETAG_SHORT} -t hocker:${IMAGETAG_SHORT} $buildstring -f "Dockerfile.current" --rm=false -t ${REGISTRY_PROJECT}/${PROJECT_NAME}:${IMAGETAG_SHORT} . &> ${startdir}/buildlogs/build-${IMAGETAG}".log"
                )
                
                ## see here https://github.com/docker/buildx
                )
                ##END BUILD STAGE 
                
    echo -n "|" ; tail -n 10 ${startdir}/buildlogs/build-${IMAGETAG}".log"| grep -i -e "failed" -e "did not terminate sucessfully" -q && return true || return false ; } ;
#####################################
_docker_purge() { 
    IMAGETAG_SHORT=$1
    echo;echo "::.oO0 PURGE 0Oo.::"
    docker image rm ${REGISTRY_PROJECT}/${PROJECT_NAME}:${IMAGETAG_SHORT} hocker:${IMAGETAG_SHORT} | grep -v "Untagged"| _reformat_docker_purge
    docker image prune -a -f 2>&1  | _reformat_docker_purge
    echo "→→→";
    docker system prune -a -f 2>&1 | _reformat_docker_purge
    echo ;echo "::IMG"
    docker image ls |sed 's/$/|/g'|tr -d '\n'
    #docker logout
    echo -n "|" ; } ;
#####################################
_run_buildwheel() { 
    runbuildfail=0
    FILENAME=$1
    ## Prepare env
    test -f $FILENAME && ( cat  $FILENAME > Dockerfile.current ) || (echo "Dockerfile not found";break)
    SHORTALIAS=$(basename $(readlink -f ${FILENAME}))
    
        if [[ "$MODE" == "allfeaturesincreasing" ]];then  ## BUID ALL FEATURES with a INSTALL_WHATEVER= scheme IN ORDER OF APPEARANCE in Dockerfile
         
        
        ### START NOSQL_BUILD
         
        #####REPEAT IF MARIADB POSSIBLE
            cat "${FILENAME}" |grep -q INSTALL_MARIADB && (
                echo;echo "→→NO SQL IMAGE"
        cleantags="";
        tagstring="";
        buildstring="";
        test -d /etc/apt/  &&  grep ^Acquire::http::Proxy /etc/apt/ -rlq &&  proxystring=$(grep ^Acquire::http::Proxy /etc/apt/ -r|cut -d: -f2-|sed 's/Acquire::http::Proxy//g;s/ //g;s/\t//g;s/"//g;s/'"'"'//g;s/;//g')  || (echo "NO SYSTEM APT PROXY FOUND ...creating" )
        #echo $proxystring
        test -d /etc/apt/  && grep ^Acquire::http::Proxy /etc/apt/ -rlq && buildstring='--build-arg APT_HTTP_PROXY_URL='$proxystring' '
        
                # do generation once with all features EXCEPT MARIADB OR MYSQL
                for feature in $(cat $FILENAME|grep -v -e MYSQL -e mysql -e MARIADB -e mariadb|grep ^ARG|grep =|sed 's/ARG \+//g;s/ //'|cut -d= -f1 |awk '!x[$0]++' |grep INSTALL|sed 's/$/=true/g') ;do
                
                      tagstring=$tagstring"_"$(echo "$feature"|cut -d_ -f2 |cut -d= -f1 |awk '{print tolower($0)}') ;
                      #buildstring=$buildstring" "$(echo $feature|sed 's/ \+$//g;s/$/"/g;s/=/="/g;s/^/--build-arg /g');
                      buildstring=$buildstring" "$(echo $feature|sed 's/ \+$//g;s/^/--build-arg /g');
                      cleantags=$(echo "$tagstring"|sed 's/^_//g;s/_\+/_/g')
                done
                
                #echo "TAG:$cleantags" # BUILD:$buildstring";
                IMAGETAG=$(echo $FILENAME|sed 's/Dockerfile-//g' |awk '{print tolower($0)}')"_"$cleantags"_"$(date -u +%Y-%m-%d_%H.%M)"_"$(echo $CI_COMMIT_SHA|head -c8);
                IMAGETAG=$(echo "$IMAGETAG"|sed 's/_\+/_/g')
                IMAGETAG_SHORT=${IMAGETAG/_*/}
                IMAGETAG=${IMAGETAG}_NOMYSQL
                IMAGETAG_SHORT=${IMAGETAG_SHORT}_NOMYSQL
                #### since softlinks are eg Dockerfile-php7-bla → Dockerfile-php7.4-bla
                #### we pull also the "dotted" version" before , since they will have exactly the same steps and our "undotted" version does not exist
                SHORTALIAS=$(echo "${SHORTALIAS}"|sed 's/Dockerfile//g;s/^-//g')
                ##FIX Downloads wrong version
                
                #echo "PULLING ${SHORTALIAS} IF NOT FOUND"
                #echo "${FILENAME}"|grep -q "^${SHORTALIAS}$" ||  (docker pull  ${REGISTRY_PROJECT}/${PROJECT_NAME}:${SHORTALIAS} 2>&1 || true ) |grep -v -e Verifying -e Download|sed 's/Pull.\+/↓/g'|sed 's/\(Waiting\|Checksum\|exists\|complete\|fs layer\)$/→/g'|tr -d '\n'
                  echo "docker pull  "${REGISTRY_PROJECT}/${PROJECT_NAME}:${IMAGETAG_SHORT} .
                   (docker pull  ${REGISTRY_PROJECT}/${PROJECT_NAME}:${IMAGETAG_SHORT} 2>&1 || true ) |grep -v -e Verifying -e Download|sed 's/Pull.\+/↓/g'|sed 's/\(Waiting\|Checksum\|exists\|complete\|fs layer\)$/→/g'|tr -d '\n'
                  #docker pull  -a --disable-content-trust hocker:${REGISTRY_PROJECT}/${PROJECT_NAME}:${IMAGETAG_SHORT} || true
                build_success=no
                _docker_build ${IMAGETAG_SHORT} ${IMAGETAG}
                  tail -n 10 ${startdir}/buildlogs/build-${IMAGETAG}".log" | grep -e "^Successfully built " -e DONE || ( tail -n 13 ${startdir}/buildlogs/build-${IMAGETAG}".log"   )
                  tail -n 10 ${startdir}/buildlogs/build-${IMAGETAG}".log" | grep -e "^Successfully built " -e DONE || runbuildfail=100
                  end=$(date -u +%s)
                  seconds=$((end-start))
                  echo -en "\e[1:42m"
                  TZ=UTC printf "FINISHED: %d days %(%H hours %M minutes %S seconds)T\n" $((seconds/86400)) $seconds | tee -a ${startdir}/buildlogs/build-${IMAGETAG}".log"
                if [ "$build_success" == "yes" ];then
                    _docker_push ${IMAGETAG_SHORT} ##since pushing to remote does not work , also buildx has to be sent## docker buildx 2>&1 |grep -q "imagetools" ||  _docker_push ${IMAGETAG_SHORT}
                else
                  tail -n 13 ${startdir}/buildlogs/build-${IMAGETAG}".log" ;runbuildfail=100
                fi
                
                #  if [ "$runbuildfail" -ne 100 ] ;then
                 #   _docker_push ${IMAGETAG_SHORT} ##since pushing to remote does not work , also buildx has to be sent## docker buildx 2>&1 |grep -q "imagetools" ||  _docker_push ${IMAGETAG_SHORT}
                 # fi
                 ) ##
        
        ### START NORMAL_BUILD
         
        echo -n  "MULTIIMAGE:s:"
        cleantags="";
        tagstring="";
        buildstring="";
        test -d /etc/apt/  &&  grep ^Acquire::http::Proxy /etc/apt/ -rlq &&  proxystring=$(grep ^Acquire::http::Proxy /etc/apt/ -r|cut -d: -f2-|sed 's/Acquire::http::Proxy//g;s/ //g;s/\t//g;s/"//g;s/'"'"'//g;s/;//g')  || (echo "NO SYSTEM APT PROXY FOUND ...creating" )
        #echo $proxystring
        test -d /etc/apt/  && grep ^Acquire::http::Proxy /etc/apt/ -rlq && buildstring='--build-arg APT_HTTP_PROXY_URL='$proxystring' '
        
        for feature in $(cat $FILENAME|grep ^ARG|grep =|sed 's/ARG \+//g;s/ //'|cut -d= -f1 |awk '!x[$0]++' |grep INSTALL|sed 's/$/=true/g') ;do
        
          tagstring=$tagstring"_"$(echo "$feature"|cut -d_ -f2 |cut -d= -f1 |awk '{print tolower($0)}') ;
          #buildstring=$buildstring" "$(echo $feature|sed 's/ \+$//g;s/$/"/g;s/=/="/g;s/^/--build-arg /g');
          buildstring=$buildstring" "$(echo $feature|sed 's/ \+$//g;s/^/--build-arg /g');
        
          ##BUILDER_IMAGE: ${REGISTRY_HOST}/${REGISTRY_PROJECT}/${CI_PROJECT_NAME}
        
          cleantags=$(echo "$tagstring"|sed 's/^_//g;s/_\+/_/g')
                  #echo "TAG:$cleantags" # BUILD:$buildstring";
                  IMAGETAG=$(echo $FILENAME|sed 's/Dockerfile//g;s/^-//g' |awk '{print tolower($0)}')"_"$cleantags"_"$(date -u +%Y-%m-%d_%H.%M)"_"$(echo $CI_COMMIT_SHA|head -c8);
                  IMAGETAG=$(echo "$IMAGETAG"|sed 's/_\+/_/g')
                  IMAGETAG_SHORT=${IMAGETAG/_*/}
                  #### since softlinks are eg Dockerfile-php7-bla → Dockerfile-php7.4-bla
                  #### we pull also the "dotted" version" before , since they will have exactly the same steps and our "undotted" version does not exist
                  SHORTALIAS=$(echo "${SHORTALIAS}"|sed 's/Dockerfile//g;s/^-//g')
                  ##FIX Downloads wrong version
        
                  #echo "PULLING ${SHORTALIAS} IF NOT FOUND"
                  #echo "${FILENAME}"|grep -q "^${SHORTALIAS}$" ||  (docker pull  ${REGISTRY_PROJECT}/${PROJECT_NAME}:${SHORTALIAS} 2>&1 || true ) |grep -v -e Verifying -e Download|sed 's/Pull.\+/↓/g'|sed 's/\(Waiting\|Checksum\|exists\|complete\|fs layer\)$/→/g'|tr -d '\n'
                  echo "docker pull  "${REGISTRY_PROJECT}/${PROJECT_NAME}:${IMAGETAG_SHORT} .
                   (docker pull  ${REGISTRY_PROJECT}/${PROJECT_NAME}:${IMAGETAG_SHORT} 2>&1 || true ) |grep -v -e Verifying -e Download|sed 's/Pull.\+/↓/g'|sed 's/\(Waiting\|Checksum\|exists\|complete\|fs layer\)$/→/g'|tr -d '\n'
                  #docker pull  -a --disable-content-trust hocker:${REGISTRY_PROJECT}/${PROJECT_NAME}:${IMAGETAG_SHORT} || true

                _docker_build ${IMAGETAG_SHORT} ${IMAGETAG} 
                
                  tail -n 10 ${startdir}/buildlogs/build-${IMAGETAG}".log" | grep -e "^Successfully built " -e DONE || ( echo -e "\e[0m\e[3;40m" tail -n 10 ${startdir}/buildlogs/build-${IMAGETAG}".log"  ;echo -e "\e[0m" ;exit 100 )
                  tail -n 10 ${startdir}/buildlogs/build-${IMAGETAG}".log" | grep -e "^Successfully built " -e DONE || runbuildfail=100
                  end=$(date -u +%s)
                  seconds=$((end-start))
                  echo -en "\e[1:42m"
                  TZ=UTC printf "FINISHED: %d days %(%H hours %M minutes %S seconds)T\n" $((seconds/86400)) $seconds | tee -a ${startdir}/buildlogs/build-${IMAGETAG}".log"
                  if [ "$runbuildfail" -ne 100 ] ;then
                    _docker_push ${IMAGETAG_SHORT} ##since pushing to remote does not work , also buildx has to be sent## docker buildx 2>&1 |grep -q "imagetools" ||  _docker_push ${IMAGETAG_SHORT}
                  fi
        ### END NORMAL_BUILD
        
        
        _docker_purge ${IMAGETAG_SHORT}

        
                  #docker push ${REGISTRY_PROJECT}/${CI_PROJECT_NAME}:${CI_COMMIT_REF_SLUG}
        ##CUSTOM REG
        #    - docker push ${BUILDER_IMAGE}:${CI_COMMIT_REF_SLUG}
        #    - docker push ${BUILDER_IMAGE}:latest
        
                  echo -en "\e[0m"
          #$(bash _generate.env.single_container.sh |grep -v -e ^# -e ^$|grep =|sed 's/ \+$//g;s/\(^\|$\)/"/g;s/^/--build-arg /g'|grep -v -e PASS -e USER)  .
          #docker build -t hocker:${IMAGETAG} --pull $(bash _generate.env.single_container.sh |grep -v -e ^# -e ^$|grep =|sed 's/ \+$//g;s/\(^\|$\)/"/g;s/^/--build-arg /g'|grep -v -e PASS -e USER)  .
        
        done
        fi
        
        
        if [[ "$MODE" == "onefullimage" ]] ; then   ## INSTALL ONLY THE FEATURES THAT ARE ENABLED BY DEFAULT DOCKERFILES WITH "ARG INSTALL_WHATEVER=true"
        ### START NOSQL_BUILD
        
        ##### REPEAT ( if dockerfile contains INSTALL_MARIADB)
            cat "${FILENAME}" |grep -q INSTALL_MARIADB && (
                echo;echo "→→NO SQL IMAGE"
        cleantags="";
        tagstring="";
        buildstring="";
        test -d /etc/apt/  &&  grep ^Acquire::http::Proxy /etc/apt/ -rlq &&  proxystring=$(grep ^Acquire::http::Proxy /etc/apt/ -r|cut -d: -f2-|sed 's/Acquire::http::Proxy//g;s/ //g;s/\t//g;s/"//g;s/'"'"'//g;s/;//g')  || (echo "NO SYSTEM APT PROXY FOUND ...creating" )
        #echo $proxystring
        test -d /etc/apt/  && grep ^Acquire::http::Proxy /etc/apt/ -rlq && buildstring='--build-arg APT_HTTP_PROXY_URL='$proxystring' '
        
                # do generation once with all features EXCEPT MARIADB OR MYSQL
                for feature in $(cat $FILENAME|grep -v -e MYSQL -e mysql -e MARIADB -e mariadb|grep ^ARG|grep =true|sed 's/ARG \+//g;s/ //'|cut -d= -f1 |awk '!x[$0]++' |grep INSTALL|sed 's/$/=true/g') ;do
                
                      tagstring=$tagstring"_"$(echo "$feature"|cut -d_ -f2 |cut -d= -f1 |awk '{print tolower($0)}') ;
                      #buildstring=$buildstring" "$(echo $feature|sed 's/ \+$//g;s/$/"/g;s/=/="/g;s/^/--build-arg /g');
                      buildstring=$buildstring" "$(echo $feature|sed 's/ \+$//g;s/^/--build-arg /g');
                      cleantags=$(echo "$tagstring"|sed 's/^_//g;s/_\+/_/g')
                done
                
                #echo "TAG:$cleantags" # BUILD:$buildstring";
                IMAGETAG=$(echo $FILENAME|sed 's/Dockerfile-//g' |awk '{print tolower($0)}')"_"$cleantags"_"$(date -u +%Y-%m-%d_%H.%M)"_"$(echo $CI_COMMIT_SHA|head -c8);
                IMAGETAG=$(echo "$IMAGETAG"|sed 's/_\+/_/g')
                IMAGETAG_SHORT=${IMAGETAG/_*/}
                IMAGETAG=${IMAGETAG}_NOMYSQL
                IMAGETAG_SHORT=${IMAGETAG_SHORT}_NOMYSQL
                #### since softlinks are eg Dockerfile-php7-bla → Dockerfile-php7.4-bla
                #### we pull also the "dotted" version" before , since they will have exactly the same steps and our "undotted" version does not exist
                SHORTALIAS=$(echo "${SHORTALIAS}"|sed 's/Dockerfile//g;s/^-//g')
                ##FIX Downloads wrong version
                
                #echo "PULLING ${SHORTALIAS} IF NOT FOUND"
                #echo "${FILENAME}"|grep -q "^${SHORTALIAS}$" ||  (docker pull  ${REGISTRY_PROJECT}/${PROJECT_NAME}:${SHORTALIAS} 2>&1 || true ) |grep -v -e Verifying -e Download|sed 's/Pull.\+/↓/g'|sed 's/\(Waiting\|Checksum\|exists\|complete\|fs layer\)$/→/g'|tr -d '\n'
                echo "docker pull  "${REGISTRY_PROJECT}/${PROJECT_NAME}:${IMAGETAG_SHORT} .
                (docker pull  ${REGISTRY_PROJECT}/${PROJECT_NAME}:${IMAGETAG_SHORT} 2>&1 || true ) |grep -v -e Verifying -e Download|sed 's/Pull.\+/↓/g'|sed 's/\(Waiting\|Checksum\|exists\|complete\|fs layer\)$/→/g'|tr -d '\n'
                #docker pull  -a --disable-content-trust hocker:${REGISTRY_PROJECT}/${PROJECT_NAME}:${IMAGETAG_SHORT} || true
                
                _docker_build ${IMAGETAG_SHORT} ${IMAGETAG} 

                tail -n 10 ${startdir}/buildlogs/build-${IMAGETAG}".log" | grep -e "^Successfully built " -e DONE || ( tail -n 13 ${startdir}/buildlogs/build-${IMAGETAG}".log"  ;exit 100 )
                tail -n 10 ${startdir}/buildlogs/build-${IMAGETAG}".log" | grep -e "^Successfully built " -e DONE || runbuildfail=100
                end=$(date -u +%s)
                seconds=$((end-start))
                echo -en "\e[1:42m"
                TZ=UTC printf "FINISHED: %d days %(%H hours %M minutes %S seconds)T\n" $((seconds/86400)) $seconds | tee -a ${startdir}/buildlogs/build-${IMAGETAG}".log"
                if [ "$runbuildfail" -ne 100 ] ;then
                    _docker_push ${IMAGETAG_SHORT} ##since pushing to remote does not work , also buildx has to be sent## docker buildx 2>&1 |grep -q "imagetools" ||  _docker_push ${IMAGETAG_SHORT}      
                fi
                ) ##
        
        
        
        ### START NORMAL BUILD ( 
                  echo -n "SINGLEIMAGE:"
        cleantags="";
        tagstring="";
        buildstring="";
        test -d /etc/apt/  &&  grep ^Acquire::http::Proxy /etc/apt/ -rlq &&  proxystring=$(grep ^Acquire::http::Proxy /etc/apt/ -r|cut -d: -f2-|sed 's/Acquire::http::Proxy//g;s/ //g;s/\t//g;s/"//g;s/'"'"'//g;s/;//g')  || (echo "NO SYSTEM APT PROXY FOUND ...creating" )
        #echo $proxystring
        test -d /etc/apt/  && grep ^Acquire::http::Proxy /etc/apt/ -rlq && buildstring='--build-arg APT_HTTP_PROXY_URL='$proxystring' '
        
        
                  # do generation once with all features
                  for feature in $(cat $FILENAME|grep ^ARG|grep =true|sed 's/ARG \+//g;s/ //'|cut -d= -f1 |awk '!x[$0]++' |grep INSTALL|sed 's/$/=true/g') ;do
        
                        tagstring=$tagstring"_"$(echo "$feature"|cut -d_ -f2 |cut -d= -f1 |awk '{print tolower($0)}') ;
                        #buildstring=$buildstring" "$(echo $feature|sed 's/ \+$//g;s/$/"/g;s/=/="/g;s/^/--build-arg /g');
                        buildstring=$buildstring" "$(echo $feature|sed 's/ \+$//g;s/^/--build-arg /g');
                        cleantags=$(echo "$tagstring"|sed 's/^_//g;s/_\+/_/g')
                done
      
                #echo "TAG:$cleantags" # BUILD:$buildstring";
                IMAGETAG=$(echo $FILENAME|sed 's/Dockerfile-//g' |awk '{print tolower($0)}')"_"$cleantags"_"$(date -u +%Y-%m-%d_%H.%M)"_"$(echo $CI_COMMIT_SHA|head -c8);
                IMAGETAG=$(echo "$IMAGETAG"|sed 's/_\+/_/g')
                IMAGETAG_SHORT=${IMAGETAG/_*/}
                #### since softlinks are eg Dockerfile-php7-bla → Dockerfile-php7.4-bla
                #### we pull also the "dotted" version" before , since they will have exactly the same steps and our "undotted" version does not exist
                SHORTALIAS=$(echo "${SHORTALIAS}"|sed 's/Dockerfile//g;s/^-//g')
                ##FIX Downloads wrong version
      
                #echo "PULLING ${SHORTALIAS} IF NOT FOUND"
                #echo "${FILENAME}"|grep -q "^${SHORTALIAS}$" ||  (docker pull  ${REGISTRY_PROJECT}/${PROJECT_NAME}:${SHORTALIAS} 2>&1 || true ) |grep -v -e Verifying -e Download|sed 's/Pull.\+/↓/g'|sed 's/\(Waiting\|Checksum\|exists\|complete\|fs layer\)$/→/g'|tr -d '\n'
                echo "docker pull  "${REGISTRY_PROJECT}/${PROJECT_NAME}:${IMAGETAG_SHORT} .
                 (docker pull  ${REGISTRY_PROJECT}/${PROJECT_NAME}:${IMAGETAG_SHORT} 2>&1 || true ) |grep -v -e Verifying -e Download|sed 's/Pull.\+/↓/g'|sed 's/\(Waiting\|Checksum\|exists\|complete\|fs layer\)$/→/g'|tr -d '\n'
                #docker pull  -a --disable-content-trust hocker:${REGISTRY_PROJECT}/${PROJECT_NAME}:${IMAGETAG_SHORT} || true
                
                _docker_build ${IMAGETAG_SHORT} ${IMAGETAG}  
                
                tail -n 10 ${startdir}/buildlogs/build-${IMAGETAG}".log" | grep -e "^Successfully built " -e DONE || ( tail -n 13 ${startdir}/buildlogs/build-${IMAGETAG}".log"  ;exit 100 )
                tail -n 10 ${startdir}/buildlogs/build-${IMAGETAG}".log" | grep -e "^Successfully built " -e DONE || runbuildfail=100
                end=$(date -u +%s)
                seconds=$((end-start))
                echo -en "\e[1:42m"
                TZ=UTC printf "FINISHED: %d days %(%H hours %M minutes %S seconds)T\n" $((seconds/86400)) $seconds | tee -a ${startdir}/buildlogs/build-${IMAGETAG}".log"
                if [ "$runbuildfail" -ne 100 ] ;then
                    _docker_push ${IMAGETAG_SHORT} ##since pushing to remote does not work , also buildx has to be sent## docker buildx 2>&1 |grep -q "imagetools" ||  _docker_push ${IMAGETAG_SHORT}
                fi
      ### END NORMAL BUILD

        _docker_purge ${IMAGETAG_SHORT}
                #docker push ${REGISTRY_PROJECT}/${CI_PROJECT_NAME}:${CI_COMMIT_REF_SLUG}
      ##CUSTOM REG
      #    - docker push ${BUILDER_IMAGE}:${CI_COMMIT_REF_SLUG}
      #    - docker push ${BUILDER_IMAGE}:latest
               echo -en "\e[0m"
      
        fi
            
            
return $runbuildfail ; } ;

### END BUILD WHEL DEFINITION 

_build_latest() { 
    localbuildfail=0
    for FILENAME in $(ls -1 Dockerfile*latest |sort -r);do
        echo DOCKERFILE: $FILENAME
        test -f Dockerfile.current && rm Dockerfile.current
        
       _run_buildwheel ${FILENAME}
        if [ "$?" -ne 0 ] ;then localbuildfail=$(($localbuildfail+10000));fi
    done
return $localbuildfail ; } ;
    

_build_php5() { 
    localbuildfail=0
    for FILENAME in $(ls -1 Dockerfile-php5*|grep -v latest$ |sort -r);do
        echo DOCKERFILE: $FILENAME
        test -f Dockerfile.current && rm Dockerfile.current
        
       _run_buildwheel ${FILENAME}
        if [ "$?" -ne 0 ] ;then localbuildfail=$(($localbuildfail+10));fi
    done
return $localbuildfail ; } ;
    
    
_build_php7() { 
    localbuildfail=0
    for FILENAME in $(ls -1 Dockerfile-php7* |grep -v latest$ |sort -r);do
        echo DOCKERFILE: $FILENAME
        test -f Dockerfile.current && rm Dockerfile.current
       _run_buildwheel ${FILENAME}
        if [ "$?" -ne 0 ] ;then localbuildfail=$(($localbuildfail+100));fi
    done
return $localbuildfail ; } ;

_build_aux() { 
    localbuildfail=0
    for FILENAME in $(ls -1 Dockerfile-*|grep -v Dockerfile-php|grep -v latest$  |sort -r);do
        echo DOCKERFILE: $FILENAME
        test -f Dockerfile.current && rm Dockerfile.current
       _run_buildwheel ${FILENAME}
        if [ "$?" -ne 0 ] ;then localbuildfail=$(($localbuildfail+1000));fi
    done
return $localbuildfail ; } ;

_build_all() { 
    localbuildfail=0
    for FILENAME in $(ls -1 Dockerfile-*|grep -v latest$ |sort -r);do
        echo DOCKERFILE: $FILENAME
        test -f Dockerfile.current && rm Dockerfile.current
       _run_buildwheel ${FILENAME}
        if [ "$?" -ne 0 ] ;then localbuildfail=$(($localbuildfail+1000000));fi
    done
return $localbuildfail ; } ;


buildargs=""
echo -n "::SYS:PREP"
echo -n "+↑UPGR↑+|"
which apt-get 2>/dev/null |grep -q apt-get && apt-get update &>/dev/null || true
which apk     2>/dev/null |grep -q apk  && apk update &>/dev/null  || true
echo -n "+↑PROG↑+|"
##alpine
which git 2>/dev/null |grep -q git || which apk       2>/dev/null |grep -q apk && apk add git util-linux bash && apk add jq || true
which apk       2>/dev/null |grep -q apk && apk add git util-linux bash qemu-aarch64 qemu-x86_64 qemu-i386 qemu-arm || true

##deb
which git 2>/dev/null |grep -q git || which apt-get   2>/dev/null |grep -q "/apt-get" && apt-get install -y git bash && apt-get -y install jq || true
which apt-get   2>/dev/null |grep -q apt-get && apt-get install -y binfmt-support || true
which apt-get   2>/dev/null |grep -q "/apt-get" && apt-get install -y  qemu-user-static || apt-get install -y  qemu-user-binfmt || true

startdir=$(pwd)
mkdir buildlogs
echo "::GIT"
/bin/sh -c "test -d Hocker || git clone https://github.com/TheFoundation/Hocker.git --recurse-submodules && (cd Hocker ;git pull origin master --recurse-submodules )"
cd Hocker/build/

echo -n ":REG_LOGIN[test:init]:"
sleep $(($RANDOM%42));sleep $(($RANDOM%23));docker login  -u ${REGISTRY_USER} -p ${REGISTRY_PASSWORD} ${REGISTRY_HOST} || exit 666
# Use docker-container driver to allow useful features (push/multi-platform)



docker logout

echo -n "::SYS:PREP=DONE ... "
### LAUNCHING ROCKET
echo '+++WELCOME+++'
echo '|||+++>> SYS: '$(uname -a)" | binfmt count "$(ls /proc/sys/fs/binfmt_misc/ |wc -l) " | BUILDX: "$(docker buildx 2>&1 |grep -q "imagetools"  && echo OK || echo NO )" | docker vers. :"$(docker --version)"| IDentity"$(id -u) " == "$(id -un)"@"$(hostname -f)'|ARGZ : '"$@"'<<+++|||'
test -f Dockerfile.current && rm Dockerfile.current

buildfail=0

case $1 in
  buildx  ) _build_docker_buildx ;;
  latest  )   _build_latest "$@" ;buildfail=$? ;; 
  php5|p5 )  _build_php5 "$@" ;buildfail=$? ;; 
  php7|p7 )  _build_php7 "$@" ;buildfail=$? ;;
  rest|aux) _build_aux  "$@" ;buildfail=$? ;;
  **  )     _build_all ; buildfail=$? ; _build_latest ; buildfail=$(($buildfail+$?)) ;;
  
esac

docker logout
test -f Dockerfile && rm Dockerfile

exit $buildfail
