require 'vips'

# This class is almost a direct copy of Vips.rb from carrierwave-Vips
class EasyImage
  class Vips

    def initialize(path)
      @path = path
      @image = ::Vips::Image.new_from_file path
    end

    ##
    # See EasyImage::resize_to_fit
    def resize_to_fit(width, height)
      resize_image width, height
    end

    ##
    # See EasyImage::resize_to_fill
    def resize_to_fill(width, height)
      resize_image width, height, :max

      if @image.width > width
        top = 0
        left = (@image.width - width) / 2
      elsif @image.height > height
        left = 0
        top = (@image.height - height) / 2
      else
        left = 0
        top = 0
      end

      @image = @image.extract_area left, top, width, height
    end

    ##
    # See EasyImage::resize_to_limit
    def resize_to_limit(width, height)
      if width < @image.width || height < @image.height
        resize_image width, height
      end
    end

    ##
    # See EasyImage::save
    # The format param accepts 'jpg' or 'png'
    def save(path, format=nil, quality=nil)
      ext = File.extname(path)[1..-1]
      if not format
        format = (ext and ext.downcase == 'png') ? 'png' : 'jpg'
      end

      output_path = path.sub(/\.\w+$/, '') + ".#{format}"

      @image.write_to_file output_path, Q: (quality || 80)
      # Reset the image so we can use it again
      @image = ::Vips::Image.new_from_file @path

      output_path
    end

    private

    def resize_image(width, height, min_or_max=:min)
      ratio = get_ratio width, height, min_or_max
      return @image if ratio == 1

      if jpeg? # find the shrink ratio for loading
        shrink_factor = [8, 4, 2, 1].find {|sf| 1.0 / ratio >= sf }
        shrink_factor = 1 if shrink_factor == nil
        @image = ::Vips::Image.jpegload(@path).shrink(shrink_factor, shrink_factor)
        ratio = get_ratio width, height, min_or_max
      elsif png?
        @image = ::Vips::Image.pngload(@path)
      end

      if ratio > 1
        @image = @image.resize ratio
      else
        if ratio <= 0.5
          factor = (1.0 / ratio).floor
          @image = @image.shrink(factor)
          @image = @image.tilecache(@image.width, 1, 30)
          ratio = get_ratio width, height, min_or_max
        end
        @image = @image.resize ratio
      end
    end

    def get_ratio(width, height, min_or_max=:min)
      width_ratio = width.to_f / @image.width
      height_ratio = height.to_f / @image.height
      [width_ratio, height_ratio].send(min_or_max)
    end

    def jpeg?
      @path =~ /.*jpg$/i or @path =~ /.*jpeg$/i
    end

    def png?
      @path =~ /.*png$/i
    end
  end
end
