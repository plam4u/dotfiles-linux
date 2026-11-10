FROM scratch AS checkout

COPY bin/pm /workspace/bin/pm
COPY bundles/ /workspace/bundles/
COPY packages/ /workspace/packages/
COPY share/ /workspace/share/

FROM debian:13-slim AS debian

RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates git stow sudo \
    && rm -rf /var/lib/apt/lists/*

RUN useradd --create-home --user-group --shell /bin/bash pmtest \
    && printf '%s\n' 'pmtest ALL=(root) NOPASSWD: ALL' > /etc/sudoers.d/pmtest \
    && chmod 0440 /etc/sudoers.d/pmtest \
    && ln -s /workspace/bin/pm /usr/local/bin/pm

COPY --from=checkout /workspace/ /workspace/

USER pmtest
ENV HOME=/home/pmtest
WORKDIR /workspace
CMD ["bash"]

FROM archlinux:base AS arch

RUN pacman -Syu --noconfirm --needed git stow sudo \
    && pacman -Scc --noconfirm

RUN useradd --create-home --user-group --shell /bin/bash pmtest \
    && printf '%s\n' 'pmtest ALL=(root) NOPASSWD: ALL' > /etc/sudoers.d/pmtest \
    && chmod 0440 /etc/sudoers.d/pmtest \
    && ln -s /workspace/bin/pm /usr/local/bin/pm

COPY --from=checkout /workspace/ /workspace/

USER pmtest
ENV HOME=/home/pmtest
WORKDIR /workspace
CMD ["bash"]
