# Media: where it lives and how to add it

All photos and videos are served from **Cloudinary**; none are bundled in the app.
The app only knows the public *cloud name* — never an API key or secret.

## Configure
```
flutter run --dart-define=CLOUDINARY_CLOUD_NAME=<your-cloud-name>
```
Without it, every media slot shows a labelled placeholder (the brief for the photo/video).

## Folder layout (Cloudinary Media Library)
| Folder | Contents | Public id |
|---|---|---|
| `calesthetics/exercises/` | the 98 exercise videos | file name from the exercise guide, without `.mp4` |
| `calesthetics/slots/` | UI photos (welcome hero, plan hero, …) | slot id from `media_manifest.dart` |

Example: `calesthetics_001_wall_push_up_beginner_v1.mp4` is uploaded to
`calesthetics/exercises/` with public id `calesthetics_001_wall_push_up_beginner_v1`.
The 17 repeated exercises reuse the first entry's video, so only 98 files exist.

## Rules
- Exercise videos: 9:16, 1080×1920+, 30 fps, no music/text (see the exercise guide).
- Never overwrite an approved video — upload `…_v2.mp4` and update the catalog's file name.
- Delivery uses `q_auto,f_auto` (and `vc_auto` for video) so devices get the smallest good file.
- Uploading is done in the Cloudinary dashboard (or a server-side script) — **never from the app**.

## Caching & offline
Photos are disk-cached by `cached_network_image`; once seen they work offline.
Exercise videos stream; the workout player preloads the next exercise's video while the current one plays.

## Adding a new photo slot
1. Add a `MediaSlotSpec` to `lib/features/media/data/media_manifest.dart` (id + brief).
2. Upload the photo to `calesthetics/slots/` with that id.
3. Use `MediaSlot(slot: …)` in the UI.
