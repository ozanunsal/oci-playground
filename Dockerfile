ARG CONTAINER_IMAGE=quay.io/automotive-toolchain/autosd
ARG CONTAINER_TAG=qemu-minimal

FROM ${CONTAINER_IMAGE}:${CONTAINER_TAG}

ARG NAME="AutoSD"
ARG VERSION=

LABEL com.redhat.component="$NAME" \
      name="$NAME" \
      version="$VERSION" \
      usage="This image is useful for running test on rpms using beakerlib and restraint" \
      summary="QA image based on Red Hat In-Vehicle Operating System or CentOS Automotive Stream Distribution images" \
      maintainer="Juanje Ojeda <juanje@redhat.com>"


# Remove extra repos
RUN rm -fv /etc/yum.repos.d/*.repo

# Copy repo files and Epel GPG public key to install restrain packages
COPY etc /etc/

# Install new packages
RUN rpm-ostree install -y \
                sudo \
                openssh-clients \
                openssh-server \
                rsync \
                wget \
                git \
                jq \
                time \
                nfs-utils \
                ncurses \
                beakerlib \
                beaker-client \
                restraint \
                restraint-client \
                podman \
                audit \
                chrony \
                cloud-utils-growpart

# Remove the repos we don't want for the tests
RUN rm -fv /etc/yum.repos.d/{epel.repo,beaker-harness-CentOSStream.repo}

# Add SSH key
RUN mkdir -p /usr/etc-system/
COPY root.keys /usr/etc-system/root.keys
RUN chmod 0600 /usr/etc-system/root.keys
RUN echo 'AuthorizedKeysFile /usr/etc-system/%u.keys' > /etc/ssh/sshd_config.d/30-auth-system.conf

# Enable SSH, but disable the password auth
RUN echo "PasswordAuthentication no" > /etc/ssh/sshd_config.d/30-password-auth.conf \
 && systemctl enable NetworkManager \
 && systemctl enable sshd

# Change the IMAGE_NAME
RUN sed -i 's/minimal/qa/' /etc/build-info

# Add audit to tmpfiles.d
RUN echo "d /var/log/audit 0700 root root - -" >> /usr/lib/tmpfiles.d/rpm-ostree-1-autovar.conf

# Commit the changes with some workarounds to avoid errors
RUN --mount=type=tmpfs,destination=/var ostree container commit

