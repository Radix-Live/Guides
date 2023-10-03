#!/bin/bash

(mv -f /root/babylon-node-config/node-keystore.ks /root/babylon-node-config/node-keystore.validator.ks) && \
  (mv -f /root/babylon-node-config/node-keystore.blank.ks /root/babylon-node-config/node-keystore.ks)
