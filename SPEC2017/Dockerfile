# syntax = edrevo/dockerfile-plus

# choose a ubuntu version
FROM ubuntu:focal

INCLUDE+ ./common/Dockerfile.common

# Copy SPEC2017
ARG SPEC2017_ISO
RUN echo $SPEC2017_ISO
COPY --chown=memtrace $SPEC2017_ISO /home/memtrace/cpu2017.iso

USER root
RUN apt-get install -y gfortran
# RUN mount -t iso9660 -o ro,exec,loop cpu2017-1_0_5.iso ./cpu2017

# Switch to the memtrace user
USER memtrace


# Start your application
CMD ["/bin/bash"]
