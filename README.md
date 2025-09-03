This is a direct translation of godot's MovieWritter. This version works on gameplay, can add frames to a AVI, and encode the video on runtime.
Essentially, a AVI encoder.

It's pretty light, though, untested on weaker devices.

Functions:
## func WriteInit(video_res: Vector2i, fps: int, output_path: String, audio_mix_rate: int = 48000)
This starts writting a AVI video. *Writting a frame before calling for WriteInit will result in a error.*
* video_res: The resolution of the output video (i.e: 1280x720, 1440x1080, etc).
* fps: The fps of the video, in int.
* output_path: The path in which the AVI video will be created.
* audio_mix_rate: The video's audio samplerate.
