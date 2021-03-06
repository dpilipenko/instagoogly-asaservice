## START Python27 ##
FROM ubuntu:trusty

ENV PYTHON_VERSION 2.7.11
ENV PYTHON_PIP_VERSION 8.0.2
ENV YASM_VERSION 1.3.0
ENV NUM_CORES 4

RUN locale-gen en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

#RUN apt-get -qq remove ffmpeg
RUN apt-get purge -y python.*

RUN echo deb http://archive.ubuntu.com/ubuntu trusty universe multiverse >> /etc/apt/sources.list; \
    apt-get update -qq && apt-get install -y --force-yes \
    ant \
    autoconf \
    automake \
    build-essential \
    curl \
    checkinstall \
    cmake \
    default-jdk \
    f2c \
    gfortran \
    git \
    g++ \
    imagemagick \
    libass-dev \
    libatlas-base-dev \
    libavcodec-dev \
    libavformat-dev \
    libcnf-dev \
    libfaac-dev \
    libfreeimage-dev \
    libjpeg-dev \
    libjasper-dev \
    libgnutls-dev \
    liblapack3 \
    libmp3lame-dev \
    libpq-dev \
    libpng-dev \
    libssl-dev \
    libtheora-dev \
    libtiff4-dev \
    libtool \
    libxine-dev \
    libxvidcore-dev \
    libv4l-dev \
    libvorbis-dev \
    mercurial \
    openssl \
    pkg-config \
    postgresql-client \
    supervisor \
    wget \
    unzip; \
    apt-get clean

# gpg: key 18ADD4FF: public key "Benjamin Peterson <benjamin@python.org>" imported
ENV GPG_KEY C01E1CAD5EA2C4F0B8E3571504C367C218ADD4FF
RUN set -ex \
        && gpg --keyserver ha.pool.sks-keyservers.net --recv-keys "$GPG_KEY" \
        && curl -fSL "https://www.python.org/ftp/python/$PYTHON_VERSION/Python-$PYTHON_VERSION.tar.xz" -o python.tar.xz \
        && curl -fSL "https://www.python.org/ftp/python/$PYTHON_VERSION/Python-$PYTHON_VERSION.tar.xz.asc" -o python.tar.xz.asc \
        && gpg --verify python.tar.xz.asc \
        && mkdir -p /usr/src/python \
        && tar -xJC /usr/src/python --strip-components=1 -f python.tar.xz \
        && rm python.tar.xz* \
        && cd /usr/src/python \
        && ./configure --enable-shared --enable-unicode=ucs4 \
        && make -j$(nproc) \
        && make install \
        && ldconfig \
        && curl -fSL 'https://bootstrap.pypa.io/get-pip.py' | python2 \
        && pip install --no-cache-dir --upgrade pip==$PYTHON_PIP_VERSION \
        && find /usr/local \
                \( -type d -a -name test -o -name tests \) \
                -o \( -type f -a -name '*.pyc' -o -name '*.pyo' \) \
                -exec rm -rf '{}' + \
        && rm -rf /usr/src/python

RUN pip install --no-cache-dir virtualenv

WORKDIR /usr/local/src

RUN curl -Os http://www.tortall.net/projects/yasm/releases/yasm-${YASM_VERSION}.tar.gz \
    && tar xzvf yasm-${YASM_VERSION}.tar.gz

WORKDIR /usr/local/src/yasm-${YASM_VERSION}
RUN ./configure \
    && make -j ${NUM_CORES} \
    && make install

WORKDIR /usr/local/
RUN rm -rf /usr/local/src
RUN apt-get autoremove -y; apt-get clean -y

RUN mkdir /work
WORKDIR /work

## END Python27 ##

ENV OPENCV_VERSION 2.4.10

WORKDIR /usr/local/src

RUN git clone --depth 1 https://github.com/l-smash/l-smash \
    && git clone --depth 1 git://git.videolan.org/x264.git \
    && hg clone https://bitbucket.org/multicoreware/x265 \
    && git clone --depth 1 git://source.ffmpeg.org/ffmpeg \
    && git clone https://github.com/Itseez/opencv.git \
    && git clone https://github.com/Itseez/opencv_contrib.git \
    && git clone --depth 1 git://github.com/mstorsjo/fdk-aac.git \
    && git clone --depth 1 https://chromium.googlesource.com/webm/libvpx \
    && git clone https://git.xiph.org/opus.git \
    && git clone --depth 1 https://github.com/mulx/aacgain.git

# Build L-SMASH
WORKDIR /usr/local/src/l-smash
RUN ./configure
RUN make -j 4
RUN make install

# Build libx264
WORKDIR /usr/local/src/x264
RUN ./configure --enable-static
RUN make -j 4
RUN make install

# Build libx265
WORKDIR /usr/local/src/x265/build/linux
RUN cmake -DCMAKE_INSTALL_PREFIX:PATH=/usr ../../source
RUN make -j 4
RUN make install

# Build libfdk-aac
WORKDIR /usr/local/src/fdk-aac
RUN autoreconf -fiv
RUN ./configure --disable-shared
RUN make -j 4
RUN make install

# Build libvpx
WORKDIR /usr/local/src/libvpx
RUN ./configure --disable-examples
RUN make -j 4
RUN make install

# Build libopus
WORKDIR /usr/local/src/opus
RUN ./autogen.sh
RUN ./configure --disable-shared
RUN make -j 4
RUN make install

# Build OpenCV 3.x
RUN apt-get update -qq && apt-get install -y --force-yes libopencv-dev
RUN pip install --no-cache-dir --upgrade numpy
WORKDIR /usr/local/src
RUN mkdir -p opencv/release
WORKDIR /usr/local/src/opencv/release
RUN cmake -D CMAKE_BUILD_TYPE=RELEASE \
          -D CMAKE_INSTALL_PREFIX=/usr/local \
          -D WITH_TBB=ON \
          -D BUILD_PYTHON_SUPPORT=ON \
          -D WITH_V4L=ON \
          -D OPENCV_EXTRA_MODULES_PATH=../../opencv_contrib/modules \
          ..
RUN make -j4
RUN make install
RUN sh -c 'echo "/usr/local/lib" > /etc/ld.so.conf.d/opencv.conf'
RUN ldconfig

# Build ffmpeg
RUN apt-get update -qq && apt-get install -y --force-yes \
    libass-dev
WORKDIR /usr/local/src/ffmpeg
RUN ./configure --extra-libs="-ldl" \
                --enable-gpl \
                --enable-libfdk-aac \
                --enable-libfontconfig \
                --enable-libfreetype \
                --enable-libfribidi \
                --enable-libmp3lame \
                --enable-libopus \
                --enable-libtheora \
                --enable-libvorbis \
                --enable-libvpx \
                --enable-libx264 \
                --enable-nonfree
RUN make -j 4
RUN make install

# Remove all tmpfile
WORKDIR /usr/local/
RUN rm -rf /usr/local/src
