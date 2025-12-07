# peertube-runner

This docker image provides a simple, easy and declarative way to create simple, stateless peertube-runner instances.

I couldn't quite find an image that did *exactly* what I wanted so I decided to create my own.

## Image Variants

Two image variants are available to suit different use cases. All variants support **linux/amd64** and **linux/arm64** architectures and are based on **Debian Trixie**.

### `<version>` `<version>-trixie` (The full-fat original!)
- **Capabilities**: All job types (transcoding + transcription)
- **Job types**: Supports all job types. Customize which job types to target using the `PEERTUBE_RUNNER_JOB_TYPES` env (leave empty for all, or specify: `vod-web-video-transcoding`, `vod-hls-transcoding`, `vod-audio-merge-transcoding`, `live-rtmp-hls-transcoding`, `video-studio-transcoding`, `video-transcription`)
- **Use case**: Single runner handling all workloads, or dedicated transcription-only runner

### `<version>-no-whisper` `<version>-trixie-no-whisper` (Transcoding only - no whisper models for a reduced image size!)
- **Capabilities**: Transcoding jobs only (no transcription)
- **Job types**: `vod-web-video-transcoding`, `vod-hls-transcoding`, `vod-audio-merge-transcoding`, `live-rtmp-hls-transcoding`, `video-studio-transcoding`
- **Use case**: Dedicated transcoding runners

## Usage

At a minimum, the image requires a `PEERTUBE_URL` and `PEERTUBE_RUNNER_TOKEN` to successfully execute. All other environment variables have default values to fall back on.

### Docker

```
docker run ghcr.io/fediverse-games/peertube-runner:latest -e PEERTUBE_URL=https://your-peertube-url.example/ -e PEERTUBE_RUNNER_TOKEN=prrt-yourtoken
```

### Docker Compose

Example docker compose to come.

### Kubernetes

Example kubernetes manifest to come.

## Configuration

| Variable                     | Function                                                  | Default |
| -------------                |--------------                                             | - |
| `PEERTUBE_URL`               | **REQUIRED**: The peertube URL the runner will connect to | N/A |
| `PEERTUBE_RUNNER_TOKEN`      | **REQUIRED**: The peertube runner registration token generated in peertube | N/A |
| `PEERTUBE_RUNNER_JOB_TYPES`     | Which types of jobs the runner will run. **NOTE**: not all images support all job types, refer to Image Variants section above.
`vod-web-video-transcoding`, `vod-hls-transcoding`, `vod-audio-merge-transcoding`, `live-rtmp-hls-transcoding`, `video-studio-transcoding`, `video-transcription` | See Image Variants  |
| `PEERTUBE_JOBS_CONCURRENCY`     | How many runner jobs the instance will process at once | 2  |
| `FFMPEG_THREADS`             | The number of threads FFMPEG should use for each job. 0 is auto | 0 |
| `FFMPEG_NICE`                | The FFMPEG niceness value                                  | -20 |
| `PEERTUBE_RUNNER_NAME`       | THe name/id to assign to the runner.                      | The `HOSTNAME` value |
| `PEERTUBE_RUNNER_DESCRIPTION`| The description to assign to the runner.                  | Peertube Runner |
| `WHISPER_TRANSCRIPTION_MODEL`| The model size for the transcription engine (tiny, base, small, medium, large). | small |

## TO DO:

- Proper documentation.
- Try and get hardware acceleration working (may require changes to the peertube-runner package itself).
