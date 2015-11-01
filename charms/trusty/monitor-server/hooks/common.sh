#!/bin/bash
APP_NAME=simple-monitor-server

WORK_DIR=/var/lib/$APP_NAME
CONFIG_PATH=${WORK_DIR}/${APP_NAME}.conf
JUJU_TOOL_CONFIG_PATH=${WORK_DIR}/.jujuapi.yaml

install(){
  rm -rf $WORK_DIR
  mkdir -p $WORK_DIR

  #install jujuapicli
  apt-get install -y python-jujuclient
  cp ./lib/jujuapicli $WORK_DIR

  #install server
  cp ./lib/monitor-server $WORK_DIR/$APP_NAME

  render_config
  render_init

  open-port 8090
}

render_juju_tool_config(){

  local API_HOST=$JUJU_API_HOST
  
  if [ -n "$CONFIG_JUJU_API_HOST" ]; then
      API_HOST=$CONFIG_JUJU_API_HOST
  fi

  echo "juju-api:
  endpoint: "wss://"${API_HOST}"/ws"
  admin-secret: ${JUJU_API_PASSWORD}
" > $JUJU_TOOL_CONFIG_PATH

}

render_config(){
  echo "
REDIS_HOST=${REDIS_HOST}
CHECK_PERIOD=${CHECK_PERIOD}
PORT=${PORT}
JUJU_API_HOST=${JUJU_API_HOST}
JUJU_API_PASSWORD=${JUJU_API_PASSWORD}
JUJU_DEPLOY_DELAY=${JUJU_DEPLOY_DELAY}
MESOS_DEPLOY_DELAY=${MESOS_DEPLOY_DELAY}
MARATHON_API_HOST=${MARATHON_API_HOST}
JUJU_SCALE_UP=${JUJU_SCALE_UP}
JUJU_SCALE_DOWN=${JUJU_SCALE_DOWN}
MESOS_SCALE_UP=${MESOS_SCALE_UP}
MESOS_SCALE_DOWN=${MESOS_SCALE_DOWN}
CONFIG_JUJU_API_HOST=${CONFIG_JUJU_API_HOST}
" > $CONFIG_PATH
}

render_init(){

    echo '
description "call-consumer"
author "gdubina <gdubina@dataart.com>"
start on runlevel [2345]
stop on runlevel [!2345]
respawn
normal exit 0

limit nofile 20000 20000

script
  . '$CONFIG_PATH'
  '$WORK_DIR'/'$APP_NAME' -r $REDIS_HOST -p $PORT -t $CHECK_PERIOD -jd $JUJU_DEPLOY_DELAY -md $MESOS_DEPLOY_DELAY -j-up $JUJU_SCALE_UP -j-down $JUJU_SCALE_DOWN -m-up $MESOS_SCALE_UP -m-down $MESOS_SCALE_DOWN -m $MARATHON_API_HOST -cli-dir '$WORK_DIR'
end script
' > /etc/init/${APP_NAME}.conf

}

start_me(){
  if [ -z "`status $APP_NAME | grep start`" ]; then
    start $APP_NAME
  fi
}

stop_me(){
  if [ -n "`status $APP_NAME | grep start`" ]; then
    stop $APP_NAME
  fi
}

restart_me(){
  stop_me
  start_me
#  restart $APP_NAME  
}
