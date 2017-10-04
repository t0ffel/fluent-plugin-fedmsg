# fluent-plugin-fedmsg

## Overview

Fluentd plugin to listen to FedMsg.

## Why this plugin was created?

FedMsg is ZeroMQ-based message bus used by Fedora infrastructure. The plugin allows listening to the message bus and forward the events to other systems.

## Dependencies

This plugin use ffi-rzmq to support ZMQ, and need v3.2 or greater version of ZMQ library installed in your system.

## Installation

You need to install ZeroMQ libraries before installing this plugin (RedHat/CentOS)
```
  # yum install zeromq3 zeromq3-devel
  # fluent-gem install fluent-plugin-fedmsg
```
## Configuration

Here is the sample configuration of the plugin

    <source>
       type fedmsg
       publisher tcp://127.0.0.1:5556
       subkey zmq.,zmq2
       tag_prefix fedmsg
    </source>

* `subkey` is a comma separated list of keys to subscribe. In this example, keys starting "zmq." or "zmq2." will be subscribed.
* `tag_prefix` will prefix the topic name from the message, the resulting string will be the tag.
* `drop_fields` is a comma-separated list of fields to drop from each record. By default the following records are dropped: "username,certificate,i,crypto,signature"

## Copyright

* Copyright (c) 2017- Anton Sherkhonov
* License
  * Apache License, Version 2.0
