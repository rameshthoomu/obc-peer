#!/bin/bash

# ---------------------------------------------------------------------------
# Install the openblockchain/baseimage docker environment
# ---------------------------------------------------------------------------
#
# There are some interesting things to note here:
#
# 1) Note that we take the slightly unorthodox route of _not_ publishing
#    a "latest" tag to dockerhub.  Rather, we only publish specifically
#    versioned images and we build the notion of "latest" here locally
#    during vagrant provisioning.  This is because the notion always
#    pulling the latest/greatest from the net doesn't really apply to us;
#    we always want a coupling between the dev-env and the docker environment.
#    At the same time, requiring each and every Dockerfile to pull a specific
#    version adds overhead to the Dockerfile generation logic.  Therefore,
#    we employ a hybrid solution that capitalizes on how docker treats the
#    "latest" tag.  That is, untagged references implicitly assume the tag
#    "latest" (good for simple Dockerfiles), but will satisfy the tag from
#    the local cache before going to the net (good for helping us control
#    what "latest" means locally)
#
#    A good blog entry covering the mechanism being exploited may be found here:
#
#          http://container-solutions.com/docker-latest-confusion
#
# 2) A benefit of (1) is that we now have a convenient vehicle for performing
#    JIT customizations of our docker image during provisioning just like we
#    do for vagrant.  For example, we can install new packages in docker within
#    this script.  We will capitalize on this in future patches.
#
# 3) Note that we do some funky processing of the environment (see "printenv"
#    and "ENV" components below).  Whats happening is we are providing a vehicle
#    for allowing the baseimage to include environmental definitions using
#    standard linux mechanisms (e.g. /etc/profile.d).  The problem is that
#    docker-run by default runs a non-login/non-interactive /bin/dash shell
#    which omits any normal /etc/profile or ~/.bashrc type processing, including
#    environment variable definitions.  So what we do is we force the execution
#    of an interactive shell and extract the defined environment variables
#    (via "printenv") and then re-inject them (using Dockerfile::ENV) in a
#    manner that will make them visible to a non-interactive DASH shell.
#
#    This helps for things like defining things such as the GOPATH.
#
#    An alternative would be to bake any Dockerfile::ENV items in during
#    baseimage creation, but packer lacks the capability to do so, so this
#    is a compromise.
# ---------------------------------------------------------------------------
DOCKER_BASEIMAGE=openblockchain/baseimage
DOCKER_FQBASEIMAGE=$DOCKER_BASEIMAGE:$1
docker pull $DOCKER_FQBASEIMAGE
GUESTENV=`mktemp`
# extract the interactive environment
docker run -i $DOCKER_FQBASEIMAGE /bin/bash -l -c printenv > $GUESTENV
# and then inject the environment for use under standard RUN directives with a :latest tag
echo -e "FROM $DOCKER_FQBASEIMAGE\n`for i in \`cat $GUESTENV\`; do echo ENV $i; done`"  | docker build -t $DOCKER_BASEIMAGE:latest -
rm $GUESTENV

