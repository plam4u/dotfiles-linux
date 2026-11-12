#!/bin/sh

case ":${PATH:-}:" in
    *":$HOME/.deno/bin:"*) ;;
    *) export PATH="$HOME/.deno/bin${PATH:+:$PATH}" ;;
esac
