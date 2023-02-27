FROM debian:bookworm
LABEL maintainer="Nicholas McDonnell"

ARG DEBIAN_FRONTEND=noninteractive

ENV pip_packages "ansible cryptography"

# Install dependencies.
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
       build-essential \
       iproute2 \
       libffi-dev \
       libssl-dev \
       procps \
       python3-apt \
       python3-dev \
       python3-pip \
       python3-setuptools \
       python3-venv \
       python3-wheel \
       sudo \
       systemd \
       systemd-sysv \
       wget \
    && rm -rf /var/lib/apt/lists/* \
    && rm -Rf /usr/share/doc && rm -Rf /usr/share/man \
    && apt-get clean

# Set up a Python virtual environment to install Ansible. This is necessary
# because Debian 12 (Bookworm) is configured as an externally managed base
# Python environment per PEP 668.
RUN python3 -m venv /.venv
ENV PATH="/.venv/bin:${PATH}"

# Upgrade pip, setuptools, and wheel to the latest versions.
RUN python3 -m pip install --upgrade pip setuptools wheel

# Install Ansible via pip.
RUN pip3 install $pip_packages

COPY initctl_faker .
RUN chmod +x initctl_faker && rm -fr /sbin/initctl && ln -s /initctl_faker /sbin/initctl

# Install Ansible inventory file.
RUN mkdir -p /etc/ansible
RUN echo "[local]\nlocalhost ansible_connection=local" > /etc/ansible/hosts

# Make sure systemd doesn't start agettys on tty[1-6].
RUN rm -f /lib/systemd/system/multi-user.target.wants/getty.target

VOLUME ["/sys/fs/cgroup"]
CMD ["/lib/systemd/systemd"]
