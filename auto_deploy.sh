# 소스 도커 자동적용 및 자동 컨테이너 시작 스크립트
# ./auto_deploy.sh

## 컨테이너 포트 설정
HOST_PORT=19999
CONTAINER_PORT=19999
## app 홈디렉토리(log 및 heapdump 디렉토리 생성 위치)
APP_HOME="/home/azureuser/apps/api"
## 이미지 Tag
VERSION="lts"
# 프로파일 이름(ex:stage,dev,pro)
SPRING_PROFILE="stage"
## Tag
VERSION="lts"
# 프로파일 이름(ex:stage,dev,pro)
SPRING_PROFILE="stage"

# 대문자 파일 이름을 소문자로 변경(docker tag를 실행하려면 파일명이 소문자여야만 한다.)
to_lowercase() {
  local input="$([[ -p /dev/stdin ]] && cat - || echo "$@")"
  [[ -z "$input" ]] && return 1
  echo "$input" | tr '[:upper:]' '[:lower:]'
}

variable_func()
{
  # 파일명에서 확장자를 제거한 문자열을 서비스 이름으로 사용.
  SERVICE_NAME=$(echo ${DEPLOY_FILE%.*})
  # 이미지 이름
  IMAGE_NAME="${SERVICE_NAME}-${SPRING_PROFILE}"
  # old 배포 파일 관련 변수(도커 배포 시 오래된 소스 파일은 삭제한다.)
  OLD_FILE=$(ls -1 ${APP_HOME}/${SERVICE_NAME}*.jar 2> /dev/null | grep -v "$DEPLOY_FILE") # 디렉토리의 파일 이름 목록을 배열에 저장 (ls -1)
  OLD_FILE_COUNT=$(ls ${APP_HOME}/${SERVICE_NAME}*.jar 2> /dev/null | grep -v "$DEPLOY_FILE" | wc -l)
  # 도커 관련 변수
  CONTAINER_ID=$(docker ps -af ancestor=${IMAGE_NAME}:${VERSION} --format "{{.ID}}")
  IMAGE_ID=$(docker images -f=reference=${IMAGE_NAME}':*' --format "{{.ID}}")
}

lowercase_deploy_file()
{
  ## app 파일명 추출
  DEPLOY_FILE=$(basename $APP_HOME/*.jar)
  local FILE=$(to_lowercase $DEPLOY_FILE) # 파일명을 소문자로 변경
  if [[ $FILE != $DEPLOY_FILE ]];then     # 소문자로 변경한 파일과 원래 배포하려는 파일이 동일한지 비교
    mv $DEPLOY_FILE $(to_lowercase $DEPLOY_FILE)  # 파일이 대문자이면 소문자로 변경
    DEPLOY_FILE=$(basename $APP_HOME/*.jar)       # 변경된 파일을 $DEPLOY_FILE 변수에 저장
    variable_func
  else
    variable_func
  fi
}

check_param()
{
  # 인자값 개수($#) 1보다 작으면, 스크립트 사용법을 출력하고 종료.
  if [[ "$#" -lt 1 ]]; then
    echo "Usage: $0 filenname"
    exit 1
  fi
}

check_dir()
{
  if [[ ! -d ${APP_HOME} ]];then
    echo "Does not exist ${APP_HOME} ========> Create ${APP_HOME}"
    mkdir -p ${APP_HOME}
  fi
}

check_app()
{
  # 배포할 파일, 배포할 파일의 디렉토리 생성 유무 확인
  if [[ -f ${APP_HOME}/${DEPLOY_FILE} ]];then
    return 0
  else
    echo "$DEPLOY_FILE dose not exist in $APP_HOME"
    exit 1
  fi
}

remove_old_file()
{
  # old 버전의 배포 파일이 있으면 삭제한다.
  if [[ -n $OLD_FILE ]] && [[ $OLD_FILE_COUNT -gt 0 ]];then
    echo "OLD_FILE_COUNT=$OLD_FILE_COUNT"
    echo "remove old version"
    for array in "${OLD_FILE[@]}"
    do
      echo "$array"
      rm $array
    done
  fi
}

docker_conainer_stop_remove()
{
  # 실행 중인 컨테이너를 stop하고 delete한다.
  if [ $CONTAINER_ID ];then
    echo "CONTAINER_ID=$CONTAINER_ID"
    echo "docker stop $CONTAINER_ID"
    docker stop $CONTAINER_ID
    echo "---------------------"
    echo "Docker container remove"
    echo "docker rm $CONTAINER_ID"
    docker rm $CONTAINER_ID
  else
    echo "CONTAINER is Empty pass..."
  fi
}

docker_image_remove()
{
  # 기존 생성된 이미지 삭제
  if [ $IMAGE_ID ];then
    echo "IMAGE_ID=$IMAGE_ID"
    echo "docker rmi -f $IMAGE_ID"
    docker rmi -f $IMAGE_ID
  else
    echo "IMAGE is Empty pass..."
  fi
}

docker_image_build()
{
  echo "Docker build"
  docker build --build-arg DEPLOY_FILE="${DEPLOY_FILE}" \
    --build-arg DEPLOY_FILE="${DEPLOY_FILE}" \
    --build-arg SPRING_PROFILE=${SPRING_PROFILE}  \
    --tag ${IMAGE_NAME}:${VERSION} ./
}

docker_conainer_start()
{
  echo "Run docker container"
  docker run -itd -p $HOST_PORT:$CONTAINER_PORT \
    --name ${IMAGE_NAME} \
    -v $APP_HOME/logs:/logs \
    -v $APP_HOME/heapdump:/heapdump:rw \
    -v /etc/localtime:/etc/localtime:ro \
    -e TZ=Asia/Seoul ${IMAGE_NAME}:${VERSION}
}

main()
{
  if [[ -x $(basename $0) ]];then   # 스크립트가 실행가능한 상태인지 체크
    cd ${APP_HOME} >& /dev/null || { echo "[Cannot cd to ${APP_HOME}]"; exit 1; }
    check_dir && check_app || { echo "[Failed check dir and check app]"; exit 1; }
    remove_old_file
    docker_conainer_stop_remove && docker_image_remove || { echo "[cannot stop container and remove image ]"; exit 1; }
    docker_image_build && docker_conainer_start || { echo "[cannot build image and start container ]"; exit 1; }
    rm $DEPLOY_FILE && echo "[ Successfully docker build and run ]"
  else
    echo "Cannot run a $(basename $0)"
    exit 1
  fi
}

# 인자값을 체크하고 대문자 파일명을 소문자로 변경한고 나면, main을 실행한다.
check_param "$@" && lowercase_deploy_file && main
