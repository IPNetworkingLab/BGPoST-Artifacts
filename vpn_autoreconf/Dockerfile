FROM alpine:3.19

RUN apk update && apk upgrade && \
    apk add autoconf automake build-base iproute2 \
            flex bison linux-headers ncurses-dev \
            readline-dev libssh-dev git

RUN git clone https://gitlab.nic.cz/labs/bird.git /opt/bird && \
    cd /opt/bird && git checkout v2.14 && autoreconf -si && \
    ./configure --prefix=/usr \
        --sysconfdir=/etc/bird \
        --runstatedir=/run  \
        --localstatedir=/var && \
    make -j$(nproc) && \
    make install && \
    rm -rf /opt/bird

ENTRYPOINT bird 
