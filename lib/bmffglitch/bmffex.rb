require 'bmff'

# At first, I intended to use "refinements" mechanism to minimize the effects of monkey patch, but BMFF::BOX::Base.parse_data
# can't be called from anywhere.  I guess there is something wrong with the inheritance relationship, but I have no idea.
# So I have to use bare monkey patch, sorry.

class BMFF::FileContainer
  def to_s
    @children.map {|box| box.to_s}.join
  end
end

class BMFF::Box::Base
  attr_accessor :raw_data
  def compose(data)
    # size(uint32) + type(uint32)
    size = 4 + 4
    if @type == 'uuid'
      # extended_type(uint8[16])
      size += 16
    end
    # 8 is the size of largesize(uint64)
    if size + 8 + data.length > 0xffffffff
      largesize = size + 8 + data.length 
      size = 1
    else
      size += data.length
    end
    
    sio = StringIO.new("", "r+")
    sio.set_encoding("ascii-8bit")
    sio.extend(BMFF::BinaryAccessor)
    
    sio.write_uint32(size)
    sio.write_ascii(@type)
    sio.write_uint64(largesize) if size == 1
    sio.write_uuid(@usertype) if @type == 'uuid'
    return sio.string + data
  end

  def parse_data
    data_start_pos = @io.pos
    seek_to_end
    data_end_pos = @io.pos
    @io.pos = data_start_pos
    @raw_data = @io.read(data_end_pos - data_start_pos)
    @io.pos = data_start_pos
  end
  
  def to_s
    if container?
      compose(@children.map {|box| box.to_s}.join)
    else
      compose(@raw_data)
    end
  end
end

class BMFF::Box::Full
  def compose(data)
    sio = StringIO.new("", "r+")
    sio.set_encoding("ascii-8bit")
    sio.extend(BMFF::BinaryAccessor)
    
    sio.write_uint8(@version)
    sio.write_uint24(@flags)
    super(sio.string + data)
  end
  
  def parse_data
    @version = io.get_uint8
    @flags = io.get_uint24
    super
  end
end

class BMFF::Box::DataReference
  def to_s
    sio = StringIO.new("", "r+")
    sio.set_encoding("ascii-8bit")
    sio.extend(BMFF::BinaryAccessor)
    
    sio.write_uint32(@entry_count)
    compose(sio.string + @children.map {|box| box.to_s}.join)
  end
end

class BMFF::Box::SampleDescription
  def to_s
    sio = StringIO.new("", "r+")
    sio.set_encoding("ascii-8bit")
    sio.extend(BMFF::BinaryAccessor)
    
    sio.write_uint32(@entry_count)
    compose(sio.string + @children.map {|box| box.to_s}.join)
  end
end

class BMFF::Box::SampleSize
  def to_s
    sio = StringIO.new("", "r+")
    sio.set_encoding("ascii-8bit")
    sio.extend(BMFF::BinaryAccessor)

    sio.write_uint32(@sample_size)
    sio.write_uint32(@sample_count)
    if @sample_size == 0 
      @sample_count.times do |i|
        sio.write_uint32(@entry_size[i])
      end
    end
    compose(sio.string)
  end
end

class BMFF::Box::SyncSample
  def to_s
    sio = StringIO.new("", "r+")
    sio.set_encoding("ascii-8bit")
    sio.extend(BMFF::BinaryAccessor)

    sio.write_uint32(@entry_count)
    @entry_count.times do |i|
      sio.write_uint32(@sample_number[i])
    end
    compose(sio.string)
  end
end

class BMFF::Box::TimeToSample
  def to_s
    sio = StringIO.new("", "r+")
    sio.set_encoding("ascii-8bit")
    sio.extend(BMFF::BinaryAccessor)
      
    sio.write_uint32(@entry_count)
    @entry_count.times do |i|
      sio.write_uint32(@sample_count[i])
      sio.write_uint32(@sample_delta[i])
    end
    compose(sio.string)
  end
end

class BMFF::Box::TimeToSample
  def to_s
    sio = StringIO.new("", "r+")
    sio.set_encoding("ascii-8bit")
    sio.extend(BMFF::BinaryAccessor)
    
    sio.write_uint32(@entry_count)
    @entry_count.times do |i|
      sio.write_uint32(@sample_count[i])
      sio.write_uint32(@sample_delta[i])
    end
    compose(sio.string)
  end
end

class BMFF::Box::CompositionOffset
  def to_s
    sio = StringIO.new("", "r+")
    sio.set_encoding("ascii-8bit")
    sio.extend(BMFF::BinaryAccessor)
    
    sio.write_uint32(@entry_count)
    @entry_count.times do |i|
      sio.write_uint32(@sample_count[i])
      sio.write_uint32(@sample_offset[i])
    end
    compose(sio.string)
  end
end

class BMFF::Box::CompositionOffset
  def to_s
    sio = StringIO.new("", "r+")
    sio.set_encoding("ascii-8bit")
    sio.extend(BMFF::BinaryAccessor)
    
    sio.write_uint32(@entry_count)
    @entry_count.times do |i|
      sio.write_uint32(@sample_count[i])
      sio.write_uint32(@sample_offset[i])
    end
    compose(sio.string)
  end
end

class BMFF::Box::ChunkOffset
  def to_s
    sio = StringIO.new("", "r+")
    sio.set_encoding("ascii-8bit")
    sio.extend(BMFF::BinaryAccessor)

    sio.write_uint32(@entry_count)
    @entry_count.times do |i|
      sio.write_uint32(@chunk_offset[i])
    end
    compose(sio.string)
  end
end

class BMFF::Box::SampleToChunk
  def to_s
    sio = StringIO.new("", "r+")
    sio.set_encoding("ascii-8bit")
    sio.extend(BMFF::BinaryAccessor)
      
    sio.write_uint32(@entry_count)
    @entry_count.times do |i|
      sio.write_uint32(@first_chunk[i])
      sio.write_uint32(@samples_per_chunk[i])
      sio.write_uint32(@sample_description_index[i])
    end
    compose(sio.string)
  end
end

class BMFF::Box::SampleEntry
  def parse_data
    @reserved1 = []
    6.times do
      @reserved1 << io.get_uint8
    end
    @data_reference_index = io.get_uint16
    super
  end
  
  def compose(data)
    sio = StringIO.new("", "r+")
    sio.set_encoding("ascii-8bit")
    
    sio.extend(BMFF::BinaryAccessor)
    6.times do |i|
      sio.write_uint8(@reserved1[i])
    end
    sio.write_uint16(@data_reference_index)
    super(sio.string + data)
  end
end

class BMFF::Box::VisualSampleEntry
  def to_s
    sio = StringIO.new("", "r+")
    sio.set_encoding("ascii-8bit")
    sio.extend(BMFF::BinaryAccessor)
      
    sio.write_uint16(@pre_defined1)
    sio.write_uint16(@reserved2)
    3.times do |i|
      sio.write_uint32(@pre_defined2[i])
    end
    sio.write_uint16(@width)
    sio.write_uint16(@height)
    sio.write_uint32(@horizresolution)
    sio.write_uint32(@vertresolution)
    sio.write_uint32(@reserved3)
    sio.write_uint16(@frame_count)
    sio.write_uint8(@compressorname.length)
    sio.write_ascii(@compressorname)
    (31 - @compressorname.length).times do
      sio.write_uint8(0) #padding with 0
    end
    sio.write_uint16(@depth)
    sio.write_int16(@pre_defined3)
    compose(sio.string + @children.map {|box| box.to_s}.join)
  end
end
