

# <img src="icon.png" width="24"> CRDT Draw

A collaborative real-time local-first global canvas.

This project is a demonstration of the family of the Dart-native libraries based on [crdt](https://github.com/cachapa/crdt) and the WebSocket-based synchronization layer [crdt_sync](https://github.com/cachapa/crdt_sync).

The project is composed of a Flutter-based client optimized for the web, and a simple server that acts as a central orchestrator.

## Try it out:  https://draw.cachapa.net

Open the site on any browser, desktop or mobile. Open it on multiple browsers, even and see your drawings get replicated in real-time.

Tap the switch on the top-left to go offline and experience the local-first functionality.

Go online again and see your offline changes get immediately synced globally.

## How does it work?

The client instantiates a simple [HashMap-based CRDT dataset](https://github.com/cachapa/crdt). It exists only in-memory on your browser and gets recycled as soon as you leave or reload the page.

As you paint, each pixel you draw gets added to the local dataset which triggers the [sync mechanism](https://github.com/cachapa/crdt_sync) to immediately send the data to the remote server.

In the same way, any changes that happen on the server get immediately pushed to our node, allowing us to see other clients drawing in real time.

When you toggle the switch on the top-left, the connection is closed and changes only happen locally. The same happens if you enable the switch but the server isn't accessible, though in that case the sync mechanism keeps attempting to connect with an [exponential backoff](https://en.wikipedia.org/wiki/Exponential_backoff).

Once connected, there's a quick negotiation with the server to know where both left off, and the delta subset of changes that happened since last sync get transferred in both directions.

This results in the apparent contradiction of a local-first, real-time system. These systems enable robust applications that can display reactive data when online, while retaining most of their functionality when not.

## See also

In-memory hashmaps are nice for demonstration purposes, but they're seldom useful for real applications.

For more permanent storage, the [crdt](https://github.com/cachapa/crdt) package has been extended to use a choice of popular storage frameworks such as [Sqlite](https://github.com/cachapa/sqlite_crdt), [PostgreSQL](https://github.com/cachapa/postgres_crdt) and [Hive](https://github.com/cachapa/hive_crdt).

They are tied together by [crdt_sync](https://github.com/cachapa/crdt_sync) which enables building client/server applications based on any of the above libraries with very little code.