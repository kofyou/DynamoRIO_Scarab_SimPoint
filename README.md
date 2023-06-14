# SimPoint Based on DynamoRIO and Scarab
This repository is created by [@Surim](https://github.com/5surim) and [@Mingsheng](https://github.com/kofyou).

This repository contains the setup and scripts for the [SimPoint](https://cseweb.ucsd.edu/~calder/simpoint/) methdology with [Dynamorio](https://dynamorio.org/) and [Scarab](https://github.com/hpsresearchgroup/scarab). The applications considered are a subset of [SPEC2017 benchmarks](https://www.spec.org/cpu2017/Docs/index.html#benchmarks). The user may extend it for their own purpose.

## Docker setup
Install Docker based on the instructions from official [docker docs](https://docs.docker.com/get-docker/). The commands to download and run a container can be found [here](https://docs.docker.com/engine/reference/commandline/run/).

## Usage
```
Usage: ./run_scarab.sh [ -h | --help ]
                [ -b | --build]
                [ -i | --spec2017_iso ]
                [ -a | --appname ]
                [ -p | --parameters ]
                [ -t | --trace_based ]

Options:
h     Print this Help.
b     Build a docker image. Run a container of existing docker image without bulding an image if not given. e.g) -b
i     Path to the SPEC2017 iso. e.g) -i SPEC2017/cpu2017-1_0_5.iso
a     Application name (508.namd_r | 519.lbm_r | 520.omnetpp_r | 527.cam4_r | 548.exchange2_r | 549.fotonik3d_r). e.g) -a 519.lbm_r
p     Scarab parameters. e.g) -p '--frontend memtrace --fetch_off_path_ops 1 --fdip_enable 1 --inst_limit 999900 --uop_cache_enable 0'
t     Run trace-based simulations for the SimPoint workflow. e.g) -t
```
### Build an image and run SimPoint for an application
```
$ ./run_scarab.sh -b -i <path/to/SPEC2017_ISO> -a 519.lbm_r -t
```
### Already have built the image, run SimPoint for another application
```
$ ./run_scarab.sh -a 549.fotonik3d_r -t
```