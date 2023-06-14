#!/bin/bash

# code to ignore case restrictions
shopt -s nocasematch

# help function
help()
{
  echo "Usage: ./run_scarab.sh [ -h | --help ]
                [ -b | --build]
                [ -i | --spec2017_iso ]
                [ -a | --appname ]
                [ -p | --parameters ]
                [ -t | --trace_based ]"
  echo
  echo "Options:"
  echo "h     Print this Help."
  echo "b     Build a docker image. Run a container of existing docker image without bulding an image if not given. e.g) -b"
  echo "i     Path to the SPEC2017 iso. e.g) -i SPEC2017/cpu2017-1_0_5.iso"
  echo "a     Application name (508.namd_r | 519.lbm_r | 520.omnetpp_r | 527.cam4_r | 548.exchange2_r | 549.fotonik3d_r). e.g) -a 519.lbm_r"
  echo "p     Scarab parameters. e.g) -p '--frontend memtrace --fetch_off_path_ops 1 --fdip_enable 1 --inst_limit 999900 --uop_cache_enable 0'"
  echo "t     Run trace-based simulations for the SimPoint workflow. Otherwise, run executable-driven simulations. e.g) -t"
}

SHORT=h:,b,i:,a:,p:,t
LONG=help:,build:,spec2017_iso:,appname:,parameters:,trace_based
OPTS=$(getopt -a -n run_scarab.sh --options $SHORT --longoptions $LONG -- "$@")

VALID_ARGUMENTS=$# # Returns the count of arguments that are in short or long options

if [ "$VALID_ARGUMENTS" -eq 0 ]; then
  help
  exit 0
fi

eval set -- "$OPTS"

# Get the options
while [[ $# -gt 0 ]];
do
  case "$1" in
    -h | --help) # display help
      help
      exit 0
      ;;
    -b | --build) # build a docker image
      BUILD=true
      shift
      ;;
    -i | --spec2017_iso) # application name
      SPEC2017_ISO="$2"
      echo $SPEC2017_ISO
      shift 2
      ;;
    -a | --appname) # application name
      APPNAME="$2"
      shift 2
      ;;
    -p | --parameters) # scarab parameters
      SCARABPARAMS="$2"
      shift 2
      ;;
    -t | --trace_based) # simulation type for simpoint method
      TRACE_BASED=true
      shift
      ;;
    --)
      shift 2
      break
      ;;
    *) # unexpected option
      echo "Unexpected option: $1"
      exit 1
      ;;
  esac
done

if [ -z "$APPNAME" ]; then
  echo "appname is unset"
  exit
fi

case $APPNAME in
  # TODO: add all SPEC names
  508.namd_r | 519.lbm_r | 520.omnetpp_r | 527.cam4_r | 548.exchange2_r | 549.fotonik3d_r)
    echo "spec2017"
    APP_GROUPNAME="spec2017_g"
    # build a docker image
    if [ $BUILD ]; then
      if [ -z "$SPEC2017_ISO" ]; then
        echo "path to spec2017 iso is unset"
        exit
      fi
      DOCKER_BUILDKIT=1 COMPOSE_DOCKER_CLI_BUILD=1 docker build . -f ./SPEC2017/Dockerfile --no-cache -t $APP_GROUPNAME:latest --build-arg SPEC2017_ISO="$SPEC2017_ISO"
      # create volume for the app group
      docker volume create $APP_GROUPNAME
    else
      # rm the last container
      docker rm $APP_GROUPNAME -f
    fi
    ;;
  *)
    echo "unknown application"
    exit
    ;;
esac


# set BINCMD
case $APPNAME in
  508.namd_r | 519.lbm_r | 520.omnetpp_r | 527.cam4_r | 548.exchange2_r | 549.fotonik3d_r)
    # SPEC app cmd is set within container
    BINCMD=""
    ;;
esac

# mount and install spec benchmark
if [ $BUILD ] && [ "$APP_GROUPNAME" == "spec2017_g" ]; then
  # TODO: make it inside docker file?
  # no detach, wait for it to terminate
  echo "installing spec 2017..."
  # docker exec -it $APP_GROUPNAME /bin/bash -c "cd /home/memtrace && mkdir cpu2017_install && echo \"memtrace\" | sudo -S mount -t iso9660 -o ro,exec,loop cpu2017.iso ./cpu2017_install"
  # docker exec -it $APP_GROUPNAME /bin/bash -c "cd /home/memtrace && mkdir cpu2017 && cd cpu2017_install && echo \"yes\" | ./install.sh -d /home/memtrace/cpu2017"

  INSTALL="
  cd /home/memtrace && mkdir cpu2017_install \
  && echo \"memtrace\" | sudo -S mount -t iso9660 -o ro,exec,loop cpu2017.iso ./cpu2017_install \
  && cd /home/memtrace && mkdir cpu2017 \
  && cd cpu2017_install \
  && echo \"yes\" | ./install.sh -d /home/memtrace/cpu2017
  "
  docker run --privileged -it --name $APP_GROUPNAME -v $APP_GROUPNAME:/home/memtrace $APP_GROUPNAME:latest /bin/bash -c "$INSTALL"
  docker cp ./SPEC2017/memtrace.cfg $APP_GROUPNAME:/home/memtrace/cpu2017/config/memtrace.cfg
  docker container rm $APP_GROUPNAME
fi

# start container
# docker run -dit --name $APP_GROUPNAME -v $APP_GROUPNAME:/home/memtrace $APP_GROUPNAME:latest /bin/bash
# the simpoint workflow
# docker exec -dit --privileged $APP_GROUPNAME /home/memtrace/run_simpoint.sh $APP_GROUPNAME &
# docker exec -it $APP_GROUPNAME /home/memtrace/run_simpoint.sh "$APPNAME" "$APP_GROUPNAME" "$BINCMD" "$SCARABPARAMS" "$TRACE_BASED"
docker run -dit --name $APP_GROUPNAME -v $APP_GROUPNAME:/home/memtrace $APP_GROUPNAME:latest /home/memtrace/run_simpoint.sh "$APPNAME" "$APP_GROUPNAME" "$BINCMD" "$SCARABPARAMS" "$TRACE_BASED"
echo "To inspect the progress, use \"docker logs -t $APP_GROUPNAME\""
echo "To inspect the running container interactively, use \"docker exec -it $APP_GROUPNAME /bin/bash\""
