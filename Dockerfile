FROM debian AS build

RUN apt-get update && apt-get install -y \
	libstdc++ \
	libtool \
	curl

RUN curl --output clever-tools_linux.tar.gz https://clever-tools.cellar.services.clever-cloud.com/releases/1.4.2/clever-tools-1.4.2_linux.tar.gz \
	&& mkdir clever-tools_linux \
	&& tar xvzf clever-tools_linux.tar.gz -C clever-tools_linux --strip-components=1 \
	&& cp clever-tools_linux/clever /usr/local/bin

# Only grep the clever-tools binary and his libraries for the release stage
# We use ldd to find the shared object dependencies.
RUN \
	mkdir -p /tmp/fakeroot/lib  && \
	cp $(ldd /usr/local/bin/clever | grep -o '/.\+\.so[^ ]*' | sort | uniq) /tmp/fakeroot/lib && \
	for lib in /tmp/fakeroot/lib/*; do strip --strip-all $lib; done && \
	mkdir -p /tmp/fakeroot/bin/ && \
	cp /usr/local/bin/clever /tmp/fakeroot/bin/


FROM busybox AS release

LABEL version="1.4.2" \
	maintainer="Clever Cloud CI <ci@clever-cloud.com>" \
	description="Command Line Interface for Clever Cloud." \
	license="MIT"

WORKDIR /

COPY --from=build /tmp/fakeroot/ /

# The loader search ld-linux-x86-64.so.2 in /lib64 but the folder does not exist
RUN ln -s lib lib64

ENTRYPOINT ["clever"]
