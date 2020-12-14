#! /bin/bash
set -eux
systemctl --user daemon-reload || true

systemctl --user enable server || true
systemctl --user start server

systemctl --user enable backgroundworker || true
systemctl --user start backgroundworker

systemctl --user enable frontend || true
systemctl --user start frontend

