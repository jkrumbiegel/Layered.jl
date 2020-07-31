# import VideoIO
import FFMPEG

export record

function record(f_canvas, filename, timestamps; fps = 60, px_per_pt = 1)

    nframes = length(timestamps)
    bname = basename(filename)

    mktempdir() do dir
        for (i, t) in enumerate(timestamps)
            canv = f_canvas(t)
            png(canv, joinpath(dir, "$(lpad(i, 5, '0')).png"); px_per_pt = 1)
        end

        FFMPEG.exe(` -i $dir/%5d.png -framerate $fps $dir/$bname`)
        cp(joinpath(dir, bname), filename, force = true)
    end
end
