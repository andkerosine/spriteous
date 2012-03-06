#coding: utf-8
require 'fileutils'
require 'oily_png'

class Spriteous
  def initialize(data)
    # Allow for creation from either raw PNG data or a file.
    meth = data[0] == "\x89" ? :from_string : :from_file
    @img = ChunkyPNG::Image.send meth, data

    back, @w = @img.pixels.first, @img.width

    # The original image's pixels get modified in place to erase the background
    # color, They're duplicated because the algorithm relies on "erasing" found
    # pixels, and we eventually need the originals to construct the sprites.
    @pixels = @img.pixels.map! { |p| p == back ? 0 : p }.dup
  end

  # A "reverse flood fill" algorithm for finding all of the pixels that belong
  # to a given sprite. Rather than finding and replacing background pixels, it
  # looks for a contiguous path starting from the first non-transparent pixel.
  def traverse(pixel)
    queue = [pixel]

    # Used for checking the target's adjacent pixels. All eight directions are
    # checked to avoid missing single diagonal pixels at the edges.
    neighbors = [-@w - 1, -@w, -@w + 1, -1, 1, @w - 1, @w, @w + 1]

    until queue.empty?
      p = queue.pop

      if @pixels[p] > 0
        # Store this non-transparent pixel's index and then make it transparent
        # to avoid unnecessarily checking it again from a neighbor.
        @pixels[(@found << p).last] = 0

        # Apply the eight cardinal directions to the current pixel's index and
        # prepare them to be checked on the next iteration.
        queue.concat neighbors.map { |n| p + n }
      end
    end
  end

  # Entry point for the traverse method defined above. Returns array of sprites
  # (instances of ChunkyPNG::Image) if called without the argument. save_format
  # should be a format string that specifies %d in some way, as this is used to
  # generate the names of the ripped sprites. Example: 'sprites/mario/%03d.png'
  def extract(opts = {})
    sprites = []

    # Sprites are erased as they're found, so we're done when the entire image
    # is comprised of a single color value, 0 (transparent) in this case.
    while @pixels.uniq.size > 1
      @found = []

      # Find the next sprite (first non-transparent pixel) and traverse from it
      # until there is no contiguous direction to continue in. @found will then
      # contain all of the pixel indices for the current sprite.
      traverse @pixels.find_index { |p| p > 0 }

      # @found contains pixel indices, but now we need coordinate data.
      x, y = @found.map { |f| f % @w }, @found.map { |f| f / @w }

      # Determine the sprite's bounding box (top, left, width, height), crop it
      # from the original image, and push it to the collection unless a minimum
      # size is desired and the resulting sprite's dimensions don't satisfy it.
      box = [x.min, y.min, (w = x.max - x.min + 1), (h = y.max - y.min + 1)]
      sprites << @img.crop(*box) if w * h >= opts[:min_size].to_i
    end

    return sprites unless opts[:save_format]

    unless opts[:save_format].include? '%d'
      raise ArgumentError, "%d is required to properly save extracted sprites."
    end

    dir = opts[:save_format].split('/')[0..-2].join '/'
    FileUtils.mkdir_p dir unless dir.empty?
    sprites.each_with_index { |s, i| s.save opts[:save_format] % i }
  end
end