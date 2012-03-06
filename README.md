### Description
Spriteous is a righteous sprite extraction utility. It uses a "reverse flood fill" algorithm to naively obtain each individual sprite from a spritesheet, "sprite" here defined as a contiguous group of pixels which do not match the background color (assumed to be the first pixel) of the sheet.

### Installation
    gem install spriteous

### Usage
Spriteous currently uses the ChunkyPNG library (more specifically, the oily_png C extension), so only that format is supported at this time. On the bright side, this means that a Spriteous instance can easily be initialized either from a filename or raw PNG data:

```ruby
Spriteous.new('sheet.png')
Spriteous.new(File.read 'sheet.png')
mario = Spriteous.new(` curl -s http://i.imgur.com/Fmd9q.png `)
```

**#extract** is where the magic happens. If called with no parameters, it simply returns all of the extracted sprites as an array of ChunkyPNG::Images.

```ruby
sprites = mario.extract
sprites.size # => 85
sprites.each_with_index do |sprite, i|
  puts "Sprite #{i} contains #{sprite.palette.size} colors."
end
```

If you bothered to count the sprites in the linked image, you might have noticed that #size's value is unfortunately a little off. Specifically, it's over by 4, and [zooming way in](http://i.imgur.com/l9xE5.png) reveals why this is the case. The algorithm used relies on all of a sprite's pixels being contiguous, but those damned fireballs just *have* to have disjointed pixels.

Alas, this seems to be an unavoidable consequence of the flood fill algorithm, and I think a major overhaul would be required to properly handle these edge cases. Of course, then the algorithm would break completely on sheets where the sprites are positioned very closely together. The only solution would be to implement content-awareness, but that is beyond the scope of this project, and‒given the plethora of potential sprite styles and sheet layouts‒perhaps even all of computer vision. ("If you seek advice, compel people to prove you wrong.")

Spriteous compromises by allowing for a minimum square pixel value to be passed to #extract.

```ruby
mario.extract(min_size: 2).size # => 81
```

Lossy sprite extraction is unpleasant, sure, but it's at least a slight improvement over grabbing lots of "junk" sprites.

##### Saving

More often than not, the intention will simply be to save the extracted sprites rather than do something with them individually. While you could use #each_with_index to implement this functionality, it's much saner to just pass the *save_format* option to #extract.

```ruby
mario.extract(min_size: 2, save_format: 'sprites/mario/%02d.png')
```

Saving a collection of sprites by index is pretty much the only reasonable way to do it, so some form of `%d` must be present, but that's the only hard-and-fast requirement.

### Roadmap
Spriteous was predominantly created to assist in a personal project of mine, and it has served that purpose quite well. It certainly caters to a relatively small niche, as the scarcity of available options would indicate, but during my research I came upon several people seeking such a tool, only to be told (on spriting-centric forums, no less!) that their only option was to manually crop. If nothing else, I hope those previously lost souls find their way here.

As is the case in any creative endeavor, this project's growth would please its designer immensely. Spriteous is by no means feature-complete, and indeed it very likely tackles the problem in a non-optimal way. Following is a list of my own criticisms and potential avenues for improvement.

##### TODO
* Implement a better algorithm. Flood fill was nice and easy, but there are numerous ways to improve upon it. I've entertained the idea of using a moving box to determine the edges of a sprite, but irregular dimensions and transparency make this difficult.
* Support, at the very least, JPG and GIF formats, likely via RMagick.
* Improve speed when working with large spritesheets, probably by avoiding checking the entire image for the next non-transparent pixel when looking for the next sprite, though how to do this presently escapes me.
* Cleverly determine when the background color has changed, as is a common occurrence between sections.
* Attempt to remove non-sprite portions of a sheet like the ripper's tag and irrelevant text, instead of it being a manual step for the user.

##### Contributing
Comments, criticisms, and code are all heartily welcome.