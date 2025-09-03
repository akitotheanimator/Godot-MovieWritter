This is a direct translation of godot's MovieWritter. This version works on gameplay, can add frames to a AVI, and encode the video on runtime.
Essentially, a AVI encoder.

It's pretty light, though, untested on weaker devices.

Functions:
## func WriteInit(video_res: Vector2i, fps: int, output_path: String, audio_mix_rate: int = 48000) -> Error:
This starts writting a AVI video.
* video_res: The resolution of the output video (i.e: 1280x720, 1440x1080, etc).
* fps: The fps of the video, in int.
* output_path: The path in which the AVI video will be created.
* audio_mix_rate: The video's audio samplerate.


## func WriteFrame(image: Image, audio_data: PackedByteArray, frame_image_quality: float = 1) -> Error:
This writes a singular frame on the AVI file.
* image: The frame to be added on the AVI stream.
* audio_data: The audio data to be added on this frame.
* frame_image_quality: The image quality of the JPEG (1 = max quality, 0 = min quality)


  ## func WriteEnd():
  This finishes the AVI stream.


The main workflow for writting a frame is:

*creating one AVI video:*    WriteInit > WriteFrame > WriteEnd


Calling the functions out of this order will probably return a error.
  
