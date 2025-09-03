class_name AVIEncoder

var f: FileAccess
var base_path: String
var fps: int
var frame_count: int = 0
var total_frames_ofs: int
var total_frames_ofs2: int
var total_frames_ofs3: int
var total_audio_frames_ofs4: int
var movi_data_ofs: int
var audio_block_size: int
var jpg_frame_sizes: Array = []

var mix_rate: int
var speaker_mode: int = 0
# var audio_sample_count: int = 0 # Optional: use this for accurate audio frame count

var recording: bool = false

func _exit_tree():
	if recording:
		WriteEnd()
## Starts writting a AVI video.
func WriteInit(video_res: Vector2i, fps: int, output_path: String, audio_mix_rate: int = 48000) -> Error:
	recording = true
	mix_rate = audio_mix_rate
	base_path = output_path
	f = FileAccess.open(base_path, FileAccess.WRITE)
	if f == null:
		return ERR_CANT_OPEN
	
	self.fps = fps
	
	f.store_buffer("RIFF".to_ascii_buffer())
	f.store_32(0) # Placeholder for total file size
	f.store_buffer("AVI ".to_ascii_buffer())
	f.store_buffer("LIST".to_ascii_buffer())
	f.store_32(300)
	f.store_buffer("hdrl".to_ascii_buffer())
	f.store_buffer("avih".to_ascii_buffer())
	f.store_32(56)
	
	f.store_32(1000000 / fps) # Microseconds per frame

	var estimated_bitrate = video_res.x * video_res.y * 3 * fps
	f.store_32(estimated_bitrate) # Max bytes per second (estimate)

	f.store_32(0) # Padding Granularity
	f.store_32(16)
	total_frames_ofs = f.get_position()
	f.store_32(0) # Total frames (update later)
	f.store_32(0) # Initial frames
	f.store_32(1) # Streams
	f.store_32(0) # Suggested buffer size
	f.store_32(video_res.x)
	f.store_32(video_res.y)
	for i in range(4):
		f.store_32(0) # Reserved
	
	f.store_buffer("LIST".to_ascii_buffer())
	f.store_32(132)
	f.store_buffer("strl".to_ascii_buffer())
	f.store_buffer("strh".to_ascii_buffer())
	f.store_32(48)
	f.store_buffer("vids".to_ascii_buffer())
	f.store_buffer("MJPG".to_ascii_buffer())
	f.store_32(0)
	f.store_16(0)
	f.store_16(0)
	f.store_32(0)
	f.store_32(1)
	f.store_32(fps)
	f.store_32(0)
	total_frames_ofs2 = f.get_position()
	f.store_32(0)
	f.store_32(0)
	f.store_32(0)
	f.store_32(0)
	
	f.store_buffer("strf".to_ascii_buffer())
	f.store_32(40)
	f.store_32(40)
	f.store_32(video_res.x)
	f.store_32(video_res.y)
	f.store_16(1)
	f.store_16(24)
	f.store_buffer("MJPG".to_ascii_buffer())
	f.store_32(((video_res.x * 24 / 8 + 3) & 0xFFFFFFFC) * video_res.y)
	f.store_32(0)
	f.store_32(0)
	f.store_32(0)
	f.store_32(0)
	
	f.store_buffer("LIST".to_ascii_buffer())
	f.store_32(16)
	f.store_buffer("odml".to_ascii_buffer())
	f.store_buffer("dmlh".to_ascii_buffer())
	f.store_32(4)
	total_frames_ofs3 = f.get_position()
	f.store_32(0)
	
	# Audio
	var bit_depth: int = 32
	var channels: int = 2
	match speaker_mode:
		AudioServer.SPEAKER_MODE_STEREO:
			channels = 2
		AudioServer.SPEAKER_SURROUND_31:
			channels = 4
		AudioServer.SPEAKER_SURROUND_51:
			channels = 6
		AudioServer.SPEAKER_SURROUND_71:
			channels = 8
	
	var blockalign: int = bit_depth / 8 * channels
	#audio_block_size = (mix_rate / fps) * blockalign
	audio_block_size = (mix_rate / fps) * blockalign
	
	f.store_buffer("LIST".to_ascii_buffer())
	f.store_32(84)
	f.store_buffer("strl".to_ascii_buffer())
	f.store_buffer("strh".to_ascii_buffer())
	f.store_32(48)
	f.store_buffer("auds".to_ascii_buffer())
	f.store_32(0)
	f.store_32(0)
	f.store_16(0)
	f.store_16(0)
	f.store_32(0)
	f.store_32(blockalign)
	f.store_32(mix_rate * blockalign)
	f.store_32(0)
	total_audio_frames_ofs4 = f.get_position()
	f.store_32(0)
	f.store_32(12288)
	f.store_32(0xFFFFFFFF)
	f.store_32(blockalign)
	
	f.store_buffer("strf".to_ascii_buffer())
	f.store_32(16)
	f.store_16(1)
	f.store_16(channels)
	f.store_32(mix_rate)
	f.store_32(mix_rate * blockalign)
	f.store_16(blockalign)
	f.store_16(bit_depth)
	
	f.store_buffer("LIST".to_ascii_buffer())
	movi_data_ofs = f.get_position()
	f.store_32(0)
	f.store_buffer("movi".to_ascii_buffer())
	
	return OK
## Writes a frame on the current AVI stream.
func WriteFrame(image: Image, audio_data: PackedByteArray, frame_image_quality: float = 1) -> Error:
	if f == null:
		return ERR_UNCONFIGURED
	
	var jpg_buffer: PackedByteArray = image.save_jpg_to_buffer(frame_image_quality)
	if jpg_buffer.size() == 0:
		return ERR_FILE_CORRUPT
	
	var s: int = jpg_buffer.size()
	f.store_buffer("00db".to_ascii_buffer())
	f.store_32(s)
	f.store_buffer(jpg_buffer)
	if s & 1:
		f.store_8(0)
		s += 1
	jpg_frame_sizes.append(s)
	
	# Fix audio data length
	if audio_data.size() < audio_block_size:
		var padded = PackedByteArray()
		padded.resize(audio_block_size)
		for i in range(audio_data.size()):
			padded[i] = audio_data[i]
		audio_data = padded
	elif audio_data.size() > audio_block_size:
		audio_data = audio_data.slice(0, audio_block_size)
	
	f.store_buffer("01wb".to_ascii_buffer())
	f.store_32(audio_block_size)
	f.store_buffer(audio_data)
	
	# Optional: count samples manually
	# audio_sample_count += audio_block_size / (bit_depth / 8)

	frame_count += 1
	return OK
## Finishes the AVI stream.
func WriteEnd():
	if not recording or f == null or frame_count == 0:
		return
	
	recording = false
	
	f.store_buffer("idx1".to_ascii_buffer())
	f.store_32(8 * 4 * frame_count)
	
	var ofs: int = 4
	var all_data_size: int = 0
	
	for i in range(frame_count):
		f.store_buffer("00db".to_ascii_buffer())
		f.store_32(16)
		f.store_32(ofs)
		f.store_32(jpg_frame_sizes[i])
		
		ofs += jpg_frame_sizes[i] + 8
		
		f.store_buffer("01wb".to_ascii_buffer())
		f.store_32(16)
		f.store_32(ofs)
		f.store_32(audio_block_size)
		
		ofs += audio_block_size + 8
		all_data_size += jpg_frame_sizes[i] + audio_block_size
	
	var file_size: int = f.get_position()
	f.seek(4)
	f.store_32(file_size - 8) # Corrected RIFF size
	
	f.seek(total_frames_ofs)
	f.store_32(frame_count)
	f.seek(total_frames_ofs2)
	f.store_32(frame_count)
	f.seek(total_frames_ofs3)
	f.store_32(frame_count)
	
	f.seek(total_audio_frames_ofs4)
	f.store_32(frame_count * mix_rate / fps) # Or use: audio_sample_count
	
	f.seek(movi_data_ofs)
	f.store_32(all_data_size + 4 + 16 * frame_count)
	
	f = null
