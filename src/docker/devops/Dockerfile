FROM ubuntu:20.04

ARG UID
ARG GID
ARG PRODUCT

ENV PRODUCT=$PRODUCT
ENV USER="ubuntu"
ENV GROUP="ubuntu"
ENV TERM="xterm-256color"
ENV TZ="Etc/UTC"
# this is the dir to use to edit the source code
ENV PRODUCT_DIR="/opt/$PRODUCT"
VOLUME $PRODUCT_DIR

ENV TERM="xterm-256color"
ENV PS1="`date \"+%F %T\"` \u@\h  \w \n\n  "
ENV TZ="Etc/UTC"
# app user and group are used to run in non-root mode
ENV USER=ubuntu
ENV GROUP=ubuntu
ENV ENV=dev

# workaround the interactivity questions on ubuntu
RUN echo \n\
XKBMODEL="pc105" \n\
XKBLAYOUT="se" \n\
XKBVARIANT="" \n\
XKBOPTIONS="" \n\
BACKSPACE="guess" \n\
 > /etc/default/keyboard

# ubuntu 20.04 os utils
RUN export DEBIAN_FRONTEND=noninteractive && apt-get update && apt-get upgrade -y && \
   apt-get install -y --no-install-recommends apt-utils
RUN export DEBIAN_FRONTEND=noninteractive && ln -fs /usr/share/zoneinfo/UTC /etc/localtime && \
   apt-get install -y --no-install-recommends tzdata && \
   dpkg-reconfigure --frontend noninteractive tzdata
RUN export DEBIAN_FRONTEND=noninteractive && apt-get install -y \
        lsb-release sudo curl net-tools wget bsdmainutils \
        git zip unzip build-essential linux-headers-5.4.0-1037-aws \
        perl make vim ufw jq snapd debconf-utils dialog telnet
RUN export DEBIAN_FRONTEND=noninteractive && apt-get clean all && apt-get install --fix-missing

# start ::: install python && python libs
RUN export DEBIAN_FRONTEND=noninteractive && apt-get install -y \
        python3.8 python3-pip python3.8-venv
RUN ln -sfn /usr/bin/python3.8 /usr/bin/python && \
    ln -sfn /usr/bin/python3.8 /usr/bin/python3
# stop  ::: install python && python libs

# start ::: install depts for headless chrome and puppetteer
# src: https://github.com/puppeteer/puppeteer/blob/main/docs/troubleshooting.md#chrome-headless-doesnt-launch-on-unix
RUN export DEBIAN_FRONTEND=noninteractive && apt-get update && apt-get upgrade -y && \
    apt-get install -y ca-certificates fonts-liberation libappindicator3-1 libasound2 libatk-bridge2.0-0 \
    libatk1.0-0 libc6 libcairo2 libcups2 libdbus-1-3 libexpat1 libfontconfig1 libgbm1 libgcc1 libglib2.0-0 \
    libgtk-3-0 libnspr4 libnss3 libpango-1.0-0 libpangocairo-1.0-0 libstdc++6 libx11-6 libx11-xcb1 libxcb1 \
    libxcomposite1 libxcursor1 libxdamage1 libxext6 libxfixes3 libxi6 libxrandr2 libxrender1 libxss1 libxtst6 \
    lsb-release wget xdg-utils
# stop  ::: install depts for headless chrome and puppetteer

# Enable host to container edit of proj code on ubuntu and mac.
RUN test -z $(getent group $GID | cut -d: -f1) || \
      groupmod -g $((GID+1000)) $(getent group $GID | cut -d: -f1)

RUN addgroup --gid $GID $GROUP
RUN adduser \
      --gid $GID \
      --shell "/bin/bash" \
      --home "/home/$USER" \
      --uid $UID \
      $USER && exit 0

RUN echo "$USER:1432@lAFk" | chpasswd
# TODO: remove this line during deployment
RUN test $ENV != 'prd' && echo "$USER ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
RUN echo "export PS1=\"$PS1\"" >> /home/$USER.bashrc

# got into non-root mode, use the app user from now on
USER $USER

# the static non-editable dir could be used for deployments
ADD --chown=$USER:$GROUP "." "/home/"$USER""$PRODUCT_DIR""

# start ::: deploy aws-cli
RUN bash /home/"$USER""$PRODUCT_DIR"/run -a do_ubuntu_check_install_awscli
# stop  ::: deploy aws-cli

# start ::: deploy nodejs
RUN bash /home/"$USER""$PRODUCT_DIR"/run -a do_ubuntu_check_install_nodejs
# stop  ::: deploy nodejs

# start ::: the global npm modules
RUN bash /home/"$USER""$PRODUCT_DIR"/run -a do_ubuntu_check_install_global_npm_modules
# stop  ::: the global npm modules

# start ::: install python modules
RUN export TGT_DIR=/home/"$USER""$PRODUCT_DIR"/src/python/api-caller && \
  bash /home/"$USER""$PRODUCT_DIR"/run -a do_check_install_py_modules

RUN export TGT_DIR=/home/"$USER""$PRODUCT_DIR"/src/python/min-jinja && \
  bash /home/"$USER""$PRODUCT_DIR"/run -a do_check_install_py_modules
# stop  ::: install python modules

# but use the proj root dir to write the code on and interact
WORKDIR $PRODUCT_DIR

CMD exec /bin/bash -c "/home/"$USER""$PRODUCT_DIR"/src/bash/run/docker-init.sh"
# CMD exec /bin/bash -c "trap : TERM INT; sleep infinity & wait"
