require 'bmffglitch/version'
require 'bmffglitch/bmffex'
require 'bmffglitch/base'
require 'bmffglitch/sample'

# BMFFGlitch: BMFFGlitch: A library to destroy your movies stored in ISO Base Media File Format(BMFF)
#             and its relatives(such as MP4), like AviGlitch
#
# == Synopsis:
#
# You can manipulate each sample(this may be video frame or audio data), like this:
#
#   bmff = BMFFGlitch.open("/path/to/input.mp4")
#   bmff.samples.each do |sample|
#     if sample.is_syncsample?
#       sample.data.gsub!(/\d/, '0')
#     end
#   end
#   bmff.output('/path/to/output.mp4')

module BMFFGlitch
  def self.open(path)
    BMFFGlitch::Base.new(path)
  end
end
