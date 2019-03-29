# BMFFGlitch

BMFFGlitch enables you to destroy your files stored in ISO Base Media File Format(BMFF) and its relatives(such as MP4/MOV).
BMFFGlitch makes use of [BMFF library](https://github.com/zuku/bmff/) made by Takayuki OGISO, and is influenced by 
[AviGlitch](http://ucnv.github.io/aviglitch/) made by ucnv.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'bmffglitch'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install bmffglitch

## Usage

```ruby
  require 'bmffglitch'

  bmff = BMFFGlitch.open("/path/to/input.mp4")
  bmff.samples.each do |sample|
    if sample.is_syncsample?
      sample.data.gsub!(/\d/, '0')
    end
  end
  bmff.output('/path/to/output.mp4')
```

This library also includes a command line tool named `bmffdtmsh`.
It creates the syncsample(keyframe)-removed video.

```sh
  $ bmffdtmsh /path/to/your.mp4 -o /path/to/broken.mp4
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/sabishirop/bmffglitch. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Bmffglitch project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/bmffglitch/blob/master/CODE_OF_CONDUCT.md).
