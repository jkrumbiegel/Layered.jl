import VideoIO
import Colors
using ProgressMeter

export record

function rgba_array(fig)
    fig.canvas.draw()
    arr = Vector{UInt8}(fig.canvas.buffer_rgba())
    arr_rgba = reinterpret(Colors.RGBA{Colors.N0f8}, arr)
    l, b, w, h = Int.(fig.bbox.bounds)
    permutedims(reshape(arr_rgba, h, w), [2, 1])
end

function rgb_array(fig)
    rgba = rgba_array(fig)
    rgb = Colors.RGB.(rgba)
end

function record(figure_func, filename, framerate, ts)

    nframes = length(ts)

    first_frame = rgb_array(figure_func(ts[1]))

    full_size = (nframes, size(first_frame)...)
    full_buffer = Array{Colors.RGB{Colors.N0f8}, 3}(undef, full_size...)
    full_buffer[1, :, :, :] = first_frame

    @showprogress 1/3 "Rendering frames..." for (i, t) in enumerate(ts[2:end])
        full_buffer[i, :, :, :] = rgb_array(figure_func(t))
    end

    props = [:priv_data => ("crf"=>"22","preset"=>"medium")]
    frames = [view(full_buffer, i, :, :) for i in 1:nframes]
    VideoIO.encodevideo(filename, frames, framerate=framerate, AVCodecContextProperties=props)

    nothing
end
