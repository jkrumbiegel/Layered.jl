import VideoIO
import Colors
using ProgressMeter

export record

function bgra_array(c::Cairo.CairoSurfaceBase{UInt32})
    bgra_buffer_ptr = ccall((:cairo_image_surface_get_data, Cairo.libcairo), Ptr{UInt8}, (Ptr{Nothing},), c.ptr)
    w = Int(c.width)
    h = Int(c.height)
    arr = unsafe_wrap(Array{UInt8, 3}, bgra_buffer_ptr, (h, w, 4))
    arr_bgra = reinterpret(Colors.BGRA{Colors.N0f8}, arr)
    reshaped = reshape(arr_bgra, h, w)
    permutedims(reshaped, [2, 1])
end

function rgb_array(c)
    bgra = bgra_array(c)
    rgb = Colors.RGB.(bgra)
end

function record(figure_func, filename, framerate::Real, ts; quality=:medium)

    nframes = length(ts)

    first_frame = rgb_array(figure_func(ts[1]))

    full_size = (nframes, size(first_frame)...)
    full_buffer = Array{Colors.RGB{Colors.N0f8}, 3}(undef, full_size...)
    full_buffer[1, :, :, :] = first_frame

    @showprogress 1/3 "Rendering frames..." for (i, t) in enumerate(ts[2:end])
        fig = figure_func(t)
        full_buffer[i, :, :, :] = rgb_array(fig)
    end

    codec_name, props = if quality == :medium
        ("libx264", [:priv_data => ("crf"=>"22","pix_fmt"=>"yuv420p", "profile:v"=>"baseline", "level"=>"3")])
    elseif quality == :fastbig
        ("libx264rgb", [:priv_data => ("crf"=>"0","preset"=>"ultrafast")])
    elseif quality == :slowsmall
        ("libx264rgb", [:priv_data => ("crf"=>"0","preset"=>"ultraslow")])
    # elseif quality == :bitrate
    #     ("libx264", [:bit_rate => 400000,:gop_size => 0,:max_b_frames=>1])
    end

    frames = [view(full_buffer, i, :, :) for i in 1:nframes]
    VideoIO.encodevideo(filename, frames, framerate=framerate, AVCodecContextProperties=props, codec_name=codec_name)

    nothing
end

function record(figure_func, filename, framerate::Real, duration::Real; excludelast=false, kwargs...)
    frames = 0:1//framerate:duration
    if excludelast
        frames = frames[1:end-1]
    end
    record(figure_func, filename, framerate, frames; kwargs...)
end
