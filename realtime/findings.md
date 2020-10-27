- when compiling with target "web" as recommended, it tries to use the browser's websocket implementation

  - i can use webpack.resolve alias to force the node version
  - but the node version depends on https://github.com/websockets/bufferutil module which is a native module
    - and this requires 'fs' which is not available

- cant compile with target node since most of the modules required by node is not supported by the k6 runtime (fs etc)

other links

- https://github.com/theturtle32/WebSocket-Node/commit/d873a9173f8c73b561704cd477251a4473ec8331

challenge comes because the goja runtime doesn't have node functionality but also doens't have full web functionality (native websocket)
