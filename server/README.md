# crdt_draw

A collaborative real-time local-first global canvas.

## Getting Started

This project is the server part.

It implements a Dart WebSocket server based on [crdt_sync](https://github.com/cachapa/crdt_sync) and waits for incoming [clients](https://github.com/cachapa/crdt_draw/tree/master/client).

You can run the server with the [Dart SDK](https://dart.dev/get-dart)
like this:

```
$ dart run bin/server.dart [port]
```
